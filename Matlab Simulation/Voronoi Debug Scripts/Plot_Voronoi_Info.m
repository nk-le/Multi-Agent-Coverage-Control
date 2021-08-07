function Plot_Voronoi_Info(Info, maxX, maxY)

cellColors = cool(Info.Common.nAgent);

bndVertexes = [0, 0; 0,maxY; maxX,maxY; maxX, 0; 0, 0];
ax = figure()
hold on; grid on; axis equal;
for i = 1: size(bndVertexes,1)-1                
   plot([bndVertexes(i,1) bndVertexes(i+1,1)],[bndVertexes(i,2) bndVertexes(i+1,2)], '-r', 'LineWidth',4);                    
end   

for thisAgent = 1:Info.Common.nAgent
    thisAgentCoord = [Info.AgentReport(thisAgent).MyInfo.Coord.x Info.AgentReport(thisAgent).MyInfo.Coord.y];
    thisAgentCVT = [Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.CVTCoord.x Info.AgentReport(thisAgent).MyInfo.VoronoiInfo.CVTCoord.y];
    
    text(thisAgentCoord(1), thisAgentCoord(2), [num2str(thisAgent)]);
    plot(thisAgentCoord(1), thisAgentCoord(2), 'x', 'Color', cellColors(thisAgent,:), 'Linewidth', 2);
    plot(thisAgentCVT(1), thisAgentCVT(2), '*', 'Color', cellColors(thisAgent,:), 'Linewidth', 1);

    % Scan over the adjacent list
    for friendAgent = 1:Info.Common.nAgent
        friendInfo = Info.AgentReport(thisAgent).FriendAgentInfo(friendAgent);
        if(friendInfo.isVoronoiNeighbor)
           commonVertex1 = [friendInfo.VoronoiInfo.CommonVertex.Vertex1.x     friendInfo.VoronoiInfo.CommonVertex.Vertex1.y];
           commonVertex2 = [friendInfo.VoronoiInfo.CommonVertex.Vertex2.x     friendInfo.VoronoiInfo.CommonVertex.Vertex2.y];
           % Plot the common line by two colors to determine the neighbor
           % easily
           midPoint = [(commonVertex1(1) + commonVertex2(1)) (commonVertex1(2) + commonVertex2(2))]/2;
           plot([commonVertex1(1) midPoint(1)] , [commonVertex1(2) midPoint(2)], 'Color', cellColors(thisAgent,:));
           plot([midPoint(1) commonVertex2(1)] , [midPoint(2) commonVertex2(2)], 'Color', cellColors(friendAgent,:));
        end
    end
end     
end

