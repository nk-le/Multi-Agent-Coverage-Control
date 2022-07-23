function Logger = ProcessLogFile(logFile)
    LoadParameterExperiment
    %% Default constructor
    fileHandle = load(logFile);
    Logger = DataLoggerRealExp(SIM_PARAM, REGION_CONFIG, CONTROL_PARAM, CONTROL_PARAM.V_CONST* ones(SIM_PARAM.N_AGENT,1), CONTROL_PARAM.W_ORBIT* ones(SIM_PARAM.N_AGENT,1));
    % Parse the log file of the real information into the logger instance
    Logger = retrieve_info(fileHandle.dataTable, Logger);
    fileStr = erase(logFile, ".mat");
    fileStr = erase(fileStr, ".log");
    folder = fullfile(pwd, "Log", sprintf("Figures_%s",fileStr));
    mkdir(folder);
end


%% Helper function
function [Logger] = retrieve_info(dataTable, Logger)   
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
            ControlOutput(agentID, :) = thisAgent.w(i) * 0.02; % TODO: Note that this is currently hard coded due to the imperfections of hardwares
            Vk_List(agentID) = thisAgent.V(i);
            vmCmoord_2d_list(agentID, :) = [thisAgent.zx(i), thisAgent.zy(i)];
            %ID_LIST(agentID) = thisAgent.ID(i);
        end
        [v,c] = Voronoi2d_calcPartition(vmCmoord_2d_list, Logger.regionConfig.BOUNDARIES_VERTEXES);
        Logger.log(pose_3d_list, vmCmoord_2d_list, CVT_2d_List, Vk_List, ControlOutput, v, c);
    end
    
    % Since the real experiments use the real time value, we assign this
    % into the logger
    Logger.set_time_axis(dataTable.(fName{1}).Time);
end