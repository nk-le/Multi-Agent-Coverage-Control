%% Adding path
addpath(genpath('./Source/Agents'));
addpath(genpath('./Source/Controller'));
addpath(genpath('./Source/DataStructure'));
addpath(genpath('./Source/Tools'));
addpath(genpath('./Source/Algorithm'));
addpath(genpath('./Source/Coverage'));
addpath(genpath('./Source/Parameters'));
addpath(genpath('./Library/vert2con'));

%% Load User Setup Parameters
clear all; 
close all;
Config
       
%% DEFAULT SETUP **********************************************************
initPose = RegionParameter.generate_start_pose(6)';
SIM_PARAM = SimulationParameter(dt, maxIter, nAgent, initPose');
REGION_CONFIG = RegionParameter(vertexes);
CONTROL_PARAM = ControlParameter(vConst, wOrbit, wSat, Q, gamma, eps);

%% Type of agent
% Agent handler
for k = 1 : SIM_PARAM.N_AGENT
    if(type == "Simple")
        agentHandle(k) = UnicycleSimpleCoverageAgent(SIM_PARAM.TIME_STEP, SIM_PARAM.ID_LIST(k), SIM_PARAM.START_POSE(k,:), REGION_CONFIG, CONTROL_PARAM);
    else    % BLF controller
        agentHandle(k) = UnicycleCoverageAgent(SIM_PARAM.TIME_STEP, SIM_PARAM.ID_LIST(k), SIM_PARAM.START_POSE(k,:), REGION_CONFIG, CONTROL_PARAM);
        disp('Used default BLF Controller');
    end
end

% Instance of Logger for data post processing, persistent over all files
Logger = DataLogger(SIM_PARAM, REGION_CONFIG, CONTROL_PARAM, CONTROL_PARAM.V_CONST* ones(SIM_PARAM.N_AGENT,1), CONTROL_PARAM.W_ORBIT* ones(SIM_PARAM.N_AGENT,1));

%% Unified Voronoi Computer
VoronoiCom = Voronoi2D_Handler(9999, REGION_CONFIG.BOUNDARIES_VERTEXES);

%% Unified Communication Link for data broadcasting (GBS : global broadcasting service)
GBS = CommunicationLink(SIM_PARAM.N_AGENT, SIM_PARAM.ID_LIST); 

%% END *******************************************************************


%% MAIN LOOP *************************************************************
for iteration = 1: SIM_PARAM.MAX_ITER
    %% Logging instances
    pose_3d_list = zeros(SIM_PARAM.N_AGENT, 3);
    coord_3d_list = zeros(SIM_PARAM.N_AGENT, 3);
    CVT_2d_List = zeros(SIM_PARAM.N_AGENT, 2);
    ControlOutput = zeros(SIM_PARAM.N_AGENT, 1);
    Vk_List = zeros(SIM_PARAM.N_AGENT, 1);
    vmCmoord_2d_list = zeros(SIM_PARAM.N_AGENT, 2);

    %% Thread Voronoi Update - Agent interacts with the "nature" and receive the partitions information
    for k = 1: SIM_PARAM.N_AGENT
        pose_3d_list(k,:) = agentHandle(k).get_pose();
        coord_3d_list(k,:) = agentHandle(k).get_coord_3();
        vmCmoord_2d_list(k, :) = agentHandle(k).get_voronoi_generator_2();
    end
    %% Update new coordinates to the Environment
    [v,c] = VoronoiCom.exec_partition(vmCmoord_2d_list, SIM_PARAM.ID_LIST);

    %% Thread Agents communicate with adjacent agents through the communication link GBS (sharing dC_dz)
    for k = 1 : SIM_PARAM.N_AGENT 
       %% Mimic the behaviour of Voronoi Topology
       [voronoiInfo, isAvailable] = VoronoiCom.get_Voronoi_Parition(agentHandle(k).ID);        
       if(isAvailable)
            [CVT, neighborPDCVT] = agentHandle(k).computePartialDerivativeCVT(voronoiInfo);
            GBS.uploadVoronoiPartialDerivativeProperty(agentHandle(k).ID, neighborPDCVT);
            CVT_2d_List(k,:) = CVT;
       else
            error("Unavailable Voronoi information required by agent %d", SIM_PARAM.ID_LIST(k));
       end
    end

    %% Thread Agent move according to the received information from the adjacent agents (compute control output)
    for k = 1 : SIM_PARAM.N_AGENT 
       %% Perform the control algorithm
       [report, isAvailable] = GBS.downloadVoronoiPartialDerivativeProperty(agentHandle(k).ID);  
       %% Move
       if(isAvailable)
           % Barrier Lyapunov based controller 
           [Vk_List(k), ControlOutput(k)] = agentHandle(k).compute_control_input(report);
           agentHandle(k).move(ControlOutput(k));
       else
           % Pass through so
           error("Unavailable information required by agent %d", SIM_PARAM.ID_LIST(k));
       end    
    end

    %% Logging
    Logger.log(pose_3d_list, vmCmoord_2d_list, CVT_2d_List, Vk_List, ControlOutput, v, c);
    if(animation)
        if(mod(iteration, 25) == 1)
            try
                Logger.live_plot();
            catch
            end
        end
    end    
    fprintf("Decentralized. Iter: %d. L: %f \n", iteration, sum(Vk_List));
end
