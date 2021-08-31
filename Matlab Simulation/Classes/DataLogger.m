classdef DataLogger < handle
    %CLASS_LOGGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CONST_PARAM
        startPose
        vConstList
        wOrbitList
        
        maxCnt 
        curCnt
        
        PoseAgent
        PoseVM 
        ControlOutput 
        CVT
        V_BLF
    end
    
    methods
        function obj = DataLogger(CONST_PARAM, startPose, vList, wList)
            obj.CONST_PARAM = CONST_PARAM;
            obj.vConstList = vList;
            obj.wOrbitList = wList;
            obj.startPose = startPose;
            obj.curCnt = 0;
            
            obj.maxCnt = CONST_PARAM.MAX_ITER + 10;
            obj.PoseAgent = zeros(CONST_PARAM.N_AGENT, 3, obj.maxCnt);
            obj.PoseVM = zeros(CONST_PARAM.N_AGENT, 2, obj.maxCnt);
            obj.ControlOutput = zeros(CONST_PARAM.N_AGENT, obj.maxCnt);
            obj.CVT = zeros(CONST_PARAM.N_AGENT, 2, obj.maxCnt);
            obj.V_BLF = zeros(CONST_PARAM.N_AGENT, obj.maxCnt);
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
        
        function logDecentralized(obj, CurPose, CurPoseVM, CurPoseCVT, LyapunovCost)
            obj.curCnt = obj.curCnt + 1;
            if(obj.curCnt <= obj.maxCnt)
                obj.PoseAgent(:, :,obj.curCnt) = CurPose(:,:);
                obj.PoseVM(:, :,obj.curCnt) = CurPoseVM(:,:);
                obj.CVT(:,:, obj.curCnt)  = CurPoseCVT(:,:);
                obj.V_BLF(:, obj.curCnt) = LyapunovCost(:);
            end
        end 
        
        
    end
end

