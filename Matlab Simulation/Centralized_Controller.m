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
        
        %% Tmp
        dVk_dzj
        lastPosition 
        lastCVT 
        lastV
        BLF 
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
            obj.lastPosition = zeros(nAgent, 3);
            obj.lastCVT = zeros(nAgent, 2);
            obj.lastV = zeros(nAgent,1);
            obj.BLF = zeros(nAgent, 1);
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
        function [CVTs, adjacentMat] = updateVoronoi(obj, newCoord)
            % The used methods are developed by Aaron_Becker
            [obj.v,obj.c]= Function_VoronoiBounded(newCoord(:,1), newCoord(:,2), obj.boundariesVertexes);
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
            obj.adjacentMat = getAdjacentList(obj.v ,obj.c, obj.CurPoseCVT);
            % Return 
            CVTs = obj.CurPoseCVT;
            adjacentMat = obj.adjacentMat;
        end
        
        % This method updates all neccessary states of the agents and
        % [@vmPos]  Current coordinates of virtual center of all agents
        % [@out]:    
        %       - List of centroid  --> new target for each agent
        %       - Adjacent matrix   --> information about the adjacent
        %                               agents
        %
        function updateCoverage(obj)            
            % Compute Lyapunov function and the gradient
            newV = zeros(obj.nAgent, 1);
            for k = 1:obj.nAgent
                zk = obj.CurPoseVM(k,:);
                ck = obj.CurPoseCVT(k,:);
                [newV(k), obj.BLFden(k)] = obj.computeV(zk, ck);
            end
            
            % Computation of Gradient: dV/dz: Euler numerical method
            % Currently there are some problems with the integration so we
            % use this one temporarily. TODO: Check file "ComputeGradientCVT.m"
            obj.dVk_dzj(:,:,:) = 0;  % Reset
            for k = 1:obj.nAgent
                % Get the neighbors of the current bot
                flagNeighbor = obj.adjacentMat(k,:,1);
                nNeighbor = numel(flagNeighbor(flagNeighbor ~= 0));
                neighborIndex = find(flagNeighbor);
                for j = 1: nNeighbor 
                    neighborPtr = neighborIndex(j);
                    obj.dVk_dzj(k,neighborPtr,:) = (newV(k) - obj.lastV(k)) ./ (obj.CurPoseVM(neighborPtr, 1:2) - obj.lastPosition(neighborPtr, 1:2)) ;
                end
                % Derivative of itself
                obj.dVk_dzj(k,k,:) = (newV(k) - obj.lastV(k)) ./ (obj.CurPoseVM(k, 1:2) - obj.lastPosition(k, 1:2)) ;
            end
            
            % Update values
            obj.lastPosition = obj.CurPoseVM;
            obj.lastCVT = obj.CurPoseCVT;
            obj.lastV = newV;
            
            % Publish the values to all agents
            global dVi_dzMat;
            dVi_dzMat = obj.dVk_dzj;
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
            % Computation of Gradient: dV/dz: Euler numerical method
            % Currently there are some problems with the integration so we
            % use this one temporarily. TODO: Check file "ComputeGradientCVT.m"
            obj.dVk_dzj(:,:,:) = 0;  % Reset
            for k = 1:obj.nAgent
                % Get the neighbors of the current bot
                flagNeighbor = obj.adjacentMat(k,:,1);
                %obj.adjacentMat(:,:,1)
                nNeighbor = numel(flagNeighbor(flagNeighbor ~= 0));
                neighborIndex = find(flagNeighbor);
                for j = 1: nNeighbor 
                    neighborPtr = neighborIndex(j);
                    obj.dVk_dzj(k,neighborPtr,:) = (newV(k) - obj.lastV(k)) ./ (obj.CurPoseVM(neighborPtr, 1:2) - obj.lastPosition(neighborPtr, 1:2)) ;
                end
                obj.dVk_dzj(k,k,:) = (newV(k) - obj.lastV(k)) ./ (newVMCoord(k, 1:2) - obj.lastPosition(k, 1:2)) ;
            end
            
            % Update values
            obj.lastPosition = obj.CurPoseVM;
            obj.lastCVT = obj.CurPoseCVT;
            obj.lastV = newV;
        end

        %% MAIN
        % Main loop of the simulation 
        % [@in]  --
        % [@out]:    
        %       Current pose of agents for simulation      
        %       
        %
        function [botPose] = loop(obj)
            %% Update dynamic - Each agents move according to the updated control policy
            for i = 1:obj.nAgent
               obj.CurPose(i,:) = obj.agentList(i).move();
            end
            
            %% Update the new state (Virtual center) and update Voronoi partitions
            for i = 1:obj.nAgent
                obj.CurPoseVM(i,:) =  obj.agentList(i).updateVirtualCenter();
            end
            obj.updateVoronoi(obj.CurPoseVM);
            
            %% Update the broadcasted information
            obj.updateCoverage();
            global neighborInformation;
            for i = 1:obj.nAgent
                neighborInformation = 0;
            end
            
            %% Update the control policy for each agent
            for i = 1:obj.nAgent
                obj.agentList(i).executeControl(obj.CurPoseCVT(i,:));       
                %obj.agentList(i).setAngularVel(3);
                
            end
            
            %% Final update for the next process
            % ...
            disp(sum(obj.lastV))
            
            %% Return
            botPose = obj.CurPose;
        end
    end

end

