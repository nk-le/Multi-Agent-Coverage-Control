%% Description
%   - This is an abstract class to assign the Timestamp and SenderID whenever a report is created.
%   - Each report created by one agent is assigned with a specific sender's ID and published to the environment. 
%   - A peer-to-peer report inherits this class and has additional information that is the receiver's ID. (See Child Class ...) 

%% Attention
%   - All report structure is encapsulated to avoid race condition and to simplify the asynchronous simulation in the future.
%   - All child classes must define the printing function so that the sender or receiver can print out the internal private information 
%     to simplify the debugging process.

classdef (Abstract) Report_Base < handle
    properties (Access  = protected)
        SenderID
        Timestamp
    end
    
    methods
        function obj = Report_Base(initID)
            obj.SenderID = initID;
            obj.Timestamp = rem(now,1);
        end
        
        function printValue(obj)
            fprintf("Time: %.7f. Owner: %d ", obj.Timestamp, obj.SenderID);
            obj.printInfo()
        end
        
        function out = getSenderID(obj)
           out = obj.SenderID; 
        end
    end
    
    % Child class must declare these abstract methods 
    methods (Access = protected, Abstract)
        printInfo(obj) % Print out the internal information of each inherited report
    end    
end

