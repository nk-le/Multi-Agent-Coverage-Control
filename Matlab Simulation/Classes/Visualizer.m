classdef Visualizer < handle
    %VISUALIZES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        verCellHandle
        posPathHandle
        genPathHandle
        
        genHandle
        goalHandle
        dirHandle
        
        titleHandle
        figHandle
        
        botColors 
        recordFlag
    end
    
    methods
        function obj = Visualizer(n)
            obj.figHandle = figure("Name", "Multi-Agent Coverage Control", 'Position', get(0, 'Screensize'));
            
            poseGen_3 = zeros(n, 3);
            posePos_3 = zeros(n, 3);
            poseCVT_3 = zeros(n, 3);
            
            obj.verCellHandle = cell(n,1);
            obj.genPathHandle = cell(n,1);    
            obj.posPathHandle = cell(n,1);

            obj.posPathHandle = cell(n,1);
            obj.goalHandle = cell(n,1);
            obj.genHandle = cell(n,1);
            obj.dirHandle = cell(n,1);
            obj.botColors = cool(n);
            for i = 1:n % color according to
                obj.posPathHandle{i} = plot(posePos_3(i,1), posePos_3(i,2), 'color',obj.botColors(i,:)*.8, 'linewidth',2, 'LineStyle', '-');  
                hold on; 

                obj.posPathHandle{i}.Color(4) = 1;
                obj.verCellHandle{i} = patch(poseGen_3(i,1), poseGen_3(i,2),obj.botColors(i,:)); 
                obj.verCellHandle{i}.FaceAlpha = 0.3;
                obj.genPathHandle{i}  = plot(poseGen_3(i,1), poseGen_3(i,2), 'color',obj.botColors(i,:)*.8, 'linewidth',2, 'LineStyle', '-');
                obj.genPathHandle{i}.Color(4) = 1;
                obj.dirHandle{i} = quiver(poseGen_3(i,1), poseGen_3(i,2), 0, 0, 'color', obj.botColors(i,:), 'Marker','*','LineWidth',2, 'MaxHeadSize', 2);
                obj.goalHandle{i} = plot(poseCVT_3(i,1), poseCVT_3(i,2),'o','linewidth',2, 'color',obj.botColors(i,:)*.8);
                obj.genHandle{i} = plot(poseGen_3(i,1), poseGen_3(i,2),'+','linewidth',2, 'color',obj.botColors(i,:)*.8);
            end
            obj.titleHandle = title(['+ = Robots, o = Goals', num2str(0)]);
            
            grid on; grid minor; axis equal;
            xlabel("X Coordinate");
            ylabel("Y Coordinate");
            set(gca,'FontSize',20);            
        end
       
        function set_boundary(obj, regionConfig)
            xrange = max(regionConfig.BOUNDARIES_VERTEXES(:,1));
            yrange = max(regionConfig.BOUNDARIES_VERTEXES(:,2));
            offset = 100;
            xlim([0 - offset, xrange + offset]);
            ylim([0 - offset, yrange + offset]);
            str =  "Coverage Control of Multi-Agent System";
            str = str + newline + "+ = Virtual Center, o = CVT";
            title(str);
            
            % Boundaries
            for i = 1: size(regionConfig.BOUNDARIES_VERTEXES,1)-1                
               plot([regionConfig.BOUNDARIES_VERTEXES(i,1) regionConfig.BOUNDARIES_VERTEXES(i+1,1)],[regionConfig.BOUNDARIES_VERTEXES(i,2) regionConfig.BOUNDARIES_VERTEXES(i+1,2)], '-r', 'LineWidth',2);                    
            end  
            
        end
        
        function live_plot(obj, iter, curPose, curVm, CurPoseCVT, curDir, v, c, pathGen, pathCVT)
            %plot current position
            
            % Plot the path
%             for i = 1:size(generator,1) % color according to
%                 xD = [get(obj.genPathHandle{i},'XData'),generator(i,1)];
%                 yD = [get(obj.genPathHandle{i},'YData'),generator(i,2)];
%                 set(obj.genPathHandle{i},'XData',xD,'YData',yD);%plot path position
%             end 

            for i = 1:numel(c) % update Voronoi cells
                set(obj.verCellHandle{i}, 'XData',v(c{i},1),'YData',v(c{i},2));
                set(obj.genHandle{i},'XData',curVm(i,1),'YData',curVm(i,2));
                set(obj.goalHandle{i},'XData',CurPoseCVT(i,1),'YData',CurPoseCVT(i,2)); %plot CVT
                set(obj.genPathHandle{i},'XData',pathGen(i,1,:),'YData',pathGen(i,2,:));%plot path position+                
                set(obj.dirHandle{i},'XData', curPose(i,1), 'YData', curPose(i,2),'udata',curDir(i,1),'vdata',curDir(i,2));
            end

            set(obj.titleHandle,'string',['* = Agents | + = Virtual Mass | o = CVT | Iteration: ', num2str(iter,'%3d')]);
            %drawnow
            
        end
    end
end

