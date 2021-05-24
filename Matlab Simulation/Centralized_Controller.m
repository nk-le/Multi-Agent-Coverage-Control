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
        
        %% Tmp
        dVk_dzj
        lastPoseVM 
        lastPoseCVT 
        LyapunovCost 
        lastV
        BLFden 
    end
    
    properties (Access = private)
        % Agent handler
       
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
            
            % Reconsider this
            obj.dVk_dzj = zeros(nAgent, nAgent,2);
            obj.lastPoseVM = zeros(nAgent, 3);
            obj.lastPoseCVT = zeros(nAgent, 2);
            obj.lastV = zeros(nAgent,1);
            obj.LyapunovCost = zeros(nAgent, 1);
            obj.BLFden = zeros(nAgent, 1);
            
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
        % [@newCoord]  Current coordinates of virtual center of all agents
        % [@out]:
        %
        %       - List of centroid  --> new target for each agent
        %       - Adjacent matrix   --> information about the adjacent
        %                               agents
        %
%         function [CVTs, adjacentMat] = updateVoronoi(obj, newCoord)
%             % The used methods are developed by Aaron_Becker
%             [obj.v,obj.c]= Function_VoronoiBounded(newCoord(:,1), newCoord(:,2), obj.boundariesVertexes);
%             % Compute the new setpoint for each agent
%             for i = 1:obj.nAgent
%                 [cx,cy] = Function_PolyCentroid(obj.v(obj.c{i},1),obj.v(obj.c{i},2));
%                 cx = min(obj.xrange,max(0, cx));
%                 cy = min(obj.yrange,max(0, cy));
%                 if ~isnan(cx) && inpolygon(cx,cy, obj.boundariesVertexes(:,1), obj.boundariesVertexes(:,2))
%                     obj.CurPoseCVT(i,1) = cx;  %don't update if goal is outside the polygon
%                     obj.CurPoseCVT(i,2) = cy;
%                 end
%             end    
%             obj.adjacentMat = getAdjacentList(obj.v ,obj.c, obj.CurPoseCVT);
%             % Return 
%             CVTs = obj.CurPoseCVT;
%             adjacentMat = obj.adjacentMat;
%         end
        
        % This method updates all neccessary states of the agents and
        % [@vmPos]  Current coordinates of virtual center of all agents
        % [@out]:    
        %       - List of centroid  --> new target for each agent
        %       - Adjacent matrix   --> information about the adjacent
        %                               agents
        %
        function [infoOut, LypOut, CVTsOut] = updateCoverage(obj, newPoseVM)
            % Save all the current VM
            obj.CurPoseVM = newPoseVM;          
            % The used methods were developed by Aaron_Becker
            [obj.v,obj.c]= Function_VoronoiBounded(obj.CurPoseVM(:,1), obj.CurPoseVM(:,2), obj.boundariesVertexes);
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
         
            % Update Lyapunov function 
            newV = zeros(obj.nAgent, 1);
            for k = 1:obj.nAgent
                zk = obj.CurPoseVM(k,:);
                ck = obj.CurPoseCVT(k,:);
                [newV(k), obj.BLFden(k)] = obj.computeV(zk, ck);
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
                %% One shot computation for each agent
                Q = eye(2);
                Ci = obj.CurPoseCVT(thisCell,:)';
                zi = obj.CurPoseVM(thisCell, :)';
                sumHj = 0;
                sum_aj_HjSquared = 0;
                for j = 1: size(obj.boundariesCoeff)
                    tol = 2; % Tolerance to relax the state constraint
                    hj = (obj.boundariesCoeff(j,3)- (obj.boundariesCoeff(j,1)*zi(1) + obj.boundariesCoeff(j,2)*zi(2) + tol)); 
                    sumHj = sumHj + 1/hj;
                    sum_aj_HjSquared = sum_aj_HjSquared + [obj.boundariesCoeff(j,1); obj.boundariesCoeff(j,2)] / hj^2 / 2; 
                end
                Q_zDiff_hj = Q * (zi - Ci) / sumHj;
                 
                %% Compute the Partial dVi_dzi of itself
                dCi_dzi = [obj.CVTpartialDerivativeMat(thisCell, thisCell, 2), obj.CVTpartialDerivativeMat(thisCell, thisCell, 3);
                           obj.CVTpartialDerivativeMat(thisCell, thisCell, 4), obj.CVTpartialDerivativeMat(thisCell, thisCell, 5)];
                
                dVidi = (eye(2) - dCi_dzi')*Q_zDiff_hj + sum_aj_HjSquared;
                outdVMat(thisCell, thisCell, 1) = true;   
                outdVMat(thisCell, thisCell, 2) = dVidi(1);    % dVi_dzix 
                outdVMat(thisCell, thisCell, 3) = dVidi(2);    % dVi_dziy 
                %% Scan over the adjacent list and compute the corresponding partial derivative
                flagAdj =  obj.adjacentMat(thisCell,:,1);
                thisAdjList = find(flagAdj);
                for i = 1: numel(thisAdjList)
                    adjIndex = thisAdjList(i);
                    dCi_dzj = [obj.CVTpartialDerivativeMat(thisCell, adjIndex, 2), obj.CVTpartialDerivativeMat(thisCell, adjIndex, 3);
                               obj.CVTpartialDerivativeMat(thisCell, adjIndex, 4), obj.CVTpartialDerivativeMat(thisCell, adjIndex, 5)];
                    dVidj = -dCi_dzj' * Q_zDiff_hj;
                    % Assign the new adjacent partial derivative
                    outdVMat(thisCell, adjIndex, 1) = true;
                    outdVMat(thisCell, adjIndex, 2) = dVidj(1);       % dVi_dzjx 
                    outdVMat(thisCell, adjIndex, 3) = dVidj(2);       % dVi_dzjy
                end
            end 
        end
        
        function [Vk, den] = computeV(obj, Zk, Ck)
            tol = 0.001;
            a = obj.boundariesCoeff(:, 1:2);
            b = obj.boundariesCoeff(:, 3);
            m = numel(b);
            Vk = 0;
            for j = 1 : m
                Vk = Vk +  1 / ( b(j) - (a(j,1) * Zk(1) + a(j,2) * Zk(2) + tol)) / 2 ;
            end
            den = Vk;
            Vk =  (norm(Zk - Ck))^2 * Vk;
        end
        
        function controlCentralize(obj)
            % Update all the control policy for all agents
            for i = 1 : obj.nAgent
                agentHandle = obj.agentList(i);        
                v0 = agentHandle.vConst;
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
                epsSigmoid = 6;
                mu = 1/w0; % Control gain %% ADJUST THE CONTROL GAIN HERE
                w = w0 + mu * w0 * (sumdVj_diX * cT + sumdVj_diY * sT)/(abs(sumdVj_diX * cT + sumdVj_diY * sT) + epsSigmoid); 
                
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
            [CoverageStateInfo, curLypCost, newCVTs] = obj.updateCoverage(newPoseVM);
            global globalInformation;
            globalInformation = CoverageStateInfo;
            
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
            disp(curLypCost)
            
            %% Return
            outLypCost = curLypCost;
            botPose = obj.CurPose;
        end
    end

end

