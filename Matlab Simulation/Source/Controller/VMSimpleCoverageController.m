classdef VMSimpleCoverageController < CoverageControllerBase 
    %VMSimpleCoverageController Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods

        function wOut = compute(obj, curPose, voronoiCom)  
            dZC = voronoiCom.GeneratorCoord_2d - voronoiCom.CVTCoord_2d;
            wOut =   obj.controlParam.W_ORBIT + ...
                3e-2 * obj.controlParam.W_ORBIT * (dZC' * [cos(curPose(3)) ;sin(curPose(3))]);                     
        end
        

    end
end

