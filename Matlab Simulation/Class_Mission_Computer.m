classdef Class_Mission_Computer < handle
    %CLASS_MISSION_COMPUTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numberOfBot
        setPoint
        handleList
        boundaries
        xrange;
        yrange;
        v
        c
        verCellHandle
        cellColors
        showPlot
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
        end
     
        function obj = updateSetPoint(obj,x,y,bot)
            obj.setPoint(:,bot) = [x;y]; 
        end    
        
        function [vOut,cOut] = computeTarget(obj, agentPosition)
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
            vOut = obj.v;
            cOut = obj.c;
        end
        
        
        function obj = displayTarget(obj)
            
            ;
        end
    end
end

