%% Agent_Controller - distributed controller for unicycle agent
%

classdef Agent_Controller < handle
    properties
        %% Should be private
        w               % float: current angular velocity
    end
    
    properties (SetAccess = immutable)
        % Simulation time step
        dt           
        ID              % int        
        regionParam
        controlParam
    end
    
    properties (Access = private)
        %% Coordinates of agent, its virtual masses and the calculated CVT
        AgentPose_3d = zeros(3,1)         % [x y theta]
        CVTCoord_2d = zeros(2,1)
        VMCoord_2d = zeros(2,1);
        % Save the last computed result to evaluate the calculation
        prev_CVTCoord_2d
        prev_AgentPose_3d
        prev_VMCoord_2d 
        
        %% Obtained Voronoi partitions from the centralized Voronoi computer (Simulation)
        received_VoronoiPartitionInfo
        prev_received_VoronoiPartitionInfo
        
        %% Computed partial derivative of CVT related to the adjacent agents
        dCkdzk
        published_dC_neighbor
        prev_dCkdzk
        prev_published_dC_neighbor

        %% Computed partial derivative of Lyapunov function
        dVkdzk
        Vk
        Local_dVkdzi_List
        prev_dVkdzk
        prev_Vk
        prev_Local_dVkdzi_List
        
        %% For debugging only, these results are computed but only used internally
        dVk_dzi_List
        prev_dVk_dzi_List
    end
    
    methods
        %% Initalize class handler
        %function obj = Agent_Controller(dt, botID, coverage_region_coeff, initPose_3d, )
        function obj = Agent_Controller(dt, botID, initPose_3d, regionParam, controlParam)
            assert(dt~=0);
            obj.dt = dt;
            obj.w = 0;            
            obj.ID = botID;
            obj.regionParam = regionParam;
            obj.controlParam = controlParam;
            
            %% Update initial position and the virtual center
            obj.AgentPose_3d(:) = initPose_3d(:);
            obj.VMCoord_2d(1) = obj.AgentPose_3d(1) - (obj.controlParam.V_CONST/obj.controlParam.W_ORBIT) * sin(obj.AgentPose_3d(3)); 
            obj.VMCoord_2d(2) = obj.AgentPose_3d(2) + (obj.controlParam.V_CONST/obj.controlParam.W_ORBIT) * cos(obj.AgentPose_3d(3)); 
        end

        %% Simulate dynamic model 
        % Call this function once every time the control policy is updated
        % to simulate the movement.
        function move(obj, calc_w) 
            obj.w = calc_w;
            % Unicycle Dynamic
            obj.prev_AgentPose_3d = obj.AgentPose_3d;
            obj.AgentPose_3d(1) = obj.AgentPose_3d(1) + obj.dt * (obj.controlParam.V_CONST * cos(obj.AgentPose_3d(3)));
            obj.AgentPose_3d(2) = obj.AgentPose_3d(2) + obj.dt * (obj.controlParam.V_CONST * sin(obj.AgentPose_3d(3)));
            obj.AgentPose_3d(3) = obj.AgentPose_3d(3) + obj.dt * obj.w;
            %% Update the virtual mass
            obj.prev_VMCoord_2d = obj.VMCoord_2d;
            obj.VMCoord_2d(1) = obj.AgentPose_3d(1) - (obj.controlParam.V_CONST/obj.controlParam.W_ORBIT) * sin(obj.AgentPose_3d(3)); 
            obj.VMCoord_2d(2) = obj.AgentPose_3d(2) + (obj.controlParam.V_CONST/obj.controlParam.W_ORBIT) * cos(obj.AgentPose_3d(3)); 
        end
        
        function [CVT, dCk_dzi_For_Neighbor] = computePartialDerivativeCVT(obj, i_received_VoronoiPartitionInfo)
             format long;
             obj.prev_received_VoronoiPartitionInfo = obj.received_VoronoiPartitionInfo;
             obj.received_VoronoiPartitionInfo = i_received_VoronoiPartitionInfo;
             obj.prev_CVTCoord_2d = obj.CVTCoord_2d;
             obj.prev_dCkdzk = obj.dCkdzk;
             
             assert(isa(i_received_VoronoiPartitionInfo, 'Struct_Voronoi_Partition_Info'));  
             
             [assignedID, Vertex2D_List, neighborInfoList] = i_received_VoronoiPartitionInfo.getValue();
             assert(assignedID == obj.ID);
             
             % Initally no vertex passed 
             if(~isempty(Vertex2D_List))
                 
                [obj.CVTCoord_2d] = Voronoi2D_calcCVT(Vertex2D_List);
                CVT = obj.CVTCoord_2d;
               
                nNeighbor = numel(neighborInfoList);
                dCk_dzk = zeros(2,2);
                %% Iterate to obtain the aggregated dCi_dzi
                mVi = Voronoi2D_calcPartitionMass(Vertex2D_List);
                dCk_dzi_For_Neighbor = Struct_Neighbor_CVT_PD.empty(nNeighbor, 0);
                for i = 1: nNeighbor
                    % Compute the partial derivative related to each
                    % adjacent agent
                    [neighborID, neighbor_vm_2d, v1_2d, v2_2d] = neighborInfoList{i}.getNeighborInfo();
                    
                    [dCk_dzk_Neighbor_i, dCk_dzi] = Voronoi2D_calCVTPartialDerivative(...
                                                        obj.VMCoord_2d, ...
                                                        obj.CVTCoord_2d, ...
                                                        mVi, ... 
                                                        neighbor_vm_2d, ... 
                                                        v1_2d, ...
                                                        v2_2d);
                    % Result for an adjacent agent to be published
                    dCk_dzi_For_Neighbor(i) = Struct_Neighbor_CVT_PD(obj.ID, neighborID, ...
                                                                       obj.VMCoord_2d, ...
                                                                       obj.CVTCoord_2d, ...
                                                                       dCk_dzi); %% Create a report with neighbor ID to publish             
                    % Accumulate to get the own partial derivative
                    dCk_dzk = dCk_dzk + dCk_dzk_Neighbor_i;
                end
                obj.dCkdzk = dCk_dzk;
                
                %% For debugging only
                obj.prev_published_dC_neighbor = obj.published_dC_neighbor;
                obj.published_dC_neighbor = dCk_dzi_For_Neighbor;
             else
                 fprintf("WARN: Agent %d: No vertex for region partitioning detected \n", obj.ID);
                 CVT = [];
                 dCk_dzi_For_Neighbor = [];
             end
        end

        function [Pose_3d, PoseVM_2d] = getPose(obj)
            Pose_3d =  obj.AgentPose_3d;
            PoseVM_2d = obj.VMCoord_2d;
        end
        
        function [Vk, wOut] = computeControlInput(obj, report)
            assert(isa(report{1}, 'Struct_Neighbor_CVT_PD'));
            obj.prev_Vk = obj.Vk;
            obj.prev_dVkdzk = obj.dVkdzk;
            obj.prev_Local_dVkdzi_List = obj.Local_dVkdzi_List;
            format long;
           
            %% Compute the partial derivate of Lyapunov from the received partial derivative of CVTs from adjacent agents
            [obj.Vk, obj.dVkdzk] = Lyapunov_Self_PD_Computation(obj.VMCoord_2d, obj.CVTCoord_2d, obj.dCkdzk , obj.controlParam.Q2x2, obj.regionParam.BOUNDARIES_COEFF(:,1:2), obj.regionParam.BOUNDARIES_COEFF(:,3));         
            assert(obj.Vk >= 0);
            %% This is for debugging the changes of the Lyapunov Partial derivative
            obj.prev_dVk_dzi_List = obj.dVk_dzi_List;
            obj.dVk_dzi_List = cell(numel(report),1);
            for i = 1: numel(report)
                for t = 1: numel(obj.published_dC_neighbor)
                    [~, rxID] = obj.published_dC_neighbor(t).getIDs();
                    [txID, ~] = report{i}.getIDs();
                    if(rxID == txID)
                        [~, ~, zk, Ck, dCkdzi_2x2] = obj.published_dC_neighbor(t).getValue();
                        [~, ~, zi, Ci, dCidzk_2x2] = report{i}.getValue();
                        dVk_dzi = Lyapunov_Adjacent_PD_Computation(obj.VMCoord_2d, obj.CVTCoord_2d, ...
                                                                    dCkdzi_2x2 ,obj.controlParam.Q2x2, obj.regionParam.BOUNDARIES_COEFF(:,1:2), obj.regionParam.BOUNDARIES_COEFF(:,3));
                        obj.dVk_dzi_List{i} = {rxID, zi, dVk_dzi};  
                        break;
                    end
                end
            end
            
            %% Aggregate the Lyapunov feedback from neighbor agents
            obj.Local_dVkdzi_List = Struct_Neighbor_CVT_PD_Extended.empty(numel(report), 0);
            dV_Accum_Adjacent_Term = zeros(2,1);
            for i = 1: numel(report)
                [~, ~, zi, Ci, dCidzk_2x2] = report{i}.getValue();
                [tmp_dV_dAdj] = Lyapunov_Adjacent_PD_Computation(zi, Ci, dCidzk_2x2 ,obj.controlParam.Q2x2, obj.regionParam.BOUNDARIES_COEFF(:,1:2), obj.regionParam.BOUNDARIES_COEFF(:,3));
                dV_Accum_Adjacent_Term = dV_Accum_Adjacent_Term + tmp_dV_dAdj;    
                obj.Local_dVkdzi_List(i) = Struct_Neighbor_CVT_PD_Extended(report{i}, tmp_dV_dAdj);
            end
            dV_dzk_total =  obj.dVkdzk + dV_Accum_Adjacent_Term;
            
            %% Adjustable variable --> Will move later to constant
            sigmoid_func = @(x,eps) x / (abs(x) + eps);              
            %% Compute the control policy
            wOut = obj.controlParam.W_ORBIT + obj.controlParam.P * obj.controlParam.W_ORBIT * sigmoid_func(dV_dzk_total' * [cos(obj.AgentPose_3d(3)) ;sin(obj.AgentPose_3d(3))], obj.controlParam.EPS_SIGMOID); 
            %wOut = obj.w;
            %% Logging out
            Vk = obj.Vk;
        end
        
        %% Simple controller
        function [Hk] = computeControlSimple(obj)
            IntDomain = struct('type','polygon','x',obj.received_VoronoiPartitionInfo.Vertex2D_List(1: end -1,1)','y',obj.received_VoronoiPartitionInfo.Vertex2D_List(1: end - 1,2)');
            param = struct('method','gauss','points',6);
            normSquared = @(x,y) (x - obj.VMCoord_2d(1))^2 + (y - obj.VMCoord_2d(2))^2;
            Hk = doubleintegral(normSquared, IntDomain, param);
            
            %% Some temporary parameter here
            gamma = 5;
            obj.controlParam.W_ORBIT = 0.4;
            sigmoid_func = @(x,eps) x / (abs(x) + eps);  
            epsSigmoid = 10;
            calc_W = obj.controlParam.W_ORBIT + gamma * obj.controlParam.W_ORBIT * obj.controlParam.V_CONST *sigmoid_func((obj.VMCoord_2d - obj.CVTCoord_2d)' * [cos(obj.AgentPose_3d(3)) ; sin(obj.AgentPose_3d(3))],epsSigmoid); 
            
            % Predict the next state            
            predict_Pose_3d = zeros(3,1);
            predict_Pose_VM = zeros(2,1);
            predict_Pose_3d(1) = obj.AgentPose_3d(1) + obj.dt * (obj.controlParam.V_CONST * cos(obj.AgentPose_3d(3)));
            predict_Pose_3d(2) = obj.AgentPose_3d(2) + obj.dt * (obj.controlParam.V_CONST * sin(obj.AgentPose_3d(3)));
            predict_Pose_3d(3) = obj.AgentPose_3d(3) + obj.dt * calc_W;
            predict_Pose_VM(1) = predict_Pose_3d(1) - (obj.controlParam.V_CONST/obj.controlParam.W_ORBIT) * sin(predict_Pose_3d(3)); 
            predict_Pose_VM(2) = predict_Pose_3d(2) + (obj.controlParam.V_CONST/obj.controlParam.W_ORBIT) * cos(predict_Pose_3d(3)); 
            
            isValid = true;
            for j = 1: size(obj.regionParam.BOUNDARIES_COEFF, 1)
                if(obj.regionParam.BOUNDARIES_COEFF(j,3)- (obj.regionParam.BOUNDARIES_COEFF(j,1:2) * predict_Pose_VM) <= 0)
                   isValid = false; 
                end
            end
                
            if(isValid)
                obj.w = calc_W;
            else
                %disp("OUT BOUND ALERT");
                obj.w = obj.controlParam.W_ORBIT;
            end
        end 
        
        function PrintReceivedReport(obj)
            fprintf("============ CURRENT REPORT OF AGENT %d =================== \n", obj.ID);
            fprintf("Pose: [%.9f %.9f %.9f], VM: [%.9f %.9f] CVT: [%.9f %.9f] \n", ...
            obj.AgentPose_3d(1), obj.AgentPose_3d(2), obj.AgentPose_3d(3), obj.VMCoord_2d(1), obj.VMCoord_2d(2), obj.CVTCoord_2d(1), obj.CVTCoord_2d(2))
            fprintf("dCk_dzk : [%.9f %.9f; %.9f %.9f]. dVk_dzk: [%.9f %.9f]. Vk %.9f \n", ...
                obj.dCkdzk(1,1), obj.dCkdzk(1,2), obj.dCkdzk(2,1), obj.dCkdzk(2,2), obj.dVkdzk(1), obj.dVkdzk(2), obj.Vk);
            fprintf("VORONOI PARTITION INFORMATION RECEIVED FROM THE ""NATURE"" \n");
           
            [~,~,neighborInfoList] = obj.received_VoronoiPartitionInfo.getValue();
            for i = 1: numel(neighborInfoList)
               neighborInfoList{i}.printValue();
            end
            fprintf("COMPUTED PARTIAL DERIVATIVE \n");
            for i = 1:numel(obj.published_dC_neighbor)
                obj.published_dC_neighbor(i).printValue();
            end
            fprintf("PARTIAL DERIVATIVE INFORMATION DOWNLOADED FROM THE COMMUNICATION LINK\n");
            for i = 1: numel(obj.Local_dVkdzi_List)
                obj.Local_dVkdzi_List(i).printValue();
            end
            fprintf("=============== END ================= \n");
        end
        
        function EvaluateComputation(obj)
            %% Also print the current registered report
            fprintf("============ START LAST REPORT OF AGENT %d =================== \n", obj.ID);
            fprintf("Pose: [%.9f %.9f %.9f], VM: [%.9f %.9f] CVT: [%.9f %.9f] \n", ...
            obj.prev_AgentPose_3d(1), obj.prev_AgentPose_3d(2), obj.prev_AgentPose_3d(3), obj.prev_VMCoord_2d(1), obj.prev_VMCoord_2d(2), ...
                                        obj.prev_CVTCoord_2d(1), obj.prev_CVTCoord_2d(2))
            fprintf("dCk_dzk : [%.9f %.9f; %.9f %.9f]. dVk_dzk: [%.9f %.9f]. Vk %.9f \n", ...
                obj.prev_dCkdzk(1,1), obj.prev_dCkdzk(1,2), obj.prev_dCkdzk(2,1), obj.prev_dCkdzk(2,2), obj.prev_dVkdzk(1), obj.prev_dVkdzk(2), obj.prev_Vk);
            fprintf("VORONOI PARTITION INFORMATION RECEIVED FROM THE ""NATURE"" \n");
            [~,~,neighborInfoList] = obj.prev_received_VoronoiPartitionInfo.getValue();
            for i = 1: numel(neighborInfoList)
               neighborInfoList{i}.printValue();
            end
            fprintf("COMPUTED PARTIAL DERIVATIVE \n");
            for i = 1:numel(obj.prev_published_dC_neighbor)
                obj.prev_published_dC_neighbor(i).printValue();
            end
            fprintf("PD_CVT INFO FROM GBS AND EXTENDED PD_LYAPUNOV INFO\n");
            for i = 1: numel(obj.prev_Local_dVkdzi_List)
                obj.prev_Local_dVkdzi_List(i).printValue();
            end
            
            %% Also print the current registered report
            obj.PrintReceivedReport();
            
            fprintf("============ COMPUTATION EVALUATION =================== \n");
            calc_dCk = obj.prev_dCkdzk * (obj.VMCoord_2d - obj.prev_VMCoord_2d);
            for i = 1:numel(obj.published_dC_neighbor)
                [~, ~, prev_zi, ~, ~, ~] = obj.prev_Local_dVkdzi_List(i).getValue();
                [~, ~, zi, ~, ~, ~] = obj.Local_dVkdzi_List(i).getValue();
                [~, ~, ~, ~, dCkdzi] = obj.prev_published_dC_neighbor(i).getValue();
                dzi = zi - prev_zi;
                calc_dCk = calc_dCk + dCkdzi * dzi;
            end
            real_dCk =  obj.CVTCoord_2d - obj.prev_CVTCoord_2d;
            fprintf("Calculated dC: [%.9f %.9f]. Real dC: [%.9f %.9f] \n", calc_dCk(1), calc_dCk(2), real_dCk(1), real_dCk(2));
            fprintf("=============== END ================= \n");
            
            fprintf("=============== EXTRA _DEBUG _ ONLY ================= \n");
            fprintf("Last")
            for i = 1 : numel(obj.dVk_dzi_List)
                z = obj.prev_dVk_dzi_List{i}{2};
                V = obj.prev_dVk_dzi_List{i}{3};
                fprintf("Neighbor i = %d. zi : [%.9f %.9f] dV_dzi [%.9f %.9f] \n", obj.prev_dVk_dzi_List{i}{1}, z(1), z(2), V(1), V(2));
            end
            fprintf("Now")
            for i = 1 : numel(obj.dVk_dzi_List)
                z = obj.dVk_dzi_List{i}{2};
                V = obj.dVk_dzi_List{i}{3};
                fprintf("Neighbor i = %d. zi : [%.9f %.9f] dV_dzi [%.9f %.9f] \n", obj.prev_dVk_dzi_List{i}{1}, z(1), z(2), V(1), V(2));
            end
            
            fprintf("Computation \n")
            calc_dV = obj.prev_dVkdzk' * (obj.VMCoord_2d - obj.prev_VMCoord_2d);
            for i = 1 :numel(obj.dVk_dzi_List)
                z_last = obj.prev_dVk_dzi_List{i}{2};
                z_now = obj.dVk_dzi_List{i}{2};
                V = obj.prev_dVk_dzi_List{i}{3};
                calc_dV = calc_dV + V' * (z_now - z_last);
            end
            real_dV = obj.Vk - obj.prev_Vk;
            
            fprintf("Calculated dV: %.9f. Real dV: %.9f \n", calc_dV, real_dV);
            fprintf("=============== END ================= \n");
        end
        
    end
end


function [p1, p2, flag] = findVertexes(posX, posY, boundaries)
    distance = zeros(1, numel(boundaries(1,:)) - 1);
    for i = 1:numel(boundaries(1,:))-1
        p1(1) = boundaries(1,i);
        p1(2) = boundaries(2,i);
        p2(1) = boundaries(1, i + 1);
        p2(2) = boundaries(2, i + 1); 

        p1Tod =  [posX, posY,0] - [p1(1), p1(2),0];
        p1Top2 = [p2(1),p2(2),0] - [p1(1), p1(2), 0];   
        
        angle = atan2(norm(cross(p1Tod,p1Top2)), dot(p1Tod,p1Top2));
        distance(i) = norm(p1Tod) * sin(angle); % Find distance 
    end  
    [value, minIndex] = min(distance(1,:));
    p1(1) = boundaries(1,minIndex);
    p1(2) = boundaries(2,minIndex);
    p2(1) = boundaries(1,minIndex + 1);
    p2(2) = boundaries(2,minIndex + 1);
    if(value < 3) % Stop before going outbound
        flag = 1;
    else 
        flag = 0;
    end
end





