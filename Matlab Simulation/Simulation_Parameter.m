classdef Simulation_Parameter
    %SIMULATION_PARAMETER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        TIME_STEP = 0.001;
        MAX_ITER = 40000;
        N_AGENT = 5;
        
        REGION_MAX_X = 200;
        REGION_MAX_Y = 200;
    end
    
    properties
        BOUNDARIES_VERTEXES      
        BOUNDARIES_COEFF;
        ID_LIST ;
    end
    
    methods 
       function obj = Simulation_Parameter() 
            obj.BOUNDARIES_VERTEXES = [ 0, 0; 
                                0, obj.REGION_MAX_X; ...
                                obj.REGION_MAX_Y, obj.REGION_MAX_Y; ...
                                obj.REGION_MAX_Y, 0; ...
                                0, 0];
            obj.BOUNDARIES_COEFF = [-1 , 0, 0 ; ...
                                    1 , 0, obj.REGION_MAX_X; ...
                                    0 , 1, obj.REGION_MAX_Y; ...
                                    0 , -1, 0];
            %% Assigned specific IDs for each agents to clarify the coommunication protocol
            obj.ID_LIST = (1:obj.N_AGENT) * 8; % For examples: 8, 16, 24, ...
       end
    end
    
    
    
end


