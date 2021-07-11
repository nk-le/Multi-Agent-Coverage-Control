%% This function returns ...
%
function [Info] = ComputeVoronoiProperty(pointCoord, CVTCoord, verList, verPtr)
    nAgent = numel(verPtr);
    
    %% Assign the computed Voronoi and instantiate an Dat Structure that contains all neccessary Coverage Information
    Info.Common.nAgent = nAgent;
    Info.Common.VoronoiVertexes = verList;
    AgentReport(nAgent) = struct();
    % Tmp Variable to scan the collaborative agent
    for thisAgent = 1:nAgent
        % Instatinate struct data to carry all information of another agent
        AgentReport(thisAgent).MyInfo.Coord.x = pointCoord(thisAgent, 1);
        AgentReport(thisAgent).MyInfo.Coord.y = pointCoord(thisAgent, 2);
        AgentReport(thisAgent).MyInfo.VoronoiInfo.CVTCoord.x = CVTCoord(thisAgent, 1);
        AgentReport(thisAgent).MyInfo.VoronoiInfo.CVTCoord.y = CVTCoord(thisAgent, 2);
        AgentReport(thisAgent).MyInfo.VoronoiInfo.VertexesID = verPtr{thisAgent}(1:end-1); % The built in function of matlab duplicaes so we eliminate
        AgentReport(thisAgent).MyInfo.VoronoiInfo.VertexesCoord.x = verList(verPtr{thisAgent},1);
        AgentReport(thisAgent).MyInfo.VoronoiInfo.VertexesCoord.y = verList(verPtr{thisAgent},2);
    end 
    Info.AgentReport = AgentReport;
    AgentReport = []; % Delete this to avoid misused data structure, from now we only use the Info structure
    
    %% Append the Adjacent Information into the Info Data Structure
    Info = AppendAdjacentAgentInfo(Info);
    for thisAgent = 1:nAgent
        PartialCVTComputation_Struct.my.Coord = Info.AgentReport(thisAgent).MyInfo.Coord;
        PartialCVTComputation_Struct.my.CVTCoord =  Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.CVTCoord;
        % Compute this one first to reduce redundant computation 
        PartialCVTComputation_Struct.my.PartionMass = ComputePartitionMass(Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.VertexesCoord);
        PartialCVTComputation_Struct.friend.Coord.x = [];
        PartialCVTComputation_Struct.friend.Coord.y = [];
        PartialCVTComputation_Struct.Common.Vertex1.x = [];
        PartialCVTComputation_Struct.Common.Vertex1.y = [];
        PartialCVTComputation_Struct.Common.Vertex2.x = [];
        PartialCVTComputation_Struct.Common.Vertex2.y = [];

        %% Scan over the friend list of each agent to compute the Voronoi properties
        ownParitialDerivative = zeros(2,2);
        for friendAgent = 1: nAgent
            isNeighbor = (friendAgent ~= thisAgent) && (Info.AgentReport(thisAgent).FriendAgentInfo(friendAgent).isVoronoiNeighbor);
            if(isNeighbor)                
                PartialCVTComputation_Struct.friend.Coord = Info.AgentReport(thisAgent).FriendAgentInfo(friendAgent).Coord;
                %PartialCVTComputation_Struct.friend.CVTCoord = Info.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.CVTCoord;
                PartialCVTComputation_Struct.Common.Vertex1 = Info.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.CommonVertex.Vertex1;
                PartialCVTComputation_Struct.Common.Vertex2 = Info.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.CommonVertex.Vertex2;
            
                [tmpdCidZi, adjacentPartialDerivative] = ComputePartialDerivativeCVTs(PartialCVTComputation_Struct);
                ownParitialDerivative = ownParitialDerivative + tmpdCidZi;
                Info.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.partialCVT.dCx_dVMFriend_x =  adjacentPartialDerivative(1, 1);
                Info.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.partialCVT.dCx_dVMFriend_y =  adjacentPartialDerivative(1, 2);
                Info.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.partialCVT.dCy_dVMFriend_x =  adjacentPartialDerivative(2, 1);
                Info.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.partialCVT.dCy_dVMFriend_y =  adjacentPartialDerivative(2, 2);
            end 
        end

        Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCx_dVMx = ownParitialDerivative(1, 1);
        Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCx_dVMy = ownParitialDerivative(1, 2);
        Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCy_dVMx = ownParitialDerivative(2, 1);
        Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.partialCVT.dCy_dVMy = ownParitialDerivative(2, 2);
    end    
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

