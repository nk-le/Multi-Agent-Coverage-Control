format long;
[simConfig, regionConfig, agentConfig] = Config();

%% Agent handler
agentHandle = Agent_Controller.empty(simConfig.nAgent, 0);
for id = 1 : simConfig.nAgent
    agentHandle(id) = Agent_Controller(simConfig.dt);
    agentHandle(id).begin(id, regionConfig.BoundariesCoeff, agentConfig.startPose, agentConfig.vConstList(id), agentConfig.wOrbitList(id));
end

%% Communication Link for data broadcasting (GBS : global broadcasting service)
GBS = Communication_Link(simConfig.nAgent, regionConfig.bndVertexes); 

% Instance of logger for data post processing, persistent over all files
logger = DataLogger(simConfig.nAgent, simConfig.maxIter);
logger.bndVertexes = regionConfig.bndVertexes;

    %% MAIN
for iteration = 1: simConfig.maxIter
    for id = 1 : simConfig.nAgent
       %% Synchronise with the GBS
       voronoiInfo = GBS.download(id);
       %agentHandle(id).receiveGBS(voronoiInfo);
        
       %% Execute Control algorithm
       agentHandle(id).computeOutput(voronoiInfo)
       agentHandle(id).move();

       %% Update the data to GBS
       tmp = agentHandle(id).getAgentCoordReport();       
       GBS.upload(tmp);
    end
    
    %% GBS with its own thread
    GBS.loop()
    
end
%% END

