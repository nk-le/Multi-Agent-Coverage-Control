classdef BLFController < CoverageControllerBase
    %BLFCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %% Computed partial derivative of Lyapunov function
        dVkdzk
        Vk
        Local_dVkdzi_List
        prev_dVkdzk
        prev_Vk
        prev_Local_dVkdzi_List
        
        %% For debugging only, these results are computed but only used internally
        dVk_dzi_List
        prev_dVk_dzi_List
    end
    
    methods
        
        function [Vk, wOut] = compute(obj, curPose, voronoiCom)
            obj.prev_Vk = obj.Vk;
            obj.prev_dVkdzk = obj.dVkdzk;
            obj.prev_Local_dVkdzi_List = obj.Local_dVkdzi_List;
            
            %% Compute the partial derivate of Lyapunov from the received partial derivative of CVTs from adjacent agents
            [obj.Vk, obj.dVkdzk] = Lyapunov_Self_PD_Computation(...
                voronoiCom.GeneratorCoord_2d, voronoiCom.CVTCoord_2d, voronoiCom.dCkdzk , obj.controlParam.Q2x2, obj.regionParam.BOUNDARIES_COEFF(:,1:2), obj.regionParam.BOUNDARIES_COEFF(:,3));         
            assert(obj.Vk >= 0);
            %% This is for debugging the changes of the Lyapunov Partial derivative
            obj.prev_dVk_dzi_List = obj.dVk_dzi_List;
            obj.dVk_dzi_List = cell(numel(voronoiCom.rxPartialDerivativeInfo),1);
            for i = 1: numel(voronoiCom.rxPartialDerivativeInfo)
                for t = 1: numel(voronoiCom.published_dC_neighbor)
                    [~, rxID] = voronoiCom.published_dC_neighbor(t).getIDs();
                    [txID, ~] = voronoiCom.rxPartialDerivativeInfo{i}.getIDs();
                    if(rxID == txID)
                        [~, ~, zk, Ck, dCkdzi_2x2] = voronoiCom.published_dC_neighbor(t).getValue();
                        [~, ~, zi, Ci, dCidzk_2x2] = voronoiCom.rxPartialDerivativeInfo{i}.getValue();
                        dVk_dzi = Lyapunov_Adjacent_PD_Computation(voronoiCom.GeneratorCoord_2d, voronoiCom.CVTCoord_2d, ...
                                                                    dCkdzi_2x2 ,obj.controlParam.Q2x2, obj.regionParam.BOUNDARIES_COEFF(:,1:2), obj.regionParam.BOUNDARIES_COEFF(:,3));
                        obj.dVk_dzi_List{i} = {rxID, zi, dVk_dzi};  
                        break;
                    end
                end
            end
            
            %% Aggregate the Lyapunov feedback from neighbor agents
            obj.Local_dVkdzi_List = Struct_Neighbor_CVT_PD_Extended.empty(numel(voronoiCom.rxPartialDerivativeInfo), 0);
            dV_Accum_Adjacent_Term = zeros(2,1);
            for i = 1: numel(voronoiCom.rxPartialDerivativeInfo)
                [~, ~, zi, Ci, dCidzk_2x2] = voronoiCom.rxPartialDerivativeInfo{i}.getValue();
                [tmp_dV_dAdj] = Lyapunov_Adjacent_PD_Computation(zi, Ci, dCidzk_2x2 ,obj.controlParam.Q2x2, obj.regionParam.BOUNDARIES_COEFF(:,1:2), obj.regionParam.BOUNDARIES_COEFF(:,3));
                dV_Accum_Adjacent_Term = dV_Accum_Adjacent_Term + tmp_dV_dAdj;    
                obj.Local_dVkdzi_List(i) = Struct_Neighbor_CVT_PD_Extended(voronoiCom.rxPartialDerivativeInfo{i}, tmp_dV_dAdj);
            end
            dV_dzk_total =  obj.dVkdzk + dV_Accum_Adjacent_Term;
            
            %% Adjustable variable --> Will move later to constant
            sigmoid_func = @(x,eps) x / (abs(x) + eps);              
            %% Compute the control policy
            wOut = obj.controlParam.W_ORBIT + obj.controlParam.P * obj.controlParam.W_ORBIT * sigmoid_func(dV_dzk_total' * [cos(curPose(3)) ;sin(curPose(3))], obj.controlParam.EPS_SIGMOID); 
            %wOut = obj.w;
            %% Logging out
            Vk = obj.Vk;
        end
    end
end

