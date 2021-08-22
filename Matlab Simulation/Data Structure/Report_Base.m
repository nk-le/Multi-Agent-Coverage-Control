classdef (Abstract) Report_Base < handle
    properties (Access  = public)
        SenderID
    end
    
    methods
        function obj = Report_Base(initID)
            obj.SenderID = initID;
        end
        
        function printValue(obj)
            fprintf("Agent: %d\n", obj.SenderID);
            % Call the printing information of the child class
            obj.printInfo()
        end
        
        function out = getSenderID(obj)
           out = obj.SenderID; 
        end
    end
    
    % Child class must declare these abstract methods 
    methods (Access = protected, Abstract)
        printInfo(obj)
    end    
end

