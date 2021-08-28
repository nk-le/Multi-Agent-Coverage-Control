classdef (Abstract) Report_Base < handle
    properties (Access  = public)
        SenderID
        Timestamp
    end
    
    methods
        function obj = Report_Base(initID)
            obj.SenderID = initID;
            obj.Timestamp = rem(now,1);
        end
        
        function printValue(obj)
            %fprintf("=========== REPORT Of AGENT %d ============== \n", obj.SenderID);
            % Call the printing information of the child class
            fprintf("Time: %.7f ", obj.Timestamp);
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

