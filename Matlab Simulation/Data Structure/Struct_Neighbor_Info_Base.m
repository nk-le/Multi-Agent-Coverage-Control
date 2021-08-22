classdef (Abstract) Struct_Neighbor_Info_Base < Report_Base
    properties (Access = public)
        ReceiverID
    end
    
    methods
        function obj = Struct_Neighbor_Info_Base(myID, neighborID)
            obj@Report_Base(myID);
            obj.ReceiverID = neighborID;
        end
        
        function out = getReceiverID(obj)
            out = obj.ReceiverID;
        end
    end
    
end

