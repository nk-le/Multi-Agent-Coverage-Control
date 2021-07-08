%% Centralized_Controller
% Centralized controller for multiple unicycle agents, which contains a
% list of agent_controller handles to send command to unicycle
% Brief
% - The unicycle kinmematic is implmented directly in class
%  "agent_controller", which is performed by method "move()". Whenever
%  "agent_controller.move()" method is called, the unicycle simulates the next time step position
%   according to the commaned control input. 
% - Centralized_controllers update the desired control input to
%   agent_controller by calling "agent_controller.setAngularVel()"
%   The work flow of centralized_controller is described further in the
%   method "loop(obj)"

classdef Centralized_Controller < handle
    properties
        % Agents configuration
        nAgent                                 % amount of agents
        
        % Coverage region - Voronoi computation
        boundariesVertexes          
        boundariesCoeff                         % Line function of coverage region: [axj ayj bj]: axj*x + ayj*y <= b
        xrange                                  % Max range of x Axis
        yrange                                  % Max range of y Axis
        v                                       % Current List of Voronoi vertexes
        c                                       % Current List of Voronoi vertexes index
   
        % State variable
        agentList
        CurPose
        CurPoseVM
        CurPoseCVT
        adjacentMat
        CVTpartialDerivativeMat
        CoverageStateInfo % Some information here
        CurAngularVel
        
        %% Tmp
        lastPoseVM 
        lastPoseCVT 
        LyapunovCost 
        lastV
    end

    methods
        %% Initialization constant variables
        function obj = Centralized_Controller(nAgent, bndCoeff, bndVertexes, initPose, vConstList, wOrbitList)
            % Default empty variables
            obj.nAgent = nAgent;
            obj.boundariesVertexes = bndVertexes;
            obj.boundariesCoeff = bndCoeff;
            obj.xrange = max(bndVertexes(:,1));
            obj.yrange = max(bndVertexes(:,2));
            obj.CurPose = zeros(obj.nAgent, 3);
            obj.CurPoseCVT = zeros(obj.nAgent, 2);
            obj.CurPoseVM = zeros(obj.nAgent, 2);
            obj.adjacentMat = zeros(obj.nAgent, obj.nAgent);
            obj.CurAngularVel = zeros(obj.nAgent, 1);
            
            % record of last timestamp
            obj.lastPoseVM = zeros(nAgent, 3);
            obj.lastPoseCVT = zeros(nAgent, 2);
            obj.lastV = zeros(nAgent,1);
            obj.LyapunovCost = zeros(nAgent, 1);
            
            % Init list of controller
            obj.agentList = Agent_Controller.empty(obj.nAgent, 0);
            for i = 1 : obj.nAgent
                botID = i;
                obj.agentList(i) = Agent_Controller();
                obj.agentList(i).begin(botID, obj.boundariesCoeff, initPose(i, :), vConstList(i), wOrbitList(i));
            end
        end   
        
        %% Assign the parameters for each controller
        function setupControlParameter(obj, eps, gamma, Q)
            % TBD
        end
        
        %% Methods related to coverage control       
        % This method updates all neccessary states of the agents and
        % [@newPoseVM]  Current coordinates of virtual center of all agents
        % [@out]:  
        %       - infoOut           --> total required coverage
        %                           information, which is ...
        %                           ...
        %                           ...
        %       - LypOut            --> Current Lyapunov cost
        %       - CVTsOut           --> List of new centroids asnew target for each agent
        function [infoOut, LypOut, CVTsOut] = updateCoverage(obj, newPoseVM)
            % Save all the current VM
            obj.CurPoseVM = newPoseVM;          
            % The used methods were developed by Aaron_Becker
            [obj.v,rawC]= Function_VoronoiBounded(obj.CurPoseVM(:,1), obj.CurPoseVM(:,2), obj.boundariesVertexes);
            % Added a layer to outlier the duplicated vertexes
            obj.c = outlierVertexList(obj.v, rawC, [0 obj.xrange], [0 obj.yrange]);
            % Compute the new setpoint for each agent
            for i = 1:obj.nAgent
                [cx,cy] = Function_PolyCentroid(obj.v(obj.c{i},1),obj.v(obj.c{i},2));
                cx = min(obj.xrange,max(0, cx));
                cy = min(obj.yrange,max(0, cy));
                if ~isnan(cx) && inpolygon(cx,cy, obj.boundariesVertexes(:,1), obj.boundariesVertexes(:,2))
                    obj.CurPoseCVT(i,1) = cx;  %don't update if goal is outside the polygon
                    obj.CurPoseCVT(i,2) = cy;
                end
            end
            % Update the partial derivativ of each cells and construct the
            % broadcased information matrix
            [obj.CVTpartialDerivativeMat, obj.adjacentMat] = ComputeVoronoiProperty(obj.CurPoseVM, obj.CurPoseCVT, obj.v, obj.c);
            obj.CoverageStateInfo = obj.computeLyapunovDerivative();
         
            %% This will be updated - Update Lyapunov function 
            newV = zeros(obj.nAgent, 1);
            for k = 1:obj.nAgent
                zk = obj.CurPoseVM(k,:);
                ck = obj.CurPoseCVT(k,:);
                [newV(k)] = obj.computeVLyp(zk, ck);
            end   
            obj.lastPoseVM = obj.CurPoseVM;
            obj.lastPoseCVT = obj.CurPoseCVT;
            obj.LyapunovCost = newV;
            
            % Return the global info to be published and evaluation
            LypOut = sum(obj.LyapunovCost);
            infoOut = obj.CoverageStateInfo;
            CVTsOut = obj.CurPoseCVT;
        end
        
        %% Partial dervivative of Lyapunov function
        function outdVMat = computeLyapunovDerivative(obj)
            outdVMat = zeros(obj.nAgent, obj.nAgent, 3); % Checkflag - dVi/dzx - dVi/dzy
            % CVTCoord      : CVT information of each agent
            % adjacentList  : 
            for thisCell = 1: obj.nAgent
                %% One shot computation before scanning over the adjacent matrix
                Q = eye(2);
                Ci = obj.CurPoseCVT(thisCell,:)';
                zi = obj.CurPoseVM(thisCell, :)';
                sumHj = 0;
                sum_aj_HjSquared = 0;
                for j = 1: size(obj.boundariesCoeff)
                    tol = 0; % Tolerance to relax the state constraint
                    hj = (obj.boundariesCoeff(j,3)- (obj.boundariesCoeff(j,1)*zi(1) + obj.boundariesCoeff(j,2)*zi(2) + tol)); 
                    sumHj = sumHj + 1/hj;
                    sum_aj_HjSquared = sum_aj_HjSquared + [obj.boundariesCoeff(j,1); obj.boundariesCoeff(j,2)] / hj^2 / 2; 
                end
                Q_zDiff_hj = Q * (zi - Ci) / sumHj;
                 
                %% Compute the Partial dVi_dzi of itself
                dCi_dzi = [obj.CVTpartialDerivativeMat(thisCell, thisCell, 2), obj.CVTpartialDerivativeMat(thisCell, thisCell, 3);
                           obj.CVTpartialDerivativeMat(thisCell, thisCell, 4), obj.CVTpartialDerivativeMat(thisCell, thisCell, 5)];
                
                dVidi = (eye(2) - dCi_dzi')*Q_zDiff_hj + sum_aj_HjSquared * (zi - Ci)' * Q * (zi - Ci);
                outdVMat(thisCell, thisCell, 1) = true;   
                outdVMat(thisCell, thisCell, 2) = dVidi(1);    % dVi_dzix 
                outdVMat(thisCell, thisCell, 3) = dVidi(2);    % dVi_dziy 
                
                %% Scan over the adjacent list and compute the corresponding partial derivative
                flagAdj =  obj.adjacentMat(thisCell,:,1);
                thisAdjList = find(flagAdj);
                for nextAdj = 1: numel(thisAdjList)
                    adjIndex = thisAdjList(nextAdj);
                    dCi_dzk = [obj.CVTpartialDerivativeMat(thisCell, adjIndex, 2), obj.CVTpartialDerivativeMat(thisCell, adjIndex, 3);
                               obj.CVTpartialDerivativeMat(thisCell, adjIndex, 4), obj.CVTpartialDerivativeMat(thisCell, adjIndex, 5)];
                    dVidj = -dCi_dzk' * Q_zDiff_hj;
                    % Assign the new adjacent partial derivative
                    outdVMat(thisCell, adjIndex, 1) = true;
                    outdVMat(thisCell, adjIndex, 2) = dVidj(1);       % dVi_dzjx 
                    outdVMat(thisCell, adjIndex, 3) = dVidj(2);       % dVi_dzjy
                end
            end 
        end
        
        function [Vk] = computeVLyp(obj, Zk, Ck)
            tol = 0;
            Vk = 0;
            for j = 1 : size(obj.boundariesCoeff, 1)
                Vk = Vk +  1 / (obj.boundariesCoeff(j,3) - (obj.boundariesCoeff(j,1)*Zk(1) + obj.boundariesCoeff(j,2)* Zk(2) + tol)) / 2 ;
            end
            if(Vk < 0)
                error("State constraint is violated. Check inital position of virtual centers or the control algorithm");
            end
            Vk =  (norm(Zk - Ck))^2 * Vk;
        end
        
        function controlCentralize(obj)
            % Update all the control policy for all agents
            for i = 1 : obj.nAgent
                agentHandle = obj.agentList(i);        
                w0 = agentHandle.wOrbit;
                cT = cos(agentHandle.curPose(3));   % agentStatus.curPose(3): Actual Orientation
                sT = sin(agentHandle.curPose(3));

                % Compute the Lyapunov feedback from adjacent agents
                sumdVj_diX = 0;     % Note that the adjacent agent affects this agent, so the index is dVj/dVi <--> obj.CoverageStateInfo(Agent_J, Agent_I, :)
                sumdVj_diY = 0;
                for j = 1 : obj.nAgent % Scan to see which are the adjacent agents
                    % If the considering cell affects us, add it to the gradient
                    if(obj.CoverageStateInfo(j, i, 1) == true) % Is neighbor or itself ?
                        sumdVj_diX = sumdVj_diX + obj.CoverageStateInfo(j,i,2); % dVj_dzix
                        sumdVj_diY = sumdVj_diY + obj.CoverageStateInfo(j,i,3); % dVj_dziy
                    end
                end      
                % Compute the control input
                epsSigmoid = 5;
                mu = 1/w0/2; % Control gain %% ADJUST THE CONTROL GAIN HERE
                w = w0 + mu * w0 * (sumdVj_diX * cT + sumdVj_diY * sT)/(abs(sumdVj_diX * cT + sumdVj_diY * sT) + epsSigmoid); 
                % Logging
                obj.CurAngularVel(i) = w;
                % Set the computed output for this agent
                agentHandle.setAngularVel(w);  
            end
        end

        %% MAIN
        % Main loop of the simulation 
        % [@in]  --
        % [@out]:    
        %       Current pose of agents for simulation      
        %       
        %
        function [botPose, outLypCost] = loop(obj)
            %% Update dynamic - Each agents move according to the updated control policy
            % This method should be called independent from centralized
            % controller (inside the loop), however put it here for
            % simplicity
            for i = 1:obj.nAgent
               obj.CurPose(i,:) = obj.agentList(i).move();
            end
            
            %% Update the new coordinate feedback (Virtual center) and update Voronoi partitions
            newPoseVM = zeros(obj.nAgent,2);
            for i = 1:obj.nAgent
                newPoseVM(i,:) =  obj.agentList(i).updateVirtualCenter();
            end
            
            %% Update the broadcasted information
            [obj.CoverageStateInfo, curLypCost, newCVTs] = obj.updateCoverage(newPoseVM);
            global globalInformation;
            globalInformation = obj.CoverageStateInfo;
            
            %% Update the control policy for each agent
%% DISTRIBUTED CONTROLL POLICY
%           TODO: implement the distributed fashion for each controller
%             for i = 1:obj.nAgent
%                 obj.agentList(i).executeControl(obj.CurPoseCVT(i,:));       
%                 %obj.agentList(i).setAngularVel(3);
%                  
%             end
            
%% CENTRALIZED CONTROLL POLICY
            obj.controlCentralize();
            
            %% Final update for the next process
            % ...
            % disp(curLypCost)
            
            %% Return
            outLypCost = curLypCost;
            botPose = obj.CurPose;
        end
    end

end

