%% This function returns ...
%
function [outList, REPLACE_PLEASE] = ComputeVoronoiProperty(pointCoord, CVTCoord, verList, verPtr)
    nAgent = numel(verPtr);
    outList = zeros(nAgent, nAgent, 5); % Checkflag - dCix/dzjx - dCix/dzjy - dCiy/dzjx - dCiy/dzjy 
    [REPLACE_PLEASE, AgentReport] = computeAdjacentList(CVTCoord, verList, verPtr);
%     if(1)
%         global cellColors;
%         cellColors = summer(n);
%         [ax] = Plot_Cell(trueCoord, CVTCoord, verList, verPtr);
%     end
    % CVTCoord      : CVT information of each agent
    % adjacentList  : 
    for thisAgent = 1:nAgent
        thisCoord = pointCoord(thisAgent, :);
        thisCVTCoord = CVTCoord(thisAgent, :);
        verThisCell = verPtr{thisAgent}(1:end-1);
        coordVertexX = verList(verThisCell,1);
        coordVertexY = verList(verThisCell,2);
        [mOmegai, denseXi, denseYi] = computePartitionMass(coordVertexX, coordVertexY);
        
        % Take the information of this cell's adjacent to compute the
        % derivative
        flagAdj =  REPLACE_PLEASE(thisAgent,:,1);
        
        %isVoronoiNeighborList =  AgentReport(thisAgent).FriendAgentInfo(:).isVoronoiNeighbor;
        thisAdjList = find(flagAdj);
        ownParitialDerivative = zeros(2,2);
        
        for friendAgent = 1: numel(nAgent)
            isNeighbor = (friendAgent ~= thisAgent) && (AgentReport(thisAgent).FriendAgentInfo(friendAgent).isVoronoiNeighbor);
            if(isNeighbor)
                neighborIndex = AgentReport(thisAgent).FriendAgentInfo(friendAgent).ID;
                neighborCoord = pointCoord(neighborIndex,:);
                
                curAdjCoord = pointCoord(neighborIndex, :);
                curAdjCVTCoord = CVTCoord(neighborIndex, :);
                commonVertex1 = [REPLACE_PLEASE(thisAgent, neighborIndex, 6), REPLACE_PLEASE(thisAgent, neighborIndex, 7)];
                commonVertex2 = [REPLACE_PLEASE(thisAgent, neighborIndex, 8), REPLACE_PLEASE(thisAgent, neighborIndex, 9)];
            
            [tmpdCidZi, adjacentPartialDerivative] = computePartialDerivativeCVTs(thisCoord, thisCVTCoord, curAdjCoord, curAdjCVTCoord, commonVertex1, commonVertex2, mOmegai);
            
            ownParitialDerivative = ownParitialDerivative + tmpdCidZi;
            % Update the desired information
            outList(thisAgent, neighborIndex, 1) = true; % Is neighbor ?
            outList(thisAgent, neighborIndex, 2) = adjacentPartialDerivative(1, 1);    % adjacentPartialDerivative dCix_dzjx
            outList(thisAgent, neighborIndex, 3) = adjacentPartialDerivative(1, 2);    % adjacentPartialDerivative dCix_dzjy
            outList(thisAgent, neighborIndex, 4) = adjacentPartialDerivative(2, 1);    % adjacentPartialDerivative dCiy_dzjx
            outList(thisAgent, neighborIndex, 5) = adjacentPartialDerivative(2, 2);    % adjacentPartialDerivative dCiy_dzjy 
            end 
        end
        
        for i = 1: numel(thisAdjList)
            neighborIndex = thisAdjList(i);
            curAdjCoord = pointCoord(neighborIndex, :);
            curAdjCVTCoord = CVTCoord(neighborIndex, :);
            commonVertex1 = [REPLACE_PLEASE(thisAgent, neighborIndex, 6), REPLACE_PLEASE(thisAgent, neighborIndex, 7)];
            commonVertex2 = [REPLACE_PLEASE(thisAgent, neighborIndex, 8), REPLACE_PLEASE(thisAgent, neighborIndex, 9)];
            % Debugging
            %if(1)
            %    plot([commonVertex1(1) commonVertex2(1)] , [commonVertex1(2) commonVertex2(2)], 'Color', cellColors(thisCell,:));
            %end
            %[tmpdCidZi1, adjacentPartialDerivative1] = computePartialDerivativeCVT(thisCoord, curAdjCoord, commonVertex1, commonVertex2, mOmegai, denseXi, denseYi);
            [tmpdCidZi, adjacentPartialDerivative] = computePartialDerivativeCVTs(thisCoord, thisCVTCoord, curAdjCoord, curAdjCVTCoord, commonVertex1, commonVertex2, mOmegai);
            
            ownParitialDerivative = ownParitialDerivative + tmpdCidZi;
            % Update the desired information
            outList(thisAgent, neighborIndex, 1) = true; % Is neighbor ?
            outList(thisAgent, neighborIndex, 2) = adjacentPartialDerivative(1, 1);    % adjacentPartialDerivative dCix_dzjx
            outList(thisAgent, neighborIndex, 3) = adjacentPartialDerivative(1, 2);    % adjacentPartialDerivative dCix_dzjy
            outList(thisAgent, neighborIndex, 4) = adjacentPartialDerivative(2, 1);    % adjacentPartialDerivative dCiy_dzjx
            outList(thisAgent, neighborIndex, 5) = adjacentPartialDerivative(2, 2);    % adjacentPartialDerivative dCiy_dzjy
        end
        % Assign own partial deriveativ 
        outList(thisAgent, thisAgent, 2) = ownParitialDerivative(1, 1);    % adjacentPartialDerivative dCix_dzix
        outList(thisAgent, thisAgent, 3) = ownParitialDerivative(1, 2);    % adjacentPartialDerivative dCix_dziy
        outList(thisAgent, thisAgent, 4) = ownParitialDerivative(2, 1);    % adjacentPartialDerivative dCiy_dzix
        outList(thisAgent, thisAgent, 5) = ownParitialDerivative(2, 2);    % adjacentPartialDerivative dCiy_dziy
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

