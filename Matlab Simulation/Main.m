addpath('./Data Structure');
addpath('./Evaluation Scripts');
addpath('./Library');
addpath('./Voronoi Debug Scripts');

format long;
CONST_PARAM = Simulation_Parameter();

%% Agent handler
rng(6);
vConstList = 15 .* ones(1,CONST_PARAM.N_AGENT);
wOrbitList = 0.8 .* ones(1,CONST_PARAM.N_AGENT);
centerCoord = [100, 100];    % deploy all agents near this coord
rXY = 50;                   % agents formualates a circle at the beginning
startPose = zeros(CONST_PARAM.N_AGENT, 3);
startPose(:,1) = centerCoord(1) + rXY.*rand(CONST_PARAM.N_AGENT,1); %x
startPose(:,2) = centerCoord(2) + rXY.*rand(CONST_PARAM.N_AGENT,1); %y
startPose(:,3) = zeros(CONST_PARAM.N_AGENT,1); %theta
agentHandle = Agent_Controller.empty(CONST_PARAM.N_AGENT, 0);
for k = 1 : CONST_PARAM.N_AGENT
    agentHandle(k) = Agent_Controller(CONST_PARAM.TIME_STEP, CONST_PARAM.ID_LIST(k), CONST_PARAM.BOUNDARIES_COEFF, startPose(k,:), vConstList(k), wOrbitList(k));
    tmp = agentHandle(k).getAgentCoordReport();       
end

%% Centralized Controller
centralCom = Centralized_Controller(CONST_PARAM.N_AGENT, CONST_PARAM.BOUNDARIES_COEFF, CONST_PARAM.BOUNDARIES_VERTEXES);

% Instance of logger for data post processing, persistent over all files
logger = DataLogger(CONST_PARAM.N_AGENT, CONST_PARAM.MAX_ITER + 1);
logger.bndVertexes = CONST_PARAM.BOUNDARIES_VERTEXES;


    %% MAIN
for iteration = 1: CONST_PARAM.MAX_ITER
    %% Agent Move
    newPose_3d = zeros(CONST_PARAM.N_AGENT, 3);
    newPoseVM_2d = zeros(CONST_PARAM.N_AGENT, 2);
    for k = 1: CONST_PARAM.N_AGENT
        agentHandle(k).move();
        newPose_3d(k,:) = agentHandle(k).curPose(:);
        newPoseVM_2d(k,:) = agentHandle(k).VMCoord_2d(:);
    end
    
    [Info, poseCVT_2D, ControlInput, V_BLF_List] = centralCom.updateCoverage(newPose_3d, newPoseVM_2d, wOrbitList);
    
    for k = 1: CONST_PARAM.N_AGENT
        agentHandle(k).w = ControlInput(k);
    end
        
    % Displaying for debugging
    fprintf('Iter: %d Lyp: %f \n',iteration, sum(V_BLF_List));
    
    % Logging
    loggedTopics.CurPose = newPose_3d;
    loggedTopics.CurPoseVM = newPoseVM_2d;
    loggedTopics.CurPoseCVT = poseCVT_2D;
    loggedTopics.CurAngularVel = ControlInput;
    loggedTopics.LyapunovCost = V_BLF_List;
    logger.logCentralizedController(loggedTopics);
end
%% END

