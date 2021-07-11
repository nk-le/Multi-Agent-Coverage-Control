format long;

[simConfig, regionConfig, agentConfig] = Config();
%% Centralized Controller
masterCom = Centralized_Controller(simConfig.nAgent, simConfig.dt, regionConfig.BoundariesCoeff, regionConfig.bndVertexes, agentConfig.startPose, agentConfig.vConstList, agentConfig.wOrbitList);

% Instance of logger for data post processing, persistent over all files
logger = DataLogger(simConfig.nAgent, simConfig.maxIter);
logger.bndVertexes = regionConfig.bndVertexes;

    %% MAIN
for iteration = 1: simConfig.maxIter
    % Main process
    [currentPose, currentLyapunov, AgentReport, LyapunovState] = masterCom.loop();

    % Using two variables AgentReport and LyapunovState for easy debugging
    
    
    % Update Visualization
    if(simConfig.visualization)
        env((1:simConfig.nAgent), currentPose');
    end    
    % Displaying for debugging
    if(mod(iteration, 1) == 0)
        fprintf('Iter: %d Lyp: %f \n',iteration, currentLyapunov);
        %disp(masterCom.LyapunovCost');
    end
    % Logging
    logger.logCentralizedController(masterCom);
end
%% END

