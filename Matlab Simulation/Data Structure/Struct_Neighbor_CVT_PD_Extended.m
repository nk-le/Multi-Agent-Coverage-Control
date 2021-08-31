classdef Struct_Neighbor_CVT_PD_Extended < Struct_Neighbor_CVT_PD
    properties (Constant, Access = private )
        NAME = "Struct_Neighbor_CVT_PD_Extended"
    end
    
    properties    
        calc_dV_dzNeighbor_2d
    end
    
    methods
        function obj = Struct_Neighbor_CVT_PD_Extended(i_sample, i_dVdz_2d)
            assert(isa(i_sample, 'Struct_Neighbor_CVT_PD'));
            obj@Struct_Neighbor_CVT_PD(i_sample.PublisherID, i_sample.ReceiverID, i_sample.z, i_sample.C, i_sample.dCdz_2x2);
            obj.calc_dV_dzNeighbor_2d = i_dVdz_2d;
        end
    end
    
    methods (Access = protected)
        function printInfo(obj)
            printInfo@Struct_Neighbor_CVT_PD(obj);
            fprintf("dVidzk: [%.9f %.9f] \n", obj.calc_dV_dzNeighbor_2d(1), obj.calc_dV_dzNeighbor_2d(2));
        end
    end
end

