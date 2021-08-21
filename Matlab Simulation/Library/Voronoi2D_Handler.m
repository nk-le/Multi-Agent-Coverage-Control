classdef Voronoi2D_Handler < handle
    properties
        boundVertex 
        
        % Lastes computation
        partitionVertexes
        vertexPtr
    end
    
    methods
        function obj = Voronoi2D_Handler()

        end
        
        function setup(obj, bndVertexes)
            obj.boundVertex = bndVertexes;
        end
        
        function [VoronoiReportList] = exec_partition(obj, pose2D, IDList)
            assert(size(pose2D, 2) == 2);
            
            [obj.partitionVertexes, obj.vertexPtr] = Voronoi2d_calcPartition(pose2D, obj.boundVertex);
            o_neighborInfo = Voronoi2D_getNeightbor(pose2D, obj.partitionVertexes, obj.vertexPtr,IDList);
            
            nPoints = size(pose2D, 1);
            o_Vertexes = cell(nPoints, 1);
            for i = 1 : nPoints 
                o_Vertexes{i} = obj.partitionVertexes(obj.vertexPtr{i}, :);
            end

            VoronoiReportList = GBS_Voronoi_Report.empty(nPoints, 0);
            for i = 1: nPoints
                VoronoiReportList(i) = GBS_Voronoi_Report(IDList(i));
                VoronoiReportList(i).assign(o_Vertexes{i}, o_neighborInfo{i}) ;
            end
        end
    end
end

