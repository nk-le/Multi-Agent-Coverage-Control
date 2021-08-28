function [adjacentTable] = Voronoi2D_getNeightbor(points2d, vertexes, vertexIndexList, IDList)
    
    % n = amount of points
    % size(points) = [n, 2]
    assert(size(points2d, 2) == 2);
    nPoints = size(points2d, 1);
    adjacentTable = cell(nPoints, 1);
    if(~exist('IDList','var'))
        IDList = 1:nPoints;
    end
    
    %% Start searching for common vertexes to determine neighbor agents
    for thisAgentIndex = 1 : nPoints
        % Checking all another CVTs
        adjacentTable{thisAgentIndex} = cell(nPoints, 1);
        for friendAgentIndex = 1: nPoints
              % First structure declaration as no neighbor so that the data is consistent
              adjacentTable{thisAgentIndex}{friendAgentIndex} = [];         
              if(friendAgentIndex ~= thisAgentIndex)  % Only consider the other agents, not itself
                       % Comparing these 2 arrays to find out whether it is the
                       % adjacent CVT or not  -> currentVertexes vs vertexBeingChecked
                       commonVertex = intersect(vertexIndexList{thisAgentIndex}, vertexIndexList{friendAgentIndex});       
                       nComVer = numel(commonVertex);
                       if(nComVer == 0)
                            % not adjacent
                       elseif(nComVer == 1)
                           disp("Warning: only 1 common vertex found");
                       elseif(nComVer == 2)
                            tmp = Struct_Neighbor_Coordinates(IDList(thisAgentIndex), IDList(friendAgentIndex), ...
                                                               points2d(friendAgentIndex, :)', ...
                                                               vertexes(commonVertex(1),:)', ...
                                                               vertexes(commonVertex(2),:)');
                           
                            adjacentTable{thisAgentIndex}{friendAgentIndex} = tmp;
                       else
                           error("More than 3 vertexes for 1 common line detected");
                       end
              end
        end
    end
    
    %% Clean the non existing information
    for i = 1: nPoints
           adjacentTable{i} = adjacentTable{i}(~cellfun(@isempty,adjacentTable{i}));
    end
end
