classdef Class_Mission_Computer < handle
    %CLASS_MISSION_COMPUTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numberOfBot
        setPoint
        handleList
        boundaries
        boundariesCoeff
        xrange;
        yrange;
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
    
    methods
        function obj = Class_Mission_Computer(numberOfBot, worldVertexes, xrange, yrange)
            %CLASS_MISSION_COMPUTER Construct an instance of this class
            %   Detailed explanation goes here
            obj.setPoint = zeros(2, numberOfBot);
            obj.handleList = zeros(1, numberOfBot);
            obj.boundaries = worldVertexes;
            obj.xrange = xrange;
            obj.yrange = yrange;
            obj.numberOfBot = numberOfBot;
            
            obj.dVk_dzj = zeros(numberOfBot, numberOfBot,2);
            obj.lastPosition = zeros(numberOfBot, 3);
            obj.lastCVT = zeros(2, numberOfBot);
            obj.lastV = zeros(numberOfBot,1);
            obj.BLF = zeros(numberOfBot, 1);
            obj.BLFden = zeros(numberOfBot, 1);
        end
     
        function obj = updateSetPoint(obj,x,y,bot)
            obj.setPoint(:,bot) = [x;y]; 
        end    
        
        function [vOut,cOut, dVidz] = computeTarget(obj, agentPosition)
            [obj.v,obj.c]= Function_VoronoiBounded(agentPosition(:,1),agentPosition(:,2), obj.boundaries);
            % Calculate the neighbor list for each agent and update to each
            % agent
            %adjacentList = getAdjacentList(obj.v ,obj.c, agentPosition(:,1:2));
            
            % Compute the new setpoint for each agent
            for i = 1:obj.numberOfBot
                [cx,cy] = Function_PolyCentroid(obj.v(obj.c{i},1),obj.v(obj.c{i},2));
                cx = min(obj.xrange,max(0, cx));
                cy = min(obj.yrange,max(0, cy));
                if ~isnan(cx) && inpolygon(cx,cy, obj.boundaries(:,1), obj.boundaries(:,2))
                    obj.setPoint(1,i) = cx;  %don't update if goal is outside the polygon
                    obj.setPoint(2,i) = cy;
                end
                
                % Calculate the dVi_dz and send them to each agent
                %adjacentMatrixOfZi = zeros(obj.numberOfBot, 7);
                %adjacentMatrixOfZi(:,:) = adjacentList(i,:,:);
                %listVertexesVi = [obj.v(obj.c{i}(1:end-1),1)' ; obj.v(obj.c{i}(1:end-1),2)'];
                % obj.dVi_dz(:,i) = Compute_dVi_dz(agentPosition(i,1:2),[cx, cy], adjacentMatrixOfZi, listVertexesVi, obj.boundariesCoeff);
                %[tmp_dVi_dzi , tmp_dVi_dzj_Vector] = Compute_dVi_dz(agentPosition(i,1:2),[cx, cy], adjacentMatrixOfZi, listVertexesVi, obj.boundariesCoeff);
                %obj.dVk_dzj(i, :, :) = tmp_dVi_dzj_Vector(:,:);   
                %obj.dVk_dzj(i, i, :) = tmp_dVi_dzi;
            end
            vOut = obj.v;
            cOut = obj.c;
            %dVidz = obj.dVk_dzj;
        end
        
        function [Vk, den] = computeV(obj, Zk, Ck)
            tol = 1;
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
        
        function compute(obj, vmPos)
            global dVi_dzMat;
            [obj.v,obj.c]= Function_VoronoiBounded(vmPos(:,1),vmPos(:,2), obj.boundaries);
            % Calculate the neighbor list for each agent and update to each
            % agent
            adjacentList = getAdjacentList(obj.v ,obj.c, vmPos(:,:));
            
            % Compute the new setpoint for each agent
            for i = 1:numel(obj.c) 
                [cx,cy] = Function_PolyCentroid(obj.v(obj.c{i},1),obj.v(obj.c{i},2));
                cx = min(obj.xrange,max(0, cx));
                cy = min(obj.yrange,max(0, cy));
                if ~isnan(cx) && inpolygon(cx,cy, obj.boundaries(:,1), obj.boundaries(:,2))
                    obj.setPoint(1,i) = cx;  %don't update if goal is outside the polygon
                    obj.setPoint(2,i) = cy;
                end       
            end
            
            % Compute Lyapunov function and the gradient
            newV = zeros(obj.numberOfBot, 1);
            for k = 1:obj.numberOfBot
                zk = [vmPos(k,1), vmPos(k,2)];
                ck = [obj.setPoint(1,k), obj.setPoint(2,k)];
                [newV(k), obj.BLFden(k)] = obj.computeV(zk, ck);
            end
            
            % Computation of Gradient
            obj.dVk_dzj(:,:,:) = 0;  % Reset
            for k = 1:obj.numberOfBot
                % Get the neighbors of the current bot
                flagNeighbor = adjacentList(k,:,1);
                nNeighbor = numel(flagNeighbor(flagNeighbor ~= 0));
                neighborIndex = find(flagNeighbor);
                for j = 1: nNeighbor 
                    curNeighbor = neighborIndex(j);
                    obj.dVk_dzj(k,curNeighbor,:) = (newV(k) - obj.lastV(k)) ./ (vmPos(curNeighbor, 1:2) - obj.lastPosition(curNeighbor, 1:2)) ;
                end
                obj.dVk_dzj(k,k,:) = (newV(k) - obj.lastV(k)) ./ (vmPos(k, 1:2) - obj.lastPosition(k, 1:2)) ;
            end
            
            dVi_dzMat = obj.dVk_dzj;
            % Update values
            obj.lastPosition(:,:) = vmPos(:,:);
            obj.lastCVT(:,:) = obj.setPoint(:,:);
            obj.lastV = newV;
        end
    end
end

