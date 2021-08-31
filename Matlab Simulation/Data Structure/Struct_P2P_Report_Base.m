%% This class indicates a telegraph-fashion report, which inherits the Report_Base class assigned
% with a PublisherID and is transmitted to a specific agent with a
% ReceiverID.
classdef (Abstract) Struct_P2P_Report_Base < Report_Base
    properties (Access = protected)
        ReceiverID
    end
    
    methods
        function obj = Struct_P2P_Report_Base(myID, ReceiverID)
            obj@Report_Base(myID);
            obj.ReceiverID = ReceiverID;
        end
        
        function out = getReceiverID(obj)
            out = obj.ReceiverID;
        end
    end
end

