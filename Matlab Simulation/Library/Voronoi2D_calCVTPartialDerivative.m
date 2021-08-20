function [dCi_dzi_AdjacentJ, dCi_dzj] = Voronoi2D_calCVTPartialDerivative(thisCoord_2d, thisCVT_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d)
    % Parse the struct
%     mVi = PartialCVTComputation_Struct.my.PartionMass;
%     thisCoord_2d = PartialCVTComputation_Struct.my.Coord;
%     adjCoord_2d = PartialCVTComputation_Struct.friend.Coord;
%     thisCVT_2d = PartialCVTComputation_Struct.my.CVTCoord;
%     vertex1_2d = PartialCVTComputation_Struct.Common.Vertex1;
%     vertex2_2d = PartialCVTComputation_Struct.Common.Vertex2;

    %% Function definition for partial derivative
    % rho = @(x,y) 1;
    distanceZiZj = sqrt((thisCoord_2d(1) - adjCoord_2d(1))^2 + (thisCoord_2d(2) - adjCoord_2d(2))^2);
    dq__dZix_n = @(qX, ziX) (qX - ziX) / distanceZiZj; %        ((zjX - ziX)/2 + (qX - (qXY + zjX)/2)) / distanceZiZj; 
    dq__dZiy_n = @(qY, ziY) (qY - ziY) / distanceZiZj; %        ((zjY - ziY)/2 + (qY - (ziY + zjY)/2)) /distanceZiZj; 
    dq__dZjx_n = @(qX, zjX) (zjX - qX) / distanceZiZj; %        ((zjX - ziX)/2 - (qX - (ziX + zjX)/2)) /distanceZiZj; 
    dq__dZjy_n = @(qY, zjY) (zjY - qY) / distanceZiZj; %        ((zjY - ziY)/2 - (qY - (ziY + zjY)/2))/distanceZiZj; 
    
    
    
    %% Integration parameter: t: 0 -> 1
    XtoT = @(t) vertex1_2d(1) + (vertex2_2d(1) - vertex1_2d(1))* t;
    YtoT = @(t) vertex1_2d(2) + (vertex2_2d(2) - vertex1_2d(2))* t;
    % Factorization of dq = param * dt for line integration
    dqTodtParam = sqrt((vertex2_2d(1) - vertex1_2d(1))^2 + (vertex2_2d(2) - vertex1_2d(2))^2);  
    
    %% dCi_dzix
    dCi_dzix_secondTermInt = integral(@(t) dq__dZix_n(XtoT(t), thisCoord_2d(1)) * dqTodtParam , 0, 1);
    dCix_dzix = (integral(@(t) XtoT(t) .* dq__dZix_n(XtoT(t), thisCoord_2d(1)) .* dqTodtParam, 0, 1) - dCi_dzix_secondTermInt * thisCVT_2d(1)) / mVi;
    dCiy_dzix = (integral(@(t) YtoT(t) .* dq__dZix_n(XtoT(t), thisCoord_2d(1)) .* dqTodtParam, 0, 1) - dCi_dzix_secondTermInt * thisCVT_2d(2)) / mVi;
    
    %% dCi_dziy
    dCi_dziy_secondTermInt = integral(@(t) dq__dZiy_n(YtoT(t), thisCoord_2d(2)) * dqTodtParam , 0, 1);
    dCix_dziy = (integral(@(t) XtoT(t) .* dq__dZiy_n(YtoT(t), thisCoord_2d(2)) .* dqTodtParam, 0, 1) - dCi_dziy_secondTermInt * thisCVT_2d(1)) / mVi;
    dCiy_dziy = (integral(@(t) YtoT(t) .* dq__dZiy_n(YtoT(t), thisCoord_2d(2)) .* dqTodtParam, 0, 1) - dCi_dziy_secondTermInt * thisCVT_2d(2)) / mVi;
    
    %% dCi_dzjx
    dCi_dzjx_secondTermInt = integral(@(t) dq__dZjx_n(XtoT(t), adjCoord_2d(1)) * dqTodtParam , 0, 1 );
    dCix_dzjx = (integral(@(t) XtoT(t) .* dq__dZjx_n(XtoT(t), adjCoord_2d(1)) .* dqTodtParam, 0, 1) - dCi_dzjx_secondTermInt * thisCVT_2d(1)) / mVi;
    dCiy_dzjx = (integral(@(t) YtoT(t) .* dq__dZjx_n(XtoT(t), adjCoord_2d(1)) .* dqTodtParam, 0, 1) - dCi_dzjx_secondTermInt * thisCVT_2d(2)) / mVi;
    
    %% dCi_dzjy
    dCi_dzjy_secondTermInt = integral(@(t) dq__dZjy_n(YtoT(t), adjCoord_2d(2)) * dqTodtParam , 0, 1 );
    dCix_dzjy =  (integral(@(t) XtoT(t) .* dq__dZjy_n(YtoT(t), adjCoord_2d(2)) .* dqTodtParam, 0, 1) - dCi_dzjy_secondTermInt * thisCVT_2d(1)) / mVi;
    dCiy_dzjy =  (integral(@(t) YtoT(t) .* dq__dZjy_n(YtoT(t), adjCoord_2d(2)) .* dqTodtParam, 0, 1) - dCi_dzjy_secondTermInt * thisCVT_2d(2)) / mVi;
    
    %% Return
    dCi_dzi_AdjacentJ   = [ dCix_dzix, dCix_dziy; 
                            dCiy_dzix, dCiy_dziy];
    dCi_dzj             = [ dCix_dzjx, dCix_dzjy ;
                            dCiy_dzjx, dCiy_dzjy];   
end

%% Compute the mass of Voronoi partition
function [mOmega] = ComputePartitionMass(vertexCoord)
        IntDomain = struct('type','polygon','x',vertexCoord.x(:)','y',vertexCoord.y(:)');
        param = struct('method','gauss','points',6); 
        %param = struct('method','dblquad','tol',1e-6);
        %% The total mass of the region
        func = @(x,y) 1;
        mOmega = doubleintegral(func, IntDomain, param);
        
        %% The density over X axis
        %denseFuncX = @(x,y) x;
        %denseX = doubleintegral(denseFuncX, IntDomain, param);
        
        %% The density over Y axis
        %denseFuncY = @(x,y) y;
        %denseY = doubleintegral(denseFuncY, IntDomain, param);
end
