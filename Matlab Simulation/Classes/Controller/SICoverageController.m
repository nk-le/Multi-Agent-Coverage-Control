classdef SICoverageController < CoverageControllerBase 
    %SICONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function v = compute(obj, pIst_3, pSoll_3)            
            v = obj.controlParam.P * (pSoll_3 - pIst_3);
            v(v > 30) = 30;
            v(v < -30) = -30;
        end
    end
end

