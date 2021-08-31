classdef Struct_Neighbor_CVT_PD < Struct_P2P_Report_Base
    properties (Constant, Access = private )
        NAME = "Struct_Neighbor_CVT_PD"
    end
    
    properties    
        dCdz_2x2
        z
        C
    end
    
    methods
        function obj = Struct_Neighbor_CVT_PD(myID, ReceiverID, i_z, i_C, i_dCdz_2x2)
            obj@Struct_P2P_Report_Base(myID, ReceiverID);
            assert(all(size(i_z) == [2,1]));
            assert(all(size(i_C) == [2,1]));
            assert(all(size(i_dCdz_2x2) == [2,2]));
            obj.z = i_z;
            obj.C = i_C;
            obj.dCdz_2x2 = i_dCdz_2x2;
        end
    end
    
    methods (Access = protected)
        function printInfo(obj)
            fprintf("Neighbor PD. i: %d, k: %d | ", obj.PublisherID, obj.ReceiverID);
            fprintf("VM Coord zi :[%.9f %.9f]. CVT Ci: [%.9f %.9f] ", obj.z(1), obj.z(2), obj.C(1), obj.C(2));
            fprintf("dCi_dzk: [%.9f %.9f; %.9f %.9f] \n", obj.dCdz_2x2(1,1), obj.dCdz_2x2(1,2), obj.dCdz_2x2(2,1), obj.dCdz_2x2(2,2));
        end
    end
end

