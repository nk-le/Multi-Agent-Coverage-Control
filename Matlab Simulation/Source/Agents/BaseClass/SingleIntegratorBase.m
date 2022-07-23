classdef SingleIntegratorBase < AgentBase & CoverageAgentBase
    %SINGLEINTEGRATORAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        velocity_3
    end
    
    methods
        function obj = SingleIntegratorBase(dt, id, initPose_3d)
            obj@AgentBase(dt, id);
            obj.coord_3 = initPose_3d;
        end
        
        function obj = move(obj, v) 
            obj.velocity_3 = v;
            obj.coord_3 = obj.coord_3 + obj.velocity_3 * obj.dt;
        end
        
        function [Pose_3d] = get_pose(obj)
            Pose_3d =  [0,0,0];
        end
        
        function [Coord_3] = get_coord_3(obj)
            % Todo: properly distinguish coord and pose (orientation)
            Coord_3 = obj.coord_3;
        end
    end
end

