classdef Struct_Neighbor_Coordinates < Struct_Neighbor_Info_Base
    properties (Constant)
        NAME = "Struct_Neighbor_Coordinates"
    end
    
    properties
        Neighbor_VM_Coord_2d
        CommonVertex_2d_1
        CommonVertex_2d_2
    end
    
    methods
        function obj = Struct_Neighbor_Coordinates(myID, neighborID, i_Neighbor_VM_Coord_2d, i_cmV1_2d, i_cmV2_2d)
            obj@Struct_Neighbor_Info_Base(myID, neighborID);
            assert(all(size(i_Neighbor_VM_Coord_2d) == [2,1]));
            assert(all(size(i_cmV1_2d) == [2,1]));
            assert(all(size(i_cmV2_2d) == [2,1]));
            obj.Neighbor_VM_Coord_2d = i_Neighbor_VM_Coord_2d;
            obj.CommonVertex_2d_1 = i_cmV1_2d;
            obj.CommonVertex_2d_2 = i_cmV2_2d;
        end
    end
    
    methods (Access = protected)
        function printInfo(obj)
            fprintf("Voronoi Neighbor Info. Neighbor ID: %d. ", obj.ReceiverID);
            fprintf("Neighbor VM coordinate z%d: [%.9f %.9f]. ", obj.ReceiverID, obj.Neighbor_VM_Coord_2d(1), obj.Neighbor_VM_Coord_2d(2));
            fprintf("Common Vertexes. v1: [%.9f %.9f], v2: [%.9f %.9f] \n", obj.CommonVertex_2d_1(1), obj.CommonVertex_2d_1(2), obj.CommonVertex_2d_2(1), obj.CommonVertex_2d_2(2));
        end
    end
end

