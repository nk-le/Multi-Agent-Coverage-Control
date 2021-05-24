function [ax] = Plot_Cell(trueCoord, CVTCoord, verList, verPtr)
global cellColors;
nCell = size(trueCoord,1);
maxX = 100;
maxY = 150;
bndVertexes = [0, 0; 0,maxY; maxX,maxY; maxX, 0; 0, 0];

%% Visualization
ax = figure()
hold on; grid on; axis equal;
for i = 1: size(bndVertexes,1)-1                
   plot([bndVertexes(i,1) bndVertexes(i+1,1)],[bndVertexes(i,2) bndVertexes(i+1,2)], '-r', 'LineWidth',4);                    
end   


%% Get Voronoi centroids
for i = 1:nCell
    plot(trueCoord(i,1), trueCoord(i,2), 'x', 'Color', cellColors(i,:), 'Linewidth', 2);
    plot(CVTCoord(i,1), CVTCoord(i,2), '*', 'Color', cellColors(i,:), 'Linewidth', 1);
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

