%% Todo:
% Enumeration -1 for unassigned agent
%%

classdef Communication_Link < handle
    properties (Access = private)
        %% Help variables
        ID_List
        
        %% Communication
        nAgent
        NeighborReportList
        
    end
    
    methods
        function obj = Communication_Link(nAgents, ID_List)
            obj.nAgent = nAgents;
            obj.ID_List = ID_List;
            obj.NeighborReportList = cell(nAgents);
            obj.ID_List = ID_List;          
        end

        function isValid = uploadVoronoiProperty(obj, UploaderID, report)
            assert(isa(report, 'Struct_Neighbor_Lyapunov'));
            txAgentIndex = find(obj.ID_List  == UploaderID);
            assert(~isempty(txAgentIndex)); %% Agent not yet registered in the communication link so it can not upload

            obj.NeighborReportList{txAgentIndex} = Struct_Neighbor_Lyapunov.empty(numel(report), 0);
            for i = 1: numel(report)
                %rxIndex = report.getReceiverID();
                %rxAgentIndex = find(obj.ID_List  == rxIndex, 1);
                %assert(~isempty(rxAgentIndex)); %% Agent not yet registered in the communication link so it can not upload
                obj.NeighborReportList{txAgentIndex}(i) = report(i);
            end

            
            
            nReports = numel(report);
            obj.NeighborReportList(txAgentIndex) = [];
            %obj.NeighborReportList(index) = 
            if(isValid)
                %obj.NeighborReportList(index) = Struct_Neighbor_Lyapunov(report.getSenderID(), report.getReceiverID(), );
            else
                return
            end
        end
        
        function [out, isAvailable] = downloadVoronoiProperty(obj, agentID)
            agentIndex = find(obj.ID_List == agentID);
            try
                out = obj.NeighborReportList(agentIndex);
                isAvailable = true;
            catch ME
                fprintf("Data sharing for Agent %d is not available \n", agentID);
                isAvailable = false;
                out = [];
            end
        end
        
    end
end

