addpath(genpath('./Classes'));
addpath(genpath('./Data Structure'));
addpath(genpath('./Evaluation Scripts'));
addpath(genpath('./Library'));
addpath(genpath('./Algorithm'));
addpath(genpath('./Voronoi Debug Scripts'));


format long;
CONST_PARAM = Simulation_Parameter();

%% Agent handler
rng(8);
vConstList = 10 .* ones(1,CONST_PARAM.N_AGENT);
wOrbitList = 0.8 .* ones(1,CONST_PARAM.N_AGENT);
%centerCoord = [100, 100];    % deploy all agents near this coord
rXY = 100;                   % agents formualates a circle at the beginning
startPose(:,1) = rXY.*rand(CONST_PARAM.N_AGENT,1); %x
startPose(:,2) = rXY.*rand(CONST_PARAM.N_AGENT,1); %y
startPose(:,3) = zeros(CONST_PARAM.N_AGENT,1); %theta
agentHandle = Agent_Controller.empty(CONST_PARAM.N_AGENT, 0);
for k = 1 : CONST_PARAM.N_AGENT
    agentHandle(k) = Agent_Controller(CONST_PARAM.TIME_STEP, CONST_PARAM.ID_LIST(k), CONST_PARAM.BOUNDARIES_COEFF, startPose(k,:), vConstList(k), wOrbitList(k));
end

% Instance of logger for data post processing, persistent over all files
logger = DataLogger(CONST_PARAM, startPose, vConstList, wOrbitList);

%% MAIN
%% Centralized Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(CONST_PARAM.MODE == "Centralized")
    centralCom = Centralized_Controller(CONST_PARAM.N_AGENT, CONST_PARAM.BOUNDARIES_COEFF, CONST_PARAM.BOUNDARIES_VERTEXES);
    
    for iteration = 1: CONST_PARAM.MAX_ITER
        %% Agent Move
        newPose_3d = zeros(CONST_PARAM.N_AGENT, 3);
        newPoseVM_2d = zeros(CONST_PARAM.N_AGENT, 2);
        for k = 1: CONST_PARAM.N_AGENT
            agentHandle(k).move();
            newPose_3d(k,:) = agentHandle(k).AgentPose_3d(:);
            newPoseVM_2d(k,:) = agentHandle(k).VMCoord_2d(:);
        end

        [Info, poseCVT_2D, ControlInput, V_BLF_List] = centralCom.updateCoverage(newPose_3d, newPoseVM_2d, wOrbitList);

        for k = 1: CONST_PARAM.N_AGENT
            agentHandle(k).w = ControlInput(k);
        end

        % Displaying for debugging
        fprintf('Centralized. Iter: %d L: %f \n',iteration, sum(V_BLF_List));

        % Logging
        loggedTopics.CurPose = newPose_3d;
        loggedTopics.CurPoseVM = newPoseVM_2d;
        loggedTopics.CurPoseCVT = poseCVT_2D;
        loggedTopics.CurAngularVel = ControlInput;
        loggedTopics.LyapunovCost = V_BLF_List;
        logger.logCentralizedController(loggedTopics);
    end

%% Decentralized Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    %% Voronoi Computer
    VoronoiCom = Voronoi2D_Handler(9999, CONST_PARAM.BOUNDARIES_VERTEXES);
    
    %% Communication Link for data broadcasting (GBS : global broadcasting service)
    GBS = Communication_Link(CONST_PARAM.N_AGENT, CONST_PARAM.ID_LIST); 
    for iteration = 1: CONST_PARAM.MAX_ITER
        %% Logging instances
        pose_3d_list = zeros(CONST_PARAM.N_AGENT, 3);
        CVT_2d_List = zeros(CONST_PARAM.N_AGENT, 2);
        Vk_List = zeros(CONST_PARAM.N_AGENT, 1);
        vmCmoord_2d_list = zeros(CONST_PARAM.N_AGENT, 2);

        %% Thread Voronoi Update - Agent interacts with the "nature" and receive the partitions information
        for k = 1: CONST_PARAM.N_AGENT
           [pose_3d_list(k,:), vmCmoord_2d_list(k, :)] = agentHandle(k).getPose();
        end
        %% Update new coordinates to the Environment
        [v,c] = VoronoiCom.exec_partition(vmCmoord_2d_list, CONST_PARAM.ID_LIST);

        %% Thread Agents communicate with adjacent agents through the communication link GBS (sharing dC_dz)
        for k = 1 : CONST_PARAM.N_AGENT 
           %% Mimic the behaviour of Voronoi Topology
           [voronoiInfo, isAvailable] = VoronoiCom.get_Voronoi_Parition(agentHandle(k).ID);        
           if(isAvailable)
                [CVT, neighborPDCVT] = agentHandle(k).computePartialDerivativeCVT(voronoiInfo);
                GBS.uploadVoronoiPartialDerivativeProperty(agentHandle(k).ID, neighborPDCVT);
                CVT_2d_List(k,:) = CVT;
           else
                error("Unavailable Voronoi information required by agent %d", CONST_PARAM.ID_LIST(k));
           end
        end

        %% Thread Agent move according to the received information from the adjacent agents (compute control output)
        for k = 1 : CONST_PARAM.N_AGENT 
           %% Perform the control algorithm
           [report, isAvailable] = GBS.downloadVoronoiPartialDerivativeProperty(agentHandle(k).ID);  
           %% Move
           if(isAvailable)
               Vk_List(k) = agentHandle(k).computeControlInput(report);
               %Vk_List(k) = agentHandle(k).computeControlSimple();
               agentHandle(k).move();
           else
               % Pass through so
               error("Unavailable information required by agent %d", CONST_PARAM.ID_LIST(k));
           end    
        end

        %% Logging
        logger.logDecentralized(pose_3d_list, vmCmoord_2d_list, CVT_2d_List, Vk_List);
        fprintf("Decentralized. Iter: %d. L: %f \n", iteration, sum(Vk_List)); 
    end
    
end
