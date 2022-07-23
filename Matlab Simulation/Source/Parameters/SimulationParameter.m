classdef SimulationParameter < handle
    properties
        TIME_STEP = 0.001;
        MAX_ITER = 50000;
        N_AGENT = 6;
        ID_LIST 
        START_POSE
    end
   
    methods 
       function obj = SimulationParameter(dt, maxIter, nAgent, initialPose)
           % Assigned specific IDs for each agents to clarify the coommunication protocol 
           obj.TIME_STEP = dt;
           obj.MAX_ITER = maxIter;
           obj.N_AGENT = nAgent;
           obj.ID_LIST = (1:obj.N_AGENT);
           obj.START_POSE = initialPose(1:obj.N_AGENT,:);
       end       
    end
end


