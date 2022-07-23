% crs = [ 20, 20;    
%             20, 2800;
%             4000, 2800;  % a world with a narrow passage
%             4000, 20];
% n = 6;
% xrange = 4000;
% yrange = 2800;
% startingIter = 10;
% fileId = 2;
% %for fileId = 0:3
%     
% filename =  sprintf("Parsed_TRO_LogSim%d.log.mat", fileId);
% videoname = sprintf("Lyapunov_%d", fileId);
% 
% dataTable = load(filename);
% dataTable = dataTable.dataTable;
% numIterations = numel(dataTable.Agent_20001.Time);
% fName = fieldnames(dataTable);
% 
% [ti, vi, wi, w0, wLim] = get_control_info(dataTable, 1);
% %% Plot Handles to adjust the color and update the data
% figure('units','normalized','outerposition',[0 0 1 1])
% cellColors = cool(n);
% 
% subplot(121);
% lyapunovHandle = cell(n,1);
% for i = 1:n % color according to
%     lyapunovHandle{i} = plot(1, vi(i), 'color',cellColors(i,:)*.8, 'linewidth',2, 'LineStyle', '-'); 
%     hold on; grid on;
% end
% 
% sumV = sum(vi);
% sumLyapunovHandle =  plot(1, sumV, 'linewidth',2, 'LineStyle', '--', "DisplayName", "V(Z)"); 
% 
% titleHandle = title('Lyapunov Evaluation');
% %axis([0 , numIterations, 0, sumV * 1.2]);
% ylim([0, sumV * 1.2])
% xlabel("Iteration");
% ylabel("V(Z)");
% %legend
% ax = gca;
% ax.FontSize = 20;
% 
% subplot(122)
% inputHandle = cell(n,1);
% 
% for i = 1:n % color according to
%     inputHandle{i} = plot(1, wi(i) - w0, 'color',cellColors(i,:)*.8, 'linewidth',2, 'LineStyle', '-'); 
%     hold on; grid on;
%     %upperLimitHandle = plot([1, 1], [wLim - w0, -wLim-w0], 'color', [1, 0, 0], 'linewidth',2, 'LineStyle', '*');
%     %lowerLimitHandle = plot([1, 1], [wLim - w0, -wLim-w0], 'color', [1, 0, 0], 'linewidth',2, 'LineStyle', '*');
%     
% end
% titleHandle = title(sprintf('Control Input Evaluation. Orbital Velocity: %s = %.1f rad/s', "\omega_0", 0.8));
% %axis([0 , numIterations, -80, 80]);
% ylim([-wLim-w0-0.5, wLim])
% xlabel("Iteration");
% ylabel("u_k(t) - \omega_0 [rad/s]");
% 
% ax = gca;
% ax.FontSize = 20;
% 
% %% To video
% myVideo = VideoWriter(videoname); %open video file
% myVideo.Quality = 100;
% myVideo.FrameRate = 30;  
% open(myVideo)
% 
% %%
% for iter = startingIter + 1:numIterations
%     [ti, vi, wi, w0] = get_control_info(dataTable, iter);
%     
%     % Plot sub Lyapunov Function
%     for i = 1:n
%         index = get(lyapunovHandle{i},'XData');
%         V = [get(lyapunovHandle{i},'YData'), vi(i)];
%         set(lyapunovHandle{i},'XData', startingIter:iter,'YData',V); %plot position path         
%     end 
% 
%     % Plot the total Lyapunov
%     index = get(sumLyapunovHandle,'XData');
%     V = [get(sumLyapunovHandle,'YData'), sum(vi)];
%     set(sumLyapunovHandle,'XData', startingIter:iter,'YData',V); %plot position path
% 
%     % Plot the control input
%     for i = 1:n
%         index = get(inputHandle{i},'XData');
%         u = [get(inputHandle{i},'YData'), wi(i) - w0];
%         set(inputHandle{i},'XData', startingIter:iter ,'YData', u); %plot position path      
%     end 
%     tmp = startingIter:iter;
%     plot(tmp, (wLim - w0) * ones(size(tmp)), "Color", [1,0,0], "LineWidth", 2);
%     plot(tmp, (-wLim - w0) * ones(size(tmp)), "Color", [1,0,0], "LineWidth", 2);
% 
%     frame = getframe(gcf); %get frame
%     writeVideo(myVideo, frame);
%     disp(iter)
% end
% close(myVideo)
% 
% function w = mapAngularVel(inp)
%     w = 16/20 * inp/40;
% end
% 
% 
% function [ti, vi, wi, w0, wLim] = get_control_info(dataTable, iter)
%     fName = fieldnames(dataTable);
%     n = numel(fName);
%     ti = zeros(n, 1);
%     vi = zeros(n, 1); 
%     wi = zeros(n, 1);
%    
%     for id = 1: n
%         ti(id) = dataTable.(fName{id}).Time(iter);
%         vi(id) = dataTable.(fName{id}).V(iter);
%         wi(id) = mapAngularVel(dataTable.(fName{id}).w(iter));
%     end
%     w0 = mapAngularVel(40);
%     wLim = mapAngularVel(80);
% end