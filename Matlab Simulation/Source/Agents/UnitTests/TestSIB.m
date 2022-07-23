Config

for iteration = 1: SIM_PARAM.MAX_ITER
    %% Logging instances
    pose_3d_list = zeros(SIM_PARAM.N_AGENT, 3);
    CVT_2d_List = zeros(SIM_PARAM.N_AGENT, 2);
    ControlOutput = zeros(SIM_PARAM.N_AGENT, 3);
    Vk_List = zeros(SIM_PARAM.N_AGENT, 1);
    vmCmoord_2d_list = zeros(SIM_PARAM.N_AGENT, 2);

    %% Thread Voronoi Update - Agent interacts with the "nature" and receive the partitions information
    for k = 1: SIM_PARAM.N_AGENT
       [pose_3d_list(k,:)] = agentHandle(k).get_coord_3();
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
           % Controller proposed by Qingchen
           %[Vk_List(k), ControlOutput(k)] = agentHandle(k).computeControlSimple();
           [Vk_List(k), ControlOutput(k,:)] = agentHandle(k).compute_control_input(report);
           agentHandle(k).move(ControlOutput(k,:));
       else
           % Pass through so
           error("Unavailable information required by agent %d", SIM_PARAM.ID_LIST(k));
       end    
    end

    %% Logging  
    Logger.log(pose_3d_list, vmCmoord_2d_list, CVT_2d_List, Vk_List, zeros(SIM_PARAM.N_AGENT, 1), v, c);
    
        if(mod(iteration, 25) == 1)
            try
                Logger.live_plot();
            catch
            end
        end
    
    fprintf("Decentralized. Iter: %d. L: %f \n", iteration, sum(Vk_List)); 
end