function [dCi_dzi_AdjacentJ, dCi_dzj] = ComputePartialDerivativeCVTs(PartialCVTComputation_Struct)
    % Parse the struct
    mVi = PartialCVTComputation_Struct.my.PartionMass;
    thisCoord = PartialCVTComputation_Struct.my.Coord;
    adjCoord = PartialCVTComputation_Struct.friend.Coord;
    thisCVT = PartialCVTComputation_Struct.my.CVTCoord;
    vertex1 = PartialCVTComputation_Struct.Common.Vertex1;
    vertex2 = PartialCVTComputation_Struct.Common.Vertex2;
    

    % Computation
    mViSquared = mVi^2;    
    
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
    dCix_dzix = (integral(@(t) XtoT(t) .* dq__dZix_n(XtoT(t), thisCoord.x) .* dqTodtParam, 0, 1) + dCi_dzix_secondTermInt * thisCVT.x) / mVi;
    dCiy_dzix = (integral(@(t) YtoT(t) .* dq__dZix_n(XtoT(t), thisCoord.x) .* dqTodtParam, 0, 1) + dCi_dzix_secondTermInt * thisCVT.y) / mVi;
    
    %% dCi_dziy
    dCi_dziy_secondTermInt = integral(@(t) dq__dZiy_n(YtoT(t), thisCoord.y) * dqTodtParam , 0, 1);
    dCix_dziy = (integral(@(t) XtoT(t) .* dq__dZiy_n(YtoT(t), thisCoord.y) .* dqTodtParam, 0, 1) + dCi_dziy_secondTermInt * thisCVT.x) / mVi;
    dCiy_dziy = (integral(@(t) YtoT(t) .* dq__dZiy_n(YtoT(t), thisCoord.y) .* dqTodtParam, 0, 1) + dCi_dziy_secondTermInt * thisCVT.y) / mVi;
    
    %% dCi_dzjx
    dCi_dzjx_secondTermInt = integral(@(t) dq__dZjx_n(XtoT(t), adjCoord.x) * dqTodtParam , 0, 1 );
    dCix_dzjx = (integral(@(t) XtoT(t) .* dq__dZjx_n(XtoT(t), adjCoord.x) .* dqTodtParam, 0, 1) + dCi_dzjx_secondTermInt * thisCVT.x) / mVi;
    dCiy_dzjx = (integral(@(t) YtoT(t) .* dq__dZjx_n(XtoT(t), adjCoord.x) .* dqTodtParam, 0, 1) + dCi_dzjx_secondTermInt * thisCVT.y) / mVi;
    
    %% dCi_dzjy
    dCi_dzjy_secondTermInt = integral(@(t) dq__dZjy_n(YtoT(t), adjCoord.y) * dqTodtParam , 0, 1 );
    dCix_dzjy =  (integral(@(t) XtoT(t) .* dq__dZjy_n(YtoT(t), adjCoord.y) .* dqTodtParam, 0, 1) + dCi_dzjy_secondTermInt * thisCVT.x) / mVi;
    dCiy_dzjy =  (integral(@(t) YtoT(t) .* dq__dZjy_n(YtoT(t), adjCoord.y) .* dqTodtParam, 0, 1) + dCi_dzjy_secondTermInt * thisCVT.y) / mVi;
    
    %% Return
    dCi_dzi_AdjacentJ   = [ dCix_dzix, dCix_dziy; 
                            dCiy_dzix, dCiy_dziy];
    dCi_dzj             = [ dCix_dzjx, dCix_dzjy ;
                            dCiy_dzjx, dCiy_dzjy];   
end


%% Determine which CVTs are adjacent CVTs
function [InfoStruct] = AppendAdjacentAgentInfo(InfoStruct)
    %% Start searching for common vertexes to determine neighbor agents
    for thisAgent = 1 : InfoStruct.Common.nAgent
        % Checking all another CVTs
        for friendAgent = 1: InfoStruct.Common.nAgent
              % First structure declaration so that the data is consistent
              InfoStruct.AgentReport(thisAgent).FriendAgentInfo(friendAgent).isVoronoiNeighbor = false;
              if(friendAgent ~= thisAgent)  % Only consider the other agents, not itself
                       % Comparing these 2 arrays to find out whether it is the
                       % adjacent CVT or not  -> currentVertexes vs vertexBeingChecked
                       commonVertex = intersect(InfoStruct.AgentReport(thisAgent).MyInfo.VoronoiInfo.VertexesID,...
                                                InfoStruct.AgentReport(friendAgent).MyInfo.VoronoiInfo.VertexesID);       
                       nComVer = numel(commonVertex);
                       if(nComVer == 0)
                            % not adjacent
                       elseif(nComVer == 1)
                           disp("Warning: only 1 common vertex found");
                       elseif(nComVer == 2)
                           InfoStruct.AgentReport(thisAgent).FriendAgentInfo(friendAgent).Coord = InfoStruct.AgentReport(friendAgent).MyInfo.Coord;
                           InfoStruct.AgentReport(thisAgent).FriendAgentInfo(friendAgent).isVoronoiNeighbor = true;
                           InfoStruct.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.CVTCoord = InfoStruct.AgentReport(friendAgent).MyInfo.VoronoiInfo.CVTCoord;
                           InfoStruct.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.CommonVertex.Vertex1.x = InfoStruct.Common.VoronoiVertexes(commonVertex(1),1);
                           InfoStruct.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.CommonVertex.Vertex1.y = InfoStruct.Common.VoronoiVertexes(commonVertex(1),2);
                           InfoStruct.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.CommonVertex.Vertex2.x = InfoStruct.Common.VoronoiVertexes(commonVertex(2),1);
                           InfoStruct.AgentReport(thisAgent).FriendAgentInfo(friendAgent).VoronoiInfo.CommonVertex.Vertex2.y = InfoStruct.Common.VoronoiVertexes(commonVertex(2),2);
                       else
                           error("More than 3 vertexes for 1 common line detected");
                       end
              end
         end
    end
end
