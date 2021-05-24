%% Agent_Controller - distributed controller for unicycle agent
%

classdef Agent_Controller < handle
    %AGENT_CONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ID              % int
        curPose         % [x y theta]
        curVMPose       % [x y]
        curCVTPose      % [x y]
        
        regionCoeff     % [a1 a2 b] --> a1*x + a2*y - b <= 0
        
        %% Should be private
        vConst          % const float
        wOrbit          % const float
        
        w               % float: current angular velocity
        v               % float: current heading velocity
        lastSubV
        currentSubV
    end
    
    properties (Access = private)
        
    end
    
    methods
        %% Initalize class handler
        function obj = Agent_Controller()
            obj.v = 0;
            obj.w = 0;
        end
        
        %% One time configuration
        %   Assign a fix ID for each controller for communication broadcasting and easy debugging
        %   Assign the coefficient of the closed convex region: [coverageRegionCoeff] = [a1 a2 b] --> a1*x + a2*y - b <= 0
        function obj = begin(obj, botID, coverageRegionCoeff, initPose, v0, w0)
            obj.ID = botID;
            obj.regionCoeff = coverageRegionCoeff;
            obj.vConst = v0;
            obj.wOrbit = w0;
            
            % Update initial position
            obj.updateState(initPose);
        end
        
        %% Position feedback and internal state update
        function [newVMPose] = updateState(obj, newPose)
            % Update Current state
            obj.curPose = newPose;
            % Update virtual center, save internally
            [curVM] = obj.updateVirtualCenter();
            
            %% To be updated
%             obj.ErrorX = obj.virtualMassX - obj.targetX;
%             obj.ErrorY = obj.virtualMassY - obj.targetY;  
%             obj.distance  = (obj.ErrorX ^ 2 + obj.ErrorY ^ 2) ^ (0.5);
%             obj.L = obj.agent.bodyWidth;         
%             cosPhi = (obj.ErrorX * cos(obj.agent.theta) + obj.ErrorY * sin(obj.agent.theta))/((obj.ErrorX ^ 2 + obj.ErrorY ^ 2) ^ (0.5));
%             obj.phi = acos(cosPhi);   
            
            %% Return
            newVMPose = curVM;
        end
        
        %% Get the current virtual center according to the current pose 
        %  wOrbit is fixed orbiting angular velocity
        %  cVonst is fixed heading velocity
        function [poseVM] = updateVirtualCenter(obj)            
            obj.curVMPose(1) = obj.curPose(1) - (obj.vConst/obj.wOrbit) * sin(obj.curPose(3)); 
            obj.curVMPose(2) = obj.curPose(2) + (obj.vConst/obj.wOrbit) * cos(obj.curPose(3)); 
            poseVM = [obj.curVMPose];
        end
        
        %% Execute the control policy 
        % [@in]
        %      curCVTPose   : New Voronoi centroid
        % [@out]
        %      wOut         : desired control ouput   
        function [v, wOut] = executeControl(obj, newCVTPose)
            % Pseudo communication matrix that used to exchange information
            % between agents
            % global neighborInformation;
            global dVi_dzMat;
            
            % Update the new target
            obj.curCVTPose = newCVTPose;
            %obj.currentSubV = obj.computeCurrentV();
           
            % Determine Output
            v = obj.vConst;             
            cT = cos(obj.curPose(3));
            sT = sin(obj.curPose(3));
            
            dVj_di_Matrix = dVi_dzMat(:,obj.ID,:);
            sumdVj_diX = 0;
            sumdVj_diY = 0;
            for i = 1 : size(dVj_di_Matrix, 1)
                sumdVj_diX = sumdVj_diX + dVj_di_Matrix(i,1);
                sumdVj_diY = sumdVj_diY + dVj_di_Matrix(i,2);
            end
            
            %w = obj.w0 + mu * sign(obj.w0) * sign(sumdVj_diX * cT + sumdVj_diY * sT); 
            % Try sigmoid function here - changeable epsilon
            epsSigmoid = 5;
            wOut = obj.wOrbit + 1 * (sumdVj_diX * cT + sumdVj_diY * sT)/(abs(sumdVj_diX * cT + sumdVj_diY * sT) + epsSigmoid); 
            obj.w = wOut;
        end
        
        function setAngularVel(obj, w)
            obj.w = w;
        end
        
        function [V] = computeCurrentV(obj)
            % The postitive tol parameter prevents agent from jumping over the
            % bounded region (discontinuity)
            % bj - (a1*x + a2*) > 0 <-- bj - (a1*x - a2*y + tol) > 0 
            tol = 0.001;
            a = obj.regionCoeff(:, 1:2);
            b = obj.regionCoeff(:, 3);
            m = numel(b);
            Vtmp = 0;
            for j = 1:m
                Vtmp = Vtmp +  1 / ( b(j) - (a(j,1) * Zk(1) + a(j,2) * Zk(2) + tol)) / 2 ;
            end
            if(Vtmp < 0)
               error("VBLF is violated. Agent: ...: Current Info"); 
            end  
            V =  (norm(Zk - Ck))^2 * Vtmp;
        end
        
        %% Simulate dynamic model 
        % Call this function once every time the control policy is updated
        % to simulate the movement.
        function [newPose] = move(obj) % Unicycle Dynamic
            % Universal time step
            global dt;
            if(dt == 0)
               error("Simulation time step dt was not assigned"); 
            end
            newPose = zeros(3,1); % [X Y Theta]
            newPose(1) = obj.curPose(1) + dt * (obj.vConst * cos(obj.curPose(3)));
            newPose(2) = obj.curPose(2) + dt * (obj.vConst * sin(obj.curPose(3)));
            newPose(3) = obj.curPose(3) + dt * obj.w;
            obj.curPose = newPose;
        end
    end
end

