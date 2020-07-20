classdef logging_Manager < handle
    %LOGGING_MANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numberOfBot
        sensorManager
        controlManager
        
        pose = [];
        poseVM = [];
        vel = [];
        wheelRPM = [];
        Error = [];
    end
    
    methods
        function obj = logging_Manager(sm,cm)
            obj.sensorManager = sm;
            obj.controlManager = cm;
        end
        
        function obj = log(obj)
            %obj.pose = [obj.pose, [obj.sensorManager.px; obj.sensorManager.py; obj.sensorManager.theta]];
            %obj.poseVM = [obj.poseVM, [obj.sensorManager.vmX ; obj.sensorManager.vmY]];
            obj.vel = [obj.vel, [obj.sensorManager.v; obj.sensorManager.w]];
            %obj.wheelRPM = [obj.wheelRPM, [obj.controlManager.wL; obj.controlManager.wR]];
            obj.Error = [obj.Error, obj.controlManager.Error];
        end  
        
        function obj = plotPose(obj)
            % Plotting
            t = 1:1:size(obj.pose,2);      
            amountPlot = 3;
            
            figure
            subplot(amountPlot,1,1)
            grid on; hold on;
            plot(t, obj.pose(3,:));
            xlabel("Time in Second");
            ylabel("Angle in Radian");

            subplot(amountPlot,1,2)
            grid on; hold on;
            plot(t, obj.poseVM(1,:));
            xlabel("Time in Second");
            ylabel("VMX Position");

            subplot(amountPlot,1,3)
            grid on; hold on;
            plot(t, obj.poseVM(2,:));
            xlabel("Time in Second");
            ylabel("VMY Position");
        end
        
        function obj = plotVelocity(obj)
            t = 1:1:size(obj.vel,2);
            
            amountPlot = 3;
            figure
            
            subplot(amountPlot,1,1)
            grid on; hold on;
            plot(t, obj.vel(1,:));
            ylim([-4, 4]);
            xlabel("Time in Second");
            ylabel("Linear Velocity");

            subplot(amountPlot,1,2)
            grid on; hold on;
            plot(t, obj.vel(2,:));
            xlabel("Time in Second");
            ylabel("Angle Velocity");
            
            subplot(amountPlot,1,3)
            grid on; hold on;
            plot(t, obj.Error(1,:));
            xlabel("Time in Second");
            ylabel("Angle Velocity");
        end 
    end
end

