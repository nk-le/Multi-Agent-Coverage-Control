classdef Struct_Neighbor_CVT_PD_Extended < Struct_Neighbor_CVT_PD
    properties (Constant, Access = private )
        NAME = "Struct_Neighbor_CVT_PD_Extended"
    end
    
    properties (Access = private)    
        calc_dV_dzNeighbor_2d
    end
    
    methods
        function obj = Struct_Neighbor_CVT_PD_Extended(i_sample, i_dVdz_2d)
            assert(isa(i_sample, 'Struct_Neighbor_CVT_PD'));
            obj@Struct_Neighbor_CVT_PD(i_sample.PublisherID, i_sample.ReceiverID, i_sample.z, i_sample.C, i_sample.dCdz_2x2);
            obj.calc_dV_dzNeighbor_2d = i_dVdz_2d;
        end
        
        function [txId, rxID, z_2d, C_2d, dCdz_2x2, calc_dV_dzNeighbor_2d] = getValue(obj)
            [txId, rxID, z_2d, C_2d, dCdz_2x2] = getValue@Struct_Neighbor_CVT_PD(obj);
            calc_dV_dzNeighbor_2d = obj.calc_dV_dzNeighbor_2d;
        end
    end
    
    methods (Access = protected)
        function printInfo(obj)
            printInfo@Struct_Neighbor_CVT_PD(obj);
            fprintf("dVidzk: [%.9f %.9f] \n", obj.calc_dV_dzNeighbor_2d(1), obj.calc_dV_dzNeighbor_2d(2));
        end
    end
end

