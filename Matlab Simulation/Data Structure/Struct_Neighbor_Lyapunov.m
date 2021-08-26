classdef Struct_Neighbor_Lyapunov < Struct_Neighbor_Info_Base
    properties    
        dCdz_2x2
        zk
        Ck
    end
    
    methods
        function obj = Struct_Neighbor_Lyapunov(myID, receiverID, i_zk, i_Ck, i_dCdz_2x2)
            obj@Struct_Neighbor_Info_Base(myID, receiverID);
            assert(all(size(i_zk) == [2,1]));
            assert(all(size(i_Ck) == [2,1]));
            assert(all(size(i_dCdz_2x2) == [2,2]));
            obj.zk = i_zk;
            obj.Ck = i_Ck;
            obj.dCdz_2x2 = i_dCdz_2x2;
        end
    end
    
    methods (Access = protected)
        function printInfo(obj)
            fprintf("Neighbor Partial Derivative. i: %d, k: %d | ", obj.SenderID, obj.ReceiverID);
            fprintf("VM Coordinates zi :[%.9f %.9f]. CVT Ci: [%.9f %.9f] ", obj.zk(1), obj.zk(2), obj.Ck(1), obj.Ck(2));
            fprintf("dCi_dzk: [%.9f %.9f; %.9f %.9f] \n", obj.dCdz_2x2(1,1), obj.dCdz_2x2(1,2), obj.dCdz_2x2(2,1), obj.dCdz_2x2(2,2));
        end
    end
end

