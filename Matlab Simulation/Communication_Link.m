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
        
        %% Voronooi handler, which handles any computation related to Voronoi properties
        VoronoiProcessor
    end
    
    methods
        function obj = Communication_Link(nAgents)
            obj.nAgent = nAgents;
            
            obj.AgentReportList = Agent_Coordinates_Report.empty(nAgents, 0);
            obj.ID_List = -1 * ones(nAgents, 1);
            obj.VoronoiReportList = GBS_Voronoi_Report.empty(nAgents, 0);
            for i = 1: nAgents
                obj.AgentReportList(i) = Agent_Coordinates_Report(-1);
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
            isAvailable = false;
            out = [];
            for i = 1: obj.nAgent
                if(~isempty(obj.VoronoiReportList))
                    if(obj.VoronoiReportList(i).getID() == agentID)
                        out = obj.VoronoiReportList(i);
                        isAvailable = true;
                        return
                    end
               end
            end
        end
        
        function uploadVoronoiParition(obj, VoronoiPartitionInfo)
            isa(VoronoiPartitionInfo, "GBS_Voronoi_Report")
        end
        
        
        function [out, ID_LIST] = downloadCoord(obj)
            obj.nAgent;
            out  = [30,20;23,22;46,94; 23, 15; 45, 25; 35, 33]; %zeros(nAgents, 2);
            ID_LIST = obj.ID_List;
        end
        
        function loop(obj)
            % Compute the CVT according to the actual agents' coord
            % Split them into neighbors and some values
            % ...
            % Get the registered data from agents

            
%             for i = 1: obj.nAgent
%                 obj.VoronoiReportList(i) = GBS_Voronoi_Report(obj.AgentReportList(i).getID());
%                 obj.VoronoiReportList(i).assign(o_Vertexes{i}, o_neighborInfo{i}) ;
%             end
        end
    end
end

