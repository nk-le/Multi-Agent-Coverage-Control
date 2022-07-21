SIM_PARAM = SimulationParameter();
REGION_CONFIG = RegionParameter();
CONTROL_PARAM = ControlParameter();

SIM_PARAM.N_AGENT = 6;
CONTROL_PARAM.V_CONST = 16;
CONTROL_PARAM.W_ORBIT = 0.8;
CONTROL_PARAM.W_LIMIT = 1.6;

vertexes = [ 20, 20;    
        20, 2800;
        4000, 2800;  % a world with a narrow passage
        4000, 20;
        20, 20];
REGION_CONFIG.set_vertexes(vertexes);

for fileID = 0:4
    logFile = sprintf("Parsed_TRO_LogSim%d.log.mat", fileID);
    Logger = DataLogger(SIM_PARAM, REGION_CONFIG, CONTROL_PARAM, CONTROL_PARAM.V_CONST* ones(SIM_PARAM.N_AGENT,1), CONTROL_PARAM.W_ORBIT* ones(SIM_PARAM.N_AGENT,1));
    fileHandle = load(logFile);
    Logger = get_info(fileHandle.dataTable, Logger);


    %% Generating figures
    fileStr = erase(logFile, ".mat");
    fileStr = erase(fileStr, ".log");
    folder = fullfile(pwd, "Log", sprintf("Figures_%s",fileStr));
    mkdir(folder);
    Logger.generate_figures(fileStr, folder);
    close all;
end


function [Logger] = get_info(dataTable, Logger)   
    % get n Agent
    fName = fieldnames(dataTable);
    nAgent = Logger.SIM_PARAM.N_AGENT;
    assert(numel(fName) == nAgent);
    
    % get total iteration
    nIter = size(dataTable.(fName{1}).Time, 1);
    ID_LIST = zeros(nAgent, 1);
    pose_3d_list = zeros(nAgent, 3);
    CVT_2d_List = zeros(nAgent, 2);
    ControlOutput = zeros(nAgent, 1);
    Vk_List = zeros(nAgent, 1);
    vmCmoord_2d_list = zeros(nAgent, 2);
    
    for i = 1: nIter
        for agentID = 1: nAgent
            thisAgent = dataTable.(fName{agentID});
            pose_3d_list(agentID, :) = [thisAgent.x(i), thisAgent.y(i), thisAgent.theta(i)];
            CVT_2d_List(agentID,:) = [thisAgent.Cx(i), thisAgent.Cy(i)];
            ControlOutput(agentID, :) = thisAgent.w(i) * 0.02; % Note that this is currently hard coded due to the imperfections of hardwares
            Vk_List(agentID) = thisAgent.V(i);
            vmCmoord_2d_list(agentID, :) = [thisAgent.zx(i), thisAgent.zy(i)];
            %ID_LIST(agentID) = thisAgent.ID(i);
        end
        [v,c] = Voronoi2d_calcPartition(vmCmoord_2d_list, Logger.regionConfig.BOUNDARIES_VERTEXES);
        Logger.log(pose_3d_list, vmCmoord_2d_list, CVT_2d_List, Vk_List, ControlOutput, v, c);
    end
    
    % Temporary add this execution time (only the real experiments is available)
    Logger.ExcTime = dataTable.(fName{1}).Time;
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
