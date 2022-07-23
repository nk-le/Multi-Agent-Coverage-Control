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
            
            % TODO: the Lyapunov function of this control method is not yet
            % properly implemented. Will be modified later. We use the
            % simple Euclidean distance for now
            H = norm(obj.VMCoord_2d(1:2) - obj.voronoiComputer.CVTCoord_2d);
        end
    end
end

