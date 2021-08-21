classdef (Abstract) Struct_Neighbor_Info_Base < Report_Base
    properties (Access = public)
        neighborID
    end
    
    methods
        function obj = Struct_Neighbor_Info_Base(myID, neighborID)
            obj@Report_Base(myID);
            obj.neighborID = neighborID;
        end
    end
    
end

