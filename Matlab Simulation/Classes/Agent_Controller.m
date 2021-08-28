%% Agent_Controller - distributed controller for unicycle agent
%

classdef Agent_Controller < handle
    %AGENT_CONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ID              % int
        curPose = zeros(3,1)         % [x y theta]
        
        regionCoeff     % [a1 a2 b] --> a1*x + a2*y - b <= 0
        
        %% Should be private
        dt              % Simulation time step
        vConst          % const float
        wOrbit          % const float
        
        w               % float: current angular velocity
        v               % float: current heading velocity
        
        
        
        %% Newly added
        VoronoiInfo
        CVTCoord_2d = zeros(2,1)
        VMCoord_2d = zeros(2,1);
        dVkdzk
        dCkdzk
        Vk
        
        %% For debug only
        last_received_VoronoiPartitionInfo
        last_published_dC_neighbor
        last_received_Adjacent_Reports
    end
    
    properties (Access = private)
        
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
            obj.curPose(:) = initPose_3d(:);
            obj.VMCoord_2d(1) = obj.curPose(1) - (obj.vConst/obj.wOrbit) * sin(obj.curPose(3)); 
            obj.VMCoord_2d(2) = obj.curPose(2) + (obj.vConst/obj.wOrbit) * cos(obj.curPose(3)); 
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
            obj.VMCoord_2d(1) = obj.curPose(1) - (obj.vConst/obj.wOrbit) * sin(obj.curPose(3)); 
            obj.VMCoord_2d(2) = obj.curPose(2) + (obj.vConst/obj.wOrbit) * cos(obj.curPose(3)); 
        end
        
        function [CVT, dCk_dzi_For_Neighbor] = computePartialDerivativeCVT(obj, i_last_received_VoronoiPartitionInfo)
             format long;
             %% For debugging only
            
             assert(isa(i_last_received_VoronoiPartitionInfo, 'GBS_Voronoi_Report'));             
             % Initally no vertex passed 
             if(~isempty(i_last_received_VoronoiPartitionInfo.Vertex2D_List))
                [obj.CVTCoord_2d] = Voronoi2D_calcCVT(i_last_received_VoronoiPartitionInfo.Vertex2D_List);
                CVT = obj.CVTCoord_2d;
               
                nNeighbor = numel(i_last_received_VoronoiPartitionInfo.NeighborInfoList);
                dCk_dzk = zeros(2,2);
                %% Iterate to obtain the aggregated dCi_dzi
                mVi = Voronoi2D_calcPartitionMass(i_last_received_VoronoiPartitionInfo.Vertex2D_List);
                dCk_dzi_For_Neighbor = Struct_Neighbor_Lyapunov.empty(nNeighbor, 0);
                for i = 1: nNeighbor
                    % Compute the partial derivative related to each
                    % adjacent agent
                    [dCk_dzk_Neighbor_i, dCk_dzi] = Voronoi2D_calCVTPartialDerivative(...
                                                        obj.VMCoord_2d, ...
                                                        obj.CVTCoord_2d, ...
                                                        mVi, ... 
                                                        i_last_received_VoronoiPartitionInfo.NeighborInfoList{i}.Neighbor_Coord_2d, ... 
                                                        i_last_received_VoronoiPartitionInfo.NeighborInfoList{i}.CommonVertex_2d_1, ...
                                                        i_last_received_VoronoiPartitionInfo.NeighborInfoList{i}.CommonVertex_2d_2);
                    % Result for an adjacent agent to be published
                    dCk_dzi_For_Neighbor(i) = Struct_Neighbor_Lyapunov(obj.ID, i_last_received_VoronoiPartitionInfo.NeighborInfoList{i}.getReceiverID(), ...
                                                                       obj.VMCoord_2d, ...
                                                                       obj.CVTCoord_2d, ...
                                                                       dCk_dzi); %% Create a report with neighbor ID to publish             
                    % Accumulate to get the own partial derivative
                    dCk_dzk = dCk_dzk + dCk_dzk_Neighbor_i;
                end
                obj.dCkdzk = dCk_dzk;
                
                %% For debugging only
                obj.last_received_VoronoiPartitionInfo = i_last_received_VoronoiPartitionInfo;
                obj.last_published_dC_neighbor = dCk_dzi_For_Neighbor;
                
             else
                 fprintf("WARN: Agent %d: No vertex for region partitioning detected \n", obj.ID);
                 CVT = [];
                 dCk_dzi_For_Neighbor = [];
             end
        end

        function [tmp] = getAgentCoordReport(obj)
            tmp = Agent_Coordinates_Report(obj.ID);
            tmp.poseCoord_3d =  obj.curPose;
            tmp.poseVM_2d = obj.VMCoord_2d;
        end
        
        function [Vk] = computeControlInput(obj, report)
            obj.last_received_Adjacent_Reports = report;
            format long;
            %% Compute the partial derivate of Lyapunov from the received partial derivative of CVTs from adjacent agents
            Q = eye(2);
            tol = 0; % Tolerance to relax the state constraint

            %% Aggregate the Lyapunov feedback from neighbor agents
            dV_Adjacent_Numerator_Term = zeros(2,1);
            
            % Own Lyapunov Partial Derivative
            sum_1_div_Hj = 0;
            sum_aj_HjSquared = zeros(2,1);
            for j = 1: size(obj.regionCoeff, 1)
                hj = (obj.regionCoeff(j,3)- (obj.regionCoeff(j,1:2) * obj.VMCoord_2d+ tol)); 
                sum_1_div_Hj = sum_1_div_Hj + 1/hj;
                sum_aj_HjSquared = sum_aj_HjSquared + obj.regionCoeff(j,1:2)' / hj^2 / 2; 
            end
            
            normQ_func = @(vec, Q2x2) sqrt(vec' * Q2x2 * vec);
            obj.Vk = normQ_func(obj.VMCoord_2d - obj.CVTCoord_2d, Q)^2 * sum_1_div_Hj / 2;
            obj.dVkdzk = (eye(2) - obj.dCkdzk') * Q * (obj.VMCoord_2d - obj.CVTCoord_2d) * sum_1_div_Hj ...
                        + normQ_func(obj.VMCoord_2d - obj.CVTCoord_2d, Q) * sum_aj_HjSquared;
            
            
            adjdV_numerator_func = @(zi_2, Ci_2, dCi2x2, Q2x2) -dCi2x2' * Q2x2 * (zi_2 - Ci_2);
            for i = 1: numel(report)
                Ci = report{i}.Ck;
                zi = report{i}.zk;
                dCi_dzk = report{i}.dCdz_2x2;   
                dV_Adjacent_Numerator_Term = dV_Adjacent_Numerator_Term + adjdV_numerator_func(zi, Ci, dCi_dzk, Q); 
            end
            dV_Adjacent_Term = dV_Adjacent_Numerator_Term * sum_1_div_Hj;
            dV_dzk_total =  obj.dVkdzk + dV_Adjacent_Term;
            
            %% Adjustable variable --> Will move later to constant
            epsSigmoid = 3;
            mu = 3; % Control gain %% ADJUST THE CONTROL GAIN HERE
            sigmoid_func = @(x,eps) x / (abs(x) + eps);  
            w0 = 0.4; 
            
            %% Compute the control policy
            obj.w = w0 + mu * w0 * sigmoid_func(dV_dzk_total' * [cos(obj.curPose(3)) ;sin(obj.curPose(3))], epsSigmoid); 
            
            %% Debugging
            Vk = obj.Vk;
        end
        
        function printReceivedReport(obj)
            fprintf("============ START REPORT OF AGENT %d =================== \n", obj.ID);
            fprintf("Pose: [%.9f %.9f %.9f], VM: [%.9f %.9f] CVT: [%.9f %.9f] \n", ...
            obj.curPose(1), obj.curPose(2), obj.curPose(3), obj.VMCoord_2d(1), obj.VMCoord_2d(2), obj.CVTCoord_2d(1), obj.CVTCoord_2d(2))
            fprintf("dCk_dzk : [%.9f %.9f; %.9f %.9f]. dVk_dzk: [%.9f %.9f]. Vk %.9f \n", ...
                obj.dCkdzk(1,1), obj.dCkdzk(1,2), obj.dCkdzk(2,1), obj.dCkdzk(2,2), obj.dVkdzk(1), obj.dVkdzk(2), obj.Vk);
            fprintf("VORONOI PARTITION INFORMATION RECEIVED FROM THE ""NATURE"" \n");
            for i = 1: numel(obj.last_received_VoronoiPartitionInfo.NeighborInfoList)
               obj.last_received_VoronoiPartitionInfo.NeighborInfoList{i}.printValue();
            end
            fprintf("COMPUTED PARTIAL DERIVATIVE \n");
            for i = 1:numel(obj.last_published_dC_neighbor)
                obj.last_published_dC_neighbor(i).printValue();
            end
            fprintf("PARTIAL DERIVATIVE INFORMATION DOWNLOADED FROM THE COMMUNICATION LINK\n");
            for i = 1: numel(obj.last_received_Adjacent_Reports)
                obj.last_received_Adjacent_Reports{i}.printValue();
            end
            fprintf("=============== END ================= \n");
           
        end
        
    end
end

