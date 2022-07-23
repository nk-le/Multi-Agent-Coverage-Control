classdef DataLogger < handle
    %CLASS_obj Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SIM_PARAM
        CONTROL_PARAM
        regionConfig
        startPose
        vConstList
        wOrbitList
        
        maxCnt 
        curCnt
        
        PoseAgent
        PoseVM 
        ControlOutput 
        CVT
        V_BLF
        V
        C
        visHandle
        
        ExcTime
        BotColor %
    end
    
    methods
        function obj = DataLogger(SIM_PARAM, regionConfig, CONTROL_PARAM, vList, wList)
            obj.SIM_PARAM = SIM_PARAM;
            obj.CONTROL_PARAM = CONTROL_PARAM;
            obj.regionConfig = regionConfig;
            obj.vConstList = vList;
            obj.wOrbitList = wList;
            obj.startPose = SIM_PARAM.START_POSE;
            obj.curCnt = 1;
            
            obj.maxCnt = obj.SIM_PARAM.MAX_ITER + 10;
            obj.PoseAgent = zeros(obj.SIM_PARAM.N_AGENT, 3, obj.maxCnt);
            obj.PoseVM = zeros(obj.SIM_PARAM.N_AGENT, 2, obj.maxCnt);
            obj.ControlOutput = zeros(obj.SIM_PARAM.N_AGENT, obj.maxCnt);
            obj.CVT = zeros(obj.SIM_PARAM.N_AGENT, 2, obj.maxCnt);
            obj.V_BLF = zeros(obj.SIM_PARAM.N_AGENT, obj.maxCnt);
            obj.V = cell(obj.maxCnt,1);
            obj.C = cell(obj.maxCnt,1);
            
            obj.visHandle = Visualizer(obj.SIM_PARAM.N_AGENT);
            obj.visHandle.set_boundary(regionConfig);
        end
        
        %% Log the necessary information for visualization and evaluation
        function log(obj, CurPose, CurPoseVM, CurPoseCVT, LyapunovCost, CurControlOutput, v, c)
            if(obj.curCnt <= obj.maxCnt)
                obj.PoseAgent(:, :,obj.curCnt) = CurPose(:,:);
                obj.PoseVM(:, :,obj.curCnt) = CurPoseVM(:,:);
                obj.CVT(:,:, obj.curCnt)  = CurPoseCVT(:,:);
                obj.ControlOutput(:, obj.curCnt) = CurControlOutput(:);
                obj.V_BLF(:, obj.curCnt) = LyapunovCost(:);
                obj.V{obj.curCnt} = v;
                obj.C{obj.curCnt} = c;
                obj.curCnt = obj.curCnt + 1;
            end
        end 
        
        %% Evaluate the Lyapunov function
        function plot_BLF_single(obj)
            botColors = cool(obj.SIM_PARAM.N_AGENT);
            xAxis = 1:obj.curCnt;
            V = zeros(1, obj.curCnt);
            % Plot
            figure
            hold on; grid on;
            for i = 1:obj.SIM_PARAM.N_AGENT
                plot(xAxis, obj.V_BLF(i,xAxis), 'Color', botColors(i,:), 'LineWidth',2, 'DisplayName',sprintf("V_%d",i));
                V(xAxis) = V(xAxis) + obj.V_BLF(i,xAxis);
            end
            plot(xAxis, V(xAxis), '-r', 'LineWidth',2, 'DisplayName', "V");
            xlim([0, obj.curCnt]);
            xlabel("Iteration");
            ylabel("V_k");
            title("Barrier Lyapunov Function")
            legend
            set(gca,'FontSize',18)            
        end
        
        function out = get_bot_colors(obj)
            if(obj.SIM_PARAM.N_AGENT > 6)
                out = cool(obj.SIM_PARAM.N_AGENT);
            else
                out = [0 0.4470 0.7410;
                       0.8500 0.3250 0.0980;
                       0.9290 0.6940 0.1250;
                       0.4660 0.6740 0.1880;
                       0.3010 0.7450 0.9330;
                       0.6350 0.0780 0.1840;
                       0.4940 0.1840 0.5560];                
            end
        end
        
        %% Plot the initial config
        function retFig = plot_initial(obj)
            botColors = obj.get_bot_colors();
            retFig = figure;
            hold on; grid on;                 
            axis equal;
            for i = 1: size(obj.regionConfig.BOUNDARIES_VERTEXES,1)-1                
               plot([obj.regionConfig.BOUNDARIES_VERTEXES(i,1) obj.regionConfig.BOUNDARIES_VERTEXES(i+1,1)],...
                    [obj.regionConfig.BOUNDARIES_VERTEXES(i,2) obj.regionConfig.BOUNDARIES_VERTEXES(i+1,2)],...
                    '--', 'LineWidth',2, "Color", "Black");                    
            end   
        end
        
        %% Plot the trajectories of virtual mass
        function retFig = plot_VM_trajectories(obj)  
            botColors = obj.get_bot_colors();
            iBegin = 10;
            nIter = obj.curCnt-1;

            drawAxis = iBegin:nIter;   
            retFig = obj.plot_initial();
            
            % Plot the coordinate info
            for i = 1:obj.SIM_PARAM.N_AGENT
                vmData = reshape(obj.PoseVM(i,:,:), [2, size(obj.PoseVM,3)])';
                poseData = reshape(obj.PoseAgent(i,:,:), [3, size(obj.PoseVM,3)])';
                cvtData = reshape(obj.CVT(i,:,:), [2, size(obj.CVT,3)])';
                
                pVm = plot(vmData(drawAxis,1), vmData(drawAxis,2),':', 'Color', "black",'LineWidth',3); 
                pVm.Color(4) = 0.9;

                pPose = plot(poseData(drawAxis,1), poseData(drawAxis,2),'-', 'Color', botColors(i,:),'LineWidth',2);
                pPose.Color(4) = 0.3;
                
                cvtPlot = plot(cvtData(drawAxis,1), cvtData(drawAxis,2),'--', 'Color', botColors(i,:),'LineWidth',3);
                cvtPlot.Color(4) = 1;
                
                % Plot some particular coordinate (initial, end, etc.)
                iPos = scatter(obj.PoseAgent(i,1,iBegin), obj.PoseAgent(i,2,iBegin), "x"); % Initial robots's coord
                iPos.MarkerEdgeColor = botColors(i,:);
                iPos.SizeData = 400;
                iPos.LineWidth = 1;
                
