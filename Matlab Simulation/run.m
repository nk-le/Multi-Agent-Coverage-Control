%% GLOBAL PARAMETER
%% General config
[nAgent, vConstList, wOrbitList, bndVertexes, bndCoeff, startPose, visualizationOn, maxIter] = Config;

% Instance of logger for data post processing
global logger;
logger = DataLogger(nAgent, maxIter);

%% Centralized Controller
masterCom = Centralized_Controller(nAgent, bndCoeff, bndVertexes, startPose, vConstList, wOrbitList);
% TODO - configurate the controller gain here
%masterCom.setupControlParameter(0,1,2,3);

%% Visualization handler
if(visualizationOn)
    env = MultiRobotEnv(nAgent);
    env((1:nAgent), startPose');
    hold on; grid on; axis equal
    offset = 20;
    xlim([0 - offset, maxX + offset]);
    ylim([0 - offset, maxY + offset]);
end
%% MAIN
for iteration = 1: maxIter
    % Main process
    [newPose, outLypCost] = masterCom.loop();

    % Update Visualization
    if(visualizationOn)
        env((1:nAgent), newPose');
    end

    % Displaying for debugging
    % fprintf('Iter: %d Lyp: %f \n',iteration,outLypCost);
    if(mod(iteration, 100) == 0)
        fprintf('Iter: %d Lyp: %f \n',iteration,outLypCost);
    end
    
    % Logging
    newPoseAgent = masterCom.CurPose(:,:);
    newPoseVM = masterCom.CurPoseVM(:,:);
    newCVT = masterCom.CurPoseCVT(:,:);
    newW = masterCom.CurAngularVel(:);
    newV = masterCom.LyapunovCost;
    logger.log(newPoseAgent, newPoseVM, newCVT, newW, newV)
end

%out = logger;
