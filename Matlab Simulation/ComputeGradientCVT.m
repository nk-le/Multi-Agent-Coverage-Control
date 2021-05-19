function [dCi_dzj, dCi_dzi_AdjacentJ] = ComputeGradientCVT(currentPosition, neighborAgentPosition, vertexes, mVi, denseViX, denseViY)
%COMPUTEGRADIENTCVT Summary of this function goes here
%vertexX = vertexes(:,1);
%vertexY = vertexes(:,2);
% Integral configurations
%lineDomain = struct('type','polygon','x', vertexX, 'y', vertexY);
%param = struct('method','gauss','points',6);
%mViIntegralScalar = @(x,y) 1;
%ViDistributionIntegralScalarX = @(x,y) x;
%ViDistributionIntegralScalarY = @(x,y) y;
% Mass of the actual voronoi tesselation - from external
%mVi = doubleintegral(mViIntegralScalar, lineDomain, param);
%densityIntegralX = doubleintegral(ViDistributionIntegralScalarX, lineDomain, param);
%densityIntegralY = doubleintegral(ViDistributionIntegralScalarY, lineDomain, param);

% Function definition for partial derivative
rho = @(x,y) 1;
gradZjOfQ = @(q, zjXorY, ziXorY) ((zjXorY - ziXorY)/2 - (q - (ziXorY + zjXorY)/2)); 
gradZiOfQ = @(q, zjXorY, ziXorY) ((zjXorY - ziXorY)/2 + (q - (ziXorY + zjXorY)/2)); 

dCix_dzjx_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* (t              .* gradZjOfQ(t, zjx, zix)             .* (1 + a^2)^(1/2));
dCix_dzjy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* (t              .* gradZjOfQ((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
dCiy_dzjx_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* ((a * t + b)    .* gradZjOfQ(t, zjx, zix)             .* (1 + a^2)^(1/2));
dCiy_dzjy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* ((a * t + b)    .* gradZjOfQ((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
gradZjOfQ_intFunc   = @(t, a, b, zj, zi)   rho(t,a*t+b) .* ((zj - zi)/2 - (t - (zj + zi)/2)) * (1 + a^2)^(1/2); 

dCix_dzix_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* (t              .* gradZiOfQ(t, zjx, zix)             .* (1 + a^2)^(1/2)) ;
dCix_dziy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* (t              .* gradZiOfQ((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
dCiy_dzix_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* ((a * t + b)    .* gradZiOfQ(t, zjx, zix)             .* (1 + a^2)^(1/2));
dCiy_dziy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* ((a * t + b)    .* gradZiOfQ((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
gradZiOfQ_intFunc   = @(t, a, b, zj, zi)   rho(t,a*t+b) .* ((zj - zi)/2 + (t - (zj + zi)/2)) .* (1 + a^2)^(1/2); 

% Iteratively add the computation depends on the neighbor agent
zix = currentPosition(1);
ziy = currentPosition(2);
zjx = neighborAgentPosition(1);
zjy = neighborAgentPosition(2);

% Temporary save the vertexes of the adjacent boundary. Boundary line is
% defined by 2 points, we use the "start" and "end" notation for the
% integration
startVx     = vertexes(1,1);
startVy     = vertexes(1,2);
endVx       = vertexes(2,1);
endVy       = vertexes(2,2);
% 2 cases to determine the line y = ax + b
if(startVx ~= endVx)
   a = (startVy - endVy) / (startVx - endVx); 
   b = startVy - a * startVx;
else       
   a = 0;                                       % Recheck this thing !!! % Here it has to grow to infinity so we can avoid calculating it
   b = 0;
end

% Distance to the neighbor agent
dZiZj = norm(currentPosition - neighborAgentPosition);
   
% Partial derivative computation
dCix_dzjx = (integral(@(x) dCix_dzjx_func(x,a,b,zjx,zix), startVx, endVx) / mVi  -  integral(@(x)gradZjOfQ_intFunc(x    ,a,b,zjx,zix), startVx, endVx) * denseViX / mVi ^ 2) / dZiZj;
dCix_dzjy = (integral(@(x) dCix_dzjy_func(x,a,b,zjx,zix), startVx, endVx) / mVi  -  integral(@(x)gradZjOfQ_intFunc(a*x+b,a,b,zjy,ziy), startVx, endVx) * denseViY / mVi ^ 2) / dZiZj;
dCiy_dzjx = (integral(@(x) dCiy_dzjx_func(x,a,b,zjx,zix), startVx, endVx) / mVi  -  integral(@(x)gradZjOfQ_intFunc(x    ,a,b,zjx,zix), startVx, endVx) * denseViX / mVi ^ 2) / dZiZj;
dCiy_dzjy = (integral(@(x) dCiy_dzjy_func(x,a,b,zjx,zix), startVx, endVx) / mVi  -  integral(@(x)gradZjOfQ_intFunc(a*x+b,a,b,zjy,ziy), startVx, endVx) * denseViY / mVi ^ 2) / dZiZj;

dCix_dzix = (integral(@(x) dCix_dzix_func(x,a,b,zjx,zix), startVx, endVx) / mVi  -  integral(@(x)gradZiOfQ_intFunc(x    ,a,b,zjx,zix), startVx, endVx) * denseViX / mVi ^ 2) / dZiZj;
dCix_dziy = (integral(@(x) dCix_dziy_func(x,a,b,zjx,zix), startVx, endVx) / mVi  -  integral(@(x)gradZiOfQ_intFunc(a*x+b,a,b,zjy,ziy), startVx, endVx) * denseViY / mVi ^ 2) / dZiZj;
dCiy_dzix = (integral(@(x) dCiy_dzix_func(x,a,b,zjx,zix), startVx, endVx) / mVi  -  integral(@(x)gradZiOfQ_intFunc(x    ,a,b,zjx,zix), startVx, endVx) * denseViX / mVi ^ 2) / dZiZj;
dCiy_dziy = (integral(@(x) dCiy_dziy_func(x,a,b,zjx,zix), startVx, endVx) / mVi  -  integral(@(x)gradZiOfQ_intFunc(a*x+b,a,b,zjy,ziy), startVx, endVx) * denseViY / mVi ^ 2) / dZiZj; 

dCi_dzi_AdjacentJ   = [dCix_dzix, dCix_dziy; dCiy_dzix, dCiy_dziy];
dCi_dzj             = [dCix_dzjx, dCix_dzjy; dCiy_dzjx, dCiy_dzjy];
end

