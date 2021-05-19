len = logger.curCnt;

env = MultiRobotEnv(amountAgent);

spX = logger.CVT(:,1,:);
spY = logger.CVT(:,2,:);
vmX = logger.PoseVM(:,1,:);
vmY = logger.PoseVM(:,2,:);

for i  = 1:amountAgent
    pose(:,i) = bot_handle(i).pose;
end
env((1:amountAgent), pose);
hold on; grid on; axis equal

% Plot Boundaries
for i = 1: size(worldVertexes,1)-1                
   plot([worldVertexes(i,1) worldVertexes(i+1,1)],[worldVertexes(i,2) worldVertexes(i+1,2)], '-r', 'LineWidth',2);                    
end
xlim([0 - offset, xrange + offset]);
ylim([0 - offset, yrange + offset]);
str =  "Coverage Control of Multi-Unicycle System";
str = str + newline + "x: WMR's Virtual Mass, o: Centroid of Voronoi Partition";
title(str);

vmPlotHandle = [];
spPlotHandle = [];

for i = 1:amountAgent    
   vmHandle =  plot(vmX(i,loopCnt), vmY(i,loopCnt), '-x', 'Color', botColors(i,:), 'LineWidth',2);
   spHandle =  plot(sp(i,1,loopCnt), sp(i,2,loopCnt), '-o','Color', botColors(i,:), 'LineWidth',2);   
   vmPlotHandle = [vmPlotHandle vmHandle];
   spPlotHandle = [spPlotHandle spHandle];
end

for loopCnt = 1:len    
    if(loopCnt == 1) % Plot only once
            figure(2);
            hold on;  grid on;
            
            % Boundaries
            for i = 1: size(worldVertexes,1)-1                
               plot([worldVertexes(i,1) worldVertexes(i+1,1)],[worldVertexes(i,2) worldVertexes(i+1,2)], '-r', 'LineWidth',4);                    
            end   
            % Color Patch
            verCellHandle = zeros(amountAgent,1);
            cellColors = cool(amountAgent);         
            if(showColorPlot == true)
                vmPlotColorHandle = [];
                spPlotColorHandle = [];
                for i = 1:amountAgent % color according to
                    verCellHandle(i) = patch(sp(1,i),sp(2,i), cellColors(i,:)); % use color i  -- no robot assigned yet
                    vmHandle =  plot(vmX(i,loopCnt), vmY(i,loopCnt),'x','Color', botColors(i,:), 'LineWidth',2);
                    spHandle =  plot(spX(i,loopCnt), spY(i,loopCnt), '-o','Color', botColors(i,:), 'LineWidth',2);   
                    vmPlotColorHandle = [vmPlotColorHandle vmHandle];
                    spPlotColorHandle = [spPlotColorHandle spHandle];
                end
            end
     end
        
    if(mod(loopCnt-1, 20) == 0)
        %Visualitation   
        env((1:amountAgent), pose);
        if(showColorPlot == true)
            figure(2);
            hold on; grid on; axis equal
            xlim([0 - offset, xrange + offset]);
            ylim([0 - offset, yrange + offset]);
            str =  "Voronoi Tessellation";
            str = str + newline + "x: WMR's Virtual Mass, o: Centroid of Voronoi Partition";
            title(str);
            for i = 1:amountAgent % update Voronoi cells
               set(spPlotColorHandle(i),'XData', spX(i,loopCnt) ,'YData', spY(i,loopCnt)); %plot current position
               set(vmPlotColorHandle(i),'XData', vmX(i,loopCnt) ,'YData', vmY(i,loopCnt)); 
               %set(verCellHandle(i), 'XData',com.v(com.c{i},1),'YData',com.v(com.c{i},2));
            end
        end
    end
end
