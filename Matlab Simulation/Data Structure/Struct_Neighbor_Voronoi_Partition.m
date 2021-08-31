classdef Struct_Neighbor_Voronoi_Partition
    properties (Constant)
        NAME = "Struct_Neighbor_Voronoi_Partition"
    end
    
    properties (Access = private)
        NeighborID
        Neighbor_VM_Coord_2d
        CommonVertex_2d_1
        CommonVertex_2d_2
    end
    
    methods
        function obj = Struct_Neighbor_Voronoi_Partition(i_NeighborID, i_Neighbor_VM_Coord_2d, i_cmV1_2d, i_cmV2_2d)
            assert(all(size(i_Neighbor_VM_Coord_2d) == [2,1]));
            assert(all(size(i_cmV1_2d) == [2,1]));
            assert(all(size(i_cmV2_2d) == [2,1]));
            obj.NeighborID = i_NeighborID;
            obj.Neighbor_VM_Coord_2d = i_Neighbor_VM_Coord_2d;
            obj.CommonVertex_2d_1 = i_cmV1_2d;
            obj.CommonVertex_2d_2 = i_cmV2_2d;
        end
        
        function [id, vm_2d, v1_2d, v2_2d] = getNeighborInfo(obj)
            id = obj.NeighborID;
            vm_2d = obj.Neighbor_VM_Coord_2d;
            v1_2d = obj.CommonVertex_2d_1;
            v2_2d = obj.CommonVertex_2d_2;
        end
        
    end
    
    methods (Access = public)
        function printValue(obj)
            fprintf("Neighbor %d. ", obj.NeighborID);
            fprintf("VM Coord z%d: [%.9f %.9f]. ", obj.NeighborID, obj.Neighbor_VM_Coord_2d(1), obj.Neighbor_VM_Coord_2d(2));
            fprintf("Vertexes. v1: [%.9f %.9f], v2: [%.9f %.9f] \n", obj.CommonVertex_2d_1(1), obj.CommonVertex_2d_1(2), obj.CommonVertex_2d_2(1), obj.CommonVertex_2d_2(2));
        end
    end
end

