% Abstract Controller for System Design
% Input: Error of Position (Reference and feedback) of Bot
% Output: Angular Velocity of Left and Right Wheel

classdef Class_Simple_Controller < handle
    properties
        agent % Carrier of agent 
        
        % Parameter
        gamma = 0;
        w0 = 0;
        vConst = 0;
        filter = 0;
        
        Kx = 0.03;
        Ky = 0.03;
        
        distanceCheck = 0;
        
        % Data
        virtualMassX = 0;
        virtualMassY = 0;
        oldTargetX = 0;
        oldTargetY = 0;
        targetX = 0;
        targetY = 0;
        ErrorX = 0;
        ErrorY = 0;
        Theta = 0;  
        posX = 0;
        posY = 0;
        distance = 0;
        L = 0.1;
        phi = 0;
        dVM = 0;
       
        state = 0;% state == 1 -> stabilizing ; state = 2 -> orbiting
        flag = 0;
        dVi_dz = 0;
        
        % Output
        boundaries;
        insideBound = true;
        onBound = false;
        output = [];
            
    end
        
    methods
        % Init Controller
        function obj = Class_Simple_Controller(gamma, w0, vConst, boundaries, bot)
            obj.agent = bot; % Now controller will carry agent Handler
            obj.gamma = gamma;
            obj.w0 = w0;
            obj.vConst = vConst;
            obj.boundaries = boundaries;
            obj.onBound = 0;
            obj.insideBound = 1; 
        end
        
        function obj = updateTarget(obj, targetX, targetY)
            obj.oldTargetX = obj.targetX;
            obj.oldTargetY = obj.targetY;
            obj.targetX = targetX;
            obj.targetY = targetY;
        end
        
        function obj = update_dVi_dz(obj, cur_dVi_dz)
            obj.dVi_dz = cur_dVi_dz;
        end  
        
        function obj = updateState(obj)
            % Update Current state
            obj.posX = obj.agent.posX;
            obj.posY = obj.agent.posY;
            obj.virtualMassX = obj.agent.virtualMassX;
            obj.virtualMassY = obj.agent.virtualMassY;
            obj.Theta = obj.agent.theta;
            obj.ErrorX = obj.virtualMassX - obj.targetX;
            obj.ErrorY = obj.virtualMassY - obj.targetY;  
            obj.distance  = (obj.ErrorX ^ 2 + obj.ErrorY ^ 2) ^ (0.5);
            obj.L = obj.agent.bodyWidth;         
            cosPhi = (obj.ErrorX * cos(obj.agent.theta) + obj.ErrorY * sin(obj.agent.theta))/((obj.ErrorX ^ 2 + obj.ErrorY ^ 2) ^ (0.5));
            obj.phi = acos(cosPhi);
            
        end
        
        function obj = checkBound(obj)
            xv = obj.boundaries(1,:);
            yv = obj.boundaries(2,:);
            [obj.insideBound, obj.onBound] =  inpolygon(obj.virtualMassX, obj.virtualMassY,xv,yv);
        end
        
        function [v,w] = stabilizingControl(obj)
            % Udpdate Current State
            %obj.updateState();
            
            % Determine Output
            v = -(obj.Kx *  obj.ErrorX * cos(obj.Theta) / obj.L) - (obj.Ky * obj.ErrorY * sin(obj.Theta) / obj.L);
            w = (obj.Kx *  obj.ErrorX * sin(obj.Theta) / (obj.L * obj.L)) - (obj.Ky * obj.ErrorY * cos(obj.Theta) / (obj.L * obj.L));
            
            if v >= obj.agent.vMax
                obj.agent.translationVelocity = obj.agent.vMax;
            elseif v <= -obj.agent.vMax
                obj.agent.translationVelocity = -obj.agent.vMax;
            else
                obj.agent.translationVelocity = v;
            end
            if w >= obj.agent.wMax
                obj.agent.angleVelocity = obj.agent.wMax;
            elseif w <= -obj.agent.wMax
                obj.agent.angleVelocity = -obj.agent.wMax;
            else
                obj.agent.angleVelocity = w;
            end
            
            v = obj.agent.translationVelocity;
            w = obj.agent.angleVelocity;
        end

        function [v,w] = orbitingControl(obj)
            % Update State
            %obj.updateState();
            
            % Determine Output
            obj.checkBound();
            v = obj.vConst;
            % Find vertexes to check next point onbound or not
            [p1,p2, outside] = findVertexes(obj.virtualMassX, obj.virtualMassY, obj.boundaries);
            obj.insideBound = 1;
            outside = 0;
            if((obj.insideBound == 1) && (outside == 0))  %If object is inside boundaries
                w = obj.w0 + obj.gamma * obj.w0 * obj.vConst *(obj.ErrorX * cos(obj.Theta) + obj.ErrorY * sin(obj.Theta)); 
            else    
                % Calculate Sigma
                % Get Vertexes First, find normal vector -> find vector in
                % other direction with centroidai
                disp("OUT BOUND ALERT");
                plot(p1(1), p1(2), "-x");
                plot(p2(1), p2(2), "-x");
                
                wNormal = obj.w0 + obj.gamma * obj.w0 * obj.vConst * (obj.ErrorX * cos(obj.Theta) + obj.ErrorY * sin(obj.Theta)); 
                wModified = obj.w0;
                thetaPredict = obj.Theta + 0.02 * wNormal;
                obj.dVM = (v * (1 - wNormal) / obj.w0)*[cos(thetaPredict); sin(thetaPredict) ; 0];
                obj.dVM = obj.dVM / norm(obj.dVM);
                
                %posPredict = [obj.posX + 0.02 * obj.dVM; obj.posY + 0.02 * obj.dVM];
                %assert(result, "No Vertexes found even on bound"); % Error if no vertexes found               
                pointingVector = p2 - p1;
                normalVector = [-pointingVector(1,2); pointingVector(1,1) ; 0];
                
                virtualMassToCentroidVector = [obj.targetX - obj.virtualMassX; obj.targetY - obj.virtualMassY ; 0];
                virtualMassToCentroidVector = virtualMassToCentroidVector / norm(virtualMassToCentroidVector);
                
                angle = atan2(norm(cross(normalVector,virtualMassToCentroidVector)), dot(normalVector,virtualMassToCentroidVector));
               
                % Get Sigma Vector
                if (cos(angle) > 0) % Same side with posToCentroid
                    sigmaVector = -normalVector;
                else
                    sigmaVector = normalVector;
                end
                sigmaVector = sigmaVector / norm(sigmaVector);
                
                plot([p1(1) p2(1)], [p1(2), p2(2)],'g');
                plot([obj.virtualMassX  obj.targetX],[obj.virtualMassY obj.targetY],'r'); % Line between centroid and virtual Mass
                plot([obj.virtualMassX obj.virtualMassX + sigmaVector(1)],[obj.virtualMassY obj.virtualMassY + sigmaVector(2)],'b');
                plot([obj.virtualMassX obj.virtualMassX + obj.dVM(1)],[obj.virtualMassY obj.virtualMassY + obj.dVM(2)],'y');

                %moveAngle = atan2(norm(cross(sigmaVector,obj.dVM)), dot(sigmaVector,obj.dVM));
                moveAngle = atan2(norm(cross(sigmaVector,obj.dVM)), dot(sigmaVector,obj.dVM));
                if(moveAngle >= 3.14 / 2 && moveAngle <= 3.14 * 3 / 2)
                    w = wNormal;
                else
                    w = wModified;
                end
            end
           
            if v >= obj.agent.vMax
                obj.agent.translationVelocity = obj.agent.vMax;
            elseif v <= -obj.agent.vMax
                obj.agent.translationVelocity = -obj.agent.vMax;
            else
                obj.agent.translationVelocity = v;
            end
            %{
            if w >= obj.agent.wMax
                obj.agent.angleVelocity = obj.agent.wMax;
            elseif w <= -obj.agent.wMax
                obj.agent.angleVelocity = -obj.agent.wMax;
            else
                obj.agent.angleVelocity = w;
            end
            %}
            obj.agent.angleVelocity = w;
            
            v = obj.agent.translationVelocity;
            w = obj.agent.angleVelocity;
        end   
        
        function [v,w] = orbitingControlWithConstraint(obj,k1,k2)
            % Update State
            obj.updateState();
            
            % Determine Output
            v = obj.vConst;
            obj.filter = obj.calculateFilter(k1,k2);
            
            g =  obj.filter * sign(obj.vConst) * sign(obj.w0) / ((obj.ErrorX ^ 2 + obj.ErrorY ^ 2)^(1/2)) ;

            w = obj.w0 + g * (obj.ErrorX * cos(obj.Theta) + obj.ErrorY * sin(obj.Theta)); 
           
            % Saturation
            if v >= obj.agent.vMax
                obj.agent.translationVelocity = obj.agent.vMax;
            elseif v <= -obj.agent.vMax
                obj.agent.translationVelocity = -obj.agent.vMax;
            else
                obj.agent.translationVelocity = v;
            end
            if w >= obj.agent.wMax
                obj.agent.angleVelocity =  obj.agent.wMax;
            elseif w <= -obj.agent.wMax
                obj.agent.angleVelocity = -obj.agent.wMax;
            else
                obj.agent.angleVelocity = w;
            end
            
            v = obj.agent.translationVelocity;
            w = obj.agent.angleVelocity;
        end   
        
        function filterGain = calculateFilter(obj,k1, k2)
            if(obj.w0 > 0)
                if(obj.phi <= 3.14 / 2) && (obj.phi >= - 3.14 / 2)
                     filterGain = k1;           
                else
                     filterGain = k2;
                end
            else
                if(obj.phi <= 3.14 / 2) && (obj.phi >= - 3.14 / 2)
                     filterGain = k1;           
                else
                     filterGain = k2;
                end
            end
        end
          
        function [v,w,M,N,g] = BLF_Controller_Quadratic(obj,k1,k2,A,b,tol)
            global dt;
           % Update State
            obj.updateState();
            
            % Determine Output
            v = obj.vConst;         
            x = obj.virtualMassX;
            y = obj.virtualMassY;
            rx = obj.ErrorX;
            ry = obj.ErrorY;
            cT = cos(obj.Theta);
            sT = sin(obj.Theta);
            
            M = 0;
            N = 0;
            condition = 0;
            for i = 1:numel(b)
               d = - A(i,1) * x - A(i,2) * y + b(i) - tol;
               if(d < 0) % Always bigger than 0
                   %close(aviobj);
                   while(1) 
                        disp("Error");
                   end
               end
               subNumM1 = (rx*cT + ry*sT)^2 / d;
               subNumM2 = -1/2 * (rx^2 + ry^2)*(-A(i,1)*cT + -A(i,2)*sT) * (rx*cT + ry*sT) / d^2;
               M = M + (subNumM1 + subNumM2);
               
               dCx = (obj.targetX - obj.oldTargetX)/dt;
               dCy = (obj.targetY - obj.oldTargetY)/dt;
               N = N - (rx*dCx + ry*dCy)/d;
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
               if(M >= 0) 
                   condition = 0;
               else
                   condition = 0; % Unknown
               end
            else 
               condition = 0;
            end
               
            if(condition)
               obj.filter = obj.calculateFilter(k1,k2);
               g =  obj.filter * sign(obj.vConst) * sign(obj.w0) / ((obj.ErrorX ^ 2 + obj.ErrorY ^ 2)^(1/2)) ;   
            else
               g = 0;
            end
 
            w = obj.w0 + g * (obj.ErrorX * cos(obj.Theta) + obj.ErrorY * sin(obj.Theta));
            
            if w >= obj.agent.wMax
                obj.agent.angleVelocity =  obj.agent.wMax;
            elseif w <= -obj.agent.wMax
                obj.agent.angleVelocity = -obj.agent.wMax;
            else
                obj.agent.angleVelocity = w;
            end
            
            obj.agent.translationVelocity = v;
            obj.agent.angleVelocity = w;          
        end
        
        function [v,w] = BLF_Controller_Log(obj,k1,k2,A,b,tol)
            global dt;
            % Update State
            obj.updateState();
            
            % Determine Output
             % Determine Output
            v = obj.vConst;         
            x = obj.virtualMassX;
            y = obj.virtualMassY;
            Cx = obj.targetX;
            Cy = obj.targetY;
            rx = obj.ErrorX;
            ry = obj.ErrorY;
            cT = cos(obj.Theta);
            sT = sin(obj.Theta);
            
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
               
               dCx = (obj.targetX - obj.oldTargetX)/dt;
               dCy = (obj.targetY - obj.oldTargetY)/dt;
              
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
               
            if(condition)
               obj.filter = obj.calculateFilter(k1,k2);
               g =  obj.filter * sign(obj.vConst) * sign(obj.w0) / ((obj.ErrorX ^ 2 + obj.ErrorY ^ 2)^(1/2)) ;   
            else
               g = 0;
            end
 
            w = obj.w0 + g * (obj.ErrorX * cos(obj.Theta) + obj.ErrorY * sin(obj.Theta));
            
            if w >= obj.agent.wMax
                obj.agent.angleVelocity =  obj.agent.wMax;
            elseif w <= -obj.agent.wMax
                obj.agent.angleVelocity = -obj.agent.wMax;
            else
                obj.agent.angleVelocity = w;
            end
            
            obj.agent.translationVelocity = v;
            obj.agent.angleVelocity = w;   
        end
       
    end
end

function [p1, p2, flag] = findVertexes(posX, posY, boundaries)
    distance = zeros(1, numel(boundaries(1,:)) - 1);
    for i = 1:numel(boundaries(1,:))-1
        p1(1) = boundaries(1,i);
        p1(2) = boundaries(2,i);
        p2(1) = boundaries(1, i + 1);
        p2(2) = boundaries(2, i + 1); 

        p1Tod =  [posX, posY,0] - [p1(1), p1(2),0];
        p1Top2 = [p2(1),p2(2),0] - [p1(1), p1(2), 0];   
        
        angle = atan2(norm(cross(p1Tod,p1Top2)), dot(p1Tod,p1Top2));
        distance(i) = norm(p1Tod) * sin(angle); % Find distance 

    end  
    [value, minIndex] = min(distance(1,:));
    p1(1) = boundaries(1,minIndex);
    p1(2) = boundaries(2,minIndex);
    p2(1) = boundaries(1,minIndex + 1);
    p2(2) = boundaries(2,minIndex + 1);
    if(value < 3) % Stop before going outbound
        flag = 1;
    else 
        flag = 0;
    end
end






