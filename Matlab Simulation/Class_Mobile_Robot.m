% Modelling kinematic of agent
classdef Class_Mobile_Robot < handle
   properties
   % Constant Configuration
       offsetBodyAxes = 0.00;
       dt = 0.02;
       
   % Input
       tLeftWheel = 0; % Left Torque 
       tRightWheel = 0; % Right Torque
       wheelRadius = 0.03;
       bodyWidth = 0.1;
       
       wheelLeftMax = 100 * 2 * pi; % radian per sec
       wheelRightMax = 100 * 2 * pi; % rps
 
   % Output
       % Position & Orientation
       posX 
       posY
       theta
       pose = []
       % Translation and Angle Velocity
       translationVelocity
       angleVelocity
       vMax
       wMax
       
       % Polar Coordinate & Qingchen Part
       r 
       virtualMassX 
       virtualMassY
       w0 = 0;
       
   end
   
   methods
       % Initial lize Robots with their own characteristics
       function obj = Class_Mobile_Robot(pX, pY, theta,dt)
            % Setting
            obj.vMax = (obj.wheelRadius * (obj.wheelLeftMax + obj.wheelRightMax))/2; % m/s
            obj.wMax = (obj.wheelRadius * (obj.wheelLeftMax + obj.wheelRightMax))/2 / obj.bodyWidth; % rad/s (Approx 30 rps)
            % Left - Right Wheel Angle Velocity
            obj.dt = dt;
            obj.angleVelocity = 0;
            obj.translationVelocity = 0;
            
            % Initial Position & Orientation
            obj.posX = pX;
            obj.posY = pY;
            obj.theta = theta;  
            obj.pose = [obj.posX; obj.posY; obj.theta];
       end
       
       % Calculate velocity and angular velocity of robots depend on
       % angular velocity of each wheel
       function [v,w] = FWK(obj,wL,wR) % Forward Kinematic of Mobile Robot
            v = (wL+wR)* obj.wheelRadius / 2; % v = (wL + wR)*R /2 
            w = (wR-wL)/ obj.bodyWidth * obj.wheelRadius; % w = (wR-wL) * R / width
       end
       
       % Calcute desired angular velocity of left and right wheel to
       % perform desired translation and angle velocity
       function [wL,wR] = BWK(obj,v,w) % Backward Kinematic
            wL = (v - w*obj.bodyWidth/2)/obj.wheelRadius;
            wR = (v + w*obj.bodyWidth/2)/obj.wheelRadius;
       end
       
       function [r, theta] = getPolar(obj)
            r = (obj.posX ^ 2 + obj.posY ^ 2)^1/2;
            theta = obj.theta;
       end
       
       % Qingchen Part
       function obj = setParameterVirtualMass(obj,w0)
            obj.w0 = w0;
       end
       
       function obj = updateVirtualMass(obj)
            %[r, theta] = obj.getPolar();
            obj.virtualMassX = obj.posX - obj.translationVelocity / obj.w0 * sin(obj.theta);
            obj.virtualMassY = obj.posY + obj.translationVelocity / obj.w0 * cos(obj.theta);
       end
       
       function [vmX, vmY] = getNextVirtualMass(obj)
            %[r, theta] = obj.getPolar();
            obj.virtualMassX = obj.posX - obj.translationVelocity / obj.w0 * sin(obj.theta);
            obj.virtualMassY = obj.posY + obj.translationVelocity / obj.w0 * cos(obj.theta);
       end
       
       % Procedure 
       % 1) Algorithms do something to calculate desired position -> desired
       % LR Wheel Rotation -> wL, wR
       % ===>   [wL, wR] = controller(reference and feedback)
       % 2) Controller calculate and put desired wheel rotation into bot ->
       % output: translation and angular velocity of body
       % ===>   myBot.updateVelocity(wL, wR)
       % 3) myBot perform movement through his dynamic by calulated
       % velocities -> update Position
       % ===>   myBot.move()
       % 4) Visualization by feeding myBot.pose into Visualizer
       
       function obj = updateVelocity(obj, wL,wR)
           [obj.translationVelocity, obj.angleVelocity] = FWK(obj, wL, wR);
       end
       
       function obj = move(obj) % Robot Dynamic
            obj.posX = obj.posX + obj.dt * (obj.translationVelocity * cos(obj.theta) - obj.offsetBodyAxes * obj.angleVelocity * sin(obj.theta));
            obj.posY = obj.posY + obj.dt * (obj.translationVelocity * sin(obj.theta) + obj.offsetBodyAxes * obj.angleVelocity * cos(obj.theta));
            obj.theta = obj.theta + obj.dt * obj.angleVelocity;
            obj.virtualMassX = obj.posX - obj.translationVelocity / obj.w0 * sin(obj.theta); % wo is fixed orbiting angular velocity
            obj.virtualMassY = obj.posY + obj.translationVelocity / obj.w0 * cos(obj.theta);
            
            obj.pose = [obj.posX; obj.posY; obj.theta];
       end
   end
end