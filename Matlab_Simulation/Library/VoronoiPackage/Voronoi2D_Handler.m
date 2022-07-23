classdef Voronoi2D_Handler < handle
    properties
        boundVertex 
        
        % Lastes computation
        partitionVertexes
        vertexPtr
        
        VoronoiReportList
        ID_List
    end
    
    properties (Access = private)
        ID
    end
    
    methods
        function obj = Voronoi2D_Handler(ID, bndVertexes)
            obj.ID = ID;
            obj.boundVertex = bndVertexes;
        end
                
        function [v, c] = exec_partition(obj, pose2D, IDList)
            format long;
            assert(size(pose2D, 2) == 2);
            
            [obj.partitionVertexes, obj.vertexPtr] = Voronoi2d_calcPartition(pose2D, obj.boundVertex);
            o_neighborInfo = Voronoi2D_getNeightbor(pose2D, obj.partitionVertexes, obj.vertexPtr, IDList);
            
            nPoints = size(pose2D, 1);
            o_Vertexes = cell(nPoints, 1);
            for i = 1 : nPoints 
                o_Vertexes{i} = obj.partitionVertexes(obj.vertexPtr{i}, :);
            end

            %% Create the report of Voronoi paritions and distributed to decentralized controllers
            obj.VoronoiReportList = Struct_Voronoi_Partition_Info.empty(nPoints, 0);
            % Only save the information of the registered agents into the
            % internal buffer
            for i = 1: nPoints
                obj.VoronoiReportList(i) = Struct_Voronoi_Partition_Info(obj.ID, IDList(i), o_Vertexes{i}, o_neighborInfo{i});
                obj.ID_List = IDList;
            end
            
            %% For debug
            v = obj.partitionVertexes;
            c = obj.vertexPtr;
        end
        
        %% Download the report structure
        function [out, isAvailable] = get_Voronoi_Parition(obj, agentID)
            out = [];            
            agentIndex = find(obj.ID_List == agentID);
            isAvailable = ~isempty(agentIndex);
            if(isAvailable)
                out = obj.VoronoiReportList(agentIndex);
            end
        end
    end
end

