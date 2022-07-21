%% Struct_Neighbor_CVT_PD 
% This class indicates the mimnimal necessarry information between agents
% to compute the control input (paper URL: ...)
% It uses the peer to peer (P2P) telegraph fashion, which implies that one data structure consists
% of a specific publisherID (considered as the partition owner) and a
% receiverID (the adjacent agent). The assigned variables belong to the
% Publisher ID

%% Parameters
%   - z: Coordinates of the publisher
%   - C: CVT coordinates of the publisher
%   - dCdz_2x2: Partial derivative of the publisher's CVT related to the
%   coordinate of the adjacent Agent

classdef Struct_Neighbor_CVT_PD < Struct_P2P_Report_Base
    properties (Constant, Access = private )
        NAME = "Struct_Neighbor_CVT_PD"
    end
    
    properties (Access = protected)   
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
        
        function [txId, rxID, z_2d, C_2d, dCdz_2x2] = getValue(obj)
            [txId, rxID] = obj.getIDs();
            z_2d = obj.z;
            C_2d = obj.C;
            dCdz_2x2 = obj.dCdz_2x2;
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

