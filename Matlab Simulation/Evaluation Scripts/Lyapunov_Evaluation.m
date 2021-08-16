[simConfig, regionConfig, agentConfig] = Config()
botColors = cool(simConfig.nAgent);
len = logger.curCnt - 1;
startId = 5;
xAxis = startId:len;
V = zeros(1, len);

% BLF
figure(1)
hold on; grid on;
for i = 1:simConfig.nAgent
    nameLegend = sprintf("V_%d",i);
    plot(xAxis, logger.V_BLF(i,xAxis), 'Color', botColors(i,:), 'LineWidth',2, 'DisplayName',nameLegend);
    V(xAxis) = V(xAxis) + logger.V_BLF(i,xAxis);
end
plot(xAxis, V(xAxis), '-r', 'LineWidth',2, 'DisplayName', "V");
ylim([0, max(V)]);
xlim([startId, len]);
xlabel("Iteration");
ylabel("V_k");
title("Barrier Lyapunov Function")
legend
%legend('V_1','V_2','V_3','V')
set(gca,'FontSize',18)

% % Control input
% figure(2)
% hold on; grid on;
% for i = 1:simConfig.nAgent
%     plot(xAxis, logger.ControlOutput(i,xAxis), 'Color', botColors(i,:), 'LineWidth',2);
% end
% plot(xAxis, -wMax*ones(1, numel(xAxis)), '-r', 'LineWidth',4);
% plot(xAxis, wMax*ones(1, numel(xAxis)), '-r', 'LineWidth',4);
% ylim([-0.8, 0.8]);
% xlim([startId, len]);
% xlabel("Iteration");
% ylabel("u_k");
% title("Control Input")
% legend('u_1','u_2','u_3','u_{max}')
% set(gca,'FontSize',18)

% State Trajectories
% figure(3)
% hold on; grid on;
% for i = 1: size(worldVertexes,1)-1                
%    plot([worldVertexes(i,1) worldVertexes(i+1,1)],[worldVertexes(i,2) worldVertexes(i+1,2)],'Color','r','LineWidth',4);                    
% end
% for i = 1:simConfig.nAgent
%    dataVMX = zeros(simConfig.nAgent, loopCnt);
%    dataVMY = zeros(simConfig.nAgent, loopCnt);
%    
%    dataVMX(i,xAxis) =  logger.PoseVM(i,1,xAxis);
%    dataVMY(i,xAxis) =  logger.PoseVM(i,2,xAxis);
%    plot(dataVMX(i,xAxis), dataVMY(i,xAxis),'-o', 'Color', botColors(i,:),'LineWidth',2); 
% end
% xlim([0 - offset, xrange + offset]);
% ylim([0 - offset, yrange + offset]);
% title("Trajectories of virtual masses");
% set(gca,'FontSize',18)
