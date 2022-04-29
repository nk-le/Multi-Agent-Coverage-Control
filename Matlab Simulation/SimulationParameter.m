classdef SimulationParameter < handle
    properties (Constant)
        TIME_STEP = 0.01;
        MAX_ITER = 50000;
        N_AGENT = 6;
        %% Simulation Mode
        MODE = "Decentralized";
    end
    
    properties (SetAccess = immutable)
        ID_LIST
    end
    
    methods 
       function obj = SimulationParameter()
           % Assigned specific IDs for each agents to clarify the coommunication protocol  
           obj.ID_LIST = (1:obj.N_AGENT) * 10; % For examples: 10, 20, 30, ...
       end
    end
    
    
    
end


