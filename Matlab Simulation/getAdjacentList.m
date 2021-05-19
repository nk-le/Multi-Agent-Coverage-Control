% Input: vertex of a voronoi cell of all agents
% vertexIndex list

function [adjacentList] = getAdjacentList(vertexes, vertexHandler, vmPos)
    % Check for all agent
    nAgent = numel(vertexHandler);
    adjacentList = zeros(nAgent,nAgent,7);
    for i = 1 : nAgent
        thisID = vertexHandler{i}(1:end - 1);
        % Checking all another agent
        for j = 1: nAgent
              if(j ~= i)
                    cnt = 0;
                    nextID = vertexHandler{j}(1:end-1); 
                       % Comparing these 2 arrays to find out whether it is the
                       % adjacent agent or not  -> currentVertexes vs vertexBeingChecked
                       isNeighbor = false;
                       for l = 1 : numel(thisID)
                          for k = 1 : numel(nextID)
                             tol = 0.00000001;
                             workaroundFlag = (abs(vertexes(thisID(l),1) - vertexes(nextID(k),1)) < tol) && (abs(vertexes(thisID(l),2) - vertexes(nextID(k),2)) < tol); % Observe identical vertexes -> work around with this condition
                             if ((thisID(l) == nextID(k)) || workaroundFlag(1))   
                                % Neighbor flag
                                isNeighbor = true;
                                % Flag to say this is neighbot
                                adjacentList(i, j, 1) = true;
                                % Put Neighbor agent's Position here
                                adjacentList(i, j, 2) = vmPos(j,1);   % X
                                adjacentList(i, j, 3) = vmPos(j,2);   % Y
                                % Counter to control the number of vertexes
                                cnt = cnt + 1;
                                if cnt == 1
                                    adjacentList(i, j, 4) = vertexes(thisID(l),1); % First vertex
                                    adjacentList(i, j, 5) = vertexes(thisID(l),2); % First vertex
                                elseif cnt == 2
                                    adjacentList(i, j, 6) = vertexes(thisID(l),1); % Second vertex
                                    adjacentList(i, j, 7) = vertexes(thisID(l),2); % Second vertex  
                                elseif cnt == 3
                                    error("3 vertexes for 1 line detected");
                                end
                             end
                          end
                       end
                  if(isNeighbor == false)
                      adjacentList(i, j, 1) = false;
                      adjacentList(i, j, 2:end) = 0;
                  elseif cnt ~= 2
                      error("Not enough vertexes");
                  end
              end
         end
    end
    
    
    
    
    
    
    
    
    
    
end

