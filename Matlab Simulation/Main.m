addpath(genpath('./Classes'));
addpath(genpath('./Data Structure'));
addpath(genpath('./Evaluation Scripts'));
addpath(genpath('./Library'));
addpath(genpath('./Algorithm'));
addpath(genpath('./Voronoi Debug Scripts'));


format long;
CONST_PARAM = Simulation_Parameter(1);

%% Some adjustable control parameter, will be moved to Simulation_Parameter later
rng(4);
V_CONST_LIST = 5 .* ones(1,CONST_PARAM.N_AGENT);
W_ORBIT_LIST = 0.8 .* ones(1,CONST_PARAM.N_AGENT);
Q_2x2 = 2 * eye(2);
P = 1;
rXY = 30;                   % agents formualates a circle at the beginning
startPose = zeros(CONST_PARAM.N_AGENT, 3);
startPose(:,1) = rXY.*rand(CONST_PARAM.N_AGENT,1); %x
startPose(:,2) = rXY.*rand(CONST_PARAM.N_AGENT,1); %y
startPose(:,3) = zeros(CONST_PARAM.N_AGENT,1); %theta
agentHandle = Agent_Controller.empty(CONST_PARAM.N_AGENT, 0);

%% Agent handler
for k = 1 : CONST_PARAM.N_AGENT
    agentHandle(k) = Agent_Controller(CONST_PARAM.TIME_STEP, CONST_PARAM.ID_LIST(k), CONST_PARAM.BOUNDARIES_COEFF, ...
                    startPose(k,:), V_CONST_LIST(k), W_ORBIT_LIST(k), Q_2x2, P);
end

% Instance of Logger for data post processing, persistent over all files
Logger = DataLogger(CONST_PARAM, startPose, V_CONST_LIST, W_ORBIT_LIST);

%% MAIN
%% Centralized Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(CONST_PARAM.MODE == "Centralized")
    centralCom = Centralized_Controller(CONST_PARAM.N_AGENT, CONST_PARAM.BOUNDARIES_COEFF, CONST_PARAM.BOUNDARIES_VERTEXES, Q_2x2);
    
    for iteration = 1: CONST_PARAM.MAX_ITER
        %% Agent Move
        newPose_3d = zeros(CONST_PARAM.N_AGENT, 3);
        newPoseVM_2d = zeros(CONST_PARAM.N_AGENT, 2);
        for k = 1: CONST_PARAM.N_AGENT
            [newPose_3d(k,:), newPoseVM_2d(k,:)] =  agentHandle(k).getPose();  
        end

        [Info, poseCVT_2D, ControlOutput, V_BLF_List] = centralCom.updateCoverage(newPose_3d, newPoseVM_2d, W_ORBIT_LIST);

        for k = 1: CONST_PARAM.N_AGENT
            agentHandle(k).move(ControlOutput(k));
        end

        % Displaying for debugging
        fprintf('Centralized. Iter: %d L: %f \n',iteration, sum(V_BLF_List));

        % Logging
        Logger.log(newPose_3d, newPoseVM_2d, poseCVT_2D, V_BLF_List, ControlOutput);
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
        ControlOutput = zeros(CONST_PARAM.N_AGENT, 1);
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
               % Barrier Lyapunov based controller 
               [Vk_List(k), ControlOutput(k)] = agentHandle(k).computeControlInput(report);
               % Controller proposed by Qingchen
               %[Vk_List(k), ControlOutput(k)] = agentHandle(k).computeControlSimple(); 
               agentHandle(k).move(ControlOutput(k));
           else
               % Pass through so
               error("Unavailable information required by agent %d", CONST_PARAM.ID_LIST(k));
           end    
        end

        %% Logging
        Logger.log(pose_3d_list, vmCmoord_2d_list, CVT_2d_List, Vk_List, ControlOutput);
        fprintf("Decentralized. Iter: %d. L: %f \n", iteration, sum(Vk_List)); 
    end
    
end
