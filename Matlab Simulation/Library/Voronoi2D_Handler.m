classdef Voronoi2D_Handler < handle
    properties
        boundVertex 
        
        % Lastes computation
        partitionVertexes
        vertexPtr
        
        VoronoiReportList
        ID_List
    end
    
    methods
        function obj = Voronoi2D_Handler()
            %obj.ID_List = [];
        end
        
        function setup(obj, bndVertexes)
            obj.boundVertex = bndVertexes;
        end
        
        function exec_partition(obj, pose2D, IDList)
            assert(size(pose2D, 2) == 2);
            
            [obj.partitionVertexes, obj.vertexPtr] = Voronoi2d_calcPartition(pose2D, obj.boundVertex);
            o_neighborInfo = Voronoi2D_getNeightbor(pose2D, obj.partitionVertexes, obj.vertexPtr, IDList);
            
            nPoints = size(pose2D, 1);
            o_Vertexes = cell(nPoints, 1);
            for i = 1 : nPoints 
                o_Vertexes{i} = obj.partitionVertexes(obj.vertexPtr{i}, :);
            end

            %% Creat the report of Voronoi paritions and distributed to decentralized controllers
            obj.VoronoiReportList = GBS_Voronoi_Report.empty(nPoints, 0);
            % Only save the information of the registered agents into the
            % internal buffer
            for i = 1: nPoints
                obj.VoronoiReportList(i) = GBS_Voronoi_Report(IDList(i));
                obj.VoronoiReportList(i).assign(o_Vertexes{i}, o_neighborInfo{i}) ;
                obj.ID_List = IDList;
            end
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

