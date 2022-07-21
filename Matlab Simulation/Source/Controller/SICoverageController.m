classdef SICoverageController < CoverageControllerBase 
    %SICONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function v = compute(obj, pIst_3, pSoll_3)            
            v = obj.controlParam.P * (pSoll_3 - pIst_3)/norm(pSoll_3 - pIst_3);
        end
    end
end

