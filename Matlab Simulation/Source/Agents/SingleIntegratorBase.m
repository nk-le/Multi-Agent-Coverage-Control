classdef SingleIntegratorBase < AgentBase & CoverageAgentBase
    %SINGLEINTEGRATORAGENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        velocity_3
    end
    
    methods
        function obj = SingleIntegratorBase(id, initPose_3d)
            obj@AgentBase(id);
            obj.coord_3 = initPose_3d;
        end
        
        function obj = move(obj, v) 
            obj.velocity_3 = v;
            obj.coord_3 = obj.coord_3 + obj.velocity_3 * obj.dt;
        end
    end
end