function [dCi_dzi_AdjacentJ, dCi_dzj] = computePartialDerivativeCVTs(thisCoord, thisCVT, adjCoord, adjCVT, vertex1, vertex2, mVi)
    v1x = vertex1(1);
    v1y = vertex1(2); 
    v2x = vertex2(1);
    v2y = vertex2(2);
    % Own info
    zix = thisCoord(1);
    ziy = thisCoord(2);
    cix = thisCVT(1);
    ciy = thisCVT(2);
    % Adj Info
    zjx = adjCoord(1);
    zjy = adjCoord(2);
    %cjx = adjCVT(1);
    %cjy = adjCVT(2);
    
    mViSquared = mVi^2;    
    
    %% Function definition for partial derivative
    % rho = @(x,y) 1;
    distanceZiZj = sqrt((zix - zjx)^2 + (ziy - zjy)^2);
    dq__dZix_n = @(qX, ziX) (qX - ziX) / distanceZiZj; %        ((zjX - ziX)/2 + (qX - (qXY + zjX)/2)) / distanceZiZj; 
    dq__dZiy_n = @(qY, ziY) (qY - ziY) / distanceZiZj; %        ((zjY - ziY)/2 + (qY - (ziY + zjY)/2)) /distanceZiZj; 
    dq__dZjx_n = @(qX, zjX) (zjX - qX) / distanceZiZj; %        ((zjX - ziX)/2 - (qX - (ziX + zjX)/2)) /distanceZiZj; 
    dq__dZjy_n = @(qY, zjY) (zjY - qY) / distanceZiZj; %        ((zjY - ziY)/2 - (qY - (ziY + zjY)/2))/distanceZiZj; 
    
    
    
    %% Integration parameter: t: 0 -> 1
    XtoT = @(t) v1x + (v2x - v1x)* t;
    YtoT = @(t) v1y + (v2y - v1y)* t;
    dqTodtParam = sqrt((v2x - v1x)^2 + (v2y - v1y)^2);  % Factorization of dq = param * dt for line integration
    
    %% dCi_dzix
    dCi_dzix_secondTermInt = integral(@(t) dq__dZix_n(XtoT(t), zix) * dqTodtParam , 0, 1);
    dCix_dzix = (integral(@(t) XtoT(t) .* dq__dZix_n(XtoT(t), zix) .* dqTodtParam, 0, 1) + dCi_dzix_secondTermInt * cix) / mVi;
    dCiy_dzix = (integral(@(t) YtoT(t) .* dq__dZix_n(XtoT(t), zix) .* dqTodtParam, 0, 1) + dCi_dzix_secondTermInt * ciy) / mVi;
    
    %% dCi_dziy
    dCi_dziy_secondTermInt = integral(@(t) dq__dZiy_n(YtoT(t), ziy) * dqTodtParam , 0, 1);
    dCix_dziy = (integral(@(t) XtoT(t) .* dq__dZiy_n(YtoT(t), ziy) .* dqTodtParam, 0, 1) + dCi_dziy_secondTermInt * cix) / mVi;
    dCiy_dziy = (integral(@(t) YtoT(t) .* dq__dZiy_n(YtoT(t), ziy) .* dqTodtParam, 0, 1) + dCi_dziy_secondTermInt * ciy) / mVi;
    
    %% dCi_dzjx
    dCi_dzjx_secondTermInt = integral(@(t) dq__dZjx_n(XtoT(t), zjx) * dqTodtParam , 0, 1 ) / mViSquared;
    dCix_dzjx = (integral(@(t) XtoT(t) .* dq__dZjx_n(XtoT(t), zjx) .* dqTodtParam, 0, 1) + dCi_dzjx_secondTermInt * cix) / mVi;
    dCiy_dzjx = (integral(@(t) YtoT(t) .* dq__dZjx_n(XtoT(t), zjx) .* dqTodtParam, 0, 1) + dCi_dzjx_secondTermInt * ciy) / mVi;
    
    %% dCi_dzjy
    dCi_dzjy_secondTermInt = integral(@(t) dq__dZjy_n(YtoT(t), zjy) * dqTodtParam , 0, 1 ) / mViSquared;
    dCix_dzjy =  (integral(@(t) XtoT(t) .* dq__dZjy_n(YtoT(t), zjy) .* dqTodtParam, 0, 1) + dCi_dzjy_secondTermInt * cix) / mVi;
    dCiy_dzjy =  (integral(@(t) YtoT(t) .* dq__dZjy_n(YtoT(t), zjy) .* dqTodtParam, 0, 1) + dCi_dzjy_secondTermInt * ciy) / mVi;
    
    %% Return
    dCi_dzi_AdjacentJ   = [ dCix_dzix, dCix_dziy; 
                            dCiy_dzix, dCiy_dziy];
    dCi_dzj             = [ dCix_dzjx, dCix_dzjy ;
                            dCiy_dzjx, dCiy_dzjy];   
