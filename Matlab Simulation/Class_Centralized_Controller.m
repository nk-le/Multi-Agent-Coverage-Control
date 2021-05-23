classdef Class_Centralized_Controller < handle
    %CLASS_MISSION_COMPUTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Agents configuration
        nAgents             % amount of agents
        
        % Coverage region 
        boundaries          
        boundariesCoeff % Line function of coverage region: [axj ayj bj]: axj*x + ayj*y <= b
        xrange;         % Max range of x Axis
        yrange;         % Max range of y Axis
        
        % State variable
        adjacentMat
        CVTpartialDerivativeMat
        vmPose
        
        setPoint
        v
        c
        verCellHandle
        cellColors
        showPlot
        dVk_dzj  
        lastPosition
        lastCVT
        lastV
        BLF
        BLFden
    end
    
    properties (Access = private)
        % Agent handler
        handleList
       
    end
    
    methods
        function obj = Class_Centralized_Controller(nAgents, worldVertexes, xrange, yrange)
            % Class_Centralized_Controller 
            obj.setPoint = zeros(nAgents, 2);
            obj.handleList = zeros(nAgents, 1);
            obj.boundaries = worldVertexes;
            obj.xrange = xrange;
            obj.yrange = yrange;
            obj.nAgents = nAgents;
            
            obj.dVk_dzj = zeros(nAgents, nAgents,2);
            obj.lastPosition = zeros(nAgents, 3);
            obj.lastCVT = zeros(nAgents, 2);
            obj.lastV = zeros(nAgents,1);
            obj.BLF = zeros(nAgents, 1);
            obj.BLFden = zeros(nAgents, 1);
        end
     
        function obj = updateSetPoint(obj,x,y,bot)
            obj.setPoint(:,bot) = [x;y]; 
        end    
        
        % This method updates all neccessary states of the agents and
        % [@newCoord]  Current coordinates of virtual center of all agents
        % [@out]:
        %
        %       - List of centroid  --> new target for each agent
        %       - Adjacent matrix   --> information about the adjacent
        %                               agents
        %
        function [CVTs, outdVMat, adjacentMat] = updateVoronoi(obj, newCoord)
            obj.vmPose = newCoord(:,1:2);
            % The used methods are developed by Aaron_Becker
            [obj.v,obj.c]= Function_VoronoiBounded(newCoord(:,1), newCoord(:,2), obj.boundaries);
            % Compute the new setpoint for each agent
            for i = 1:obj.nAgents
                [cx,cy] = Function_PolyCentroid(obj.v(obj.c{i},1),obj.v(obj.c{i},2));
                cx = min(obj.xrange,max(0, cx));
                cy = min(obj.yrange,max(0, cy));
                if ~isnan(cx) && inpolygon(cx,cy, obj.boundaries(:,1), obj.boundaries(:,2))
                    obj.setPoint(i,1) = cx;  %don't update if goal is outside the polygon
                    obj.setPoint(i,2) = cy;
                end
            end    
            [obj.CVTpartialDerivativeMat, obj.adjacentMat] = ComputeVoronoiProperty(obj.setPoint, obj.v, obj.c);
            outdVMat = obj.computeLyapunovDerivative();
           
            % Return 
            CVTs = obj.setPoint;
            adjacentMat = obj.adjacentMat;
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
        
        % This method updates all neccessary states of the agents and
        % [@vmPos]  Current coordinates of virtual center of all agents
        % [@out]:    
        %       - List of centroid  --> new target for each agent
        %       - Adjacent matrix   --> information about the adjacent
        %                               agents
        %
        function updateState(obj, newVMCoord)
            %% Coverage update - Voronoi partitions and CVTs
            % Compute the new setpoint for each agent adn determine the
            % current neighbor matrix
            global neighborInfo;
            [~, neighborInfo, ~] = obj.updateVoronoi(newVMCoord);
           
            % Compute Lyapunov function and the gradient
            newV = zeros(obj.nAgents, 1);
            for k = 1:obj.nAgents
                zk = [newVMCoord(k,1), newVMCoord(k,2)];
                ck = [obj.setPoint(k,1), obj.setPoint(k,2)];
                [newV(k), obj.BLFden(k)] = obj.computeV(zk, ck);
            end
            
            % Computation of Gradient: dV/dz: Euler numerical method
            % Currently there are some problems with the integration so we
            % use this one temporarily. TODO: Check file "ComputeGradientCVT.m"
            obj.dVk_dzj(:,:,:) = 0;  % Reset
            for k = 1:obj.nAgents
                % Get the neighbors of the current bot
                flagNeighbor = obj.adjacentMat(k,:,1);
                %obj.adjacentMat(:,:,1)
                nNeighbor = numel(flagNeighbor(flagNeighbor ~= 0));
                neighborIndex = find(flagNeighbor);
                for j = 1: nNeighbor 
                    neighborPtr = neighborIndex(j);
                    obj.dVk_dzj(k,neighborPtr,:) = (newV(k) - obj.lastV(k)) ./ (newVMCoord(neighborPtr, 1:2) - obj.lastPosition(neighborPtr, 1:2)) ;
                end
                obj.dVk_dzj(k,k,:) = (newV(k) - obj.lastV(k)) ./ (newVMCoord(k, 1:2) - obj.lastPosition(k, 1:2)) ;
            end
            
            % Update values
            obj.lastPosition(:,:) = newVMCoord(:,:);
            obj.lastCVT(:,:) = obj.setPoint(:,:);
            obj.lastV = newV;
            
            % Publish the values to all agents
            global dVi_dzMat;
            dVi_dzMat = obj.dVk_dzj;
        end
        
        %% 
        function outdVMat = computeLyapunovDerivative(obj)
            outdVMat = zeros(obj.nAgents, obj.nAgents, 5); % Checkflag - dVi/dzx - dVi/dzy
            % CVTCoord      : CVT information of each agent
            % adjacentList  : 
            for thisCell = 1: obj.nAgents
                %% One shot computation for each agent
                Q = eye(2);
                Ci = obj.setPoint(thisCell,:)';
                zi = obj.vmPose(thisCell, :)';
                sumHj = 0;
                sum_aj_HjSquared = 0;
                for j = 1: size(obj.boundariesCoeff)
                    tol = 10;
                    hj = (obj.boundariesCoeff(j,3)- (obj.boundariesCoeff(j,1) * zi(1) + obj.boundariesCoeff(j,2) * zi(2) + tol)); 
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
                %% Scan over the adjacent list and assign the information
                flagAdj =  obj.adjacentMat(thisCell,:,1);
                thisAdjList = find(flagAdj);
                for i = 1: numel(thisAdjList)
                    adjIndex = thisAdjList(i);
                    dCi_dzj = [obj.CVTpartialDerivativeMat(thisCell, adjIndex, 2), obj.CVTpartialDerivativeMat(thisCell, adjIndex, 3);
                               obj.CVTpartialDerivativeMat(thisCell, adjIndex, 4), obj.CVTpartialDerivativeMat(thisCell, adjIndex, 5)];
                    dVidj = -dCi_dzj' * Q_zDiff_hj;
                    % Assign the new value
                    outdVMat(thisCell, adjIndex, 1) = true;
                    outdVMat(thisCell, adjIndex, 2) = dVidj(1);       % dVi_dzjx 
                    outdVMat(thisCell, adjIndex, 3) = dVidj(2);       % dVi_dzjy
                end
            end 
        end
        
        
        
        % This method executes the control policy. 
        % [@in]  --
        % [@out]:    
        %       [wOut]:  Control output of each agent       
        %       
        %
        function [wOut] = executeControl(obj)
            for k = 1:obj.nAgents
                zk = [newVMCoord(k,1), newVMCoord(k,2)];
                ck = [obj.setPoint(k,1), obj.setPoint(k,2)];
                [newV(k), obj.BLFden(k)] = obj.computeV(zk, ck);
            end
            
            
        end
    end
end

