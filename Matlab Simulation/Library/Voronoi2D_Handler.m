classdef Voronoi2D_Handler < handle
    properties
        nPoints
        boundVertex 
        
        % Lastes computation
        partitionVertexes
        vertexPtr
    end
    
    methods
        function obj = Voronoi2D_Handler(n)
           obj.nPoints = n;
        end
        
        function setup(obj, bndVertexes)
            obj.boundVertex = bndVertexes;
        end
        
        function [out] = exec_partition(obj, pose2D)
            [obj.partitionVertexes, obj.vexterPtr] = Voronoi2d_calcPartition(pose2D, obj.boundVertex);
            out = Voronoi2D_getNeightbor(pose2D, obj.partitionVertexes, obj.vexterPtr);
        end
    end
end

