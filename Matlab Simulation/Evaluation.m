% State
figure(3)
hold on; grid on; axis equal;
figure(4)
hold on; grid on; 
wMax = 1.6;
offset = 2;
debugColors = cool(amountAgent);

% State Trajectories
figure(3)
for i = 1: size(worldVertexes,1)-1                
   plot([worldVertexes(i,1) worldVertexes(i+1,1)],[worldVertexes(i,2) worldVertexes(i+1,2)],'LineWidth',2);                    
end
for i = 1:amountAgent
   dataVMX = zeros(amountAgent, loopCnt);
   dataVMY = zeros(amountAgent, loopCnt);
   
   dataVMX(i, 1:loopCnt) =  debugVM(i,1,1:loopCnt);
   dataVMY(i, 1:loopCnt) =  debugVM(i,2,1:loopCnt);
   dataVMX(dataVMX == 0) = NaN;
   dataVMY(dataVMY == 0) = NaN;
   plot(dataVMX(i,:), dataVMY(i,:), 'color', debugColors(i,:),'LineWidth',1); 
end
xlim([0 - offset, xrange + offset]);
ylim([0 - offset, yrange + offset]);
title("Trajectories of all virtual masses");

% Input Saturation
figure(4)
sgtitle("Control Input of all agents. Input Constraints [-1.6  1.6] rad/s");
limUp = wMax * ones(1,loopCnt);
limDown = -wMax * ones(1,loopCnt);
for i = 1:amountAgent
   subplot(5,1,i)
   tmp = debugW(i,1:loopCnt);
   %tmp(tmp >= wMax | tmp <= -wMax) = 0;
   plot(1:loopCnt, tmp, 'color', debugColors(i,:)); 
   hold on; grid on; 
   
   plot(1:loopCnt, limUp(1:loopCnt), '-r', 'LineWidth',1);
   plot(1:loopCnt, limDown(1:loopCnt), '-r', 'LineWidth',1);
   xlim([0 loopCnt]);
   ylim([-1.6 1.6]);
end

