classdef (Abstract) ControllerBase < handle
    %CONTROLLERBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        controlParam
    end
    
    methods
        function obj = ControllerBase(controlParam)
            obj.controlParam = controlParam;
        end
    end
    
    methods (Abstract)
        compute(obj)
    end
end

