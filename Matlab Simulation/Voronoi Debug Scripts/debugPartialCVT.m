[dCi_dzi_AdjacentJ, dCi_dzj] = ComputePartialDerivativeCVTs(obj.curVMPose, obj.CVTCoord_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d)

function [dCi_dzi_AdjacentJ, dCi_dzj] = ComputePartialDerivativeCVTs(thisCoord_2d, thisCVT_2d, mVi, adjCoord_2d, vertex1_2d, vertex2_2d)
    % Parse the struct
    thisCoord.x = thisCoord_2d(1);
    thisCoord.y = thisCoord_2d(2);
    adjCoord.x = adjCoord_2d(1);
    adjCoord.y = adjCoord_2d(2);
    thisCVT.x = thisCVT_2d(1);
    thisCVT.y = thisCVT_2d(2);
    vertex1.x = vertex1_2d(1);
    vertex1.y = vertex1_2d(2);
    vertex2.x = vertex2_2d(1);
    vertex2.y = vertex2_2d(2);

    %% Function definition for partial derivative
    % rho = @(x,y) 1;
    distanceZiZj = sqrt((thisCoord.x - adjCoord.x)^2 + (thisCoord.y - adjCoord.y)^2);
    dq__dZix_n = @(qX, ziX) (qX - ziX) / distanceZiZj; %        ((zjX - ziX)/2 + (qX - (qXY + zjX)/2)) / distanceZiZj; 
    dq__dZiy_n = @(qY, ziY) (qY - ziY) / distanceZiZj; %        ((zjY - ziY)/2 + (qY - (ziY + zjY)/2)) /distanceZiZj; 
    dq__dZjx_n = @(qX, zjX) (zjX - qX) / distanceZiZj; %        ((zjX - ziX)/2 - (qX - (ziX + zjX)/2)) /distanceZiZj; 
    dq__dZjy_n = @(qY, zjY) (zjY - qY) / distanceZiZj; %        ((zjY - ziY)/2 - (qY - (ziY + zjY)/2))/distanceZiZj; 
    
    
    
    %% Integration parameter: t: 0 -> 1
    XtoT = @(t) vertex1.x + (vertex2.x - vertex1.x)* t;
    YtoT = @(t) vertex1.y + (vertex2.y - vertex1.y)* t;
    % Factorization of dq = param * dt for line integration
    dqTodtParam = sqrt((vertex2.x - vertex1.x)^2 + (vertex2.y - vertex1.y)^2);  
    
    %% dCi_dzix
    dCi_dzix_secondTermInt = integral(@(t) dq__dZix_n(XtoT(t), thisCoord.x) * dqTodtParam , 0, 1);
    dCix_dzix = (integral(@(t) XtoT(t) .* dq__dZix_n(XtoT(t), thisCoord.x) .* dqTodtParam, 0, 1) - dCi_dzix_secondTermInt * thisCVT.x) / mVi;
    dCiy_dzix = (integral(@(t) YtoT(t) .* dq__dZix_n(XtoT(t), thisCoord.x) .* dqTodtParam, 0, 1) - dCi_dzix_secondTermInt * thisCVT.y) / mVi;
    
    %% dCi_dziy
    dCi_dziy_secondTermInt = integral(@(t) dq__dZiy_n(YtoT(t), thisCoord.y) * dqTodtParam , 0, 1);
    dCix_dziy = (integral(@(t) XtoT(t) .* dq__dZiy_n(YtoT(t), thisCoord.y) .* dqTodtParam, 0, 1) - dCi_dziy_secondTermInt * thisCVT.x) / mVi;
    dCiy_dziy = (integral(@(t) YtoT(t) .* dq__dZiy_n(YtoT(t), thisCoord.y) .* dqTodtParam, 0, 1) - dCi_dziy_secondTermInt * thisCVT.y) / mVi;
    
    %% dCi_dzjx
    dCi_dzjx_secondTermInt = integral(@(t) dq__dZjx_n(XtoT(t), adjCoord.x) * dqTodtParam , 0, 1 );
    dCix_dzjx = (integral(@(t) XtoT(t) .* dq__dZjx_n(XtoT(t), adjCoord.x) .* dqTodtParam, 0, 1) - dCi_dzjx_secondTermInt * thisCVT.x) / mVi;
    dCiy_dzjx = (integral(@(t) YtoT(t) .* dq__dZjx_n(XtoT(t), adjCoord.x) .* dqTodtParam, 0, 1) - dCi_dzjx_secondTermInt * thisCVT.y) / mVi;
    
    %% dCi_dzjy
    dCi_dzjy_secondTermInt = integral(@(t) dq__dZjy_n(YtoT(t), adjCoord.y) * dqTodtParam , 0, 1 );
    dCix_dzjy =  (integral(@(t) XtoT(t) .* dq__dZjy_n(YtoT(t), adjCoord.y) .* dqTodtParam, 0, 1) - dCi_dzjy_secondTermInt * thisCVT.x) / mVi;
    dCiy_dzjy =  (integral(@(t) YtoT(t) .* dq__dZjy_n(YtoT(t), adjCoord.y) .* dqTodtParam, 0, 1) - dCi_dzjy_secondTermInt * thisCVT.y) / mVi;
    
    %% Return
    dCi_dzi_AdjacentJ   = [ dCix_dzix, dCix_dziy; 
                            dCiy_dzix, dCiy_dziy];
    dCi_dzj             = [ dCix_dzjx, dCix_dzjy ;
                            dCiy_dzjx, dCiy_dzjy];   
end