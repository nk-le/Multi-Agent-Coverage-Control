classdef Struct_Neighbor_Lyapunov < Struct_Neighbor_Info_Base
    properties    
        dVdz_2d
        dCdz_2x2
    end
    
    methods
        function obj = Struct_Neighbor_Lyapunov(myID, neighborID, i_dVdz_2d, i_dCdz_2x2)
            obj@Struct_Neighbor_Info_Base(myID, neighborID);
            assert(all(size(i_dVdz_2d) == [2,1]));
            obj.dVdz_2d = i_dVdz_2d;
            obj.dCdz_2x2 = i_dCdz_2x2;
        end
    end
    
    methods (Access = protected)
        function printInfo(obj)
            disp(obj.dVdz_2d);
            disp(obj.dCdz_2x2);
        end
    end
end

