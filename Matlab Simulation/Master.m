%close all;

% SETTINGS OF SIMULATION
global dt;
dt = 0.02; 
numberOfIter = 50000;
rng(8);

% SETTINGS OF DOMINATING REGION
offset = 100;
maxX = 400;
maxY = 800;

VREP = 0;
TRIANGLE = 1;
SQUARE = 2;

world = VREP;
if(world == TRIANGLE)
    A = [-1, 0; 0 , -1; maxY/maxX,1]; 
    b = [0, 0, maxY];    worldVertexes = [0, 0; 0, maxY; maxX, 0; 0, 0]; 
elseif(world == SQUARE)
    A = [-1 , 0; 1 , 0; 0 , 1; 0 , -1];
    b = [0, maxX, maxY, 0];
    worldVertexes = [0, 0; 0,maxY; maxX,maxY; maxX,0; 0, 0];
elseif(world == VREP)
    A = [-1 , 0; 0 , -1; -1 , 1; 0.6 , 1; 0.6 , -1]; 
    b = [0, 0, 6, 15.6, 3.6];
    worldVertexes = [0, 0; 0,6; 6,12 ; 16,6 ; 6,0; 0,0];
    offset = 1;
end

xrange = max(worldVertexes(:,1));
yrange = max(worldVertexes(:,2));

flag = 0;
% SETTINGS OF AGENTS
amountAgent = 5;

randLow = 2*pi;
randUp  = 0;
startTheta = randLow + rand(amountAgent,2)*(randUp-randLow);

centerX = 40;
centerY = 40;
rXY = 1;

startX = centerX + rXY * cos(0 : 2*pi/amountAgent : 2*pi);
startY = centerY + rXY * sin(0 : 2*pi/amountAgent : 2*pi );
startPose = [startX', startY', zeros(numel(startX),1)];

pose = zeros(3, amountAgent);
poseVM = zeros(amountAgent, 3);
com = Class_Mission_Computer(amountAgent, worldVertexes(1:end-1,:), xrange, yrange);

% BOT & CONTROLLER
v =  linspace(8,18, amountAgent) .* ones(1,amountAgent);
w0 = linspace(0.25, 0.55, amountAgent) .* ones(1,amountAgent);
wMax = 1.6;
K1 = 1;
K2 = 0.5;

if(world == VREP)
    v = linspace(0.2,0.4, amountAgent) .* ones(1,amountAgent);;
    w0 = linspace(0.2, 0.2, amountAgent) .* ones(1,amountAgent);
    wMax = 0.5;
    startPose = [0.375, 0.975, 0;
                 1.2250, 0.3750, 0;
                 2.850, 0.4750, 0;
                 1.675, 1.4750, 0;
                 0.650, 2.550, 0];
    K1 = 0.25;
    K2 = 0.5;
end
k_inputScale = [K1 * ones(1, amountAgent)', K2 * ones(1,amountAgent)'];         

bot_handle = Class_Mobile_Robot.empty(amountAgent, 0);
controller_handle = Class_Controller_Khanh.empty(amountAgent, 0);

for i  = 1:amountAgent
   bot_handle(i) = Class_Mobile_Robot(startPose(i,1), startPose(i,2), startPose(i,3), dt);
   bot_handle(i).wMax = wMax;
   bot_handle(i).setParameterVirtualMass(w0(i));
   controller_handle(i) = Class_Controller_Khanh(0, w0(i), v(i), worldVertexes, bot_handle(i)); 
end

debugVM = zeros(amountAgent, 2, 100000);
debugW = zeros(amountAgent, 100000);
debugTarget = zeros(amountAgent, 2, 100000);
debugError = zeros(amountAgent, 100000);

% Init Visualizer
showColorPlot = true;

env = MultiRobotEnv(amountAgent);
env.showTrajectory(1) = 0;
env.showTrajectory(2) = 0;
env.showTrajectory(3) = 0;

for i  = 1:amountAgent
    pose(:,i) = bot_handle(i).pose;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% VISUALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
env((1:amountAgent), pose);
hold on; grid on; %axis equal
% Plot Boundaries
for i = 1: size(worldVertexes,1)-1                
    plot([worldVertexes(i,1) worldVertexes(i+1,1)],[worldVertexes(i,2) worldVertexes(i+1,2)]);                    
end
xlim([0 - offset, xrange + offset]);
ylim([0 - offset, yrange + offset]);

