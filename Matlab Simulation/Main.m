%% GLOBAL PARAMETER
global masterCom;           % centralized Controller operates all the simulation process (dynamics, control, ...)
global logger;              % log instance of all time step of the centralized controller for post processing
global globalInformation;   % pseudo broadcasted information over all agents (if applied in distributed scheme)
%global env; % Simulation environment

format long;

%% Setup
visualizationOn = false;
[nAgent, maxIter] = setup(visualizationOn);

    %% MAIN
for iteration = 1: maxIter
    % Main process
    [currentPose, currentLyapunov] = masterCom.loop();
    % Update Visualization
    
    if(visualizationOn)
        env((1:nAgent), currentPose');
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




%% Support functions
function [nAgent, maxIter] = setup(visualizationOn)
    global masterCom;
    global logger;  
    [nAgent, vConstList, wOrbitList, bndVertexes, bndCoeff, startPose, visualizationOn, maxIter] = Config;

    %% Centralized Controller
    masterCom = Centralized_Controller(nAgent, bndCoeff, bndVertexes, startPose, vConstList, wOrbitList);
    % TODO - configurate the controller gain here
    %masterCom.setupControlParameter(0,1,2,3)

    % Instance of logger for data post processing, persistent over all files
    logger = DataLogger(nAgent, maxIter);
    logger.bndVertexes = bndVertexes;
    
    %% Visualization handler
%     if(visualizationOn)
%         env = MultiRobotEnv(nAgent);
%         env((1:nAgent), startPose');
%         hold on; grid on; axis equal
%         offset = 20;
%         xlim([0 - offset, maxX + offset]);
%         ylim([0 - offset, maxY + offset]);
%     end

end

