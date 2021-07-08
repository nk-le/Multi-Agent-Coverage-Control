function  plotVertexes(centroidPos, vertexes, vertexHandler)
n = size(centroidPos,1);
figure;
hold on; grid on;
for i = 1:n
   name = sprintf('%d\n', i);
   tmp = vertexHandler(i);
   vId = tmp{1};
   thisVertex = vertexes(vId,:);
   plot(centroidPos(i,1), centroidPos(i,2),'-x');
   text(centroidPos(i,1), centroidPos(i,2), name, 'HorizontalAlignment','center', 'VerticalAlignment','bottom')
   scatter(thisVertex(:,1),thisVertex(:,2));
   text(thisVertex(:,1) + i * 10,thisVertex(:,2) + i * 10, name, 'HorizontalAlignment','center', 'VerticalAlignment','bottom')
end
end

function outlierVertexes(vertexes, vertexHandler)
    

end
