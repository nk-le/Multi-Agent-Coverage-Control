%% This class illustrates the interaction between agents to determine the Voronoi paritions and the adjacent agents
%   - In practice, each agent under operation published their information
%   axialy and apply distributive Voronoi partition algorithms to determine
%   its partition and the adjacent agents.
%   - The simulation environment simplify the partitioning process by using
%   a centralized object, which obtains the current coordinate of agents to
%   determine the partitions and the Voronoi neighbor for each agent.
%   
%% Explaination:
% A report is created as an object which inherits the "Report_Base" so that it is assigned
% to a speicific agent with an ID. (OwnerID)
% - @[Vertex2D_List]: Contains the Vertexes of the Voronoi partition of
%   agent with ID = obj.OwnerID
% - @[NeighborInfoList]: The array of structure "Struct_Neighbor_Voronoi_Partition", each includes the 
%   coordinate of the Voronoi neighbor agent with a specific ID (Struct_Neighbor_Voronoi_Partition.ReceiverID) and the common vertexes
%   coordinates of these two agents
classdef Struct_Voronoi_Partition_Info < Report_Base
    properties (Constant, Access = private)
       NAME = "Struct_Voronoi_Partition_Info" 
    end
    
    properties (Access  = public)
        PartitionOwnerID
        Vertex2D_List
        NeighborInfoList
    end
    
    methods
        function obj = Struct_Voronoi_Partition_Info(PublisherID, PartitionOwnerID, vertex, neighborInfo)
            obj@Report_Base(PublisherID);
            assert(isa(neighborInfo{1}, 'Struct_Neighbor_Voronoi_Partition'));
            assert(size(vertex,2) == 2);
            obj.PartitionOwnerID = PartitionOwnerID;
            obj.Vertex2D_List = vertex;
            obj.NeighborInfoList = neighborInfo;
        end
        
        function [o_ownerID, o_Vertex2D_List, o_NeighborInfoList] = getValue(obj)
            o_ownerID = obj.PartitionOwnerID; 
            o_Vertex2D_List = obj.Vertex2D_List; 
            o_NeighborInfoList = obj.NeighborInfoList;
        end
    end
    
    methods (Access = protected)
         function printInfo(obj)
            fprintf("Voronoi Partition Owner: %d ", obj.PartitionOwnerID );
            fprintf("Vertexes: ");
            disp(obj.Vertex2D_List);
         end
    end
end

