classdef UnicycleSimpleCoverageAgent < UnicycleCoverageAgent
    %UNICYCLESIMPLECOVERAGEAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function out = set_controller(obj, controlParam, regionParam)
            %%% Set the specific controller
            % TODO: bring this method to the base class
            out = VMSimpleCoverageController(controlParam, regionParam);
        end
        
        function [H, wOut] = compute_control_input(obj, report)
            assert(isa(report{1}, 'Struct_Neighbor_CVT_PD'));
            % Call this method to raise the assertion if agent leaves the
            % coveration region
            obj.voronoiComputer.update_partial_derivative_info(report)
            
            [wOut] = obj.controller.compute(obj.AgentPose_3d, obj.voronoiComputer);
            
            % compute the Lyapunov function
            % Todo: phi(q) is not yet considered
            IntDomain = struct('type','polygon','x',obj.received_VoronoiPartitionInfo.Vertex2D_List(1: end -1,1)','y',obj.received_VoronoiPartitionInfo.Vertex2D_List(1: end - 1,2)');
            param = struct('method','gauss','points',6);
            normSquared = @(x,y) (x - obj.VMCoord_2d(1))^2 + (y - obj.VMCoord_2d(2))^2;
            H = doubleintegral(normSquared, IntDomain, param);
        end
    end
end

