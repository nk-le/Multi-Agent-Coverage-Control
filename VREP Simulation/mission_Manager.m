classdef mission_Manager < handle
    %MISSION_MANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        setPoint
        handleList
        boundaries
        xrange;
        yrange;
        v
        c
    end
    
    methods
        function obj = mission_Manager(numberOfBot, worldVertexes, xrange, yrange)
            obj.setPoint = zeros(2, numberOfBot);
            obj.handleList = zeros(1, numberOfBot);
            obj.boundaries = worldVertexes;
            obj.xrange = xrange;
            obj.yrange = yrange;
        end
        
        function obj = updateHandle(obj,handleName)
            global sim; global clientID;        
            %assert(numel(handleName) == size(obj.handleList,2), "handle list does not match ");
            for i = 1:size(handleName,1)
                [returnCode,obj.handleList(1,i)]= sim.simxGetObjectHandle(clientID, handleName(i,:), sim.simx_opmode_blocking);
            end
        end
        
        function obj = drawMap()
            global sim; global clientID;
        end
        
        function obj = updateSetPoint(obj,x,y,bot)
            obj.setPoint(:,bot) = [x;y]; 
        end    
        
        function obj = computeTarget(obj, agentPosition)
            [obj.v,obj.c]= Function_VoronoiBounded(agentPosition(:,1),agentPosition(:,2), obj.boundaries);
            for i = 1:numel(obj.c) %calculate the centroid of each cell
                [cx,cy] = Function_PolyCentroid(obj.v(obj.c{i},1),obj.v(obj.c{i},2));
                cx = min(obj.xrange,max(0, cx));
                cy = min(obj.yrange,max(0, cy));
                if ~isnan(cx) && inpolygon(cx,cy, obj.boundaries(:,1), obj.boundaries(:,2))
                    obj.setPoint(1,i) = cx;  %don't update if goal is outside the polygon
                    obj.setPoint(2,i) = cy;
                end
            end
        end
        
        function obj = displayTarget(obj)
            global sim; global clientID
            for i = 1:numel(obj.handleList)
                sim.simxSetObjectPosition(clientID, obj.handleList(1,i), -1, [obj.setPoint(1,i), obj.setPoint(2,i), 0.05], sim.simx_opmode_oneshot); 
            end
        end
    end
end

