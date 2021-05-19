% Region definition
worldVertexes = [0, 0; 0,6; 6,12 ; 16,6 ; 6,0; 0,0];
eps = 0.0000001;
X = [0 - eps, 1 - eps, 1 + eps, eps];
Y = [eps, 1 + eps, 1 - eps, -eps];

% Integral configurations
lineDomain = struct('type','polygon','x',X,'y',Y);
param = struct('method','gauss','points',8);

% Algo
numCx = @(x,y) x;
denCx = @(x,y) 1;
num_fCx = doubleintegral(numCx, lineDomain, param);
den_fCx = doubleintegral(denCx, lineDomain, param);
calCx = num_fCx / den_fCx;

numCy = @(x,y) y;
denCy = @(x,y) 1;
num_fCy = doubleintegral(numCy, lineDomain, param);
den_fCy = doubleintegral(denCy, lineDomain, param);
calCy = num_fCy / den_fCy;

calC = [calCx, calCy];

% Display
fill(X, Y, '-b');
hold on;
plot(calCx, calCy, 'g*');
strOut = sprintf("calCx: %f, calCy: %f", calCx, calCy);
disp(strOut);