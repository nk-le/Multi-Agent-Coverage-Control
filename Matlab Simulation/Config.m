%% Global Config
format long;
rng(4);
dt = 0.01;          % Time step
maxIter = 50e3;     % Maximum iteration
animation = 1;      % Live Animation Flag. 0:off/ 1:on

%% Parameter Config

% Agent Parameters
nAgent = 6;
% Initial Pose Format: each column is the pose of one agent [x,y,theta]
% Case 1
initPose = ...
[60.68 624.4 350.6 579.2 782.5 430.3;
 301.0 43.43 161.5 299.7 408.0 482.4;
 2.394 0.414 1.810 5.715 1.341 2.84];

% Region Parameters
% vertexes = [0,   0;     % Vertexes of the coverage region
%             0,   300; 
%             300, 600; 
%             800, 300;
%             300,   0;
%             0,   0];
vertexes = [0,   0; 
            0, 600; 
            800, 600;
            800,   0;
            0,   0];
        
% Controller Parameters
type = "BLF"; % Controller Type. Please choose "BLF" (safety) or "Simple" (no safety)
gamma = 1;       % Control gain. (Please check paper for a feasible value)
Q = eye(2);      % Positive definite matrix Q
eps = 2;         % Epsilon of the sigmoi function
wOrbit = 0.8;    % Desired orbital velocity (rad/s) 
vConst = 40;     % Constant heading velocity (m/s)
wSat = 2.0;      % Saturation angular velocity (rad/s)


%% Some commented simulations
% % Case 1
% initPose = ...
% [60.68 624.4 350.6 579.2 782.5 430.3;
%  301.0 43.43 161.5 299.7 408.0 482.4;
%  2.394 0.414 1.810 5.715 1.341 2.84];
% Case 2
% initPose = ...
% [177.1 696.9 165.7 734.8 390.3 489.3;
% 459.7 311.5 177.7 113.1 48.70 443.5;
% 2.773 0.995 5.529 1.722 2.603 1.860];
% 
% % Case 3
% initPose = ...
% [349.1 20.24 439.9 348.4 336.6 263.8;
% 123.2 371.5 180.3 159.6 372.3 317.5;
% 0.845 3.227 1.159 4.934 5.366 3.105];



