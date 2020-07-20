classdef control_Manager_Lumi < handle
    %CONTROLMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Handle
        leftMotor
        rightMotor
        checkInit
        
        % Properties
        v
        vMax
        w
        wMax
        wL
        wR
        w0
        L = 0.0886;
        wheelRadius = 0.0250;
        
        currentState = zeros(3,1);
        setPoint = zeros(2,1);
        oldSetpoint = zeros(2,1);
        
        % Control Parameter
        % Stabilizing Control
        Kx = 0.02;
        Ky = 0.02;
        
        % Orbitting Control
        filter = 0;
        K1 = 0.02;
        K2 = 0.02;
        
        % Debug only
        Error
    end
    
    methods
        function obj = control_Manager_Lumi(leftMotor, rightMotor)
            global sim; global clientID;
            [checkLeftMotor, obj.leftMotor]= sim.simxGetObjectHandle(clientID, leftMotor, sim.simx_opmode_blocking);
            [checkRightMotor, obj.rightMotor]= sim.simxGetObjectHandle(clientID, rightMotor, sim.simx_opmode_blocking);
            [checkRightSpeed]=sim.simxSetJointTargetVelocity(clientID, obj.rightMotor, 0, sim.simx_opmode_blocking);
            [checkLeftSpeed]=sim.simxSetJointTargetVelocity(clientID, obj.leftMotor, 0, sim.simx_opmode_blocking);
            
            if(~checkLeftMotor && ~checkRightMotor && ~checkRightSpeed && ~checkLeftSpeed)
                obj.checkInit = true;
                disp("Control Manager is initialized");
            else
                disp("Error in Initialisation of Control Manager");
            end
        end
        
        % Control Method
        function obj = stabilizingControl(obj, curX, curY, theta, spX, spY)
            eX = curX - spX;
            eY = curY - spY;  
            % Determine Output
            obj.v = -(obj.Kx *  eX * cos(theta) / obj.L) - (obj.Ky * eY * sin(theta) / obj.L);
            obj.w = (obj.Kx *  eX * sin(theta) / (obj.L * obj.L)) - (obj.Ky * eY * cos(theta) / (obj.L * obj.L));
            
            if obj.v >= obj.vMax
                obj.v = obj.vMax;
            elseif obj.v <= -obj.vMax
                obj.v = -obj.vMax;
            else
                obj.v = obj.v;
            end
            
            if obj.w >= obj.wMax
                obj.w = obj.wMax;
            elseif obj.w <= -obj.wMax
                obj.w = -obj.wMax;
            else
                obj.w = obj.w;
            end
            
            obj.setSpeed(obj.v,obj.w); % Hardware Control
        end
        
        function [v,w] = orbitingControlWithConstraint(obj, vConst, w0, curX, curY, theta, spX, spY)
            % Update State
            eX = curX - spX;
            eY = curY - spY;
            
            % For Logging
            obj.Error = ((eX ^ 2 + eY ^ 2) ^ (0.5)); 
            
            obj.v = vConst;
            obj.w0 = w0;
            cosPhi = (eX * cos(theta) + eY * sin(theta))/((eX ^ 2 + eY ^ 2) ^ (0.5));
            phi = acos(cosPhi);
            
             % Determine Output
            obj.filter = obj.calculateFilter(phi);
            g =  obj.filter * sign(obj.v) * sign(obj.w0) / ((eX ^ 2 + eY ^ 2)^(1/2)) ;
            w = obj.w0 + g * (eX * cos(theta) + eY * sin(theta)); 
            
            
            if vConst >= obj.vMax
                obj.v = obj.vMax;
            elseif vConst <= -obj.vMax
                obj.v = -obj.vMax;
            else
                obj.v = vConst;
            end
            if w >= obj.wMax
                obj.w = obj.wMax;
            elseif w <= -obj.wMax
                obj.w = -obj.wMax;
            else
                obj.w = w;
            end
            
            v = obj.v;
            w = obj.w;
            obj.setSpeed(obj.v,obj.w); % Hardware Control
        end   
        
        function obj = update_target(obj, sp, poseVM)
            obj.currentState = poseVM;
            obj.oldSetpoint = obj.setPoint;
            obj.setPoint = sp;
            
        end
        function [v,w] = BLF_Controller_Log(obj,vConst,A,b,tol)
            global dt;
            % Determine Output
            v = vConst;         
            x = obj.currentState(1);
            y = obj.currentState(2);
            Cx = obj.setPoint(1);
            Cy = obj.setPoint(2);
            rx = x - Cx;
            ry = y - Cy;
            cT = cos(obj.currentState(3));
            sT = sin(obj.currentState(3));
            
            M = 0;
            N = 0;
            condition = 0;    
            d = zeros(1, numel(b));
            % Check feasibility
            for i = 1:numel(b)
               d(i) = b(i)- (A(i,1)*x + A(i,2)*y + tol);
               if((b(i)- (A(i,1)*x + A(i,2)*y)) < 0) % Always smaller than 0
                   %close(aviobj);
                   while(1) 
                        disp("Error");
                   end
               end
               
               dCx = (obj.setPoint(1) - obj.oldSetpoint(1))/dt;
               dCy = (obj.setPoint(2) - obj.oldSetpoint(2))/dt;
              
               M = M + 2 * log((b(i)-(A(i,1)*Cx + A(i,2)*Cy))/d(i)) * ...
                   (A(i,1)*cT + A(i,2)*sT)*(rx*cT + ry*sT) / d(i); 
               N = N + 2 * log((b(i)-(A(i,1)*Cx + A(i,2)*Cy))/d(i)) * ((-A(i,1)*dCx - A(i,2)*dCy))/(b(i)-(A(i,1)*Cx + A(i,2)*Cy));
              
            end
            
            if(N == 0) % Invariant
               if(M >= 0) 
                   condition = 1;
               else
                   condition = 0;
               end
            elseif (N < 0)
               if(M >= 0) 
                   condition = 1;
               else
                   condition = 0; % Unknown
               end
            elseif (N > 0)
               condition = 0;
            else 
               condition = 0;
            end
             
            % Calculate phi to choose filter
            cosPhi = (rx* cT + ry * sT)/((rx ^ 2 + ry ^ 2) ^ (0.5));
            phi = acos(cosPhi);
            
            if(condition)
               obj.filter = obj.calculateFilter(phi);
               g =  obj.filter * sign(v) * sign(obj.w0) / ((rx ^ 2 + ry ^ 2)^(1/2)) ;   
            else
               g = 0;
            end
 
            w = obj.w0 + g * (rx * cT + ry * sT);
            
            if w >= obj.wMax
                obj.w =  obj.wMax;
            elseif w <= -obj.wMax
                obj.w = -obj.wMax;
            else
                obj.w = w;
            end
            
            obj.v = v;
            obj.w = w;   
            obj.setSpeed(obj.v,obj.w); % Hardware Control
        end
        % PRIVATE FUNCTION ================================================
         % Core
        function obj = setMotor(obj, wL, wR)
            global sim; global clientID;
            obj.wL = wL;
            obj.wR = wR;
            sim.simxPauseCommunication(clientID,1);
            [returnCode]= sim.simxSetJointTargetVelocity(clientID, obj.rightMotor,wR, sim.simx_opmode_oneshot);
            [returnCode]= sim.simxSetJointTargetVelocity(clientID, obj.leftMotor,wL, sim.simx_opmode_oneshot);
            sim.simxPauseCommunication(clientID,0);
        end    
         
        function obj = setSpeed(obj, v, w)
            obj.v = v;
            obj.w = w;
            [obj.wL, obj.wR] = BWK(v,w);
            obj.setMotor(obj.wL, obj.wR);
        end
        
        function filterGain = calculateFilter(obj,phi)
            if(obj.w0 > 0)
                if(phi <= 3.14 / 2) && (phi >= - 3.14 / 2)
                     filterGain = obj.K1;           
                else
                     filterGain = obj.K2;
                end
            else
                if(phi <= 3.14 / 2) && (phi >= - 3.14 / 2)
                     filterGain = obj.K1;           
                else
                     filterGain = obj.K2;
                end
            end
        end
    end
end

% Kinematic and Help Function
function [wL,wR] = BWK(v,w) % Backward Kinematic
    L = 0.0886; % Parameter of Lumi Bot
    wheelRadius = 0.0250;
    wL = (v - w*L/2)/wheelRadius;
    wR = (v + w*L/2)/wheelRadius;
end


