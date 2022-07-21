crs = [ 20, 20;    
            20, 2800;
            4000, 2800;  % a world with a narrow passage
            4000, 20];
n = 6;
xrange = 4000;
yrange = 2800;
startingIter = 10;
    
for fileId = 0:3
    filename =  sprintf("Parsed_TRO_LogSim%d.log.mat", fileId);
    videoname = sprintf("Video_%d", fileId);

    dataTable = load(filename);
    dataTable = dataTable.dataTable;
    numIterations = numel(dataTable.Agent_20001.Time);
    fName = fieldnames(dataTable);
    [px, py, vmx, vmy, Cx, Cy] = get_agents_coord(dataTable, startingIter);

    %% Plot Handles to adjust the color and update the data
    figure('units','normalized','outerposition',[0 0 1 1])

    verCellHandle = cell(n,1);
    vmPathHandle = cell(n,1);    
    posPathHandle = cell(n,1);

    posHandle = cell(n,1);
    cvtHandle = cell(n,1);
    vmHandle = cell(n,1);
    cellColors = cool(n);


    for i = 1:numel(vmx) % color according to
        verCellHandle{i}  = patch(vmx(i),vmy(i),cellColors(i,:)); % use color i  -- no robot assigned yet
        verCellHandle{i}.FaceAlpha = 0.3;
        hold on
        grid on;

    end


    for i = 1:n % color according to
        posPathHandle{i} = plot(px(i), py(i), 'color',cellColors(i,:)*.8, 'linewidth',2, 'LineStyle', '-');  
        posPathHandle{i}.Color(4) = 1;
        vmPathHandle{i}  = plot(vmx(i),vmy(i), 'color',cellColors(i,:)*.8, 'linewidth',2, 'LineStyle', '--');
        vmPathHandle{i}.Color(4) = 1;

        cvtHandle{i} = plot(Cx(i),Cy(i),'+','linewidth',2, 'color',cellColors(i,:)*.8);
        vmHandle{i} = plot(vmx(i),vmy(i),'o','linewidth',2, 'color',cellColors(i,:)*.8);
        posHandle{i} = plot(px(i),py(i),'linewidth',2, 'color',cellColors(i,:)*.8);
        %numHandle(i) = text(Px(i),Py(i),num2str(i));
    end
    titleHandle = title(['o = Robots, + = Goals, Iteration ', num2str(0)]);

    ax = gca;
    ax.FontSize = 20;

    %% To video
    myVideo = VideoWriter(videoname); %open video file
    myVideo.Quality = 100;
    myVideo.FrameRate = 30;  
    open(myVideo)

    %%
    for iter = startingIter:numIterations
        [px, py, vmx, vmy, Cx, Cy] = get_agents_coord(dataTable, iter);

        % Plot VMs and CVTs 
        for i = 1:numel(vmx)
            set(vmHandle{i},'XData',vmx(i),'YData',vmy(i));
            set(cvtHandle{i},'XData',Cx(i),'YData',Cy(i));
            % Path
            tmpPathX = get(posPathHandle{i},'XData');
            tmpPathY = get(posPathHandle{i},'YData');
            pxD = [tmpPathX(end - min(end,50) + 1: end),px(i)];
            pyD = [tmpPathY(end - min(end,50) + 1: end),py(i)];
            set(posPathHandle{i},'XData',pxD,'YData',pyD); %plot position path         

            % Virtual mass
            vmxD = [get(vmPathHandle{i},'XData'),vmx(i)];
            vmyD = [get(vmPathHandle{i},'YData'),vmy(i)];
            set(vmPathHandle{i},'XData',vmxD,'YData',vmyD); %plot vm path        
        end 

        % Update Voronoi cells
        [v,c]=VoronoiBounded(vmx,vmy, crs);
        for i = 1:numel(c) 
            set(verCellHandle{i}, 'XData',v(c{i},1),'YData',v(c{i},2));
        end

        set(titleHandle,'string',['o = Virtual Mass, + = Centroid Voronoi | - = Agent Path, -- = VM Path | Iteration: ', num2str(iter,'%3d')]);
        axis equal;
        offset = 200;
        axis([-offset , xrange + offset, -offset, yrange + offset]);
        xlabel("X Coordinate");
        ylabel("Y Coordinate");
        %drawnow


        frame = getframe(gcf); %get frame
        writeVideo(myVideo, frame);
        disp(iter)
    end
    close(myVideo);
