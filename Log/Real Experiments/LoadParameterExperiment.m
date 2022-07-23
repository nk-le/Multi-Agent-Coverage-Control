%% Global Config
format long;
rng(4);
dt = 0.01;          % Time step
maxIter = 50e3;     % Maximum iteration
animation = 1;      % Live Animation Flag. 0:off/ 1:on

%% Parameter Config

nAgent = 6;
% You have to look at the log file .log and fill in the initial pose of all
% agents
% Case 1
initPose = ...
[60.68 624.4 350.6 579.2 782.5 430.3;
 301.0 43.43 161.5 299.7 408.0 482.4;
 2.394 0.414 1.810 5.715 1.341 2.84];

% Region Parameters
vertexes = [ 20, 20;    
        20, 2800;
        4000, 2800;  % a world with a narrow passage
        4000, 20;
        20, 20];
        
% Controller Parameters
type = "BLF"; % Controller Type. Please choose "BLF" (safety) or "Simple" (no safety)
gamma = 1;       % Control gain. (Please check paper for a feasible value)
Q = eye(2);      % Positive definite matrix Q
eps = 2;         % Epsilon of the sigmoi function
wOrbit = 0.8;    % Desired orbital velocity (rad/s) 
vConst = 0.16;     % Constant heading velocity (m/s)
wSat = 1.6;      % Saturation angular velocity (rad/s)

SIM_PARAM = SimulationParameter(dt, maxIter, nAgent, initPose');
REGION_CONFIG = RegionParameter(vertexes);
CONTROL_PARAM = ControlParameter(vConst, wOrbit, wSat, Q, gamma, eps);