%                 ePos = scatter(obj.PoseAgent(i,1,nIter), obj.PoseAgent(i,2,nIter), "x"); % final robots's coord)
%                 ePos.MarkerEdgeColor = botColors(i,:);
%                 ePos.SizeData = 200;
%                 ePos.LineWidth = 2;
                
                iVm = scatter(obj.PoseVM(i,1,iBegin), obj.PoseVM(i,2,iBegin), "x"); % Initial vm's coord)
                iVm.MarkerEdgeColor = "Black";
                iVm.SizeData = 400;
                iVm.LineWidth = 4;
                
%                 eVm = scatter(obj.PoseVM(i,1,nIter), obj.PoseVM(i,2,nIter), "x"); % final vm's coord)
%                 eVm.MarkerEdgeColor = "Black";
%                 eVm.SizeData = 400;
%                 eVm.LineWidth = 2;
                
                iCVT = scatter(obj.CVT(i,1,iBegin), obj.CVT(i,2,iBegin), "x"); % Initial CVT's coord
                iCVT.MarkerEdgeColor = botColors(i,:);
                iCVT.SizeData = 400;
                iCVT.LineWidth = 4;
                
                eCVT = scatter(obj.CVT(i,1,nIter), obj.CVT(i,2,nIter), "o"); % Final CVT's coord
                eCVT.MarkerEdgeColor = botColors(i,:);
                eCVT.SizeData = 400;
                eCVT.LineWidth = 2;
                
            end
            
            
            % Plot the final configuration - Voronoi partitions
            v = obj.V{nIter};
            c = obj.C{nIter};
            for i = 1:obj.SIM_PARAM.N_AGENT
                verCellHandle{i} = patch(obj.PoseVM(i,1,end), obj.PoseVM(i,2,end), botColors(i,:), ... 
                                     'EdgeColor','black', "LineWidth", 2, "LineStyle", "--"); 
                verCellHandle{i}.FaceAlpha = 0.1;
                set(verCellHandle{i}, 'XData', v(c{i},1),'YData',v(c{i},2));
            end
            
            %title("Coverage Trajectory");
            set(gca,'FontSize',40)
            
            % Polish
            xrange = max(obj.regionConfig.BOUNDARIES_VERTEXES(:,1));
            yrange = max(obj.regionConfig.BOUNDARIES_VERTEXES(:,2));
            offset = 100;
            xlim([0 - offset, xrange + offset]);
            ylim([0 - offset, yrange + offset]);
            
            grid off;
            box on;
            xlabel("X Coordinate (mm)", 'interpreter','latex');
            ylabel("Y Coordinate (mm)", 'interpreter','latex');
            xticks([0:800:4000]);
            yticks([0:700:2800]);
        end
        
        
        function retFig = plot_BLF_all(obj)
            extTime = obj.get_time_axis();
            botColors = obj.get_bot_colors();
            iBegin = 10;
            nIter = obj.curCnt-1;
            
            drawAxis = iBegin:nIter;   
            
            sumV = sum(obj.V_BLF(:,drawAxis),1)';
            timeAxis = (extTime(drawAxis) - extTime(iBegin)) / 1e3;
            
            retFig = figure; 
            plt = area(timeAxis, sumV);
            plt.FaceColor = [0 0.4470 0.7410];
            plt.FaceAlpha = 0.55;
            plt.LineStyle = '-.';
            plt.LineWidth = 1.5;
            hold on; grid on; box on;
            plot(timeAxis, sumV, 'LineWidth', 3, "Color", "black", "LineStyle", "-.");
            xlabel("Time (s)", 'fontsize',20, 'interpreter','latex');
            ylabel("V($\mathcal{Z}$)",'interpreter','latex','fontsize',20);
            %yticks([0:1000:max(sumV)]);
            %xticks([0:15:90]);
            axis tight;
            ax = gca;
            ax.FontSize = 40; 
            set(gca,'linewidth',3);
            xlim([timeAxis(1), timeAxis(end)/2]);
        end
        
        function retFig = plot_control_output(obj)
            extTime = obj.get_time_axis();
            botColors = obj.get_bot_colors();
            iBegin = 10;
            nIter = obj.curCnt-1;
            
            drawAxis = iBegin:nIter;   
            timeAxis = (extTime(drawAxis) - extTime(iBegin)) / 1e3;

            retFig = figure();
            
            
            for i = 1:obj.SIM_PARAM.N_AGENT
                w = obj.ControlOutput(i, drawAxis);
                w = w - obj.wOrbitList(i);
                plot(timeAxis, w, "Color", botColors(i,:), "LineStyle", "--", "LineWidth", 2);
                %line_fewer_markers(timeAxis, w, 20, "Color", botColors(i,:),  "LineWidth", 2);
                hold on; grid on;
            end 
            yline(obj.CONTROL_PARAM.W_LIMIT - obj.CONTROL_PARAM.W_ORBIT, "Color", "red", "LineWidth", 2, "LineStyle", "--");
            %yline(-obj.CONTROL_PARAM.W_LIMIT - obj.CONTROL_PARAM.W_ORBIT, "Color", "red", "LineWidth", 2, "LineStyle", "--");
            xlabel("Time (s)", 'fontsize',20, 'interpreter','latex');
            ylabel("$\omega_k(t) - \omega_0$ (rad/s)",'interpreter','latex','fontsize',20);
            %xticks([0:15:90]);
            %yticks([-1:0.2:1])
            set(gca,'GridLineStyle','-.');
            ax = gca;
            ax.FontSize = 20; 
            ax.GridAlpha = 0.35;
            axis tight;
            set(gca,'linewidth',6);
            axis tight;
            ax = gca;
            ax.FontSize = 40; 
            set(gca,'linewidth',3);
            xlim([timeAxis(1), timeAxis(end)/2]);
        end
        
        
        function generate_figures(obj, expIdStr, path)
            if ~exist('expId','var')
              t = now;
              expIdStr = sprintf("Time_%d",floor(t));
            end
            
            if ~exist('path','var')
              path = fullfile(pwd, sprintf("Generated_Figures_Exp_%s", expIdStr));
              mkdir(path);
            end
            
            % Trajectories
            retFig = obj.plot_VM_trajectories();
            retFig.WindowState = "maximized";
            filePath = fullfile(path, sprintf("Trajectory_%s.png", expIdStr));
            saveas(retFig, filePath);
            filePath = fullfile(path, sprintf("Trajectory_%s.png", expIdStr));
            saveas(retFig, filePath);
            print(fullfile(path,sprintf("Trajectory_%s.eps", expIdStr)),'-depsc2','-r300');

            % Control Input
            retFig = obj.plot_control_output();
            retFig.WindowState = "maximized";
            filePath = fullfile(path, sprintf("Control_Output_%s.png", expIdStr));
            saveas(retFig, filePath);
            filePath = fullfile(path, sprintf("Control_Output_%s.fig", expIdStr));
            saveas(retFig, filePath);
            print(fullfile(path,sprintf("Control_Output_%s.eps", expIdStr)),'-depsc2','-r300');
            
            % Lyapunov
            retFig = obj.plot_BLF();
            retFig.WindowState = "maximized";
            filePath = fullfile(path, sprintf("Lyapunov_%s.png", expIdStr));
            saveas(retFig, filePath);
            filePath = fullfile(path, sprintf("Lyapunov_%s.fig", expIdStr));
            saveas(retFig, filePath);
            print(fullfile(path,sprintf("Lyapunov_%s.eps", expIdStr)),'-depsc2','-r300');
        end
        
        % Convert the interation into timestamp
        function excTime = get_time_axis(obj)
            obj.ExcTime = (1:obj.curCnt) * obj.SIM_PARAM.TIME_STEP;
            excTime = obj.ExcTime;
        end
        
        
        function [botPose, botZ, botCz, botCost, botInput] = get_logged_data(obj)
            curDataArr = 1:obj.curCnt-1;
            botPose = obj.PoseAgent(:,:,curDataArr);
            botZ = obj.PoseVM(:,:,curDataArr);
            botCz = obj.CVT(:,:, curDataArr);
            botCost = obj.V_BLF(:, curDataArr);
            botInput = obj.ControlOutput(:, curDataArr);
        end
            
        
