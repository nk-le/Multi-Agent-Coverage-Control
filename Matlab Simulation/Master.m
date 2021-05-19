%close all;
clear all;
close all;

% SETTINGS OF SIMULATION
visualization = true;
BLFThres = 1;
global botColors;
global dt;
dt = 0.005;
rng(4);

% CONFIGURATE COVERAGE REGION AND STARTING POSITION
Environment_Configuration

% SETTINGS OF AGENTS
Agent_Configuration

% DEBUGGER AND LOGGER
logger = Class_Logger(amountAgent, 50000);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% VISUALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Init Visualizer
showColorPlot = true;
botColors = spring(amountAgent);
if(visualization == true)
    env = MultiRobotEnv(amountAgent);
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
    for i = 1:amountAgent
        controller_handle(i).updateTarget(com.setPoint(1,i), com.setPoint(2,i)); 
        poseVM(i,:) = [controller_handle(i).virtualMassX, controller_handle(i).virtualMassY, controller_handle(i).Theta];
    end
    vmPlotHandle = [];
    spPlotHandle = [];

    for i = 1:amountAgent    
       vmHandle =  plot(controller_handle(i).virtualMassX, controller_handle(i).virtualMassY, '-x', 'Color', botColors(i,:), 'LineWidth',2);
       spHandle =  plot(com.setPoint(1,i), com.setPoint(2,i), '-o','Color', botColors(i,:), 'LineWidth',2);   
       vmPlotHandle = [vmPlotHandle vmHandle];
       spPlotHandle = [spPlotHandle spHandle];
    end
end

% SIMULATION STARTS HERE
global dVi_dzMat;
dVi_dzMat = zeros(amountAgent, amountAgent, 2);

loopCnt = 0;
totalV = 0;
while (loopCnt == 0 || totalV == 0 || totalV > BLFThres)
    loopCnt = loopCnt + 1;
    % Update mission
    filterUsed = 1;
    if(filterUsed)
        if(mod(loopCnt, 5) == 0)
            com.compute(poseVM);
        end
    else
        if (loopCnt > 3)
            com.compute(poseVM);
        end
    end
    % Update BLF
    logger.updateBLF(com.lastV(:), com.BLFden(:));

    for i = 1:amountAgent
        % Control Method
        bot_handle(i).move(); 

        controller_handle(i).updateTarget(com.setPoint(1,i), com.setPoint(2,i));
        %[~,~] = controller_handle(i).BLF_Controller_Log(k_inputScale(i,1),k_inputScale(i,2), A, b, 0.2);

        % Testing new controller here
        newWk = controller_handle(i).computeBLFoutput(i,kMu(i)); % or kmu(i)

        newVM   = [bot_handle(i).virtualMassX, bot_handle(i).virtualMassY];
        newCVT  = [com.setPoint(1,i), com.setPoint(2,i)];
        logger.updateBot(i, newVM, newWk, newCVT); % curBot, newPoseVM, newWk, newCVT

        % Update
        poseVM(i,:) = [bot_handle(i).virtualMassX, bot_handle(i).virtualMassY, bot_handle(i).theta];
        pose(:,i) = bot_handle(i).pose;
        
        % Update Setpoints and virtual mass position
        if(visualization == true)
            set(spPlotHandle(i),'XData', com.setPoint(1,i) ,'YData', com.setPoint(2,i)); %plot current position
            set(vmPlotHandle(i),'XData', bot_handle(i).virtualMassX ,'YData', bot_handle(i).virtualMassY); 
        end 
    end
    totalV = sum(logger.V_BLF(:, loopCnt));

    if(visualization == true)
        disp(totalV);
        if(loopCnt == 1) % Plot only once
            figure(2);
            hold on;
            grid on;
            
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
                    verCellHandle(i) = patch(com.setPoint(1,i),com.setPoint(2,i), cellColors(i,:)); % use color i  -- no robot assigned yet
                    vmHandle =  plot(controller_handle(i).virtualMassX, controller_handle(i).virtualMassY,'x','Color', botColors(i,:), 'LineWidth',2);
                    spHandle =  plot(com.setPoint(1,i), com.setPoint(2,i), '-o','Color', botColors(i,:), 'LineWidth',2);   
                    vmPlotColorHandle = [vmPlotColorHandle vmHandle];
                    spPlotColorHandle = [spPlotColorHandle spHandle];
                end
            end
        end
        
        
        if(totalV < 1)
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

                for i = 1:numel(com.c) % update Voronoi cells
                   set(spPlotColorHandle(i),'XData', com.setPoint(1,i) ,'YData', com.setPoint(2,i)); %plot current position
                   set(vmPlotColorHandle(i),'XData', bot_handle(i).virtualMassX ,'YData', bot_handle(i).virtualMassY); 
                   set(verCellHandle(i), 'XData',com.v(com.c{i},1),'YData',com.v(com.c{i},2));
                end
            end
        end
    else 
        disp(totalV);
    end       
end

disp("Converged!")

