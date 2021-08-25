classdef Agent_Coordinates_Report < Report_Base  
    properties (Access  = public)
        NAME = "Agent_Coordinates_Report"
        poseCoord_3d
        poseVM_2d
    end
    
    methods
        function obj = Agent_Coordinates_Report(myID)
            obj@Report_Base(myID);
            obj.poseCoord_3d = zeros(3,1);
            obj.poseVM_2d = zeros(2,1);
        end        
    end
    
    methods (Access = protected)
        function printInfo(obj)
            fprintf("Pose [%.9f %.9f %.9f]. VM Coord: [%.9f %.9f] \n", ...
            obj.poseCoord_3d(1), obj.poseCoord_3d(2),obj.poseCoord_3d(3), obj.poseVM_2d(1), obj.poseVM_2d(2));
        end
    end
end

