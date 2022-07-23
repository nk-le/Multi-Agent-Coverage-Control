classdef SingleIntegratorAgent  < SingleIntegratorBase
    %SINGLEINTEGRATORAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        regionParam
        controlParam
        
        controller
        voronoiComputer
    end
    
    methods
        function obj = SingleIntegratorAgent(dt, botID, initPose_3, regionParam, controlParam)
            obj@SingleIntegratorBase(dt, botID, initPose_3);
            obj.controller = SICoverageController(controlParam, regionParam);
            obj.voronoiComputer = VoronoiComputer(botID);
            obj.regionParam = regionParam;
        end
        
        function [Pose_3d] = getPose(obj)
            Pose_3d =  obj.coord_3;
        end
        
        function z = get_voronoi_generator_2(obj)
            z = obj.coord_3(1:2)';
        end
        
        function [H, v] = compute_control_input(obj, report)
            obj.voronoiComputer.update_partial_derivative_info(report)
            CVTCoord_3 = reshape([obj.voronoiComputer.CVTCoord_2d; 0], size(obj.coord_3));
            [v] = obj.controller.compute(obj.coord_3, CVTCoord_3);
            H = norm(obj.coord_3 - CVTCoord_3);
        end
    end
end

