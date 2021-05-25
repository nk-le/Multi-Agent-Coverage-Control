%% This function returns ...
%
function [outList, adjacentList] = ComputeVoronoiProperty(pointCoord, CVTCoord, verList, verPtr)
    n = numel(verPtr);
    outList = zeros(n, n, 5); % Checkflag - dCix/dzjx - dCix/dzjy - dCiy/dzjx - dCiy/dzjy 
    [adjacentList] = computeAdjacentList(CVTCoord, verList, verPtr);
%     if(1)
%         global cellColors;
%         cellColors = summer(n);
%         [ax] = Plot_Cell(trueCoord, CVTCoord, verList, verPtr);
%     end
    % CVTCoord      : CVT information of each agent
    % adjacentList  : 
    for thisCell = 1:n
        thisCoord = pointCoord(thisCell, :);
        verThisCell = verPtr{thisCell}(1:end-1);
        coordVertexX = verList(verThisCell,1);
        coordVertexY = verList(verThisCell,2);
        [mOmegai, denseXi, denseYi] = computePartitionMass(coordVertexX, coordVertexY);
        
        % Take the information of this cell's adjacent to compute the
        % derivative
        flagAdj =  adjacentList(thisCell,:,1);
        thisAdjList = find(flagAdj);
        ownParitialDerivative = zeros(2,2);
        for i = 1: numel(thisAdjList)
            adjIndex = thisAdjList(i);
            curAdjCoord = pointCoord(adjIndex, :);
            commonVertex1 = [adjacentList(thisCell, adjIndex, 6), adjacentList(thisCell, adjIndex, 7)];
            commonVertex2 = [adjacentList(thisCell, adjIndex, 8), adjacentList(thisCell, adjIndex, 9)];
            % Debugging
            %if(1)
            %    plot([commonVertex1(1) commonVertex2(1)] , [commonVertex1(2) commonVertex2(2)], 'Color', cellColors(thisCell,:));
            %end
            [tmpdCidZi, adjacentPartialDerivative] = computePartialDerivativeCVT(thisCoord, curAdjCoord, commonVertex1, commonVertex2, mOmegai, denseXi, denseYi);
            ownParitialDerivative = ownParitialDerivative + tmpdCidZi;
            % Update the desired information
            outList(thisCell, adjIndex, 1) = true; % Is neighbor ?
            outList(thisCell, adjIndex, 2) = adjacentPartialDerivative(1, 1);    % adjacentPartialDerivative dCix_dzjx
            outList(thisCell, adjIndex, 3) = adjacentPartialDerivative(1, 2);    % adjacentPartialDerivative dCix_dzjy
            outList(thisCell, adjIndex, 4) = adjacentPartialDerivative(2, 1);    % adjacentPartialDerivative dCiy_dzjx
            outList(thisCell, adjIndex, 5) = adjacentPartialDerivative(2, 2);    % adjacentPartialDerivative dCiy_dzjy
        end
        outList(thisCell, thisCell, 2) = ownParitialDerivative(1, 1);    % adjacentPartialDerivative dCix_dzix
        outList(thisCell, thisCell, 3) = ownParitialDerivative(1, 2);    % adjacentPartialDerivative dCix_dziy
        outList(thisCell, thisCell, 4) = ownParitialDerivative(2, 1);    % adjacentPartialDerivative dCiy_dzix
        outList(thisCell, thisCell, 5) = ownParitialDerivative(2, 2);    % adjacentPartialDerivative dCiy_dziy
    end    
end

%% Compute the mass of Voronoi partition
function [mOmega, denseX, denseY] = computePartitionMass(coordVertexX, coordVertexY)
        IntDomain = struct('type','polygon','x',coordVertexX(:)','y',coordVertexY(:)');
        param = struct('method','gauss','points',6); 
        %param = struct('method','dblquad','tol',1e-6);
        %% The total mass of the region
        func = @(x,y) 1;
        mOmega = doubleintegral(func, IntDomain, param);
        
        %% The density over X axis
        denseFuncX = @(x,y) x;
        denseX = doubleintegral(denseFuncX, IntDomain, param);
        
        %% The density over Y axis
        denseFuncY = @(x,y) y;
        denseY = doubleintegral(denseFuncY, IntDomain, param);
end

