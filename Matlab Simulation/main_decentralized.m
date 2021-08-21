format long;
[simConfig, regionConfig, agentConfig] = Config();

ID_LIST = (1:simConfig.nAgent) * 8;

%% Agent handler
agentHandle = Agent_Controller.empty(simConfig.nAgent, 0);
for k = 1 : simConfig.nAgent
    agentHandle(k) = Agent_Controller(simConfig.dt);
    agentHandle(k).begin(ID_LIST(k), regionConfig.BoundariesCoeff, agentConfig.startPose, agentConfig.vConstList(k), agentConfig.wOrbitList(k));
end

%% Voronoi Computer
VoronoiCom = Voronoi2D_Handler();
VoronoiCom.setup(regionConfig.bndVertexes);
%VoronoiCom.assignID(ID_LIST);

%% Communication Link for data broadcasting (GBS : global broadcasting service)
GBS = Communication_Link(simConfig.nAgent); 

% Instance of logger for data post processing, persistent over all files
logger = DataLogger(simConfig.nAgent, simConfig.maxIter);
logger.bndVertexes = regionConfig.bndVertexes;

%% MAIN
for iteration = 1: simConfig.maxIter
    for k = 1 : simConfig.nAgent
        [vmCmoord_2d_list, ID_List] = GBS.downloadCoord();
        [VoronoiPartitionInfo] = VoronoiCom.exec_partition(vmCmoord_2d_list, ID_List);
        GBS.uploadVoronoiParition(VoronoiPartitionInfo);
        
       %% Synchronise with the GBS
       [voronoiInfo, isAvailable] = GBS.download(agentHandle(k).ID);        
       
       if(isAvailable)
            [Vk, dVkdzk, neighbordVdz] = agentHandle(k).computeLyapunovFeedback(voronoiInfo);
       end
       %% Upload the Lyapunov State Feedback
       
       
       %% Download the feedback again
       
                   %% Perform the control algorithm
        
       
       
                   
       %% Move
       agentHandle(k).move();

       %% Update the data to GBS
       tmp = agentHandle(k).getAgentCoordReport();       
       GBS.upload(tmp);
    end
    
    %% GBS with its own thread
    GBS.loop()
    
end
%% END

