function out = Parser(InputFileName)
    format long;
    
    if(~exist('InputFileName', 'Var'))
        %% Select the report file for parsing
        dir = [pwd, ''];
        [file,path] = uigetfile(fullfile(dir,'*.log*'),'Choose Log File \n');
        if ~file
            fprintf('No Log file selected. Abort ... \n');
            dataTable = 0;
            return;
        else
            filePath = fullfile(path,file);
            name = erase(file,'.txt'); 
            name = erase(name,'.TXT');
        end
    else
       fprintf("Parsing file %s \n", InputFileName);
       [filePath,name,ext] = fileparts(InputFileName);
       filePath = fullfile(filePath, [name ext]);
    end
    
    fileDir = fileparts(filePath);
    savePath = fullfile(fileDir, sprintf("Parsed_%s.mat", name));
    
    fileHandler = regexp(fileread(filePath),'\n','split');
        
    idList = 20001:20006;
    nAgent = numel(idList);
    
    dataLog = {};
    
    for id = 1:nAgent
       curID = idList(id);
       curIDLines = find(contains(fileHandler,sprintf('%d', curID)));
       dataVec = zeros(numel(curIDLines), 11);
       cnt = 1;
       for lineID = 1: numel(curIDLines)
            try
                tmp = string2data(fileHandler{curIDLines(lineID)});
                if(tmp(1) == curID)
                    dataVec(cnt,:) = tmp;
                    cnt = cnt + 1;
                end
            catch ME 
                disp(ME.message)
            end
       end  
       dataLog.(sprintf("Agent_%d",curID)) = dataVec(~(all(dataVec==0,2)),:);
    end
    
    
    
    %% Convert DataTable
    DataStruct = ["ID", "Time", "x", "y", "theta", "zx", "zy", "Cx", "Cy", "w", "V"];
    agent = fieldnames(dataLog);
    dataTable = {};
    for agentID = 1:numel(agent)
        agentData = dataLog.(agent{agentID});
        % Assign the value according to the variable name
        for topic = 1:numel(DataStruct)
            Value.(DataStruct(topic)) = agentData(:,topic);
        end
        dataTable.(agent{agentID}) = struct2table(Value);
        Value = {};
    end
    save(savePath, "dataTable");
end

function ret = string2data(str)
%     strcell = split(str,',');
%     ret.ID = str2double(strtrim(strcell{1}));
%     ret.Time = str2double(strtrim(strcell{2}));
%     ret.x = str2double(strtrim(strcell{3}));
%     ret.y = str2double(strtrim(strcell{4}));
%     ret.theta = str2double(strtrim(strcell{5}));
%     ret.zx = str2double(strtrim(strcell{6}));
%     ret.zy = str2double(strtrim(strcell{7}));
%     ret.Cx = str2double(strtrim(strcell{8}));
%     ret.Cy = str2double(strtrim(strcell{9}));
%     ret.w = str2double(strtrim(strcell{10}));
%     ret.V = str2double(strtrim(strcell{11}));
    strcell = split(str,',');
    ID = str2double(strtrim(strcell{1}));
    Time = str2double(strtrim(strcell{2}));
    x = str2double(strtrim(strcell{3}));
    y = str2double(strtrim(strcell{4}));
    theta = str2double(strtrim(strcell{5}));
    zx = str2double(strtrim(strcell{6}));
    zy = str2double(strtrim(strcell{7}));
    Cx = str2double(strtrim(strcell{8}));
    Cy = str2double(strtrim(strcell{9}));
    w = str2double(strtrim(strcell{10}));
    V = str2double(strtrim(strcell{11}));
    ret = [ID, Time, x, y, theta, zx, zy, Cx, Cy, w, V];
end

