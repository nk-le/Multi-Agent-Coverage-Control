classdef Simulation_Parameter < handle
    properties (Constant)
        TIME_STEP = 0.01;
        MAX_ITER = 50000;
        N_AGENT = 6;
        %% Simulation Mode
        MODE = "Decentralized";
        
        %MODE = "Decentralized";
    end
    
    properties (SetAccess = immutable)
        REGION_MAX_X
        REGION_MAX_Y
        BOUNDARIES_VERTEXES      
        BOUNDARIES_COEFF;
        ID_LIST ;
    end
    
    methods 
       function obj = Simulation_Parameter(RegionSelection)
           % Assigned specific IDs for each agents to clarify the coommunication protocol  
           obj.ID_LIST = (1:obj.N_AGENT) * 10; % For examples: 10, 20, 30, ...
           
           % Modify region
           % Declare the coverage region by givin
           %    Vertexes 
           %    Boundaries coefficient: aj1*x + aj2*y - b <= 0
           %            [a11 a12 b1;
           %             a21 a22 b2;
           %               ...
           %             am1 am2 bm]
           %% Rectangle
           if(RegionSelection == 1)
                obj.REGION_MAX_X = 600;
                obj.REGION_MAX_Y = 200;
                obj.BOUNDARIES_VERTEXES = [ 0, 0; 
                                    0, obj.REGION_MAX_X; ...
                                    obj.REGION_MAX_Y, obj.REGION_MAX_Y; ...
                                    obj.REGION_MAX_Y, 0; ...
                                    0, 0];
                obj.BOUNDARIES_COEFF = [-1 , 0, 0 ; ...
                                        1 , 0, obj.REGION_MAX_X; ...
                                        0 , 1, obj.REGION_MAX_Y; ...
                                        0 , -1, 0];
            %% Triangle (special)
            elseif(RegionSelection == 2)
                obj.REGION_MAX_X = 600;
                obj.REGION_MAX_Y = 600;
                obj.BOUNDARIES_VERTEXES = [ 0, 0; 
                                    0, obj.REGION_MAX_Y; ...
                                    obj.REGION_MAX_X, 0; ...
                                    0, 0];
                obj.BOUNDARIES_COEFF = [-1 , 0, 0 ; ...
                                        0 , -1, 0; ...
                                        obj.REGION_MAX_Y/obj.REGION_MAX_X , 1, obj.REGION_MAX_Y];
           %% Polygon
           elseif(RegionSelection == 3)
                SCALE = 50;
                obj.BOUNDARIES_VERTEXES = [0,   0; 
                                           0,   6; 
                                           6,   12; 
                                           16,  6;
                                           6,   0;
                                           0,   0] * SCALE;
                obj.BOUNDARIES_COEFF = [-1 , 0, 0 ; ...
                                        0 , -1, 0; ...
                                        -1 , 1, 6 * SCALE; ...
                                        0.6, 1, 15.6 * SCALE; ...
                                        0.6, -1, 3.6 * SCALE];
                obj.REGION_MAX_X = max(obj.BOUNDARIES_VERTEXES(:,1));
                obj.REGION_MAX_Y = max(obj.BOUNDARIES_VERTEXES(:,2));
           end

            
       end
    end
    
    
    
end


