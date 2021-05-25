function [ax] = Plot_Cell(pointCoord, CVTCoord, verList, verPtr, adjacentList)
nCell = size(pointCoord,1);
cellColors = cool(nCell);
maxX = 800;
maxY = 600;
bndVertexes = [0, 0; 0,maxY; maxX,maxY; maxX, 0; 0, 0];

%% Visualization
ax = figure()
hold on; grid on; axis equal;
for i = 1: size(bndVertexes,1)-1                
   plot([bndVertexes(i,1) bndVertexes(i+1,1)],[bndVertexes(i,2) bndVertexes(i+1,2)], '-r', 'LineWidth',4);                    
end   


%% Get Voronoi centroids
% Plot the True Position, CVT and boundary lines of each partition
for i = 1:nCell
    plot(pointCoord(i,1), pointCoord(i,2), 'x', 'Color', cellColors(i,:), 'Linewidth', 2);
    text(pointCoord(i,1),pointCoord(i,2),[num2str(i)]);
    plot(CVTCoord(i,1), CVTCoord(i,2), '*', 'Color', cellColors(i,:), 'Linewidth', 1);
    % Scan over the adjacent list
    adjFlag = adjacentList(i,:,1);
    thisAdjList = find(adjFlag);
    for nextAdj = 1: numel(thisAdjList)
       adjIndex = thisAdjList(nextAdj);
       commonVertex1 = [adjacentList(i,adjIndex,6) adjacentList(i,adjIndex,7)];
       commonVertex2 = [adjacentList(i,adjIndex,8) adjacentList(i,adjIndex,9)];
       plot([commonVertex1(1) commonVertex2(1)] , [commonVertex1(2) commonVertex2(2)], 'Color', cellColors(i,:));
    end
end     

%% Plot the verList
i = 1;
while i < size(verPtr,1)
    tmp = verPtr{i};
    if(verList(tmp,1) >= maxX | verList(tmp,1) <= 0 | verList(tmp,2) >= maxY | verList(tmp,2) <= 0 | isnan(verList(tmp,1)) | isnan(verList(tmp,2)))
        verPtr{i} = [];
    else
        plot(verList(tmp,1),verList(tmp,2), 'o')
    end
    i = i + 1;
end



%% Update Voronoi property

end

