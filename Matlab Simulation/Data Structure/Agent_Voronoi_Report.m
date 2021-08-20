classdef Agent_Voronoi_Report < Report_Base
    properties (Access  = protected)
        VertexList
        NeighborCoord_2d_List
    end
    
    methods
        function obj = Agent_Voronoi_Report(myID)
            obj@Report_Base(myID);
        end
        
    end
    
    methods (Access = protected)
         function printInfo(obj)
            disp(obj.VertexList);
            disp(obj.NeighborCoord_2d_List);
         end
    end
end

