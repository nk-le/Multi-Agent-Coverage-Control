classdef Agent_Voronoi_Report < Report_Base
    properties (Access  = public)
        Vertex2D_List
    end
    
    methods
        function obj = Agent_Voronoi_Report(myID)
            obj@Report_Base(myID);
        end
        
        function assign(obj, vertex, neighborInfo)
            assert(size(vertex,2) == 2);
            
            obj.Vertex2D_List = vertex;
            obj.NeighborInfoList = neighborInfo;
        end
        
        
    end
    
    methods (Access = protected)
         function printInfo(obj)
            disp(obj.VertexList);
            disp(obj.NeighborCoord_2d_List);
         end
    end
end

