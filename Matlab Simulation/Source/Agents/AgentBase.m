classdef (Abstract) AgentBase < handle
    %    Agents Dynamic
    %
    %
    
    
    properties
        dt = SimulationParameter.TIME_STEP;
        ID = -1
        
        coord_3
        attitude_3
        
    end
    
    methods
        function obj = AgentBase(id)
            obj.ID = id;
        end
        
        function id = get_id(obj)
           id = obj.ID;
        end
    end
    
    methods (Abstract)
        move(obj)
        %control(obj)
    end
end

