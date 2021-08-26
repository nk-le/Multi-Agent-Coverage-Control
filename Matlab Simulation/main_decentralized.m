addpath('./Data Structure');
addpath('./Evaluation Scripts');
addpath('./Library');
addpath('./Voronoi Debug Scripts');

format long;

CONST_PARAM = Simulation_Parameter();

%% Voronoi Computer
VoronoiCom = Voronoi2D_Handler();
VoronoiCom.setup(CONST_PARAM.BOUNDARIES_VERTEXES);

%% Communication Link for data broadcasting (GBS : global broadcasting service)
GBS = Communication_Link(CONST_PARAM.N_AGENT, CONST_PARAM.ID_LIST); 

%% Agent handler
vConstList = 15 .* ones(1,CONST_PARAM.N_AGENT);
wOrbitList = 0.8 .* ones(1,CONST_PARAM.N_AGENT);
centerCoord = [100, 100];    % deploy all agents near this coord
rXY = 30;                   % agents formualates a circle at the beginning
startPose = zeros(CONST_PARAM.N_AGENT, 3);
startPose(:,1) = centerCoord(1) + rXY.*rand(CONST_PARAM.N_AGENT,1); %x
startPose(:,2) = centerCoord(2) + rXY.*rand(CONST_PARAM.N_AGENT,1); %y
startPose(:,3) = zeros(CONST_PARAM.N_AGENT,1); %theta
agentHandle = Agent_Controller.empty(CONST_PARAM.N_AGENT, 0);
%agentConfig.vConstList = zeros(CONST_PARAM.CONST_PARAM.N_AGENT, 1);
%agentConfig.vConstList(1) = 15; 
for k = 1 : CONST_PARAM.N_AGENT
    agentHandle(k) = Agent_Controller(CONST_PARAM.TIME_STEP, CONST_PARAM.ID_LIST(k), CONST_PARAM.BOUNDARIES_COEFF, startPose(k,:), vConstList(k), wOrbitList(k));
    tmp = agentHandle(k).getAgentCoordReport();       
end

% Instance of logger for data post processing, persistent over all files
logger = DataLogger(CONST_PARAM.N_AGENT, CONST_PARAM.MAX_ITER);
logger.bndVertexes = CONST_PARAM.BOUNDARIES_VERTEXES;

%% MAIN
for iteration = 1: CONST_PARAM.MAX_ITER
    %% Logging instances
    pose_3d_list = zeros(CONST_PARAM.N_AGENT, 3);
    CVT_2d_List = zeros(CONST_PARAM.N_AGENT, 2);
    Vk_List = zeros(CONST_PARAM.N_AGENT, 1);
    vmCmoord_2d_list = zeros(CONST_PARAM.N_AGENT, 2);
    
    %% Thread Voronoi Update - Agent interacts with the "nature" and receive the partitions information
    for k = 1: CONST_PARAM.N_AGENT
        %% Update the data to Environment
       agentReport = agentHandle(k).getAgentCoordReport();
       vmCmoord_2d_list(k, :) = agentReport.poseVM_2d;   
       pose_3d_list(k,:) = agentReport.poseCoord_3d;  
    end
    [v,c] = VoronoiCom.exec_partition(vmCmoord_2d_list, CONST_PARAM.ID_LIST);

    %% Thread Agents communicate with adjacent agents through the communication link GBS (sharing dC_dz)
    for k = 1 : CONST_PARAM.N_AGENT 
       %% Mimic the behaviour of Voronoi Topology
       [voronoiInfo, isAvailable] = VoronoiCom.get_Voronoi_Parition(agentHandle(k).ID);        
       if(isAvailable)
            [CVT, neighborLyapunov] = agentHandle(k).computeLyapunovFeedback(voronoiInfo);
            GBS.uploadVoronoiProperty(agentHandle(k).ID, neighborLyapunov);
            CVT_2d_List(k,:) = CVT;
       else
            fprintf("Check \n");
       end
    end
    
    %% Thread Agent move according to the received information from the adjacent agents (compute control output)
    for k = 1 : CONST_PARAM.N_AGENT 
       %% Perform the control algorithm
       [report, isAvailable] = GBS.downloadVoronoiProperty(agentHandle(k).ID);  
       %% Move
       if(isAvailable)
           Vk_List(k) = agentHandle(k).computeControlInput(report);    
           agentHandle(k).move();
       else
           fprintf("Check \n");
       end    
    end
    
    %% Logging
    logger.logDecentralized(pose_3d_list, vmCmoord_2d_list, CVT_2d_List, Vk_List);
    fprintf("Iter: %d. L: %f \n", iteration, sum(Vk_List)); 
    
%     if(mod(iteration, 10) == 0)
%        fprintf("Running... \n"); 
%     end
end
%% END

