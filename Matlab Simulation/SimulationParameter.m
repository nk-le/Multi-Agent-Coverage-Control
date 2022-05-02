classdef SimulationParameter < handle
    properties (Constant)
       TIME_STEP = 0.01;
        %% Simulation Mode
        MODE = "Decentralized";
    end
    
    properties
        MAX_ITER = 50000;
        N_AGENT = 6;
        ID_LIST
    end
   
    methods 
       function obj = SimulationParameter()
           % Assigned specific IDs for each agents to clarify the coommunication protocol 
           obj.ID_LIST = (1:obj.N_AGENT);
       end
       
       function obj = set_n_agents(obj, n)
            obj.N_AGENT = n;
            obj.ID_LIST = (1:obj.N_AGENT) * 10; % For examples: 10, 20, 30, ...
       end
       
       
    end
    
    
    
end


