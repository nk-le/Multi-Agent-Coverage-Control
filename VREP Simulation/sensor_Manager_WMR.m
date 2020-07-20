classdef sensor_Manager_WMR < handle
    %SENSORMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Handles
        bodyHandle = 0;
        positionHandle = 0;
        orientationHandle = 0;
        linearVelocityHandle = 0;
        angleVelocityHandle = 0;
        checkInit = false;
        
        % Virtual Mass Position
        VMHandle = 0;
        vmX = 0;
        vmY = 0;
        dToTarget = 0;
        
        % Translational and Angular Velocity
        v = 0;
        vx = 0;
        vy = 0;
        vz = 0;
        wAlpha = 0;
        wBeta = 0;
        wGamma = 0;  
        w
        
        % Euler Orientation
        alpha = 0;
        beta = 0;
        gamma = 0;
        theta = 0;
        
        % Cartesian Position
        px = 0;
        py = 0;
        pz = 0;
    end
    
    methods
        % HIGH LEVEL FUNCTION ============================================
        % Init function, the paramter "body" is the name of object in
        % CoppeliaSim. This object handle will be used to derive
        % information of position, velocity. In real life scenario,
        % measurements can be made through computer vision, onboard
        % sensors. This function will be called only once for the
        % initialisation
        function obj = sensor_Manager_WMR(body)
            global sim; global clientID;
            [checkBodyHandle, obj.bodyHandle] = sim.simxGetObjectHandle(clientID, body, sim.simx_opmode_blocking);
            [checkPosHandle, obj.positionHandle]= sim.simxGetObjectPosition(clientID,obj.bodyHandle, -1, sim.simx_opmode_streaming);
            [checkOrientationHandle, obj.orientationHandle] = sim.simxGetObjectOrientation(clientID, obj.bodyHandle, -1 , sim.simx_opmode_streaming);
            [checkVelocityHandle, obj.linearVelocityHandle, obj.angleVelocityHandle] = sim.simxGetObjectVelocity(clientID, obj.bodyHandle, sim.simx_opmode_streaming);
           
            if(~checkBodyHandle)
                obj.checkInit = true;
                disp("Sensor Manager is initialized");
            else
                disp("Error in Initialisation of Sensor Manager");
            end
        end
        
        % Begin -> start position
        function obj = begin(obj, startPose)
            global sim; global clientID;
            sim.simxSetObjectPosition(clientID, obj.bodyHandle, -1, [startPose(1), startPose(2), startPose(3)], sim.simx_opmode_blocking); 
            sim.simxSetObjectPosition(clientID, obj.VMHandle, -1, [startPose(1), startPose(2), startPose(3)], sim.simx_opmode_blocking);         
        end    
        
        % Get Handle of Virtual Mass and display it at the position of the
        % agent at the beginning. This function will be called only once at the
        % initialisation.
        function obj = updateVMHandle(obj,name)
            global sim; global clientID;
            [returnCode,obj.VMHandle]= sim.simxGetObjectHandle(clientID, name, sim.simx_opmode_blocking);
            obj.getPosition();
            sim.simxSetObjectPosition(clientID, obj.VMHandle, -1, [obj.vmX, obj.vmY, 0.002], sim.simx_opmode_oneshot); 
        end
        
         
        % Update all parameter and overwrite in the object handler
        function obj = update(obj)
            obj.getOrientation();
            obj.getPosition();
            obj.getVelocity();
        end
        
        % Update and draw Virtual Mass during operation
        function [vmX, vmY] = updateVM(obj,vConst,w0)
            global sim; global clientID;
            obj.vmX = obj.px - vConst/w0 * sin(obj.theta);
            obj.vmY = obj.py + vConst/w0 * cos(obj.theta);
            vmX = obj.vmX;
            vmY = obj.vmY;
            sim.simxSetObjectPosition(clientID, obj.VMHandle, -1, [obj.vmX, obj.vmY, 0.002], sim.simx_opmode_oneshot); 
        end
        
        % PRIVATE FUNCTION ===============================================
        % Update actual position of an agent
        function obj = getPosition(obj) 
            global sim; global clientID;
            [~, obj.positionHandle]= sim.simxGetObjectPosition(clientID,obj.bodyHandle,-1,sim.simx_opmode_buffer);
            obj.px = obj.positionHandle(1);
            obj.py = obj.positionHandle(2);
            obj.pz = obj.positionHandle(3);
        end
        
        % Update actual heading angle of an agent. The coordinate in
        % CoppeliaSim defined the gamma angle (theta in theory) 0° is positive y axis (vector [0 1 0]),
        % therefore theta = gamma - pi/2
        function obj = getOrientation(obj) 
            global sim; global clientID;
            [~, obj.orientationHandle] = sim.simxGetObjectOrientation(clientID, obj.bodyHandle, -1 , sim.simx_opmode_buffer);
            obj.alpha = obj.orientationHandle(1);
            obj.beta = obj.orientationHandle(2);
            obj.gamma = obj.orientationHandle(3);
            obj.theta = obj.gamma - pi/2;
        end  
        
        % Update actual translational and angular velocity of object in
        % each direction. From these results, we can calculate the heading velocity
        % v 
        function [v,w] = getVelocity(obj)
            global sim; global clientID;
            [~, obj.linearVelocityHandle, obj.angleVelocityHandle] = sim.simxGetObjectVelocity(clientID, obj.bodyHandle, sim.simx_opmode_buffer);
            obj.vx = obj.linearVelocityHandle(1);
            obj.vy = obj.linearVelocityHandle(2);
            obj.vz = obj.linearVelocityHandle(3);
            obj.v = (obj.vx^2 + obj.vy^2)^0.5;
            v = obj.v;

            obj.wAlpha = obj.angleVelocityHandle(1);
            obj.wBeta = obj.angleVelocityHandle(2);
            obj.wGamma = obj.angleVelocityHandle(3);
            obj.w = obj.wGamma;
        end
             
        % Use constant speed and predefined w0 to calculate virtual mass.
        % Controller must ensure that linear velocity v is approached
        % precisely
        function [vmX, vmY] = getVirtualMass(obj,v,w0)
            obj.vmX = obj.px - v/w0 * sin(obj.theta);
            obj.vmY = obj.py + v/w0 * cos(obj.theta);
            vmX = obj.vmX;
            vmY = obj.vmY;
        end
   end
end