%% Todo:
% Enumeration -1 for unassigned agent
%%

classdef Communication_Link < handle
    properties (Access = private)
        %% Help variables
        ID_List
        
        %% Communication
        nAgent
        AgentReportList
        VoronoiReportList
            
    end
    
    methods
        function obj = Communication_Link(nAgents)
            obj.nAgent = nAgents;
            
            obj.AgentReportList = Agent_Coordinates_Report.empty(nAgents, 0);
            obj.ID_List = -1 * ones(nAgents, 1);
            obj.VoronoiReportList = GBS_Voronoi_Report.empty(nAgents, 0);
            for i = 1: nAgents
                obj.AgentReportList(i) = Agent_Coordinates_Report(-1);
                obj.VoronoiReportList(i) = GBS_Voronoi_Report(-1);
            end            
        end

   
        %% Upload the report structure
        function upload(obj, reportCoordinates)
            assert(isa(reportCoordinates, 'Agent_Coordinates_Report'));
            thisID = reportCoordinates.getID();
            for i = 1: obj.nAgent
               if(obj.AgentReportList(i).getID() == thisID || obj.AgentReportList(i).getID() == -1)
                    obj.AgentReportList(i) = reportCoordinates;
                    obj.ID_List(i) = thisID;
                    return
               end
            end
        end
        
        %% Download the report structure
        function [out, isAvailable] = download(obj, agentID)
            out = [];            
            agentIndex = find(obj.ID_List == agentID);
            isAvailable = ~isempty(agentIndex);
            if(isAvailable)
                out = obj.VoronoiReportList(agentIndex);
            end
        end
        
        function uploadVoronoiParition(obj, VoronoiPartitionInfo)
            isa(VoronoiPartitionInfo, "GBS_Voronoi_Report");
            assert(numel(VoronoiPartitionInfo) == obj.nAgent);
            
            for i = 1: obj.nAgent 
                agentID = VoronoiPartitionInfo(i).getID();
                agentIndex = find(obj.ID_List == agentID);
                obj.VoronoiReportList(agentIndex) = GBS_Voronoi_Report(agentID);
                obj.VoronoiReportList(agentIndex) = VoronoiPartitionInfo(i);
            end
        end
        
        
        function [out, ID_LIST] = downloadCoord(obj)
            obj.nAgent;
            out  = [30,20;23,22;46,94; 23, 15; 45, 25; 35, 33]; %zeros(nAgents, 2);
            ID_LIST = obj.ID_List;
        end
    end
end

