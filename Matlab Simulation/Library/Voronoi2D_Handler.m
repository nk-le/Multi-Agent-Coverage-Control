classdef Voronoi2D_Handler < handle
    properties
        nPoints
        boundVertex 
    end
    
    methods
        function obj = Voronoi2D_Handler(n)
           obj.nPoints = n;
        end
        
        function setup(obj, bndVertexes)
            obj.boundVertex = bndVertexes;
        end
        
        function poseCVT_2D = partition(obj, pose2D)
            [poseCVT_2D] = Voronoi2d_calcParition(pose2D, obj.boundVertex);
        end
    end
end

