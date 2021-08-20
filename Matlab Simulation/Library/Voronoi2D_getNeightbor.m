function [out] = Voronoi2D_getNeightbor(points2d, vertexes, vertexIndexList)
    % n = amount of points
    % size(points) = [n, 2]
    assert(size(points2d, 2) == 2);
    nPoints = size(points2d, 1);
    
    %% Start searching for common vertexes to determine neighbor agents
    for thisAgent = 1 : nPoints
        % Checking all another CVTs
        out{thisAgent} = [];
        for friendAgent = 1: nPoints
              % First structure declaration so that the data is consistent
              if(friendAgent ~= thisAgent)  % Only consider the other agents, not itself
                       % Comparing these 2 arrays to find out whether it is the
                       % adjacent CVT or not  -> currentVertexes vs vertexBeingChecked
                       commonVertex = intersect(vertexIndexList{thisAgent}, vertexIndexList{friendAgent});       
                       nComVer = numel(commonVertex);
                       if(nComVer == 0)
                            % not adjacent
                       elseif(nComVer == 1)
                           disp("Warning: only 1 common vertex found");
                       elseif(nComVer == 2)
                            tmp = Struct_Neighbor_Info;
                            tmp.neighborID = friendAgent;
                            tmp.Neighbor_Coord_2d = points2d(friendAgent, :);
                            tmp.CommonVertex_2d_1 = vertexes(commonVertex(1),:);
                            tmp.CommonVertex_2d_2 = vertexes(commonVertex(2),:);
                            
                            % Attention: not yet optimized
                            % Currently this changes the size of variables.
                            out{thisAgent} = [out{thisAgent} tmp];
                       else
                           error("More than 3 vertexes for 1 common line detected");
                       end
              end
         end
    end
end
