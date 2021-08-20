classdef Struct_Neighbor_Info < handle
    properties
        neighborID
        Neighbor_Coord_2d
        CommonVertex_2d_1
        CommonVertex_2d_2
    end
    
    methods
        function obj = Struct_Neighbor_Info()
            obj.neighborID = 0;
            obj.Neighbor_Coord_2d = zeros(2,1);
            obj.CommonVertex_2d_1 = zeros(2,1);
            obj.CommonVertex_2d_2 = zeros(2,1);
        end
    end
end

