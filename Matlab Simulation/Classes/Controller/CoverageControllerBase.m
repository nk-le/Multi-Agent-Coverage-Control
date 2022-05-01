classdef CoverageControllerBase < ControllerBase
    
    properties
        regionParam 
        
    end
    
    methods
        function obj = CoverageControllerBase(controlParam, regionParam)
            obj = obj@ControllerBase(controlParam);
            obj.regionParam = regionParam;
        end
    end
end

