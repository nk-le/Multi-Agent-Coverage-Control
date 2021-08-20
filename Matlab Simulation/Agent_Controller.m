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
        function obj = Agent_Controller(dt)
            obj.dt = dt;
            obj.v = 0;
            obj.w = 0;
        end
        
        %% One time configuration
        %   Assign a fix ID for each controller for communication broadcasting and easy debugging
        %   Assign the coefficient of the closed convex region: [coverageRegionCoeff] = [a1 a2 b] --> a1*x + a2*y - b <= 0
        function obj = begin(obj, botID, coverageRegionCoeff, initPose, v0, w0)
            obj.ID = botID;
            obj.regionCoeff = coverageRegionCoeff;
            obj.vConst = v0;
            obj.wOrbit = w0;
            
            % Update initial position
            obj.setState(initPose);
        end
        
        %% Position feedback and internal state update
       function [newVMPose] = setState(obj, newPose)
            % Update Current state
            obj.curPose = newPose;
            % Update virtual center, save internally
            [curVM] = obj.updateVirtualCenter();
            
            %% Return
            newVMPose = curVM;
        end
        
        %% Get the current virtual center according to the current pose 
        %  wOrbit is fixed orbiting angular velocity
        %  cVonst is fixed heading velocity
        function [poseVM] = updateVirtualCenter(obj)            
            obj.curVMPose(1) = obj.curPose(1) - (obj.vConst/obj.wOrbit) * sin(obj.curPose(3)); 
            obj.curVMPose(2) = obj.curPose(2) + (obj.vConst/obj.wOrbit) * cos(obj.curPose(3)); 
            poseVM = [obj.curVMPose];
        end
    
        function setAngularVel(obj, w)
            obj.w = w;
        end
        
        function setHeadingVel(obj, v)
            obj.vConst = v;
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
        
        function computeOutput(obj, voronoiData)
             assert(isa(voronoiData, 'GBS_Voronoi_Report'));
             %obj.VoronoiInfo = voronoiData;
             
             if(isempty(voronoiData.Vertex2D_List))
                
             else
                [obj.CVTCoord_2d] = Voronoi2D_calcCVT(voronoiData.Vertex2D_List);
                %[out] = Voronoi2D_calCVTPartialDerivative(voronoiData.NeighborInfoList);
                %assert(isa(neighborInfoList, 'Struct_Neighbor_Info'));

                nNeighbor = numel(voronoiData.NeighborInfoList);
                for neighborID = 1: nNeighbor
                    mVi = Voronoi2D_calcPartitionMass(voronoiData.Vertex2D_List);
                    adjCoord_2d = voronoiData.NeighborInfoList(neighborID).Neighbor_Coord_2d;
                    vertex1_2d = voronoiData.NeighborInfoList(neighborID).CommonVertex_2d_1;
                    vertex2_2d = voronoiData.NeighborInfoList(neighborID).CommonVertex_2d_2;
                    Voronoi2D_calCVTPartialDerivative(obj.curVMPose, obj.CVTCoord_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d)
                end
             end

        end
        
%         function loop(obj)
%             % Universal time step
%             if(obj.dt == 0)
%                error("Simulation time step dt was not assigned"); 
%             end
%             obj.move();
%         end
        
        
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
        
%         function receiveGBS(obj, newData)
%             isa(newData, 'GBS_Voronoi_Report');
%             obj.VoronoiInfo = newData;
%         end
        
        
        
        
        
        
        
    end
end

