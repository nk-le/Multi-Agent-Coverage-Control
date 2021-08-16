classdef DataLogger < handle
    %CLASS_LOGGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nAgent
        maxCnt 
        curCnt
        PoseAgent
        PoseVM 
        ControlOutput 
        CVT
        V_BLF 
        V_BLF_Den
        bndVertexes
    end
    
    methods
        function obj = DataLogger(amountAgent, maxIter)
            obj.nAgent = amountAgent;
            obj.maxCnt = maxIter;
            obj.curCnt = 0;
            obj.PoseAgent = zeros(amountAgent, 3, maxIter);
            obj.PoseVM = zeros(amountAgent, 2, maxIter);
            obj.ControlOutput = zeros(amountAgent, maxIter);
            obj.CVT = zeros(amountAgent, 2, maxIter);
            obj.V_BLF = zeros(amountAgent, maxIter);
            obj.V_BLF_Den = zeros(amountAgent, maxIter);
        end
        
        function updateBot(obj, curBot, newPoseAgent, newPoseVM, newWk, newCVT)
            if(obj.curCnt <= obj.maxCnt)
                obj.PoseAgent(curBot, :,obj.curCnt) = newPoseAgent(:,:,:);
                obj.PoseVM(curBot, :,obj.curCnt)           = newPoseVM(:,:);
                obj.ControlOutput(curBot, obj.curCnt)    = newWk(:);
                obj.CVT(curBot,:, obj.curCnt)              = newCVT(:,:);
            else 
                disp('Max CNT already, logging stopped!');
            end
        end
        
        function updateBLF(obj, newV, newVden)
            obj.curCnt = obj.curCnt + 1;
            if(obj.curCnt <= obj.maxCnt)
                obj.V_BLF(:, obj.curCnt)            = newV(:);
                obj.V_BLF_Den(:, obj.curCnt)        = newVden(:);
            else 
                disp('Max CNT already, logging stopped!');
            end
        end
        
        function log(obj, newPoseAgent, newPoseVM, newCVT, newW, newV)
            obj.curCnt = obj.curCnt + 1;
            if(obj.curCnt <= obj.maxCnt)
                obj.V_BLF(:, obj.curCnt)            = newV(:);
                obj.PoseAgent(:, :,obj.curCnt)      = newPoseAgent(:,:);
                obj.PoseVM(:, :,obj.curCnt)    = newPoseVM(:,:);
                obj.ControlOutput(:, obj.curCnt)    = newW(:);
                obj.CVT(:,:, obj.curCnt)       = newCVT(:,:);
            else 
                disp('Max CNT already, logging stopped!');
            end
        end
        
        function logCentralizedController(obj, centralController)
            obj.curCnt = obj.curCnt + 1;
            if(obj.curCnt <= obj.maxCnt)
                obj.PoseAgent(:, :,obj.curCnt) = centralController.CurPose(:,:);
                obj.PoseVM(:, :,obj.curCnt) = centralController.CurPoseVM(:,:);
                obj.CVT(:,:, obj.curCnt)  = centralController.CurPoseCVT(:,:);
                obj.ControlOutput(:, obj.curCnt) = centralController.CurAngularVel(:);
                obj.V_BLF(:, obj.curCnt) = centralController.LyapunovCost(:);
            end
        end 
    end
end

