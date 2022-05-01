classdef (Abstract) AgentBase < handle
    %    Agents Dynamic
    %
    %
    
    
    properties
        dt = SimulationParameter.TIME_STEP;
        
        coord_3
        attitude_3
        
    end
    
    methods
        function obj = AgentBase(obj)
            
        end
        
        
    end
    
    methods (Abstract)
        move(obj)
        %control(obj)
    end
end

