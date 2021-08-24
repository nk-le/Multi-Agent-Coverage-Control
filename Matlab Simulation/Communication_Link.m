%% Todo:
% Enumeration -1 for unassigned agent
%%

classdef Communication_Link < handle
    properties (Access = private)
        %% Help variables
        ID_List
        
        %% Communication
        nAgent
        NeighborReportTable
        
    end
    
    methods
        function obj = Communication_Link(nAgents, ID_List)
            obj.nAgent = nAgents;
            obj.ID_List = ID_List;
            obj.NeighborReportTable = cell(nAgents, 1);
%             for i = 1: nAgents
%                 obj.NeighborReportTable{i} = cell(nAgents, 1); 
%             end
            obj.ID_List = ID_List;          
        end

        function uploadVoronoiProperty(obj, UploaderID, report)
            assert(isa(report, 'Struct_Neighbor_Lyapunov'));
            txAgentIndex = find(obj.ID_List  == UploaderID);
            assert(~isempty(txAgentIndex)); %% Agent not yet registered in the communication link so it can not upload

            % Delete the previously transmitted data (In practice, this should be checked by the timestamp)
            obj.NeighborReportTable{txAgentIndex} = cell(obj.nAgent, 1);
            for i = 1: numel(report)
                rxID = report(i).getReceiverID();
                rxAgentIndex = find(obj.ID_List  == rxID, 1);
                assert(~isempty(rxAgentIndex)); %% Receiver Agent not yet registered in the communication link so it can not upload
                obj.NeighborReportTable{txAgentIndex}{rxAgentIndex} = report(i);
            end
        end
        
        function [out, isAvailable] = downloadVoronoiProperty(obj, agentID)
            requestAgentIndex = find(obj.ID_List == agentID);
            try
                out = cell(obj.nAgent, 1);
                for senderAgentPtr = 1: obj.nAgent
%                     for reportPtr = 1: numel(obj.NeighborReportTable{agentPtr})
%                         if(~isempty(obj.NeighborReportTable{agentPtr}{reportPtr}))
%                             if(obj.NeighborReportTable{agentPtr}{reportPtr}.getReceiverID() == agentID)
%                                 out(agentPtr) = obj.NeighborReportTable{agentPtr}{reportPtr};
%                             end
%                         end
%                     end
                    if(~isempty(obj.NeighborReportTable{senderAgentPtr}{requestAgentIndex}))
                        out{senderAgentPtr} = obj.NeighborReportTable{senderAgentPtr}{requestAgentIndex};
                    end
                end
                
                out = out(~cellfun(@isempty,out));
                isAvailable = true;
            catch ME
                fprintf("%s \n", ME.message);
                fprintf("Data sharing for Agent %d is not available \n", agentID);
                isAvailable = false;
                out = [];
            end
        end
        
    end
end

