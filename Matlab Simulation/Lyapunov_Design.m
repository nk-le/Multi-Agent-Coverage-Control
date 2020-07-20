Cx = 200;
Cy = 30;

f1 = @(x) x - 1;
f2 = @(x) -x/2 -1;
f3 = @(x) -x + 2;

A = [1,-1; % y >= x - 1
     -1/2, -1; % y >= -x/2 -1
     1, 1]; % y <= -x + 2
b = [1,1,2];

maxX = 400;
maxY = 400;
VREP = 0;
TRIANGLE = 1;
SQUARE = 2;

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

 for i = 1: size(worldVertexes,1)-1                
   plot([worldVertexes(i,1) worldVertexes(i+1,1)],[worldVertexes(i,2) worldVertexes(i+1,2)]);                    
 end

[X,Y] = meshgrid(0:0.1:400);
% Check x,y in bounded region
check = ones(size(X));
den = ones(size(X));

Z = 0;
for i = 1:numel(b)
   tmpCheck = (b(i) - (A(i,1).*X + A(i,2).*Y) >= 0);
   Z = Z + log(tmpCheck * (b(i) - (A(i,1).*Cx + A(i,2).*Cy))./(b(i) - (A(i,1).*X + A(i,2) .*Y))).^2;
   check = check & tmpCheck;
end
%Z(Z > 0) = log(Z(Z>0)).^2;

figure
ax = axes;
hold on; grid on;

% Draw Line
Yline1 = f1(X);
Yline2 = f2(X);
Yline3 = f3(X);
P = zeros(size(Yline1));
mesh(X, Yline1, P);
mesh(X, Yline2, P);
mesh(X, Yline3, P);

mesh(X,Y,Z);
%contour(X,Y,Z)

xlim([-2 * range , 2 * range]);
%set ( ax, 'Xdir', 'reverse' )
ylim([-2 * range , 2 * range]);
%set ( ax, 'Ydir', 'reverse' )
zlim([0.001, 20]);

colormap summer
