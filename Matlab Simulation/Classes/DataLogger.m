classdef DataLogger < handle
    %CLASS_obj Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SIM_PARAM
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
    end
    
    methods
        function obj = DataLogger(SIM_PARAM, regionConfig, startPose, vList, wList)
            obj.SIM_PARAM = SIM_PARAM;
            obj.regionConfig = regionConfig;
            obj.vConstList = vList;
            obj.wOrbitList = wList;
            obj.startPose = startPose;
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
            obj.curCnt = obj.curCnt + 1;
            if(obj.curCnt <= obj.maxCnt)
                obj.PoseAgent(:, :,obj.curCnt) = CurPose(:,:);
                obj.PoseVM(:, :,obj.curCnt) = CurPoseVM(:,:);
                obj.CVT(:,:, obj.curCnt)  = CurPoseCVT(:,:);
                obj.ControlOutput(:, obj.curCnt) = CurControlOutput(:);
                obj.V_BLF(:, obj.curCnt) = LyapunovCost(:);
                obj.V{obj.curCnt} = v;
                obj.C{obj.curCnt} = c;
            end
        end 
        
        %% Evaluate the Lyapunov function
        function plot_Lyapunov(obj)
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
        
        %% Plot the computed control output of each agent
        function plot_ControlOutput(obj)
            botColors = cool(obj.SIM_PARAM.N_AGENT);
            xAxis = 1:obj.curCnt;             
            figure
            hold on; grid on;
            for i = 1:obj.SIM_PARAM.N_AGENT
                plot(xAxis, obj.ControlOutput(i,xAxis), 'Color', botColors(i,:), 'LineWidth',2, 'DisplayName',sprintf("u_%d",i));
            end
            %plot(xAxis, -wMax*ones(1, numel(xAxis)), '-r', 'LineWidth',4);
            %plot(xAxis, wMax*ones(1, numel(xAxis)), '-r', 'LineWidth',4);
            ylim([-2, 2]);
            xlabel("Iteration");
            ylabel("Angular Velocity");
            title("Control Output Evaluation")
            legend
            set(gca,'FontSize',18)
        end
        
        %% Plot the trajectories of virtual mass
        function plot_VM_trajectories(obj)
            botColors = cool(obj.SIM_PARAM.N_AGENT);
            xAxis = 1:obj.curCnt;             
            % State Trajectories
            figure
            hold on; grid on;
            for i = 1: size(obj.regionConfig.BOUNDARIES_VERTEXES,1)-1                
               plot([obj.regionConfig.BOUNDARIES_VERTEXES(i,1) obj.regionConfig.BOUNDARIES_VERTEXES(i+1,1)],[obj.regionConfig.BOUNDARIES_VERTEXES(i,2) obj.regionConfig.BOUNDARIES_VERTEXES(i+1,2)], '-r', 'LineWidth',4);                    
            end   
            for i = 1:obj.SIM_PARAM.N_AGENT
                dataVMX = zeros(obj.SIM_PARAM.N_AGENT, obj.curCnt);
                dataVMY = zeros(obj.SIM_PARAM.N_AGENT, obj.curCnt);
                dataVMX(i,xAxis) =  obj.PoseVM(i,1,xAxis);
                dataVMY(i,xAxis) =  obj.PoseVM(i,2,xAxis);
               plot(dataVMX, dataVMY,'-', 'Color', botColors(i,:),'LineWidth',2); 
            end
            %xlim([0 - 10, xrange + 10]);
            %ylim([0 - 10, yrange + 10]);
            title("Trajectories of virtual masses");
            set(gca,'FontSize',18)
            
        end
        
        
        
        function visualize(obj)
            env = MultiRobotEnv(obj.SIM_PARAM.N_AGENT);
            %% Parse data
            spX = obj.CVT(:,1,:);
            spY = obj.CVT(:,2,:);
            vmX = obj.PoseVM(:,1,:);
            vmY = obj.PoseVM(:,2,:);
            poseX =  obj.PoseAgent(:,1,:);
            poseY =  obj.PoseAgent(:,2,:);
            poseTheta =  obj.PoseAgent(:,3,:);

            poseInit = zeros(3, obj.SIM_PARAM.N_AGENT);
            env((1:obj.SIM_PARAM.N_AGENT), poseInit);
            hold on; grid on; %axis equal

            % Plot Boundaries
            xrange = max(obj.regionConfig.BOUNDARIES_VERTEXES(:,1));
            yrange = max(obj.regionConfig.BOUNDARIES_VERTEXES(:,2));
            offset = 20;
            xlim([0 - offset, xrange + offset]);
            ylim([0 - offset, yrange + offset]);
            str =  "Coverage Control of Multi-Unicycle System";
            str = str + newline + "x: WMR's Virtual Mass, o: Centroid of Voronoi Partition";
            title(str);

            vmPlotHandle = [];
            spPlotHandle = [];
            showColorPlot = true;

            for loopCnt = 1:obj.curCnt    
                if(loopCnt == 1) % Plot only once
                        %figure(2);
                        %hold on;  grid on;
                        % Boundaries
                        for i = 1: size(obj.regionConfig.BOUNDARIES_VERTEXES,1)-1                
                           plot([obj.regionConfig.BOUNDARIES_VERTEXES(i,1) obj.regionConfig.BOUNDARIES_VERTEXES(i+1,1)],[obj.regionConfig.BOUNDARIES_VERTEXES(i,2) obj.regionConfig.BOUNDARIES_VERTEXES(i+1,2)], '-r', 'LineWidth',4);                    
                        end   
                        % Color Patch
                        verCellHandle = zeros(obj.SIM_PARAM.N_AGENT,1);
                        cellColors = cool(obj.SIM_PARAM.N_AGENT);         
                        if(showColorPlot == true)
                            vmPlotColorHandle = [];
                            spPlotColorHandle = [];
                            for i = 1:obj.SIM_PARAM.N_AGENT % color according to
                                verCellHandle(i) = patch(spX(1,i),spY(2,i), cellColors(i,:)); % use color i  -- no robot assigned yet
                                vmHandle =  plot(vmX(i,loopCnt), vmY(i,loopCnt),'x','Color', cellColors(i,:), 'LineWidth',2);
                                spHandle =  plot(spX(i,loopCnt), spY(i,loopCnt), '-o','Color', cellColors(i,:), 'LineWidth',2);   
                                vmPlotColorHandle = [vmPlotColorHandle vmHandle];
                                spPlotColorHandle = [spPlotColorHandle spHandle];
                            end
                        end
                 end

                % Update the position in the environment
                for i = 1:obj.SIM_PARAM.N_AGENT
                    pose(:,i) = [poseX(i, loopCnt), poseY(i, loopCnt), poseTheta(i, loopCnt)];
                end
                env((1:obj.SIM_PARAM.N_AGENT), pose);

                if(showColorPlot == true)
                    %hold on; grid on; axis equal
                    xlim([0 - offset, xrange + offset]);
                    ylim([0 - offset, yrange + offset]);
                    str =  "Voronoi Tessellation";
                    str = str + newline + "x: WMR's Virtual Mass, o: Centroid of Voronoi Partition";
                    title(str);
                    for i = 1:obj.SIM_PARAM.N_AGENT % update Voronoi cells
                       set(spPlotColorHandle(i),'XData', spX(i,loopCnt) ,'YData', spY(i,loopCnt)); %plot current position
                       set(vmPlotColorHandle(i),'XData', vmX(i,loopCnt) ,'YData', vmY(i,loopCnt)); 
                    end
                end
            end  
        end
        
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
            v = obj.V{obj.curCnt};
            c = obj.C{obj.curCnt};
            CurPoseCVT = obj.CVT(:,:,obj.curCnt);
            CurPoseVM = obj.PoseVM(:,:,obj.curCnt);
            curPose = obj.PoseAgent(:,:,obj.curCnt);
            pathGen = obj.PoseAgent(:,1:2,max(2, obj.curCnt - 100):obj.curCnt);
            curDir = (obj.PoseAgent(:,1:2, obj.curCnt) - obj.PoseAgent(:,1:2, max(1,obj.curCnt - 1))); 
            curDir = 50 * curDir/norm(curDir);
            % Pass the current positions and the paths to the visualizer
            obj.visHandle.live_plot(obj.curCnt, curPose, CurPoseVM, CurPoseCVT, curDir, v, c, pathGen)
        end
        
        
        
    end
end

