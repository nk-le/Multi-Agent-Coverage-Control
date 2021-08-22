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
        lastSubV
        currentSubV
        
        
        
        %% Newly added
        VoronoiInfo
        CVTCoord_2d
    end
    
    properties (Access = private)
        
    end
    
    methods
        %% Initalize class handler
        function obj = Agent_Controller(dt, botID, coverageRegionCoeff, initPose, v0, w0)
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
        function move(obj) % Unicycle Dynamic
            % Universal time step
            if(obj.dt == 0)
               error("Simulation time step dt was not assigned"); 
            end
            obj.curPose(1) = obj.curPose(1) + obj.dt * (obj.vConst * cos(obj.curPose(3)));
            obj.curPose(2) = obj.curPose(2) + obj.dt * (obj.vConst * sin(obj.curPose(3)));
            obj.curPose(3) = obj.curPose(3) + obj.dt * obj.w;
            %% Update the virtual mass
            obj.curVMPose(1) = obj.curPose(1) - (obj.vConst/obj.wOrbit) * sin(obj.curPose(3)); 
            obj.curVMPose(2) = obj.curPose(2) + (obj.vConst/obj.wOrbit) * cos(obj.curPose(3)); 
        end
        
        function [Vk, dVkdzk, neighbordVdz] = computeLyapunovFeedback(obj, voronoiData)
             assert(isa(voronoiData, 'GBS_Voronoi_Report'));             
             % Initally no vertex passed 
             if(~isempty(voronoiData.Vertex2D_List))
                [obj.CVTCoord_2d] = Voronoi2D_calcCVT(voronoiData.Vertex2D_List);
                %[out] = Voronoi2D_calCVTPartialDerivative(voronoiData.NeighborInfoList);
                %assert(isa(neighborInfoList, 'Struct_Neighbor_Info'));

                nNeighbor = numel(voronoiData.NeighborInfoList);
                tmp_dCk_dzi_List = zeros(nNeighbor, 2,2);
                dCk_dzk = zeros(2,2);
                %% Iterate to obtain the aggregated dCi_dzi
                for i = 1: nNeighbor
                    mVi = Voronoi2D_calcPartitionMass(voronoiData.Vertex2D_List);
                    adjCoord_2d = voronoiData.NeighborInfoList(i).Neighbor_Coord_2d;
                    vertex1_2d = voronoiData.NeighborInfoList(i).CommonVertex_2d_1;
                    vertex2_2d = voronoiData.NeighborInfoList(i).CommonVertex_2d_2;
                    [dCk_dzk_Neighbor_i, tmp_dCk_dzi_List(i,:,:)] = Voronoi2D_calCVTPartialDerivative(obj.curVMPose, obj.CVTCoord_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d);
                    dCk_dzk = dCk_dzk + dCk_dzk_Neighbor_i;
                end
                
                %% Preparation for the computation of Lyapunov Derivative
                %% Some adjustable variables Parameter
                Q = eye(2);
                tol = 1; % Tolerance to relax the state constraint

                %% Computation
                zk = [obj.curPose(1) obj.curPose(2)]';
                sum_1_div_Hj = 0;
                sum_aj_HjSquared = 0;
                for j = 1: size(obj.regionCoeff)
                    hj = (obj.regionCoeff(j,3)- (obj.regionCoeff(j,1)*zk(1) + obj.regionCoeff(j,2)*zk(2) + tol)); 
                    sum_1_div_Hj = sum_1_div_Hj + 1/hj;
                    sum_aj_HjSquared = sum_aj_HjSquared + [obj.regionCoeff(j,1); obj.regionCoeff(j,2)] / hj^2 / 2; 
                end
                Q_zDiff_div_hj = Q * (zk - obj.CVTCoord_2d) * sum_1_div_Hj;
                 
                %% Compute the Partial dVi_dzi of itself
                Vk = (zk - obj.CVTCoord_2d)' * Q * (zk - obj.CVTCoord_2d) * sum_1_div_Hj;
                dVkdzk = (eye(2) - dCk_dzk')*Q_zDiff_div_hj + sum_aj_HjSquared * (zk - obj.CVTCoord_2d)' * Q * (zk - obj.CVTCoord_2d);
                % Assign to the Info handle
                
                %% Iterative to compute the partial Lyapunov derivative for each neighbor
                neighbordVdz = Struct_Neighbor_Lyapunov.empty(nNeighbor, 0);
                for i = 1: nNeighbor
                    dCi_dzk(:,:) = tmp_dCk_dzi_List(i,:,:);
                    dVkdzi = -dCi_dzk' * Q_zDiff_div_hj;
                    % Assign the new adjacent partial derivative
                    neighbordVdz(i) = Struct_Neighbor_Lyapunov(obj.ID, voronoiData.NeighborInfoList(i).getReceiverID(), dVkdzi); %% Create a report with neighbor ID to publish
                end
             else
                 fprintf("WARN: Agent %d: No vertex for region partitioning detected \n", obj.ID);
                 Vk = [];
                 dVkdzk = [];
                 neighbordVdz = [];
             end
        end
          
        
        function pose = getPose_3d(obj)
            pose = obj.curPose;
        end
        
        function vm = getVirtualMass_2d(obj)
            vm = obj.curVMPose;
        end
        
        function [tmp] = getAgentCoordReport(obj)
            tmp = Agent_Coordinates_Report(obj.ID);
            tmp.poseCoord_3d =  obj.curPose;
            tmp.poseVM_2d = obj.curVMPose;
        end
        
        function executeControl(obj, report)
            
        end
        
        
        
        
        
    end
end