end

%% Get the data as patch
function [px, py, vmx, vmy, Cx, Cy] = get_agents_coord(dataTable, iter)
    fName = fieldnames(dataTable);
    n = numel(fName);
    px = zeros(n, 1); 
    py = zeros(n, 1);
    vmx = zeros(n, 1);
    vmy = zeros(n, 1);
    Cx = zeros(n, 1);
    Cy = zeros(n, 1);
    for id = 1: n
        vmx(id) = dataTable.(fName{id}).zx(iter);
        vmy(id) = dataTable.(fName{id}).zy(iter);
        Cx(id) = dataTable.(fName{id}).Cx(iter);
        Cy(id) = dataTable.(fName{id}).Cy(iter);
        px(id) = dataTable.(fName{id}).x(iter);
        py(id) = dataTable.(fName{id}).y(iter);
    end
end



%% Compute the vertexes according to the virtual mass position
% Credit to: Aaron Becker, atbecker@uh.edu
function [V,C]=VoronoiBounded(x,y, crs)
    % VORONOIBOUNDED computes the Voronoi cells about the points (x,y) inside
    % the bounding box (a polygon) crs.  If crs is not supplied, an
    % axis-aligned box containing (x,y) is used.

    bnd=[min(x) max(x) min(y) max(y)]; %data bounds
    if nargin < 3
        crs=double([bnd(1) bnd(4);bnd(2) bnd(4);bnd(2) bnd(3);bnd(1) bnd(3);bnd(1) bnd(4)]);
    end

    rgx = max(crs(:,1))-min(crs(:,1));
    rgy = max(crs(:,2))-min(crs(:,2));
    rg = max(rgx,rgy);
    midx = (max(crs(:,1))+min(crs(:,1)))/2;
    midy = (max(crs(:,2))+min(crs(:,2)))/2;

    % add 4 additional edges
    xA = [x; midx + [0;0;-5*rg;+5*rg]];
    yA = [y; midy + [-5*rg;+5*rg;0;0]];

    [vi,ci]=voronoin([xA,yA]);

    % remove the last 4 cells
    C = ci(1:end-4);
    V = vi;
    % use Polybool to crop the cells
    % Polybool for restriction of polygons to domain.

    for ij=1:length(C)
            % thanks to http://www.mathworks.com/matlabcentral/fileexchange/34428-voronoilimit
            % first convert the contour coordinate to clockwise order:
            [X2, Y2] = poly2cw(V(C{ij},1),V(C{ij},2));
            [xb, yb] = polybool('intersection',crs(:,1),crs(:,2),X2,Y2);
            ix=nan(1,length(xb));
            for il=1:length(xb)
                if any(V(:,1)==xb(il)) && any(V(:,2)==yb(il))
                    ix1=find(V(:,1)==xb(il));
                    ix2=find(V(:,2)==yb(il));
                    for ib=1:length(ix1)
                        if any(ix1(ib)==ix2)
                            ix(il)=ix1(ib);
                        end
                    end
                    if isnan(ix(il))==1
                        lv=length(V);
                        V(lv+1,1)=xb(il);
                        V(lv+1,2)=yb(il);
                        ix(il)=lv+1;
                    end
                else
                    lv=length(V);
                    V(lv+1,1)=xb(il);
                    V(lv+1,2)=yb(il);
                    ix(il)=lv+1;
                end
            end
            C{ij}=ix;

    end
end


