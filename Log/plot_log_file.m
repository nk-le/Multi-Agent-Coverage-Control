%% Parsing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Nhan Khanh Le
% Date: July 23, 2022
addpath(genpath('./Matlab_Simulation/Library/'));
addpath(genpath('./Matlab_Simulation/Source/'));
addpath('./Log/Real Experiments/');

logFile = "Parsed_TRO_LogSim2.log.mat";
Logger = ProcessLogFile(logFile);

%% Plotting
Logger.plot_VM_trajectories();
Logger.plot_BLF_all();
Logger.plot_control_output();

% some conversion to adapt to Zengjie's script
[botPose, botZ, botCz, botCost, botInput] = Logger.get_logged_data();
botCost = sum(botCost)';
t_scale = Logger.get_time_axis();

%% Custom Visualization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ... custom plots ....

