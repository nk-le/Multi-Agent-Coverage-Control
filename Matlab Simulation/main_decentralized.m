addpath('./Data Structure');
addpath('./Evaluation Scripts');
addpath('./Library');
addpath('./Voronoi Debug Scripts');


format long;
[simConfig, regionConfig, agentConfig] = Config();

ID_LIST = (1:simConfig.nAgent) * 8;

%% Voronoi Computer
VoronoiCom = Voronoi2D_Handler();
VoronoiCom.setup(regionConfig.bndVertexes);

%% Communication Link for data broadcasting (GBS : global broadcasting service)
GBS = Communication_Link(simConfig.nAgent,ID_LIST); 

%% Agent handler
agentHandle = Agent_Controller.empty(simConfig.nAgent, 0);
%agentConfig.vConstList = zeros(simConfig.nAgent, 1);
%agentConfig.vConstList(1) = 15; 
for k = 1 : simConfig.nAgent
    agentHandle(k) = Agent_Controller(simConfig.dt, ID_LIST(k), regionConfig.BoundariesCoeff, agentConfig.startPose(k,:), agentConfig.vConstList(k), agentConfig.wOrbitList(k));
    tmp = agentHandle(k).getAgentCoordReport();       
end

% Instance of logger for data post processing, persistent over all files
logger = DataLogger(simConfig.nAgent, simConfig.maxIter);
logger.bndVertexes = regionConfig.bndVertexes;

%% SETUP


%% MAIN
for iteration = 1: simConfig.maxIter
    %% Logging only
    pose_3d_list = zeros(simConfig.nAgent, 3);
    CVT_2d_List = zeros(simConfig.nAgent, 2);
    Vk_List = zeros(simConfig.nAgent, 1);
    
    %% Get the latest pose and update inside the Voronoi Handler
    vmCmoord_2d_list = zeros(simConfig.nAgent, 2);
    
    for k = 1: simConfig.nAgent
        %% Update the data to Environment
       agentReport = agentHandle(k).getAgentCoordReport();
       vmCmoord_2d_list(k, :) = agentReport.poseVM_2d;   
       pose_3d_list(k,:) = agentReport.poseCoord_3d;  
    end
    
    %% Thread Voronoi Updater
    [v,c] = VoronoiCom.exec_partition(vmCmoord_2d_list, ID_LIST);
    for k = 1 : simConfig.nAgent 
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
    
    for k = 1 : simConfig.nAgent 
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

