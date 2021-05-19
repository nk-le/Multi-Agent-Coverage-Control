% SETTINGS OF THE DOMINATING / COVERAGE REGION
% Configure these parameters:
%       - amountAgent : number of agents for the simulation 
%       - maxX, maxY  : max range of the coverage map
%       - world:      : shape of the coverage region {VREP, TRIANGLE, SQUARE}
%                       Using VREP must define the region in more details
%       
%

offset = 20;
maxX = 100;
maxY = 100;
amountAgent = 3;

VREP = 0;
TRIANGLE = 1;
SQUARE = 2;

% Default Code
world = VREP;
if(world == TRIANGLE)
    A = [-1, 0; 0 , -1; maxY/maxX,1]; 
    b = [0, 0, maxY];    worldVertexes = [0, 0; 0, maxY; maxX, 0; 0, 0]; 
elseif(world == SQUARE)
    A = [-1 , 0; 1 , 0; 0 , 1; 0 , -1];
    b = [0, maxX, maxY, 0];
    worldVertexes = [0, 0; 0,maxY; maxX,maxY; maxX,0; 0, 0];
elseif(world == VREP)
    A = [-1 , 0; 0 , -1; -1 , 1; 0.6 , 1; 0.6 , -1]; 
    b = [0, 0, 6, 15.6, 3.6];
    worldVertexes = [0, 0; 0,6; 6,12 ; 16,6 ; 6,0; 0,0];
    offset = 1;
end

xrange = max(worldVertexes(:,1));
yrange = max(worldVertexes(:,2));
flag = 0;

% STARTING POSITION
