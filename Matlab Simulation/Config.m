clear all; close all;
format long;
rng(4);

%% Adding path
addpath(genpath('./Source/Agents'));
addpath(genpath('./Source/Controller'));
addpath(genpath('./Source/DataStructure'));
addpath(genpath('./Source/Tools'));
addpath(genpath('./Source/Algorithm'));
addpath(genpath('./Source/Coverage'));
addpath(genpath('./Source/Parameters'));

addpath(genpath('./Library/vert2con'));

%% Parameter
% Simulation Parameters
animation = 1;
dt = 0.01;
maxIter = 50e3; 
nAgent = 6;

% Initial Pose Format: each column is the pose of one agent [x,y,theta]
initPose = ...
[60.68 624.4 350.6 579.2 782.5 430.3;
 301.0 43.43 161.5 299.7 408.0 482.4;
 2.394 0.414 1.810 5.715 1.341 2.84];
initPose = RegionParameter.generate_start_pose(6)';
SIM_PARAM = SimulationParameter(dt, maxIter, nAgent, initPose');

% Region Parameters
vertexes = [0,   0; 
            0,   300; 
            300, 600; 
            800, 300;
            300,   0;
            0,   0];
vertexes = [0,   0; 
            0, 600; 
            800, 600;
            800,   0;
            0,   0];
REGION_CONFIG = RegionParameter(vertexes);

% Controller Parameters
gamma = 1;
Q = eye(2);
eps = 2;
wOrbit = 0.8;
vConst = 40;
wSat = 1.6;

CONTROL_PARAM = ControlParameter(vConst, wOrbit, wSat, Q, gamma, eps);

%% Type of agent
% Agent handler
for k = 1 : SIM_PARAM.N_AGENT
    % Qingchen's controller
    %agentHandle(k) = UnicycleSimpleCoverageAgent(SIM_PARAM.TIME_STEP, SIM_PARAM.ID_LIST(k), SIM_PARAM.START_POSE(k,:), REGION_CONFIG, CONTROL_PARAM);
    
    % BLF controller
    agentHandle(k) = UnicycleCoverageAgent(SIM_PARAM.TIME_STEP, SIM_PARAM.ID_LIST(k), SIM_PARAM.START_POSE(k,:), REGION_CONFIG, CONTROL_PARAM);
end

% Instance of Logger for data post processing, persistent over all files
Logger = DataLogger(SIM_PARAM, REGION_CONFIG, CONTROL_PARAM, CONTROL_PARAM.V_CONST* ones(SIM_PARAM.N_AGENT,1), CONTROL_PARAM.W_ORBIT* ones(SIM_PARAM.N_AGENT,1));


%% Unified Voronoi Computer
VoronoiCom = Voronoi2D_Handler(9999, REGION_CONFIG.BOUNDARIES_VERTEXES);

%% Unified Communication Link for data broadcasting (GBS : global broadcasting service)
GBS = CommunicationLink(SIM_PARAM.N_AGENT, SIM_PARAM.ID_LIST); 