%% Compute the partial derivative of CVTs to adjacent CVT
function [dCi_dzi_AdjacentJ, dCi_dzj] = computePartialDerivativeCVT(thisPos, thatPos, vertex1, vertex2, mVi, denseViX, denseViY)
    %% Function definition for partial derivative
    rho = @(x,y) 1;
    dq_dZj_x_n = @(q, zjXorY, ziXorY) ((zjXorY - ziXorY)/2 - (q - (ziXorY + zjXorY)/2)); 
    dq_dZi_x_n = @(q, zjXorY, ziXorY) ((zjXorY - ziXorY)/2 + (q - (ziXorY + zjXorY)/2)); 

    int_dCix_dzjx_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* (t              .* dq_dZj_x_n(t, zjx, zix)             .* (1 + a^2)^(1/2));
    int_dCix_dzjy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* (t              .* dq_dZj_x_n((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    int_dCiy_dzjx_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* ((a * t + b)    .* dq_dZj_x_n(t, zjx, zix)             .* (1 + a^2)^(1/2));
    int_dCiy_dzjy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* ((a * t + b)    .* dq_dZj_x_n((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    int_dq_dzj_x_n_intFunc   = @(t, a, b, zj, zi)  rho(t,a*t+b) .* ((zj - zi)/2 - (t - (zj + zi)/2)) * (1 + a^2)^(1/2); 
    
    int_dCix_dzix_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* (t              .* dq_dZi_x_n(t, zjx, zix)             .* (1 + a^2)^(1/2)) ;
    int_dCix_dziy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* (t              .* dq_dZi_x_n((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    int_dCiy_dzix_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* ((a * t + b)    .* dq_dZi_x_n(t, zjx, zix)             .* (1 + a^2)^(1/2));
    int_dCiy_dziy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* ((a * t + b)    .* dq_dZi_x_n((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    int_dq_dzi_x_n_intFunc   = @(t, a, b, zj, zi)  rho(t,a*t+b) .* ((zj - zi)/2 + (t - (zj + zi)/2)) .* (1 + a^2)^(1/2); 

    % Name convention
    zix = thisPos(1);
    ziy = thisPos(2);
    zjx = thatPos(1);
    zjy = thatPos(2);

    % Temporary save the vertexes of the adjacent boundary. Boundary line is
    % defined by 2 points, we use the "start" and "end" notation for the
    % integration
    x1     = vertex1(1);
    y1     = vertex1(2); 
    x2       = vertex2(1);
    y2       = vertex2(2);
    % 2 cases to determine the line y = ax + b
    dsIsdy = 0;
    if(x1 ~= x2)
       a = (y2 - y1) / (x2 - x1); 
       b = y1 - a * x1;
    else       
       dsIsdy = 1;
    end

    % Distance to the neighbor agent
    dZiZj = norm(thisPos - thatPos);

    % Partial derivative computation
    % variables to avoid recomputation
    mViSquared = mVi^2;
    
    dCix_dzjx = (integral(@(x) int_dCix_dzjx_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)int_dq_dzj_x_n_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViX / mViSquared) / dZiZj;
    dCix_dzjy = (integral(@(x) int_dCix_dzjy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)int_dq_dzj_x_n_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViX / mViSquared) / dZiZj;
    dCiy_dzjx = (integral(@(x) int_dCiy_dzjx_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)int_dq_dzj_x_n_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViY / mViSquared) / dZiZj;
    dCiy_dzjy = (integral(@(x) int_dCiy_dzjy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)int_dq_dzj_x_n_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViY / mViSquared) / dZiZj;

    dCix_dzix = (integral(@(x) int_dCix_dzix_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)int_dq_dzi_x_n_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViX / mViSquared) / dZiZj;
    dCix_dziy = (integral(@(x) int_dCix_dziy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)int_dq_dzi_x_n_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViX / mViSquared) / dZiZj;
    dCiy_dzix = (integral(@(x) int_dCiy_dzix_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)int_dq_dzi_x_n_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViY / mViSquared) / dZiZj;
    dCiy_dziy = (integral(@(x) int_dCiy_dziy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)int_dq_dzi_x_n_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViY / mViSquared) / dZiZj; 

    dCi_dzi_AdjacentJ   = [dCix_dzix, dCix_dziy; dCiy_dzix, dCiy_dziy];
    dCi_dzj             = [dCix_dzjx, dCix_dzjy; dCiy_dzjx, dCiy_dzjy];
end

function [dCi_dzi_AdjacentJ, dCi_dzj] = computePartialDerivativeCVTs(thisPos, thatPos, vertex1, vertex2, mVi, denseViX, denseViY)
    %% Function definition for partial derivative
    rho = @(x,y) 1;
    distanceZiZj = sqrt((ziX - zjX)^2 + (ziY - zjY)^2);
    dq__dZix_n = @(qX, ziX) (qX - ziX) / distanceZiZj; %        ((zjX - ziX)/2 + (qX - (qXY + zjX)/2)) / distanceZiZj; 
    dq__dZiy_n = @(qY, ziY) (qY - ziY) / distanceZiZj; %        ((zjY - ziY)/2 + (qY - (ziY + zjY)/2)) /distanceZiZj; 
    dq__dZjx_n = @(qX, zjX) (zjX - qX) / distanceZiZj; %        ((zjX - ziX)/2 - (qX - (ziX + zjX)/2)) /distanceZiZj; 
    dq__dZjy_n = @(qY, zjY) (zjY - qY) / distanceZiZj; %        ((zjY - ziY)/2 - (qY - (ziY + zjY)/2))/distanceZiZj; 
    
    v1x = vertex1(1);
    v1y = vertex1(2); 
    v2x = vertex2(1);
    v2y = vertex2(2);
    zix = thisPos(1);
    ziy = thisPos(2);
    zjx = thatPos(1);
    zjy = thatPos(2);
    mViSquared = mVi^2;
    
    %% Integration parameter: t: 0 -> 1
    XtoT = @(t) v1x + (v2x - v1x)* t;
    YtoT = @(t) v1y + (v2y - v1y)* t;
    dqTodtParam = sqrt((v2x - v1x)^2 + (v2y - v1y)^2);  % Factorization of dq = param * dt for line integration
    
    %% dCi_dzix
    dCi_dzix_secondTermInt__mSquared = integral(@(t) dq__dZix_n(XtoT(t), zix), 0, 1 * dqTodtParam ) / mViSquared;
    int_dCix_dzix =  integral(@(t) XtoT(t) * dq__dZix_n(XtoT(t), zix) * dqTodtParam, 0, 1) / mVi + dCi_dzix_secondTermInt__mSquared * denseViX;
    int_dCiy_dziy =  integral(@(t) YtoT(t) * dq__dZix_n(YtoT(t), zix) * dqTodtParam, 0, 1) / mVi + dCi_dzix_secondTermInt__mSquared * denseViY;

    %% dCi_dzjx
    dCi_dzjx_secondTermInt__mSquared = integral(@(t) dq__dZjx_n(XtoT(t), zjx), 0, 1 * dqTodtParam ) / mViSquared;
    int_dCix_dzjx = integral(@(t) XtoT(t) * dq__dZjx_n(XtoT(t), zjx) * dqTodtParam, 0, 1) / mVi + dCi_dzjx_secondTermInt__mSquared * denseViX;
    int_dCiy_dzjx = integral(@(t) YtoT(t) * dq__dZjx_n(YtoT(t), zjx) * dqTodtParam, 0, 1) / mVi + dCi_dzjx_secondTermInt__mSquared * denseViY;
    
    %%
    
    
    %%
    int_dCix_dzjx
    int_dCiy_dzjx
    int_dCix_dzix
    int_dCiy_dziy
    int_dCix_dzix_1stTerm
    dq__dZi_x_n = @(qXY, zjY, ziY) ((zjXY - ziXY)/2 + (qXY - (ziXY + zjXY)/2)); 

    int_dCix_dzjx_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* (t              .* dq__dZj_x_n(t, zjx, zix)             .* (1 + a^2)^(1/2));
    int_dCix_dzjy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* (t              .* dq__dZj_x_n((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    int_dCiy_dzjx_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* ((a * t + b)    .* dq__dZj_x_n(t, zjx, zix)             .* (1 + a^2)^(1/2));
    int_dCiy_dzjy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* ((a * t + b)    .* dq__dZj_x_n((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    int_dq_dzj_x_n_intFunc   = @(t, a, b, zj, zi)  rho(t,a*t+b) .* ((zj - zi)/2 - (t - (zj + zi)/2)) * (1 + a^2)^(1/2); 
    
    int_dCix_dzix_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* (t              .* dq__dZi_x_n(t, zjx, zix)             .* (1 + a^2)^(1/2)) ;
    int_dCix_dziy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* (t              .* dq__dZi_x_n((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    int_dCiy_dzix_func      = @(t, a, b, zjx, zix) rho(t,a*t+b) .* ((a * t + b)    .* dq__dZi_x_n(t, zjx, zix)             .* (1 + a^2)^(1/2));
    int_dCiy_dziy_func      = @(t, a, b, zjy, ziy) rho(t,a*t+b) .* ((a * t + b)    .* dq__dZi_x_n((a * t + b), zjy, ziy)   .* (1 + a^2)^(1/2));
    int_dq_dzi_x_n_intFunc   = @(t, a, b, zj, zi)  rho(t,a*t+b) .* ((zj - zi)/2 + (t - (zj + zi)/2)) .* (1 + a^2)^(1/2); 

    % Name convention
    

    % Temporary save the vertexes of the adjacent boundary. Boundary line is
    % defined by 2 points, we use the "start" and "end" notation for the
    % integration
    x1     = vertex1(1);
    y1     = vertex1(2); 
    x2       = vertex2(1);
    y2       = vertex2(2);
    % 2 cases to determine the line y = ax + b
    dsIsdy = 0;
    if(x1 ~= x2)
       a = (y2 - y1) / (x2 - x1); 
       b = y1 - a * x1;
    else       
       dsIsdy = 1;
    end

    % Distance to the neighbor agent
    dZiZj = norm(thisPos - thatPos);

    % Partial derivative computation
    % variables to avoid recomputation
    mViSquared = mVi^2;
    
    dCix_dzjx = (integral(@(x) int_dCix_dzjx_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)int_dq_dzj_x_n_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViX / mViSquared) / dZiZj;
    dCix_dzjy = (integral(@(x) int_dCix_dzjy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)int_dq_dzj_x_n_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViX / mViSquared) / dZiZj;
    dCiy_dzjx = (integral(@(x) int_dCiy_dzjx_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)int_dq_dzj_x_n_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViY / mViSquared) / dZiZj;
    dCiy_dzjy = (integral(@(x) int_dCiy_dzjy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)int_dq_dzj_x_n_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViY / mViSquared) / dZiZj;

    dCix_dzix = (integral(@(x) int_dCix_dzix_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)int_dq_dzi_x_n_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViX / mViSquared) / dZiZj;
    dCix_dziy = (integral(@(x) int_dCix_dziy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)int_dq_dzi_x_n_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViX / mViSquared) / dZiZj;
    dCiy_dzix = (integral(@(x) int_dCiy_dzix_func(x,a,b,zjx,zix), x1, x2) / mVi  -  integral(@(x)int_dq_dzi_x_n_intFunc(x    ,a,b,zjx,zix), x1, x2) * denseViY / mViSquared) / dZiZj;
    dCiy_dziy = (integral(@(x) int_dCiy_dziy_func(x,a,b,zjy,ziy), x1, x2) / mVi  -  integral(@(x)int_dq_dzi_x_n_intFunc(a*x+b,a,b,zjy,ziy), x1, x2) * denseViY / mViSquared) / dZiZj; 

    dCi_dzi_AdjacentJ   = [dCix_dzix, dCix_dziy; dCiy_dzix, dCiy_dziy];
    dCi_dzj             = [dCix_dzjx, dCix_dzjy; dCiy_dzjx, dCiy_dzjy];
end

%% Determine which CVTs are adjacent CVTs
function [adjacentList] = computeAdjacentList(centroidPos, vertexes, vertexHandler)
    % Check for all agent
    nCell = numel(vertexHandler);
    % Return the result [adjacentList] with the following information - 9 columns 
    % CheckNeighborflag - [thisCVT: x y] - [neighborCVT: x y] - [vertex1: x y] - [vertex2: x y]
    adjacentList = zeros(nCell,nCell, 9);  
    %% Start searching for common vertexes to determine neighbor agents
    for thisCVT = 1 : nCell
        thisVertexList = vertexHandler{thisCVT}(1:end - 1);
        % Checking all another CVTs
        for nextCVT = 1: nCell
              if(nextCVT ~= thisCVT)
                    cnt = 0;
                    nextVertexList = vertexHandler{nextCVT}(1:end-1); 
                       % Comparing these 2 arrays to find out whether it is the
                       % adjacent CVT or not  -> currentVertexes vs vertexBeingChecked
                       isNeighbor = false;
                       for l = 1 : numel(thisVertexList)
                          for k = 1 : numel(nextVertexList)
                             % Some work around flag here because small
                             % values can not be exactly compared
                             tol = 0.000001;
                             workaroundFlag = (abs(vertexes(thisVertexList(l),1) - vertexes(nextVertexList(k),1)) < tol) && (abs(vertexes(thisVertexList(l),2) - vertexes(nextVertexList(k),2)) < tol); % Observe identical vertexes -> work around with this condition
                             if ((thisVertexList(l) == nextVertexList(k)) || workaroundFlag(1))   
                                % Once this part is triggered, the coord under comparision is the adjacent coord
                                isNeighbor = true;
                                adjacentList(thisCVT, nextCVT, 1) = true;
                                % The Coord of this CVT
                                adjacentList(thisCVT, nextCVT, 2) = centroidPos(thisCVT,1);   % X
                                adjacentList(thisCVT, nextCVT, 3) = centroidPos(thisCVT,2);   % Y
                                % Put Neighbor CVT's Coord here
                                adjacentList(thisCVT, nextCVT, 4) = centroidPos(nextCVT,1);   % X
                                adjacentList(thisCVT, nextCVT, 5) = centroidPos(nextCVT,2);   % Y
                                % Counter to control the number of vertexes
                                % Update the vertexes into the output
                                % array. We control the amount of vertexes
                                % for precise line integration
                                cnt = cnt + 1;
                                if cnt == 1
                                    adjacentList(thisCVT, nextCVT, 6) = vertexes(thisVertexList(l),1); % First vertex
                                    adjacentList(thisCVT, nextCVT, 7) = vertexes(thisVertexList(l),2); % First vertex
                                elseif cnt == 2
                                    % Sometimes there are vexteres with
                                    % same values (guess: numerical small
                                    % values) so the input vertexes has
                                    % some redundancy. We have to check
                                    % some tolerate here to determine
                                    % whether it is a different vertex in
                                    % comparison to the saved one
                                    tol = 0.0001;
                                    isValidVertex =  (abs(vertexes(thisVertexList(l),1)  - adjacentList(thisCVT, nextCVT, 6))+ ...        % Check with the first saved vertex
                                                abs(vertexes(thisVertexList(l),2)  - adjacentList(thisCVT, nextCVT, 7)) > tol);                 
                                    if(isValidVertex)
                                        adjacentList(thisCVT, nextCVT, 8) = vertexes(thisVertexList(l),1); % Second vertex
                                        adjacentList(thisCVT, nextCVT, 9) = vertexes(thisVertexList(l),2); % Second vertex  
                                    else
                                        cnt = cnt - 1; % Keep scanning to ensure they only have 2 common vertexes
                                    end 
                                elseif cnt >= 3
                                    % Final check to ensure that exactly 2
                                    % vertexes can be found
                                    tol = 0.0001;
                                    isSavedVertex =     (abs(vertexes(thisVertexList(l),1)  - adjacentList(thisCVT, nextCVT, 6))+ ...        % Check with the first saved vertex
                                                        abs(vertexes(thisVertexList(l),2)  - adjacentList(thisCVT, nextCVT, 7)) < tol) | ...
                                                        (abs(vertexes(thisVertexList(l),1)  - adjacentList(thisCVT, nextCVT, 8))+ ...        % Check with the second saved vertex
                                                        abs(vertexes(thisVertexList(l),2)  - adjacentList(thisCVT, nextCVT, 9)) < tol);
                                    if(~isSavedVertex) % If this vertex is valid, assert
                                        error("More than 3 vertexes for 1 common line detected");
                                    end
                                end
                             end
                          end
                       end
                  if(isNeighbor == false)
                      adjacentList(thisCVT, nextCVT, 1) = false;
                      adjacentList(thisCVT, nextCVT, 2:end) = 0;
                  elseif cnt == 1
                         % adjacent agent with only 1 vertex does not
                         % effect the integration so we can skip it
                         adjacentList(thisCVT, nextCVT, 1) = false;
                         adjacentList(thisCVT, nextCVT, 2:end) = 0;
                         
                         %adjacentList(thisCVT, nextCVT, 8) = adjacentList(thisCVT, nextCVT, 6); % Second vertex is same as the first common vertex
                         %adjacentList(thisCVT, nextCVT, 9) = adjacentList(thisCVT, nextCVT, 7); 
%                        while 1
%                           disp("Not enough vertexes");
%                        end
                  end
              end
         end
    end
end