%         function visualize(obj)
%             env = MultiRobotEnv(obj.SIM_PARAM.N_AGENT);
%             %% Parse data
%             spX = obj.CVT(:,1,:);
%             spY = obj.CVT(:,2,:);
%             vmX = obj.PoseVM(:,1,:);
%             vmY = obj.PoseVM(:,2,:);
%             poseX =  obj.PoseAgent(:,1,:);
%             poseY =  obj.PoseAgent(:,2,:);
%             poseTheta =  obj.PoseAgent(:,3,:);
% 
%             poseInit = zeros(3, obj.SIM_PARAM.N_AGENT);
%             env((1:obj.SIM_PARAM.N_AGENT), poseInit);
%             hold on; grid on; %axis equal
% 
%             % Plot Boundaries
%             xrange = max(obj.regionConfig.BOUNDARIES_VERTEXES(:,1));
%             yrange = max(obj.regionConfig.BOUNDARIES_VERTEXES(:,2));
%             offset = 20;
%             xlim([0 - offset, xrange + offset]);
%             ylim([0 - offset, yrange + offset]);
%             str =  "Coverage Control of Multi-Unicycle System";
%             str = str + newline + "x: WMR's Virtual Mass, o: Centroid of Voronoi Partition";
%             title(str);
% 
%             vmPlotHandle = [];
%             spPlotHandle = [];
%             showColorPlot = true;
% 
%             for loopCnt = 1:obj.curCnt    
%                 if(loopCnt == 1) % Plot only once
%                         %figure(2);
%                         %hold on;  grid on;
%                         % Boundaries
%                         for i = 1: size(obj.regionConfig.BOUNDARIES_VERTEXES,1)-1                
%                            plot([obj.regionConfig.BOUNDARIES_VERTEXES(i,1) obj.regionConfig.BOUNDARIES_VERTEXES(i+1,1)],[obj.regionConfig.BOUNDARIES_VERTEXES(i,2) obj.regionConfig.BOUNDARIES_VERTEXES(i+1,2)], '-r', 'LineWidth',4);                    
%                         end   
%                         % Color Patch
%                         verCellHandle = zeros(obj.SIM_PARAM.N_AGENT,1);
%                         cellColors = cool(obj.SIM_PARAM.N_AGENT);         
%                         if(showColorPlot == true)
%                             vmPlotColorHandle = [];
%                             spPlotColorHandle = [];
%                             for i = 1:obj.SIM_PARAM.N_AGENT % color according to
%                                 verCellHandle(i) = patch(spX(1,i),spY(2,i), cellColors(i,:)); % use color i  -- no robot assigned yet
%                                 vmHandle =  plot(vmX(i,loopCnt), vmY(i,loopCnt),'x','Color', cellColors(i,:), 'LineWidth',2);
%                                 spHandle =  plot(spX(i,loopCnt), spY(i,loopCnt), '-o','Color', cellColors(i,:), 'LineWidth',2);   
%                                 vmPlotColorHandle = [vmPlotColorHandle vmHandle];
%                                 spPlotColorHandle = [spPlotColorHandle spHandle];
%                             end
%                         end
%                  end
% 
%                 % Update the position in the environment
%                 for i = 1:obj.SIM_PARAM.N_AGENT
%                     pose(:,i) = [poseX(i, loopCnt), poseY(i, loopCnt), poseTheta(i, loopCnt)];
%                 end
%                 env((1:obj.SIM_PARAM.N_AGENT), pose);
% 
%                 if(showColorPlot == true)
%                     %hold on; grid on; axis equal
%                     xlim([0 - offset, xrange + offset]);
%                     ylim([0 - offset, yrange + offset]);
%                     str =  "Voronoi Tessellation";
%                     str = str + newline + "x: WMR's Virtual Mass, o: Centroid of Voronoi Partition";
%                     title(str);
%                     for i = 1:obj.SIM_PARAM.N_AGENT % update Voronoi cells
%                        set(spPlotColorHandle(i),'XData', spX(i,loopCnt) ,'YData', spY(i,loopCnt)); %plot current position
%                        set(vmPlotColorHandle(i),'XData', vmX(i,loopCnt) ,'YData', vmY(i,loopCnt)); 
%                     end
%                 end
%             end  
%         end
%         
        function generate_video(obj)
             %% To video
            Filename = sprintf('%s', datestr(now,'mm-dd-yyyy HH-MM'));
            myVideo = VideoWriter(fullfile(pwd, "Sim_Video", Filename)); %open video file
            myVideo.Quality = 100;
            myVideo.FrameRate = 30;  
            open(myVideo)
            
            %% Logging
            handle = Visualizer(obj.SIM_PARAM.N_AGENT);
            handle.set_boundary(obj.regionConfig);
            for i = 1:obj.curCnt
                v = obj.V{i};
                c = obj.C{i};
                CurPoseCVT = obj.CVT(:,:,i);
                CurPoseVM = obj.PoseVM(:,:,i);
                curPose = obj.PoseAgent(:,:,i);
                pathGen = obj.PoseAgent(:,1:2,max(2, i - 100):i);
                curDir = (obj.PoseAgent(:,1:2, i) - obj.PoseAgent(:,1:2, max(1,i - 1))); 
                curDir = 50 * curDir/norm(curDir);
                % Pass the current positions and the paths to the visualizer
                handle.live_plot(i, curPose, CurPoseVM, CurPoseCVT, curDir, v, c, pathGen);
                
                frame = getframe(gcf); %get frame
                writeVideo(myVideo, frame);
            end
            
            %% End
            close(myVideo)
        end

        function live_plot(obj)
            idx = obj.curCnt - 1;
            v = obj.V{idx};
            c = obj.C{idx};
            CurPoseCVT = obj.CVT(:,:,idx);
            CurPoseVM = obj.PoseVM(:,:,idx);
            curPose = obj.PoseAgent(:,:,idx);
            pathGen = obj.PoseAgent(:,1:2,max(2, idx - 100):idx);
            curDir = (obj.PoseAgent(:,1:2, idx) - obj.PoseAgent(:,1:2, max(1,idx - 1))); 
            curDir = 50 * curDir/norm(curDir);
            % Pass the current positions and the paths to the visualizer
            obj.visHandle.live_plot(obj.curCnt, curPose, CurPoseVM, CurPoseCVT, curDir, v, c, pathGen);
            drawnow();
        end
    end
end

