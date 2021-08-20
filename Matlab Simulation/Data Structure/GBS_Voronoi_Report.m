classdef GBS_Voronoi_Report < Report_Base
    properties (Access  = public)
        NAME = "GBS_Voronoi_Report"
        Vertex2D_List
        NeighborInfoList
    end
    
    methods
        function obj = GBS_Voronoi_Report(myID)
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
            disp(obj.Vertex2D_List);
            disp(obj.NeighborInfoList);
         end
    end
end

