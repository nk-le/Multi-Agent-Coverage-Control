classdef RegionParameter < handle
    
    properties
        REGION_MAX_X
        REGION_MAX_Y
        BOUNDARIES_VERTEXES      
        BOUNDARIES_COEFF;
    end
    
    methods (Static)
        function startPose = generate_start_pose(n)
            rXY = 200;      
            startPose = zeros(n, 3);
            startPose(:,1) = rXY.*rand(n,1); %x
            startPose(:,2) = rXY.*rand(n,1); %y
            startPose(:,3) = zeros(n,1); %theta 
        end
    end
    
    methods

        function obj = RegionParameter(vArr)
           obj.set_vertexes(vArr);  
        end
        
        function set_vertexes(obj, vArr)
            % Each row is one vertex point
            assert(size(vArr,2) == 2);
            [A, b] = vert2con(vArr);
            obj.BOUNDARIES_VERTEXES = vArr;
            %obj.BOUNDARIES_COEFF = [A, b];
            obj.BOUNDARIES_COEFF = normalize([A, b]',"norm")';
            obj.REGION_MAX_X = max(vArr(:,1));
            obj.REGION_MAX_Y = max(vArr(:,2));
        end
        
        function set_manual(obj, RegionSelection)
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

