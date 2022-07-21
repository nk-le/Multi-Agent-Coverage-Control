clear all; close all;
format long;
rng(4);

%% Adding path
addpath(genpath('./Source/Agents'));
addpath(genpath('./Source/Controller'));
addpath(genpath('./Source/DataStructure'));
addpath(genpath('./Source/Tools'));
addpath(genpath('./Source/Algorithm'));
addpath(genpath('./Library'));
addpath(genpath('./Source/Coverage'));
addpath(genpath('./Source'));

%% Parameter
% Simulation Parameters
SIM_PARAM = SimulationParameter();

% Region Parameters
vertexes = [0,   0; 
            0,   300; 
            300, 600; 
            800, 300;
            300,   0;
            0,   0];
REGION_CONFIG = RegionParameter(vertexes);

% Controller Parameters
CONTROL_PARAM = ControlParameter();

%% Type of agent
% Agent handler
for k = 1 : SIM_PARAM.N_AGENT
    % Qingchen's controller
    %agentHandle(k) = UnicycleSimpleCoverageAgent(SIM_PARAM.TIME_STEP, SIM_PARAM.ID_LIST(k), SIM_PARAM.START_POSE(k,:), REGION_CONFIG, CONTROL_PARAM);
    
    % BLF controller
    agentHandle(k) = UnicycleCoverageAgent(SIM_PARAM.TIME_STEP, SIM_PARAM.ID_LIST(k), SIM_PARAM.START_POSE(k,:), REGION_CONFIG, CONTROL_PARAM);

    % Single Integrator agent
    % agentHandle(k) = SingleIntegratorAgent(SIM_PARAM.TIME_STEP, SIM_PARAM.ID_LIST(k), SIM_PARAM.START_POSE(k,:), REGION_CONFIG, CONTROL_PARAM);
end

% Instance of Logger for data post processing, persistent over all files
Logger = DataLogger(SIM_PARAM, REGION_CONFIG, CONTROL_PARAM, CONTROL_PARAM.V_CONST* ones(SIM_PARAM.N_AGENT,1), CONTROL_PARAM.W_ORBIT* ones(SIM_PARAM.N_AGENT,1));


%% Unified Voronoi Computer
VoronoiCom = Voronoi2D_Handler(9999, REGION_CONFIG.BOUNDARIES_VERTEXES);

%% Unified Communication Link for data broadcasting (GBS : global broadcasting service)
GBS = CommunicationLink(SIM_PARAM.N_AGENT, SIM_PARAM.ID_LIST); 