aviobj = VideoWriter('Controller_State_Constraint.avi');
%open(aviobj);
if(1)
    loopCnt = 0;
    for i = 1:amountAgent
        controller_handle(i).updateTarget(com.setPoint(1,i), com.setPoint(2,i)); 
        poseVM(i,:) = [controller_handle(i).virtualMassX, controller_handle(i).virtualMassY, controller_handle(i).Theta];
    end

    vmPlotHandle = [];
    spPlotHandle = [];
    for i = 1:amountAgent    
       vmHandle =  plot(controller_handle(i).virtualMassX, controller_handle(i).virtualMassY, '-x');
       spHandle =  plot(com.setPoint(1,i), com.setPoint(2,i), '-o');   
   
       vmPlotHandle = [vmPlotHandle vmHandle];
       spPlotHandle = [spPlotHandle spHandle];
    end

    while 1
        loopCnt = loopCnt + 1;        
        % Update mission
        filterUsed = 1;
        if(filterUsed)
            if(mod(loopCnt, 3) == 0)
                [v,c] = com.computeTarget(poseVM);
            end
        else
            [v,c] = com.computeTarget(poseVM);
        end
        
        for i = 1:amountAgent
            % Draw Setpoints
            debugTarget(i, :, loopCnt) = [com.setPoint(1,i), com.setPoint(2,i)];
            set(spPlotHandle(i),'XData', com.setPoint(1,i) ,'YData', com.setPoint(2,i)); %plot current position
            
            % Control Method
            bot_handle(i).move(); 
            debugVM(i, :, loopCnt) = [bot_handle(i).virtualMassX, bot_handle(i).virtualMassY];

            controller_handle(i).updateTarget(com.setPoint(1,i), com.setPoint(2,i));
            %[~,~] = controller_handle(i).orbitingControlWithConstraint(k_inputScale(i,1),k_inputScale(i,2)); 
            %[~,~] = controller_handle(i).BLF_Controller_Quadratic(k_inputScale(i,1),k_inputScale(i,2), A, b, 0);
            [~,~] = controller_handle(i).BLF_Controller_Log(k_inputScale(i,1),k_inputScale(i,2), A, b, 0.2);
            
            % Debug
            debugError(i, loopCnt) = controller_handle(i).distance;
            debugW(i, loopCnt) = bot_handle(i).angleVelocity;
            
            % Update
            set(vmPlotHandle(i),'XData', bot_handle(i).virtualMassX ,'YData', bot_handle(i).virtualMassY); 
            poseVM(i,:) = [bot_handle(i).virtualMassX, bot_handle(i).virtualMassY, bot_handle(i).theta];
            pose(:,i) = bot_handle(i).pose;
        end    

        if(1)
            if(mod(loopCnt-1, 10) == 0)
                %Visualitation   
                env((1:amountAgent), pose);

                if(showColorPlot == true)
                    figure(2);
                    xlim([0 - offset, xrange + offset]);
                    ylim([0 - offset, yrange + offset]);
                    hold on; grid on; %axis equal
                    title("Voronoi Tessellation");
                    for i = 1:numel(com.c) % update Voronoi cells
                       set(spPlotColorHandle(i),'XData', com.setPoint(1,i) ,'YData', com.setPoint(2,i)); %plot current position
                       set(vmPlotColorHandle(i),'XData', bot_handle(i).virtualMassX ,'YData', bot_handle(i).virtualMassY); 
                       set(verCellHandle(i), 'XData',com.v(com.c{i},1),'YData',com.v(com.c{i},2));
                    end
                end
            end
           
            if(loopCnt == 1) % Plot only once
                % Boundaries
                for i = 1: size(worldVertexes,1)-1                
                   plot([worldVertexes(i,1) worldVertexes(i+1,1)],[worldVertexes(i,2) worldVertexes(i+1,2)]);                    
                end
                        
                % Color Patch
                verCellHandle = zeros(amountAgent,1);
                cellColors = cool(amountAgent);
                figure(2);
                xlim([0 - offset, xrange + offset]);
                ylim([0 - offset, yrange + offset]);
                if(showColorPlot == true)
                    vmPlotColorHandle = [];
                    spPlotColorHandle = [];
                    for i = 1:amountAgent % color according to
                        verCellHandle(i) = patch(com.setPoint(1,i),com.setPoint(2,i), cellColors(i,:)); % use color i  -- no robot assigned yet
                       
                        vmHandle =  plot(controller_handle(i).virtualMassX, controller_handle(i).virtualMassY,'x','color',cellColors(i,:)*.2);
                        spHandle =  plot(com.setPoint(1,i), com.setPoint(2,i), '-o');   

                        vmPlotColorHandle = [vmPlotColorHandle vmHandle];
                        spPlotColorHandle = [spPlotColorHandle spHandle];
                    end
                end
            end
        end       
    end
end
%close(aviobj);


