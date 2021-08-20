classdef Communication_Link < handle
    properties (Access = private)
        nAgent
        AgentReportList
        VoronoiReportsList
    end
    
    methods
        function obj = Communication_Link(nAgents)
            obj.nAgent = nAgents;
            
            obj.AgentReportList = Agent_Coordinates_Report.empty(nAgents, 0);
            obj.VoronoiReportsList = Agent_Voronoi_Report.empty(nAgents, 0);
            for i = 1: nAgents
                obj.AgentReportList(i) = Agent_Coordinates_Report(i);
                obj.VoronoiReportsList(i) = Agent_Voronoi_Report(i);
            end
        end
        
        %% Upload the report structure
        function isValid = upload(obj, reportCoordinates)
            isValid = isa(reportCoordinates, 'Agent_Coordinates_Report');
            assert(isValid);

            thisID = reportCoordinates.getID();
            obj.AgentReportList(thisID) = reportCoordinates;
        end
        
        %% Download the report structure
        function out = download(obj, agentID)
            out = obj.VoronoiReportsList(agentID);
        end
        
        function loop(obj)
            % Compute the CVT according to the actual agents' coord
            % Split them into neighbors and some values
            % ...
            Voronoi2d_calcParition(points_2d_list, bndVertrex)
        end
    end
end

