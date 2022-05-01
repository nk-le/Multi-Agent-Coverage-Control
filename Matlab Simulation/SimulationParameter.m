classdef SimulationParameter < handle
    properties
        TIME_STEP = 0.01;
        MAX_ITER = 50000;
        N_AGENT = 6;
        %% Simulation Mode
        MODE = "Decentralized";
        ID_LIST
    end
   
    methods 
       function obj = SimulationParameter()
           % Assigned specific IDs for each agents to clarify the coommunication protocol  
       end
       
       function obj = set_n_agents(obj, n)
            obj.N_AGENT = n;
            obj.ID_LIST = (1:obj.N_AGENT) * 10; % For examples: 10, 20, 30, ...
       end
       
       
    end
    
    
    
end


