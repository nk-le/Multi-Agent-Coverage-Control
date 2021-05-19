function [dVi_dzi , dVi_dzj_Matrix] = Compute_dVi_dz(zi, Ci, adjacentList, listVertexesVi, worldBoundaryParameter)

vertexX = listVertexesVi(1,:);
vertexY = listVertexesVi(2,:);

flagNeighbor = adjacentList(:,1);
nNeighbor = size(flagNeighbor(flagNeighbor ~= 0),1);
neighborIndex = find(flagNeighbor);


% Integral configurations
intDomain = struct('type','polygon','x', vertexX, 'y', vertexY);
param = struct('method','gauss','points',6);

rho = @(x,y) 1;
rho_x_integralFunc = @(x,y) x;
rho_y_integralFunc = @(x,y) y;
% Mass of the actual voronoi tesselation - from external
mVi = doubleintegral(rho, intDomain, param);
denseViX = doubleintegral(rho_x_integralFunc, intDomain, param);
denseViY = doubleintegral(rho_y_integralFunc, intDomain, param);

% Init 
sum_dVi_dz = 0;
dCi_dzi = 0;
%dCi_dzj = zeros(size(listZj, 2), 2, 2);
% Line boundaryLine = ax + b
a = worldBoundaryParameter(:,1:2);
b = worldBoundaryParameter(:,3);
m = size(b);
BLFfactor1 = 0;
BLFfactor2 = 0;

for j1_m = 1:m 
    BLFfactor1 = BLFfactor1 + 1 / (a(j1_m, 1)* zi(1) + a(j1_m, 2) * zi(2) - b(j1_m));
    BLFfactor2 = BLFfactor2 + [a(j1_m, 1) ; a(j1_m, 2)] / ((a(j1_m, 1)* zi(1) + a(j1_m, 2) * zi(2) - b(j1_m, 1)))^2;
end

% Return this
dVi_dzj_Matrix = zeros(nNeighbor + 1, 2);
for i = 1: nNeighbor              % To the total amount of agent
    curId = neighborIndex(i);                          % Current neighbor
   
    % Neighbor position
    zj =  [adjacentList(curId, 2), adjacentList(curId, 3)];
    % Vertex with this neighbor
    adjacentVertex = [adjacentList(curId, 4) , adjacentList(curId, 5);
                      adjacentList(curId, 6) , adjacentList(curId, 7)];

    [dCi_dzi_AdjacentJ, dCi_dzj] = ComputePartialDerivativeCVT(zi, zj, adjacentVertex, mVi, denseViX, denseViY);
    % Partial derivative of agent i will be updated iteratively
    dCi_dzi = dCi_dzi + dCi_dzi_AdjacentJ; 

    % Compute the gradient of Vi related to neighbor agent zj: dVi_dzj
    dVi_dzj = (-1 .* dCi_dzj) * (zi - Ci)' * BLFfactor1;
    dVi_dzj_Matrix(curId,:) = dVi_dzj;
    %sum_dVi_dz = sum_dVi_dz + dVi_dzj;
end
     
% Compute the gradient of Vi related to neighbor agent zi: dVi_dzi
dVi_dzi = (ones(2,2) - dCi_dzi) * (zi - Ci)' * BLFfactor1 - (zi - Ci) * (zi - Ci)' / 2 * BLFfactor2;
end

