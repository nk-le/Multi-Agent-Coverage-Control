classdef VMSimpleCoverageController < CoverageControllerBase 
    %VMSimpleCoverageController Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods

        function wOut = compute(obj, curPose, voronoiCom)  
            [Vk, ~] = Calc_Self_PD_L(...
                voronoiCom.GeneratorCoord_2d, voronoiCom.CVTCoord_2d, voronoiCom.dCkdzk , obj.controlParam.Q2x2, obj.regionParam.BOUNDARIES_COEFF(:,1:2), obj.regionParam.BOUNDARIES_COEFF(:,3));         
            assert(Vk >= 0);
            sigmoid_func = @(x,eps) x / (abs(x) + eps);  
            dZC = voronoiCom.GeneratorCoord_2d - voronoiCom.CVTCoord_2d;
            dotProd = dZC' * [cos(curPose(3)) ;sin(curPose(3))];
            wOut =   obj.controlParam.W_ORBIT + ...
                obj.controlParam.GAMMA * obj.controlParam.W_ORBIT * obj.controlParam.V_CONST * sigmoid_func(dotProd, obj.controlParam.EPS_SIGMOID);                     
        end
        

    end
end

