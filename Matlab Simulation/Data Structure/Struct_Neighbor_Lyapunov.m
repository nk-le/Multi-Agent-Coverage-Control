classdef Struct_Neighbor_Lyapunov < Struct_Neighbor_Info_Base
    properties    
        dVdz_2d
    end
    
    methods
        function obj = Struct_Neighbor_Lyapunov(myID, neighborID, dVdz_2d)
            obj@Struct_Neighbor_Info_Base(myID, neighborID);
            assert(all(size(dVdz_2d) == [2,1]));
        end
    end
    
    methods (Access = protected)
        function printInfo(obj)

        end
    end
end

