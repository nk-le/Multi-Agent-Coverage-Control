%% Agent_Controller - distributed controller for unicycle agent
%

classdef Agent_Controller < handle
    properties
        ID              % int
        regionCoeff     % [a1 a2 b] --> a1*x + a2*y - b <= 0
        
        %% Should be private
        vConst          % const float
        wOrbit          % const float
        w               % float: current angular velocity
        v               % float: current heading velocity
        
        VoronoiInfo
        AgentPose_3d = zeros(3,1)         % [x y theta]
        CVTCoord_2d = zeros(2,1)
        VMCoord_2d = zeros(2,1);
        dVkdzk
        dCkdzk
        Vk
    end
    
    properties (Access = private)
        dt              % Simulation time step
        received_VoronoiPartitionInfo
        published_dC_neighbor
        Local_dVkdzi_List
        
        %% Save the last result to evaluate the computation of the partial derivative
        prev_dCkdzk
        prev_dVkdzk
        prev_Vk
        prev_CVTCoord_2d
        prev_AgentPose_3d
        prev_VMCoord_2d 
        prev_received_VoronoiPartitionInfo
        prev_published_dC_neighbor
        prev_Local_dVkdzi_List
        
        %% For debugging only
        prev_dVk_dzi_List
        dVk_dzi_List
    end
    
    methods
        %% Initalize class handler
        function obj = Agent_Controller(dt, botID, coverageRegionCoeff, initPose_3d, v0, w0)
            assert(dt~=0);
            obj.dt = dt;
            obj.v = 0;
            obj.w = 0;
            
            obj.ID = botID;
            obj.regionCoeff = coverageRegionCoeff;
            obj.vConst = v0;
            obj.wOrbit = w0;
            
            %% Update initial position and the virtual center
            obj.AgentPose_3d(:) = initPose_3d(:);
            obj.VMCoord_2d(1) = obj.AgentPose_3d(1) - (obj.vConst/obj.wOrbit) * sin(obj.AgentPose_3d(3)); 
            obj.VMCoord_2d(2) = obj.AgentPose_3d(2) + (obj.vConst/obj.wOrbit) * cos(obj.AgentPose_3d(3)); 
        end

        %% Simulate dynamic model 
        % Call this function once every time the control policy is updated
        % to simulate the movement.
        function move(obj) 
            % Unicycle Dynamic
            obj.prev_AgentPose_3d = obj.AgentPose_3d;
            obj.AgentPose_3d(1) = obj.AgentPose_3d(1) + obj.dt * (obj.vConst * cos(obj.AgentPose_3d(3)));
            obj.AgentPose_3d(2) = obj.AgentPose_3d(2) + obj.dt * (obj.vConst * sin(obj.AgentPose_3d(3)));
            obj.AgentPose_3d(3) = obj.AgentPose_3d(3) + obj.dt * obj.w;
            %% Update the virtual mass
            obj.prev_VMCoord_2d = obj.VMCoord_2d;
            obj.VMCoord_2d(1) = obj.AgentPose_3d(1) - (obj.vConst/obj.wOrbit) * sin(obj.AgentPose_3d(3)); 
            obj.VMCoord_2d(2) = obj.AgentPose_3d(2) + (obj.vConst/obj.wOrbit) * cos(obj.AgentPose_3d(3)); 
        end
        
        function [CVT, dCk_dzi_For_Neighbor] = computePartialDerivativeCVT(obj, i_received_VoronoiPartitionInfo)
             format long;
             obj.prev_received_VoronoiPartitionInfo = obj.received_VoronoiPartitionInfo;
             obj.received_VoronoiPartitionInfo = i_received_VoronoiPartitionInfo;
             obj.prev_CVTCoord_2d = obj.CVTCoord_2d;
             obj.prev_dCkdzk = obj.dCkdzk;
             
             assert(isa(i_received_VoronoiPartitionInfo, 'GBS_Voronoi_Report'));             
             % Initally no vertex passed 
             if(~isempty(i_received_VoronoiPartitionInfo.Vertex2D_List))
                [obj.CVTCoord_2d] = Voronoi2D_calcCVT(i_received_VoronoiPartitionInfo.Vertex2D_List);
                CVT = obj.CVTCoord_2d;
               
                nNeighbor = numel(i_received_VoronoiPartitionInfo.NeighborInfoList);
                dCk_dzk = zeros(2,2);
                %% Iterate to obtain the aggregated dCi_dzi
                mVi = Voronoi2D_calcPartitionMass(i_received_VoronoiPartitionInfo.Vertex2D_List);
                dCk_dzi_For_Neighbor = Struct_Neighbor_CVT_PD.empty(nNeighbor, 0);
                for i = 1: nNeighbor
                    % Compute the partial derivative related to each
                    % adjacent agent
                    [dCk_dzk_Neighbor_i, dCk_dzi] = Voronoi2D_calCVTPartialDerivative(...
                                                        obj.VMCoord_2d, ...
                                                        obj.CVTCoord_2d, ...
                                                        mVi, ... 
                                                        i_received_VoronoiPartitionInfo.NeighborInfoList{i}.Neighbor_VM_Coord_2d, ... 
                                                        i_received_VoronoiPartitionInfo.NeighborInfoList{i}.CommonVertex_2d_1, ...
                                                        i_received_VoronoiPartitionInfo.NeighborInfoList{i}.CommonVertex_2d_2);
                    % Result for an adjacent agent to be published
                    dCk_dzi_For_Neighbor(i) = Struct_Neighbor_CVT_PD(obj.ID, i_received_VoronoiPartitionInfo.NeighborInfoList{i}.getReceiverID(), ...
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

        function [tmp] = getAgentCoordReport(obj)
            tmp = Agent_Coordinates_Report(obj.ID);
            tmp.poseCoord_3d =  obj.AgentPose_3d;
            tmp.poseVM_2d = obj.VMCoord_2d;
        end
        
        function [Vk] = computeControlInput(obj, report)
            assert(isa(report{1}, 'Struct_Neighbor_CVT_PD'));
            obj.prev_Vk = obj.Vk;
            obj.prev_dVkdzk = obj.dVkdzk;
            obj.prev_Local_dVkdzi_List = obj.Local_dVkdzi_List;
            format long;
           
            %% Compute the partial derivate of Lyapunov from the received partial derivative of CVTs from adjacent agents
            Q = eye(2);
            [obj.Vk, obj.dVkdzk] = Lyapunov_Self_PD_Computation(obj.VMCoord_2d, obj.CVTCoord_2d, obj.dCkdzk , Q, obj.regionCoeff(:,1:2), obj.regionCoeff(:,3));         
            
            %% This is for debugging the changes of the Lyapunov Partial derivative
            obj.prev_dVk_dzi_List = obj.dVk_dzi_List;
            obj.dVk_dzi_List = cell(numel(report),1);
            for i = 1: numel(report)
                for t = 1: numel(obj.published_dC_neighbor)
                    if(obj.published_dC_neighbor(t).getReceiverID() == report{i}.getSenderID())
                        tmpRet = Lyapunov_Adjacent_PD_Computation(obj.VMCoord_2d, obj.CVTCoord_2d, ...
                                                                    obj.published_dC_neighbor(t).dCdz_2x2 , Q, obj.regionCoeff(:,1:2), obj.regionCoeff(:,3));
                        obj.dVk_dzi_List{i} = {obj.published_dC_neighbor(t).getReceiverID(), report{i}.z, tmpRet};  
                        break;
                    end
                end
            end
            
            %% Aggregate the Lyapunov feedback from neighbor agents
            obj.Local_dVkdzi_List = Struct_Neighbor_CVT_PD_Extended.empty(numel(report), 0);
            dV_Accum_Adjacent_Term = zeros(2,1);
            for i = 1: numel(report)
                [tmp_dV_dAdj] = Lyapunov_Adjacent_PD_Computation(report{i}.z, report{i}.C, report{i}.dCdz_2x2 , Q, obj.regionCoeff(:,1:2), obj.regionCoeff(:,3));
                dV_Accum_Adjacent_Term = dV_Accum_Adjacent_Term + tmp_dV_dAdj;    
                obj.Local_dVkdzi_List(i) = Struct_Neighbor_CVT_PD_Extended(report{i}, tmp_dV_dAdj);
            end
            dV_dzk_total =  obj.dVkdzk + dV_Accum_Adjacent_Term;
            
            %% Adjustable variable --> Will move later to constant
            epsSigmoid = 3;
            mu = 3; % Control gain %% ADJUST THE CONTROL GAIN HERE
            sigmoid_func = @(x,eps) x / (abs(x) + eps);              
            %% Compute the control policy
            obj.w = obj.wOrbit + mu * obj.wOrbit * sigmoid_func(dV_dzk_total' * [cos(obj.AgentPose_3d(3)) ;sin(obj.AgentPose_3d(3))], epsSigmoid); 
            
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
            obj.wOrbit = 0.4;
            sigmoid_func = @(x,eps) x / (abs(x) + eps);  
            epsSigmoid = 10;
            calc_W = obj.wOrbit + gamma * obj.wOrbit * obj.vConst *sigmoid_func((obj.VMCoord_2d - obj.CVTCoord_2d)' * [cos(obj.AgentPose_3d(3)) ; sin(obj.AgentPose_3d(3))],epsSigmoid); 
            
            % Predict the next state            
            predict_Pose_3d = zeros(3,1);
            predict_Pose_VM = zeros(2,1);
            predict_Pose_3d(1) = obj.AgentPose_3d(1) + obj.dt * (obj.vConst * cos(obj.AgentPose_3d(3)));
            predict_Pose_3d(2) = obj.AgentPose_3d(2) + obj.dt * (obj.vConst * sin(obj.AgentPose_3d(3)));
            predict_Pose_3d(3) = obj.AgentPose_3d(3) + obj.dt * calc_W;
            predict_Pose_VM(1) = predict_Pose_3d(1) - (obj.vConst/obj.wOrbit) * sin(predict_Pose_3d(3)); 
            predict_Pose_VM(2) = predict_Pose_3d(2) + (obj.vConst/obj.wOrbit) * cos(predict_Pose_3d(3)); 
            
            isValid = true;
            for j = 1: size(obj.regionCoeff, 1)
                if(obj.regionCoeff(j,3)- (obj.regionCoeff(j,1:2) * predict_Pose_VM) <= 0)
                   isValid = false; 
                end
            end
                
            if(isValid)
                obj.w = calc_W;
            else
                %disp("OUT BOUND ALERT");
                obj.w = obj.wOrbit;
            end
        end 
        
        function PrintReceivedReport(obj)
            fprintf("============ CURRENT REPORT OF AGENT %d =================== \n", obj.ID);
            fprintf("Pose: [%.9f %.9f %.9f], VM: [%.9f %.9f] CVT: [%.9f %.9f] \n", ...
            obj.AgentPose_3d(1), obj.AgentPose_3d(2), obj.AgentPose_3d(3), obj.VMCoord_2d(1), obj.VMCoord_2d(2), obj.CVTCoord_2d(1), obj.CVTCoord_2d(2))
            fprintf("dCk_dzk : [%.9f %.9f; %.9f %.9f]. dVk_dzk: [%.9f %.9f]. Vk %.9f \n", ...
                obj.dCkdzk(1,1), obj.dCkdzk(1,2), obj.dCkdzk(2,1), obj.dCkdzk(2,2), obj.dVkdzk(1), obj.dVkdzk(2), obj.Vk);
            fprintf("VORONOI PARTITION INFORMATION RECEIVED FROM THE ""NATURE"" \n");
            for i = 1: numel(obj.received_VoronoiPartitionInfo.NeighborInfoList)
               obj.received_VoronoiPartitionInfo.NeighborInfoList{i}.printValue();
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
            for i = 1: numel(obj.prev_received_VoronoiPartitionInfo.NeighborInfoList)
               obj.prev_received_VoronoiPartitionInfo.NeighborInfoList{i}.printValue();
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
                dzi = obj.Local_dVkdzi_List(i).z - obj.prev_Local_dVkdzi_List(i).z;
                calc_dCk = calc_dCk + obj.prev_published_dC_neighbor(i).dCdz_2x2 * dzi;
                %calc_dV = calc_dV + obj.prev_Local_dVkdzi_List(i).calc_dV_dzNeighbor_2d' * dzi;
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





