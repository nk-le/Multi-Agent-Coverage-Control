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
        
        function [o_Vertexes, o_neighborInfo] = exec_partition(obj, pose2D)
            assert(size(pose2D, 2) == 2);
            
            [obj.partitionVertexes, obj.vertexPtr] = Voronoi2d_calcPartition(pose2D, obj.boundVertex);
            o_neighborInfo = Voronoi2D_getNeightbor(pose2D, obj.partitionVertexes, obj.vertexPtr);
            
            nPoints = size(pose2D, 1);
            o_Vertexes = cell(nPoints, 1);
            for i = 1 : nPoints 
                o_Vertexes{i} = obj.partitionVertexes(obj.vertexPtr{i}, :);
            end
        end
    end
end

