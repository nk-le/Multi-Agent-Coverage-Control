function outVHandler = outlierVertexList(vertexes, vertexHandler, xRange, yRange)
nVer = size(vertexes,1);
%% Clean the unused vertexes
feasibleFlag = zeros(nVer, 1);
for i = 1:nVer
    feasibleFlag(i) = checkInRange2D(vertexes(i,1), vertexes(i,2), xRange(1), xRange(2), yRange(1), yRange(2),0.5);   
end
% Create a flag List that indicates duplicated values
dupFlag = zeros(nVer, 1);
dupID = zeros(nVer,2);
for i = 1:nVer-1
    % Check if the point is in the feasible range
    if(feasibleFlag(i))
        thisV = vertexes(i,:);
        % COmpare with each other vertexes to outlier
        for j = i+1:nVer
            % Check the compared vertex is feasible
            if(feasibleFlag(j))
               thatV = vertexes(j,:);
               % Check if they are duplicated
               tol = 1/(1e10);
               if(checkDup2D(thisV, thatV, tol))
                    % Assigned a unique "ID" for the duplicated flag
                    % disp([i,j])
                    dupID(j, :) = [i, j];
                    dupFlag(i) = i + j;
                    dupFlag(j) = i + j;
               end
            end
        end
    end
end

dupID( ~any(dupID,2), : ) = [];
outVHandler = replaceIndex(vertexHandler, dupID);
%disp(outVHandler);
end

function flag = checkInRange2D(x, y, xMin, xMax, yMin, yMax, tol)
    xMin = xMin - tol;
    xMax = xMax + tol;
    yMin = yMin - tol;
    yMax = yMax + tol;
    flag = (x >= xMin) && (x <= xMax) && (y >= yMin) && (y <= yMax); 
    %if(~flag)
    %       disp([x,y, xMin, xMax, yMin, yMax]) 
    %end
end

function isDup = checkDup2D(p1, p2, tol)
    isDup = (norm(p1-p2) < tol); 
end

function out = replaceIndex(verOld, dupID)
    n = size(verOld,1);
    for i = 1:n
       verArr = verOld{i};
       newID = dupID(:,1);
       oldID = dupID(:,2);
       verArrReplaced = changem(verArr, newID, oldID);
       verArrReplacedUnique = [DedupSequence(verArrReplaced(1:end-1)) verArrReplaced(end)];
       verOut{i} = verArrReplacedUnique;
    end
    out = verOut';
end

function [uniqueSequence] = DedupSequence (seq)
    % Eliminate sequentially repeated rows
    
    % Create row vector for diff (must transpose if given a column vector)
    if size(seq,1) > 1
        seqCopy = seq(:,1)'; 
    else
        seqCopy = seq;
    end
    uniqueSequence = seq([true, diff(seqCopy)~=0]);
end