end

%% Determine which CVTs are adjacent CVTs
function [adjacentList, AgentReport] = computeAdjacentList(centroidPos, vertexes, vertexHandler)
    % Check for all agent
    nAgent = numel(vertexHandler);
    % Return the result [adjacentList] with the following information - 9 columns 
    % CheckNeighborflag - [thisCVT: x y] - [neighborCVT: x y] - [vertex1: x y] - [vertex2: x y]
    
    % Declare how the structure looks like with the constant value
    % uninitialized.
    AgentReport(nAgent) = struct();
    % Tmp Variable to scan the collaborative agent
    for thisAgent = 1:nAgent
        % Instatinate struct data to carry all information of another agent
        AgentReport(thisAgent).ID = thisAgent;
        AgentReport(thisAgent).CVT.x = 0;
        AgentReport(thisAgent).CVT.y = 0;
        % Define how the info structure of friend agents looks like
%         for friendAgent = 1:nAgent
%             FriendAgentInfo(friendAgent).ID = friendAgent;
%             FriendAgentInfo(friendAgent).isVoronoiNeighbor = false;
%             FriendAgentInfo(friendAgent).CVT.x = 0;
%             FriendAgentInfo(friendAgent).CVT.y = 0;
%             FriendAgentInfo(friendAgent).CommonVertex.Vertex1.x = 0;
%             FriendAgentInfo(friendAgent).CommonVertex.Vertex1.y = 0;
%             FriendAgentInfo(friendAgent).CommonVertex.Vertex2.x = 0;
%             FriendAgentInfo(friendAgent).CommonVertex.Vertex2.y = 0;
%         end
%         AgentReport(thisAgent).FriendInfo = FriendAgentInfo;
    end
    
    adjacentList = zeros(nAgent,nAgent, 9);
    
    %% Start searching for common vertexes to determine neighbor agents
    for thisAgent = 1 : nAgent
        thisVertexList = vertexHandler{thisAgent}(1:end - 1);
        % Checking all another CVTs
        for friendAgent = 1: nAgent
              if(friendAgent ~= thisAgent)
                    nextVertexList = vertexHandler{friendAgent}(1:end-1); 
                       % Comparing these 2 arrays to find out whether it is the
                       % adjacent CVT or not  -> currentVertexes vs vertexBeingChecked
                       commonVertex = intersect(thisVertexList, nextVertexList);        % There are some bugs here. Same vertex coord but different index list. Most happens when the vexter lies on the boundary lines
                       nComVer = numel(commonVertex);
                       if(nComVer == 0)
                            % not adjacent
                            adjacentList(thisAgent, friendAgent, 1) = false;
                            AgentReport(thisAgent).FriendAgentInfo(friendAgent).isVoronoiNeighbor = false;
                       elseif(nComVer == 1)
                           disp("Warning: only 1 common vertex found");
                       elseif(nComVer == 2)
                           % Adjacent flag
                           adjacentList(thisAgent, friendAgent, 1) = true;
                           % Assign CVT coords
                           adjacentList(thisAgent, friendAgent,2) = centroidPos(thisAgent,1); % this Cx
                           adjacentList(thisAgent, friendAgent,3) = centroidPos(thisAgent,2); % this Cy
                           adjacentList(thisAgent, friendAgent,4) = centroidPos(friendAgent,1); % adj Cx
                           adjacentList(thisAgent, friendAgent,5) = centroidPos(friendAgent,2); % adj Cy
                           % Assign first common vertex
                           adjacentList(thisAgent, friendAgent,6) = vertexes(commonVertex(1),1); % v1x
                           adjacentList(thisAgent, friendAgent,7) = vertexes(commonVertex(1),2); % v1y
                           adjacentList(thisAgent, friendAgent,8) = vertexes(commonVertex(2),1); % v2x
                           adjacentList(thisAgent, friendAgent,9) = vertexes(commonVertex(2),2); % v2y 
                           
                           % Adjacent flag
                           AgentReport(thisAgent).CVT.x = centroidPos(thisAgent,1);
                           AgentReport(thisAgent).CVT.y = centroidPos(thisAgent,2);
                           AgentReport(thisAgent).FriendAgentInfo(friendAgent).isVoronoiNeighbor = true;
                           AgentReport(thisAgent).FriendAgentInfo(friendAgent).CVT.x = centroidPos(friendAgent,1);
                           AgentReport(thisAgent).FriendAgentInfo(friendAgent).CVT.x = centroidPos(friendAgent,2);
                           AgentReport(thisAgent).FriendAgentInfo(friendAgent).CommonVertex.Vertex1.x = vertexes(commonVertex(1),1);
                           AgentReport(thisAgent).FriendAgentInfo(friendAgent).CommonVertex.Vertex1.y = vertexes(commonVertex(1),2);
                           AgentReport(thisAgent).FriendAgentInfo(friendAgent).CommonVertex.Vertex2.x = vertexes(commonVertex(2),1);
                           AgentReport(thisAgent).FriendAgentInfo(friendAgent).CommonVertex.Vertex2.y = vertexes(commonVertex(2),2);
                       else
                           error("More than 3 vertexes for 1 common line detected");
                        end
              end
         end
    end
end

