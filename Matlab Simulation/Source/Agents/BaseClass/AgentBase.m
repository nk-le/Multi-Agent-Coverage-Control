classdef (Abstract) AgentBase < handle
    %    Agents Dynamic
    %
    %
    
    properties
        dt
        ID = -1
        
        coord_3
        attitude_3
        
    end
    
    methods
        function obj = AgentBase(dt, id)
            obj.dt = dt;
            obj.ID = id;
        end
        
        function id = get_id(obj)
           id = obj.ID;
        end
    end
    
    methods (Abstract)
        move(obj)
        get_coord_3(obj);
        %control(obj)
    end
end

