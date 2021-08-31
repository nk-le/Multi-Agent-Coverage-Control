addpath(genpath('./Library'));

cellColors = cool(CONST_PARAM.N_AGENT);    
env = MultiRobotEnv(CONST_PARAM.N_AGENT);
iter = logger.curCnt;
spX = logger.CVT(:,1,:);
spY = logger.CVT(:,2,:);
vmX = logger.PoseVM(:,1,:);
vmY = logger.PoseVM(:,2,:);
poseX =  logger.PoseAgent(:,1,:);
poseY =  logger.PoseAgent(:,2,:);
poseTheta =  logger.PoseAgent(:,3,:);
bndVertexes = logger.bndVertexes;



poseInit = zeros(3, CONST_PARAM.N_AGENT);
env((1:CONST_PARAM.N_AGENT), poseInit);
hold on; grid on; %axis equal

% Plot Boundaries
% for i = 1: size(bndVertexes,1)-1                
%    plot([bndVertexes(i,1) bndVertexes(i+1,1)],[bndVertexes(i,2) bndVertexes(i+1,2)], '-r', 'LineWidth',2);
% end
xrange = max(bndVertexes(:,1));
yrange = max(bndVertexes(:,2));
offset = 20;
xlim([0 - offset, xrange + offset]);
ylim([0 - offset, yrange + offset]);
str =  "Coverage Control of Multi-Unicycle System";
str = str + newline + "x: WMR's Virtual Mass, o: Centroid of Voronoi Partition";
title(str);

vmPlotHandle = [];
spPlotHandle = [];
showColorPlot = true;

for loopCnt = 1:iter    
    if(loopCnt == 1) % Plot only once
            %figure(2);
            %hold on;  grid on;
            % Boundaries
            for i = 1: size(bndVertexes,1)-1                
               plot([bndVertexes(i,1) bndVertexes(i+1,1)],[bndVertexes(i,2) bndVertexes(i+1,2)], '-r', 'LineWidth',4);                    
            end   
            % Color Patch
            verCellHandle = zeros(CONST_PARAM.N_AGENT,1);
            cellColors = cool(CONST_PARAM.N_AGENT);         
            if(showColorPlot == true)
                vmPlotColorHandle = [];
                spPlotColorHandle = [];
                for i = 1:CONST_PARAM.N_AGENT % color according to
                    verCellHandle(i) = patch(spX(1,i),spY(2,i), cellColors(i,:)); % use color i  -- no robot assigned yet
                    vmHandle =  plot(vmX(i,loopCnt), vmY(i,loopCnt),'x','Color', cellColors(i,:), 'LineWidth',2);
                    spHandle =  plot(spX(i,loopCnt), spY(i,loopCnt), '-o','Color', cellColors(i,:), 'LineWidth',2);   
                    vmPlotColorHandle = [vmPlotColorHandle vmHandle];
                    spPlotColorHandle = [spPlotColorHandle spHandle];
                end
            end
     end
        
    if(mod(loopCnt-1, 5) == 0)
        % Update the position in engine
        for i = 1:CONST_PARAM.N_AGENT
            pose(:,i) = [poseX(i, loopCnt), poseY(i, loopCnt), poseTheta(i, loopCnt)];
        end
        env((1:CONST_PARAM.N_AGENT), pose);
        
        if(showColorPlot == true)
            %figure(2);
            %hold on; grid on; axis equal
            xlim([0 - offset, xrange + offset]);
            ylim([0 - offset, yrange + offset]);
            str =  "Voronoi Tessellation";
            str = str + newline + "x: WMR's Virtual Mass, o: Centroid of Voronoi Partition";
            title(str);
            for i = 1:CONST_PARAM.N_AGENT % update Voronoi cells
               set(spPlotColorHandle(i),'XData', spX(i,loopCnt) ,'YData', spY(i,loopCnt)); %plot current position
               set(vmPlotColorHandle(i),'XData', vmX(i,loopCnt) ,'YData', vmY(i,loopCnt)); 
               %set(verCellHandle(i), 'XData',com.v(com.c{i},1),'YData',com.v(com.c{i},2));
            end
        end
    end
end
