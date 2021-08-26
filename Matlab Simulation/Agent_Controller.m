%% Agent_Controller - distributed controller for unicycle agent
%

classdef Agent_Controller < handle
    %AGENT_CONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ID              % int
        curPose         % [x y theta]
        curVMPose       % [x y]
        curCVTPose      % [x y]
        
        regionCoeff     % [a1 a2 b] --> a1*x + a2*y - b <= 0
        
        %% Should be private
        dt              % Simulation time step
        vConst          % const float
        wOrbit          % const float
        
        w               % float: current angular velocity
        v               % float: current heading velocity
        
        
        
        %% Newly added
        VoronoiInfo
        CVTCoord_2d
        dVkdzk
        dCkdzk
        
        %% For debug only
        VoronoiPartitionInfo
        PartialDerivativeReport
        Vk
    end
    
    properties (Access = private)
        
    end
    
    methods
        %% Initalize class handler
        function obj = Agent_Controller(dt, botID, coverageRegionCoeff, initPose, v0, w0)
            assert(dt~=0);
            obj.dt = dt;
            obj.v = 0;
            obj.w = 0;
            
            obj.ID = botID;
            obj.regionCoeff = coverageRegionCoeff;
            obj.vConst = v0;
            obj.wOrbit = w0;
            
            %% Update initial position and the virtual center
            obj.curPose = initPose;
            obj.curVMPose(1) = obj.curPose(1) - (obj.vConst/obj.wOrbit) * sin(obj.curPose(3)); 
            obj.curVMPose(2) = obj.curPose(2) + (obj.vConst/obj.wOrbit) * cos(obj.curPose(3)); 
        end

        %% Simulate dynamic model 
        % Call this function once every time the control policy is updated
        % to simulate the movement.
        function move(obj) 
            % Unicycle Dynamic
            obj.curPose(1) = obj.curPose(1) + obj.dt * (obj.vConst * cos(obj.curPose(3)));
            obj.curPose(2) = obj.curPose(2) + obj.dt * (obj.vConst * sin(obj.curPose(3)));
            obj.curPose(3) = obj.curPose(3) + obj.dt * obj.w;
            %% Update the virtual mass
            obj.curVMPose(1) = obj.curPose(1) - (obj.vConst/obj.wOrbit) * sin(obj.curPose(3)); 
            obj.curVMPose(2) = obj.curPose(2) + (obj.vConst/obj.wOrbit) * cos(obj.curPose(3)); 
        end
        
        function [CVT, Vk, dVkdzk, neighbordVdz] = computeLyapunovFeedback(obj, i_VoronoiPartitionInfo)
             format long;
             %% For debugging only
             obj.VoronoiPartitionInfo = i_VoronoiPartitionInfo;
            
             assert(isa(i_VoronoiPartitionInfo, 'GBS_Voronoi_Report'));             
             % Initally no vertex passed 
             if(~isempty(i_VoronoiPartitionInfo.Vertex2D_List))
                [obj.CVTCoord_2d] = Voronoi2D_calcCVT(i_VoronoiPartitionInfo.Vertex2D_List);
                CVT = obj.CVTCoord_2d;
               
                nNeighbor = numel(i_VoronoiPartitionInfo.NeighborInfoList);
                tmp_dCk_dzi_List = zeros(nNeighbor, 2,2);
                dCk_dzk = zeros(2,2);
                %% Iterate to obtain the aggregated dCi_dzi
                mVi = Voronoi2D_calcPartitionMass(i_VoronoiPartitionInfo.Vertex2D_List);
                for i = 1: nNeighbor
                    adjCoord_2d = i_VoronoiPartitionInfo.NeighborInfoList{i}.Neighbor_Coord_2d;
                    vertex1_2d = i_VoronoiPartitionInfo.NeighborInfoList{i}.CommonVertex_2d_1;
                    vertex2_2d = i_VoronoiPartitionInfo.NeighborInfoList{i}.CommonVertex_2d_2;
                    [dCk_dzk_Neighbor_i, tmp_dCk_dzi_List(i,:,:)] = Voronoi2D_calCVTPartialDerivative(obj.curVMPose, obj.CVTCoord_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d);
                    dCk_dzk = dCk_dzk + dCk_dzk_Neighbor_i;
                end
                obj.dCkdzk = dCk_dzk;
                
                %% Preparation for the computation of Lyapunov Derivative
                %% Some adjustable variables Parameter
                Q = eye(2);
                tol = 0; % Tolerance to relax the state constraint

                %% Computation
                zk = [obj.curVMPose(1) obj.curVMPose(2)]';
                sum_1_div_Hj = 0;
                sum_aj_HjSquared = 0;
                for j = 1: size(obj.regionCoeff)
                    hj = (obj.regionCoeff(j,3)- (obj.regionCoeff(j,1)*zk(1) + obj.regionCoeff(j,2)*zk(2) + tol)); 
                    sum_1_div_Hj = sum_1_div_Hj + 1/hj;
                    sum_aj_HjSquared = sum_aj_HjSquared + [obj.regionCoeff(j,1); obj.regionCoeff(j,2)] / hj^2 / 2; 
                end
                Q_zDiff_div_hj = Q * (zk - obj.CVTCoord_2d) * sum_1_div_Hj;
                 
                %% Compute the Partial dVi_dzi of itself
                obj.Vk = (zk - obj.CVTCoord_2d)' * Q * (zk - obj.CVTCoord_2d) * sum_1_div_Hj;
                Vk = obj.Vk;
                obj.dVkdzk = (eye(2) - dCk_dzk')*Q_zDiff_div_hj + sum_aj_HjSquared * (zk - obj.CVTCoord_2d)' * Q * (zk - obj.CVTCoord_2d);
                dVkdzk = obj.dVkdzk; 
                
                %% Iterative to compute the partial Lyapunov derivative for each neighbor
                neighbordVdz = Struct_Neighbor_Lyapunov.empty(nNeighbor, 0);
                for i = 1: nNeighbor
                    dCk_dzi(:,:) = tmp_dCk_dzi_List(i,:,:);
                    dVkdzi = -dCk_dzi' * Q_zDiff_div_hj;
                    % Assign the new adjacent partial derivative
                    neighbordVdz(i) = Struct_Neighbor_Lyapunov(obj.ID, i_VoronoiPartitionInfo.NeighborInfoList{i}.getReceiverID(), dVkdzi, dCk_dzi); %% Create a report with neighbor ID to publish             
                end
             else
                 fprintf("WARN: Agent %d: No vertex for region partitioning detected \n", obj.ID);
                 Vk = [];
                 dVkdzk = [];
                 neighbordVdz = [];
             end
        end

        function [tmp] = getAgentCoordReport(obj)
            tmp = Agent_Coordinates_Report(obj.ID);
            tmp.poseCoord_3d =  obj.curPose;
            tmp.poseVM_2d = obj.curVMPose;
        end
        
        function computeControlInput(obj, report)
            format long;
            obj.PartialDerivativeReport = report;
%             fprintf("AgentID %d exc Control \n", obj.ID)
%             for i = 1 : numel(report)
%                report{i}.printValue(); 
%             end
%             fprintf("End \n");
            
            %% Aggregate the Lyapunov feedback from neighbor agents
            sum_dVi_dzk = obj.dVkdzk;
            for i = 1: numel(report)
                sum_dVi_dzk = sum_dVi_dzk + report{i}.dVdz_2d;
            end
           
            %% Adjustable variable --> Will move later to constant
            epsSigmoid = 3;
            mu = 3; % Control gain %% ADJUST THE CONTROL GAIN HERE
            sigmoid_func = @(x,eps) x / (abs(x) + eps);  
            w0 = 1.2; 
            
            %% Compute the control policy
            obj.w = w0 + mu * w0 * sigmoid_func(sum_dVi_dzk' * [cos(obj.curPose(3)) ;sin(obj.curPose(3))], epsSigmoid); 
        end
        
        function printReceivedReport(obj)
            fprintf("============ START REPORT OF AGENT %d =================== \n", obj.ID);
            fprintf("Pose: [%.9f %.9f %.9f], VM: [%.9f %.9f] CVT: [%.9f %.9f] \n", ...
            obj.curPose(1), obj.curPose(2), obj.curPose(3), obj.curVMPose(1), obj.curVMPose(2), obj.CVTCoord_2d(1), obj.CVTCoord_2d(2))
            fprintf("dCk_dzk : [%.9f %.9f; %.9f %.9f]. dVk_dzk: [%.9f %.9f]. Vk %.9f \n", ...
                obj.dCkdzk(1,1), obj.dCkdzk(1,2), obj.dCkdzk(2,1), obj.dCkdzk(2,2), obj.dVkdzk(1), obj.dVkdzk(2), obj.Vk);
            fprintf("VORONOI PARTITION INFORMATION RECEIVED FROM THE ""NATURE"" \n");
            for i = 1: numel(obj.VoronoiPartitionInfo.NeighborInfoList)
               obj.VoronoiPartitionInfo.NeighborInfoList{i}.printValue();
            end
            fprintf("\nPARTIAL DERIVATIVE INFORMATION DOWNLOADED FROM THE COMMUNICATION LINK\n");
            for i = 1: numel(obj.PartialDerivativeReport)
                obj.PartialDerivativeReport{i}.printValue();
            end
            fprintf("=============== END ================= \n");
           
        end
        
    end
end

