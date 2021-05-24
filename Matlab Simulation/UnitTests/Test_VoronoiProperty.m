close all;
nCell = 6;
cellColors = spring(nCell);
centerX = 50;
centerY = 50;
rXY = 10;
startX = centerX + rXY * cos(0 : 2*pi/nCell : 2*pi);
startY = centerY + rXY * sin(0 : 2*pi/nCell : 2*pi);
Pose = [startX', startY'];

CVTs = zeros(nCell, 2);
offset = 20;
maxX = 100;
maxY = 150;

A = [-1 , 0; 1 , 0; 0 , 1; 0 , -1];
b = [0, maxX, maxY, 0];
bndCoeff = [A, b'];
bndVertexes = [0, 0; 0,maxY; maxX,maxY; maxX, 0; 0, 0];

%% Visualization
figure()
hold on; grid on; axis equal;
for i = 1: size(bndVertexes,1)-1                
   plot([bndVertexes(i,1) bndVertexes(i+1,1)],[bndVertexes(i,2) bndVertexes(i+1,2)], '-r', 'LineWidth',4);                    
end   


%% Get Voronoi centroids
[vertexes,vertexHandler]= Function_VoronoiBounded(Pose(:,1), Pose(:,2), bndVertexes);

for i = 1:nCell
    [cx,cy] = Function_PolyCentroid(vertexes(vertexHandler{i},1),vertexes(vertexHandler{i},2));
    cx = min(max(bndVertexes(:,1)),max(0, cx));
    cy = min(max(bndVertexes(:,2)),max(0, cy));
    if ~isnan(cx) && inpolygon(cx,cy, bndVertexes(:,1), bndVertexes(:,2))
        CVTs(i,1) = cx;  %don't update if goal is outside the polygon
        CVTs(i,2) = cy;
        plot(Pose(i,1), Pose(i,2), 'x', 'Color', cellColors(i,:));
        plot(cx, cy, '*', 'Color', cellColors(i,:));
    end
end 

%% Plot the vertexes
i = 1;
while i < size(vertexHandler,1)
    tmp = vertexHandler{i};
    if(vertexes(tmp,1) >= maxX | vertexes(tmp,1) <= 0 | vertexes(tmp,2) >= maxY | vertexes(tmp,2) <= 0 | isnan(vertexes(tmp,1)) | isnan(vertexes(tmp,2)))
        vertexHandler{i} = [];
    else
        plot(vertexes(tmp,1),vertexes(tmp,2), 'o')
    end
    i = i + 1;
end

%% Update Voronoi property
[outList, adjacentList] = ComputeVoronoiProperty(CVTs, vertexes, vertexHandler);




disp(outList);

%figure()
%plot()
%fo


