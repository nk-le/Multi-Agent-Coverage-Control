function [mOmega] = Voronoi2D_calcPartitionMass(vertexCoord)
    IntDomain = struct('type','polygon','x',vertexCoord(:,1)','y',vertexCoord(:,2)');
        param = struct('method','gauss','points',6); 
        %param = struct('method','dblquad','tol',1e-6);
        %% The total mass of the region
        func = @(x,y) 1; % This is the distribution
        mOmega = doubleintegral(func, IntDomain, param);
end
