classdef FixedWingBase < handle & AgentBase
    %FixedWingBase Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        AgentPose_3d = zeros(3,1);
        VMCoord_2d = zeros(2,1);
        
        v = 0.0
        w = 0.0
        controlParam
        
        prev_AgentPose_3d
        prev_VMCoord_2d
    end
    
    methods
        function obj = FixedWingBase(controlParam, startPose)
            obj.controlParam = controlParam;
            obj.AgentPose_3d = startPose;
        end

        function obj = move(obj, v, w) 
            obj.v = v;
            obj.w = w;
            % Unicycle Dynamic
            obj.prev_AgentPose_3d = obj.AgentPose_3d;
            obj.AgentPose_3d(1) = obj.AgentPose_3d(1) + obj.dt * (obj.v * cos(obj.AgentPose_3d(3)));
            obj.AgentPose_3d(2) = obj.AgentPose_3d(2) + obj.dt * (obj.v * sin(obj.AgentPose_3d(3)));
            obj.AgentPose_3d(3) = obj.AgentPose_3d(3) + obj.dt * obj.w;
            %% Update the virtual mass
            obj.prev_VMCoord_2d = obj.VMCoord_2d;
            obj.VMCoord_2d(1) = obj.AgentPose_3d(1) - (obj.v/obj.controlParam.W_ORBIT) * sin(obj.AgentPose_3d(3)); 
            obj.VMCoord_2d(2) = obj.AgentPose_3d(2) + (obj.v/obj.controlParam.W_ORBIT) * cos(obj.AgentPose_3d(3)); 
        end
    end
end

