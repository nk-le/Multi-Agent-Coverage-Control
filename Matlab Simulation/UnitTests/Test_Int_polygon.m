% Region definition
worldVertexes = [0, 0; 0,6; 6,12 ; 16,6 ; 6,0; 0,0];
X = [0; 0; 6; 16; 6; 0];
Y = [0; 6; 12; 6; 0; 0];

% Integral configurations
IntDomain = struct('type','polygon','x',X(1: end -1)','y',Y(1: end - 1)');
%param = struct('method','dblquad','tol',1e-6);
param = struct('method','gauss','points',6);
%param = struct('method','cc','points',10);

% Reference
[Cx,Cy] = Function_PolyCentroid(X,Y);

% Algo
numCx = @(x,y) x;
denCx = @(x,y) 1;
num_fCx = doubleintegral(numCx, IntDomain, param);
den_fCx = doubleintegral(denCx, IntDomain, param);
calCx = num_fCx / den_fCx;

numCy = @(x,y) y;
denCy = @(x,y) 1;
num_fCy = doubleintegral(numCy, IntDomain, param);
den_fCy = doubleintegral(denCy, IntDomain, param);
calCy = num_fCy / den_fCy;

calC = [calCx, calCy];

% Display
fill(X, Y, '-b');
hold on;
plot(Cx, Cy, 'r*');
plot(calCx, calCy, 'g*');
strOut = sprintf("Cx: %f, Cy: %f \t calCx: %f, calCy: %f", Cx, Cy, calCx, calCy);
disp(strOut);