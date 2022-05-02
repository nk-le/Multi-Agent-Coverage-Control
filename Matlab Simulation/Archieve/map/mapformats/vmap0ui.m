function vmap0ui(devicename)
%VMAP0UI UI for selecting data from Vector Map Level 0
%
%   VMAP0UI(DIRNAME) launches a graphical user interface for interactively
%   selecting and importing data from a Vector Map Level 0 (VMAP0) data
%   base.  Use the string DIRNAME to specify the directory containing the
%   data base.  For more on using VMAP0UI, click the HELP button after the
%   interface appears.
%
%   VMAP0UI(DEVICENAME) or VMAP0UI DEVICENAME uses the logical device
%   (volume) name specified in string DEVICENAME to locate CD-ROM drive
%   containing the VMAP0 CD-ROM.  Under the Windows operating system it
%   could be 'F:' or 'G:' or some other letter.  Under Macintosh OS X it
%   should be '/Volumes/VMAP'.  Under other UNIX systems it could be
%   '/cdrom/'.
%
%   VMAP0UI can be used on Windows without any arguments.  In this case it
%   attempts to automatically detect a drive containing a VMAP0 CD-ROM. If
%   VMAP0UI fails to locate the CD-ROM device, then specify it explicitly.
%
%   Vector Map Level 0, created in the 1990s, is still probably the most
%   detailed global database of vector map data available to the public.
%   VMAP0 CD-ROMs are available from through the U.S. Geological Survey
%   (USGS):
%
%       USGS Information Services (Map and Book Sales) 
%       Box 25286 
%       Denver Federal Center 
%       Denver, CO 80225 
%       Telephone: (303) 202-4700 
%       Fax: (303) 202-4693
%
%   Examples 
%   -------- 
%   % Launch VMAP0UI and automatically detect a CD-ROM on Windows 
%   vmap0ui
%
%   % Launch VMAP0UI on Macintosh OS X (need to specify volume name)
%   vmap0ui('Volumes/VMAP')
%
%   See also DISPLAYM, EXTRACTM, MLAYERS, VMAP0DATA.

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  W. Stumpf

% Try to autodetect CD if no device name provided.
if nargin == 0
    devicename = getdevicename;
    
    if isempty(devicename)
        error('map:vmap0ui:deviceNotFound', ...
            'Couldn''t detect the VMAP0 CD. Please provide a device name.')
    end
    
    if numel(devicename) > 1
        warning('map:vmap0ui:multipleDataCDsFound',...
            'More than one VMAP0 CD found. Using %s', devicename{1})
    end
    
    devicename = devicename{1};
else
    devicename = convertStringsToChars(devicename);
end
vmap0uistart(devicename)

%--------------------------------------------------------------------------

function foundpth = getdevicename
%GETDEVICENAME searches for VMAPLVL0 directory
%
% foundpath = GETDEVICENAME PC device names for the vmaplvl0 directory. 
% Now try all letter drives on PCs (A-Z)

s.name = 'vmaplv0';
foundpth = {};
if ispc
    
    for j=1:26
        
        pth = [char('A'+j-1) ':\'];
        try
            
            d = dir(pth);
            d(~[d.isdir]) = [];
            for i=1:length(s)
                if ~isempty(d) && ismember(s(i).name,lower({d.name}))
                    foundpth{end+1} = pth; 
                end
            end
            
        catch
            %oops, that drive didn't exist
        end
        
    end
    
elseif strcmp(computer,'MAC2')
    pth = 'vmap:';
    try
        
        d = dir(pth);
        d(~[d.isdir]) = [];
        for i=1:length(s)
            if ~isempty(d) && ismember(s(i).name,lower({d.name}))
                foundpth{end+1} = pth; 
            end
        end
        
    catch
        %oops, that drive didn't exist
    end
end

%--------------------------------------------------------------------------

function vmap0uistart(devicename)

% check for valid inputs


% Check that the top of the database file hierarchy is visible, and note
% the case of the directory and filenames.

filepath = fullfile(devicename,filesep);
dirstruc = dir(filepath);

if isempty(strmatch('VMAPLV0',upper(strvcat(dirstruc.name)),'exact')) %#ok<*DSTRVCT,*MATCH3>
    error('map:vmap0ui:deviceNotMounted1', ...
        'VMAP Level 0 disk not mounted or incorrect devicename.');
end

if ~isempty(strmatch('VMAPLV0',{dirstruc.name},'exact'))
    filesystemcase = 'upper';
elseif ~isempty(strmatch('vmaplv0',{dirstruc.name},'exact'))
    filesystemcase = 'lower';
else
    error('map:vmap0ui:mixedCaseFilenames', ...
        'Unexpected mixed case filenames.')
end

% Read the library attribute table to get the library associated with the
% device

switch filesystemcase
    case 'upper'
        filepath = fullfile(devicename,'VMAPLV0',filesep);
    case 'lower'
        filepath = fullfile(devicename,'vmaplv0',filesep);
end
LAT = vmap0read(filepath,'LAT');

library = LAT(end).library_name;

% build the pathname so that [pathname filename] is the full filename

switch filesystemcase
    case 'upper'
        filepath = fullfile(devicename,'VMAPLV0',upper(library),filesep);
    case 'lower'
        filepath = fullfile(devicename,'vmaplv0',lower(library),filesep);
end

dirstruc = dir(filepath);
if isempty(dirstruc)
    error('map:vmap0ui:deviceNotMounted2', ...
        'VMAP Level 0 disk %s not mounted or incorrect devicename.', ...
        upper(library));
end

% Read the list of themes on the CD

CAT = vmap0read(filepath,'CAT');

% Remove the metadata themes from the Coverage Attributes Table

% indx = find(ismember({CAT.coverage_name},{'libref','tileref','dq'}));
CAT(ismember({CAT.coverage_name},{'libref','tileref','dq'})) = [];

% Get the essential libref information (tile name/number, bounding boxes)

switch filesystemcase
    case 'upper'
        filepath = fullfile(devicename,'VMAPLV0',upper(library),'TILEREF',filesep);
    case 'lower'
        filepath = fullfile(devicename,'vmaplv0',lower(library),'tileref',filesep);
end

% tFT = vmap0read(filepath,'TILEREF.AFT');
FBR = vmap0read(filepath,'FBR');


%get information on type and attributes of data within each theme

for i=1:length(CAT)
    
    switch filesystemcase
        case 'upper'
            filepath = fullfile(devicename,'VMAPLV0',upper(library),upper(CAT(i).coverage_name),filesep);
            ifilename = 'INT.VDT';
            cfilename = 'CHAR.VDT';
        case 'lower'
            filepath = fullfile(devicename,'vmaplv0',lower(library),lower(CAT(i).coverage_name),filesep);
            ifilename = 'int.vdt';
            cfilename = 'char.vdt';
    end
    
    if sign(exist([filepath ifilename],'file'))
        [ivdt{i},ivdtheader{i}] = vmap0read(filepath,ifilename); %#ok<*AGROW>
    end
    if sign(exist([filepath cfilename],'file'))
        [cvdt{i},cvdtheader{i}] = vmap0read(filepath,cfilename);
    end
    
    wildcard = '*FT';
    if strcmp(filesystemcase,'lower'); wildcard = lower(wildcard); end
    FTfilenames{i} = dir([filepath wildcard]);
    
    for j=1:length(FTfilenames{i})
        headerstr = vmap0rhead(filepath,FTfilenames{i}(j).name);
        [field,~,description,~] =  vmap0phead(headerstr);
        FTfilenames{i}(j).description = strrep(description,' Feature Table','');
        FTfilenames{i}(j).fields = field;
    end
    
end

% construct panel and exit

vmap0uiPanel(CAT,FBR,ivdt,ivdtheader,cvdt,cvdtheader,FTfilenames,devicename,library)

%--------------------------------------------------------------------------

function vmap0uiPanel(CAT,FBR,ivdt,ivdtheader,cvdt,cvdtheader,FTfilenames,devicename,library)
%VMAP0UIPANEL constructs the VMAP0UI panel

% VMAPUI state data
h.devicename = devicename;
h.library = library;
h.FBR = FBR;
h.CAT = CAT;
h.ivdt = ivdt;
h.cvdt = cvdt;
h.ivdtheader = ivdtheader;
h.cvdtheader = cvdtheader;
h.FTfilenames = FTfilenames;

for i=1:length(CAT)
    h.VMAPnames{i}=h.CAT(i);
end

h.objparent = zeros(1,length(CAT));
h.objhndl = 1:length(CAT);
h.expandable = ones(1,length(CAT));

sources = char(CAT.description);
suffixstr = ' +   ';
sources = [repmat(suffixstr,length(CAT),1) sources];

% Build the GUI panel

%  Create the dialog window
h.fig = figure('Color',[0.8 0.8 0.8], ...
    'units','character',...
    'Position', [5.2000    2.7692  112.2000   33.1538],...
    'Tag','VMAP0UI','Visible','off',...
    'Menubar','none','Name','VMAP0UI','NumberTitle','off');

colordef(h.fig,'white');
figclr = get(h.fig,'Color');
frameclr = brighten(figclr,0.5);

p = uipanel( ...
    'Units','normalized',...
    'Position',[0.349732824427481 0.149898404255319 .599541984732825 0.799455141843972],...
    'Parent', h.fig);
c = get(h.fig, 'Color');

% Insert axes into a panel.
set(p, ...
    'BackgroundColor',c, ...
    'ForegroundColor',c, ...
    'HighlightColor',c', ...
    'ShadowColor',c)

h.axes = axes('Parent', p, ...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Tag','samplemapaxes');

% Overview map
lonlim = [min([FBR.xmin]) max([FBR.xmax])];
latlim = [min([FBR.ymin]) max([FBR.ymax])];

axesm('pcarree', 'Frame', 'on', 'Origin', [0 0 0], ...
    'MapLatlimit', latlim, 'MapLonLimit', lonlim)
tightmap
h.lim = [xlim ylim];
set(handlem('alltext'),'clipping','on')

% Base map data
coast = load('coastlines');
hold on
geoshow(coast.coastlat, coast.coastlon, 'Color',.65*[1 1 1], 'Parent', h.axes);
clear coast

h.list = uicontrol('Style','list','units','Character',...
    'Position',[2.2440    4.9731   33.6600   25.5285],'Max',1E6,...
    'Interruptible','off','BackgroundColor','w', ...
    'String',sources,'Callback', @vmap0uilist);
h.selected = 1;

h.listlabel = uicontrol('Style','text','Units','Character',...
    'Position',[2.2440   30.8331   33.6600    0.9946], ...
    'String','Available Data  ', ...
    'FontWeight','bold','backgroundColor',get(h.fig,'Color'));

% Buttons
h.helpbtn = uicontrol('Parent',h.fig, ...
    'Units','character', ...
    'Position',[4.7206    0.8369   13.2178    2.7898], ...
    'Style','push', ...
    'String','Help', ...
    'Tag','helpbtn',...
    'Callback', @(~,~) doc('vmap0ui'),...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

h.clearbtn = uicontrol('Parent',h.fig, ...
    'Units','character', ...
    'Position', [47.2063    0.8369   13.2178    2.7898], ...
    'Style','push', ...
    'String','Clear', ...
    'Tag','clearbtn',...
    'Callback', @vmap0uiclear,...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

h.getbtn = uicontrol('Parent',h.fig, ...
    'Units','character', ...
    'Position',[18.8825    0.8369   13.2178    2.7898], ...
    'Style','push', ...
    'String','Get', ...
    'Tag','getbtn',...
    'Callback', @vmap0uiget,...
    'Interruptible','on',...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

h.savebtn = uicontrol('Parent',h.fig, ...
    'Units','character', ...
    'Position',[75.5300    0.8369   13.2178    2.7898], ...
    'Style','push', ...
    'String','Save', ...
    'Tag','savebtn',...
    'Callback', @vmap0uisave,...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

h.closebtn = uicontrol('Parent',h.fig, ...
    'Units','character', ...
    'Position',[89.6919    0.8369   13.2178    2.7898], ...
    'Style','push', ...
    'String','Close', ...
    'Callback', @vmap0uiclose,...
    'Tag','closebtn',...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

% Display tiles.
zdatam('allline',-.75)
h.tiles = patchesm([FBR.ymin; FBR.ymax; FBR.ymax; FBR.ymin; FBR.ymin],...
    [FBR.xmin; FBR.xmin; FBR.xmax; FBR.xmax; FBR.xmin],'y',...
    'Tag','tiles','edgecolor',.85*[ 1 1 1]);
zdatam(h.tiles,-1);
uistack(h.tiles,'bottom')
set(h.tiles,'facecolor','y')

h.baseobjects = get(h.axes,'Children');

% Display count of tiles covered by current view
do = vmap0do(FBR,latlim,lonlim);
set(get(h.axes,'Title'),'String',[ num2str(length(do)) ' tiles'])
set(handlem('tiles'),'facecolor',[0.99          1.00          0.85])

% Make figure resizeable
set([...
    h.helpbtn,...
    h.clearbtn,...
    h.getbtn,...
    h.savebtn,...
    h.closebtn,...
    h.list,...
    h.listlabel,...
    h.axes],'units','normalized')

set([...
    h.helpbtn,...
    h.clearbtn,...
    h.getbtn,...
    h.savebtn,...
    h.closebtn,...
    h.listlabel,...
    ],'fontunits','normalized')

% Initialize saved VMAP data
h.extracteddata = [];

% Set tag value.
h.tag = 'vmap0data';

% Set Figure properties.
set(h.fig, 'UserData', h, ...
    'Visible','on', ...
    'HandleVis','callback', ...
    'WindowButtonMotionFcn', @windowButtonMotionCallback)

% Enable zoom
h.zoom = zoom(h.fig);
set(h.zoom, 'Enable', 'on', 'ActionPostCallback', @zoomCallback)

%--------------------------------------------------------------------------

function windowButtonMotionCallback(fig, ~)

if overaxes(fig)
    % Change the cursor to a magnifying glass over the map axes
    set(fig,'pointer','custom', ...
        'PointerShapeCdata',magcursor(),'PointerShapeHotSpot',[7 7])
else
    set(fig,'pointer','arrow')
end

vmap0uitilecount(fig)

%--------------------------------------------------------------------------

function C = magcursor()

C = [
    0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0
    0 0 1 1 1 0 0 1 1 1 0 0 0 0 0 0
    0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 0
    0 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0
    1 1 0 0 0 0 0 0 0 0 1 1 0 0 0 0
    1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0
    1 1 0 0 0 0 0 0 0 0 1 1 0 0 0 0
    0 1 0 0 0 0 0 0 0 1 1 0 0 0 0 0
    0 1 1 0 0 0 0 0 0 1 0 0 0 0 0 0
    0 0 1 1 1 0 0 1 1 1 1 0 0 0 0 0
    0 0 0 0 1 1 1 1 0 1 1 1 0 0 0 0
    0 0 0 0 0 1 0 0 0 0 1 1 1 0 0 0
    0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0
    0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 0
    0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1
    0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
    ];

C(C == 0)= NaN;

%--------------------------------------------------------------------------

function tf = overaxes(fig)
% If the figure fig contains a single axes (which we expect to be the
% case), return true if the cursor is over that axes.

tf = false;
panel = findobj(fig, 'type','uipanel'); 
if isscalar(panel)
    % We expect ax to scalar, but check just to be safe, and do nothing if
    % it does not have exactly one element.
    
    % Get cursor location and figure position in the same units as root.
    p = get(0,'PointerLocation');
    units = get(fig,'Units');
    set(fig,'Units',get(0,'Units'))
    figPos = get(fig,'Position');
    set(fig,'Units',units)
    
    % Normalize cursor location relative to figure.
    x = (p(1) - figPos(1)) / figPos(3);
    y = (p(2) - figPos(2)) / figPos(4);
    
    % Get axes position in normalized units.
    units = get(panel,'Units');
    set(panel,'Units','norm')
    r = get(panel,'Position');
    set(panel,'Units',units)
    
    % Compare normalized positions.
    tf = r(1) <= x && x <= r(1) + r(3) ...
        && r(2) <= y && y <= r(2) + r(4);
end

%--------------------------------------------------------------------------

function vmap0uitilecount(fig)
% Updates the count of visible tiles

h = get(fig,'UserData');
xLimits = get(h.axes,'XLim');
yLimits = get(h.axes,'Ylim');

if ~(all(h.lim == [xLimits yLimits]))
    [latlim,lonlim] = pcarreeInverse(xLimits, yLimits);
    
    do = vmap0do(h.FBR,latlim,lonlim);
    if isscalar(do)
        tileName = ' tile';        
    else
        tileName = ' tiles';
    end
    set(get(h.axes,'Title'),'String',[ num2str(length(do)) tileName])
    
end

%--------------------------------------------------------------------------

function vmap0uiclear(hsrc, ~)
% Removes extracted data from the plot and storage

hfig = get(hsrc,'Parent');
state = get(hfig,'userdata');
if isfield(state,'tag')
    htag = findall(state.axes, 'tag', state.tag);
    delete(htag);
end
state.extracteddata = [];
set(state.fig,'userdata',state)

zdatam(state.tiles,-1)
set(state.tiles,'Facecolor',[0.99 1.00 0.85],'Edgecolor',.85*[ 1 1 1])

%--------------------------------------------------------------------------

function vmap0uiclose(hsrc, ~)
% Closes the VMAP0UI panel

hfig = get(hsrc,'Parent');
state = get(hfig,'userdata');

%check if a get is in progress
hwaitbar = findall(0,'type','figure','tag','TMWWaitbar','UserData', state);
if ishghandle(hwaitbar,'figure')
    delete(hwaitbar)
end

close(hfig)

%--------------------------------------------------------------------------

function vmap0uisave(hsrc, ~)
% Save VMAP0UI data.

hfig = get(hsrc,'Parent');
state = get(hfig,'userdata');

%check if a get is in progress
hwaitbar = findall(0,'type','figure','tag','TMWWaitbar','UserData', state);
if ishghandle(hwaitbar,'figure')
    return
end

if isempty(state.extracteddata)
    warndlg('No data to save','VMAP0UI warning')
    return
end

answer = questdlg( ...
    'Save data to a Mat-file or the base workspace?', ...
    'VMAP0UI Save',...
    'Mat-File','Workspace','Cancel','Mat-File');

switch answer
    case 'Mat-File'
        vmap0filesave(state.extracteddata)
    case 'Workspace'
        vmap0workspacesave(state.extracteddata)
end

%--------------------------------------------------------------------------

function vmap0workspacesave(extracteddata)

answer = questdlg(...
    strvcat({ ...
    ' The following variables will be created in the base workspace: ',...
    extracteddata{:,2},' '}),...
    'VMAP0UI SAVE','OK','Cancel','OK');

if strcmp(answer, 'OK')
    for i=1:size(extracteddata,1)
        assignin('base',extracteddata{i,2},extracteddata{i,1})
    end
end

%--------------------------------------------------------------------------

function vmap0filesave(VMAPdata)

curpwd = pwd;
[filename,pathname] = uiputfile('*.mat', 'Save the VMAP data in MAT-file:');
if filename ~= 0
    
    eval([ VMAPdata{1,2} ' = VMAPdata{1,1};' ]);
    save([pathname filename],VMAPdata{1,2})
    clear(VMAPdata{1,2});
    
    for i=2:size(VMAPdata,1)        
        eval([ VMAPdata{i,2} ' = VMAPdata{i,1};' ]);
        save([pathname filename],VMAPdata{i,2},'-APPEND')
        clear(VMAPdata{i,2});
    end
    
    cd(curpwd)
end

%--------------------------------------------------------------------------

function vmap0uiget(hsrc,~)
% Extract data from the VMAP0 CD

hfig = get(hsrc,'Parent');
state = get(hfig,'userdata');

%check if a get is in progress
hwaitbar = findall(0,'type','figure','tag','TMWWaitbar','UserData', state);
if ishghandle(hwaitbar,'figure')
    return
end

% Determine latitude and longitude limits from current axis limits
xLimits = get(state.axes,'XLim');
yLimits = get(state.axes,'Ylim');
[latlim, lonlim] = pcarreeInverse( ...
    [min(xLimits) max(xLimits)],[min(yLimits) max(yLimits)]);

% Determine which tiles are visible
do = vmap0do(state.FBR,latlim,lonlim);

% Check if the user really wants to extract ALL the tiles

if length(do) == length(state.FBR)-1
    answer = questdlg(['Are you sure you want the entire area covered by the CD?' ...
        ' You can use the mouse to zoom into a smaller region'],...
        ' VMAP0UI Warning','Cancel','Continue','Cancel');
    
    if strcmp(answer,'Cancel')
        return
    end
    
elseif length(do) > 20
    answer = questdlg(['Are you sure you want to extract ' num2str(length(do)) ' tiles?' ...
        ' You can use the mouse to zoom into a smaller region'],...
        ' VMAP0UI Warning','Cancel','Continue','Cancel');
    
    if strcmp(answer,'Cancel')
        return
    end
    
elseif isempty(do)
    
    warndlg(['You chose an area outside this CD-ROM''s coverage. '...
        'Zoom to another area or close VMAP0UI and try another CD-ROM'],...
        'VMAP0UI Warning');
    
    return
end

% Get pseudohandles for the currently selected lines of the listbox

indx=get(state.list,'value');    									% rows of listbox
objhndl = state.objhndl;												% pseudohandles of each line in the listbox
objparent = state.objparent;										% pseudohandles of the parents of each line in the listbox
hndls = objhndl(indx);											% pseudohandles of selected objects in list
% parents = objparent(indx);											% pseudohandles of parents of selected objects in list
VMAPnames = state.VMAPnames(indx);										% contains structures with VMAP file, property and value names

n = gennum(state.objhndl(indx),state.objhndl,state.objparent); 	% generation numbers of the selected rows

% Remove items that are children of selected objects. If the parent is
% selected, all of the children will also be extracted.

chil = allekinder(hndls,objhndl,objparent);
indx2remove=find(ismember(hndls,chil));
% hndls(indx2remove)=[];
% parents(indx2remove)=[];
indx(indx2remove)=[];
n(indx2remove)=[];
VMAPnames(indx2remove)=[];

% Assemble a list of themes, feature, properties and values in the
% combinations that would be used with VMAP0DATA.

[themeReq,featureReq,propvalReq,nsteps] = assembleRequests( ...
    indx,n,VMAPnames,objhndl,objparent,state);

% get requested themes
hwaitbar = waitbar(0,'Reading data from the VMAP0 CD-ROM...', ...
    'CreateCancelBtn', 'setappdata(gcbf,''canceled'',1)');
setappdata(hwaitbar,'canceled',0)
set(hwaitbar,'handlevisibility','off')
drawnow

nsteps = length(do)*nsteps;
nstepsdone = 0;


try
    for j = 1:length(do)
        
        % obscure the base map data for the current tile
        zdatam(state.tiles(do(j)-1),-.5)
        set(state.tiles(do(j)-1),'Facecolor','w','EdgeColor','none')
        
        for i=1:length(themeReq)
            
            
            thislatlim = [state.FBR(do(j)).ymin+epsm state.FBR(do(j)).ymax-epsm];
            thislonlim = [state.FBR(do(j)).xmin+epsm state.FBR(do(j)).xmax-epsm];
            
            if isempty(featureReq{i})
                
                % get all features in a requested theme
                [state, nstepsdone] = gettheme(state, hwaitbar, ...
                    thislatlim, thislonlim, themeReq{i}, nstepsdone, nsteps);
                
            elseif isempty(propvalReq{i})
                
                % get just feature table data
                [state, nstepsdone] = getfeature(state, hwaitbar, ...
                    thislatlim, thislonlim, themeReq{i}, featureReq{i}, nstepsdone, nsteps);
                
            else
                
                % selected property value pairs of data
                [state, nstepsdone] = getpropval(state, hwaitbar, ...
                    thislatlim, thislonlim, themeReq{i}, featureReq{i}, ...
                    propvalReq{i}, nstepsdone, nsteps);
                
            end
        end
    end
    
    % save extracted data back into the figure user data slot
    set(state.fig,'userdata',state)
    
catch e
    errordlg(e.message,'Error reading data')
end

if ishghandle(hwaitbar,'figure')
    delete(hwaitbar)
end

%--------------------------------------------------------------------------

function [h,nstepsdone] = getpropval(h,hwaitbar,thislatlim,thislonlim,theme,feature,propval,nstepsdone,nsteps)

feature = lower(feature);


switch feature{:}(end-2:end)
    case 'aft'
        topolevel = 'patch';
    case 'lft'
        topolevel = 'line';
    case 'pft'
        topolevel = 'point';
    case 'tft'
        topolevel = 'text';
    otherwise
        nstepsdone = nstepsdone+1;
        if ~ishghandle(hwaitbar) || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
            return
        end
end

feature{:}(end-3:end) = [];

% get data:

% Patch
switch topolevel
    case 'patch'
        
        VMAPpatch = ...
            vmap0data(h.devicename,h.library,thislatlim,thislonlim,theme,...
            'patch',feature,propval);
        
        if ~ishghandle(hwaitbar) || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        % Set styles of objects to generally coincide with printed OPNAV
        % charts
        [VMAPpatch,newline,newpoint,newtext] = vmap0styles(VMAPpatch);
        
        h.extracteddata = catmlayerscell(h.extracteddata,VMAPpatch,[feature{:} '_subset']);
        h.extracteddata = catmlayerscell(h.extracteddata,newline,[feature{:} '_subset_line']);
        h.extracteddata = catmlayerscell(h.extracteddata,newpoint,[feature{:} '_subset_patch']);
        h.extracteddata = catmlayerscell(h.extracteddata,newtext,[feature{:} '_subset_text']);
        
        nstepsdone = nstepsdone+1;
        
        if ~ishghandle(hwaitbar) || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        if ~isempty(VMAPpatch)
            hpatch = vmap0display(h, VMAPpatch);
            zdatam(hpatch,-.25); 
        end
        vmap0display(h, newline);
        vmap0display(h, newpoint);
        vmap0display(h, newtext);
        
    case 'line'
        
        VMAPline = ...
            vmap0data(h.devicename,h.library,thislatlim,thislonlim,theme,...
            'line',feature,propval);
        
        if ~ishghandle(hwaitbar) || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        [VMAPline,newline,newpoint,newtext]= vmap0styles(VMAPline);
        
        h.extracteddata = catmlayerscell(h.extracteddata,VMAPline,[feature{:} '_subset']);
        h.extracteddata = catmlayerscell(h.extracteddata,newline,[feature{:} '_subset_line']);
        h.extracteddata = catmlayerscell(h.extracteddata,newpoint,[feature{:} '_subset_patch']);
        h.extracteddata = catmlayerscell(h.extracteddata,newtext,[feature{:} '_subset_text']);
        
        nstepsdone = nstepsdone+1;
        
        if ~ishghandle(hwaitbar) || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        if ~isempty(VMAPline)
            vmap0display(h, VMAPline);
        end
        vmap0display(h, newline);
        vmap0display(h, newpoint);
        vmap0display(h, newtext);
        
    case 'point'
        VMAPpoint = ...
            vmap0data(h.devicename,h.library,thislatlim,thislonlim,...
            theme,'point',feature,propval);
        
        if ~ishghandle(hwaitbar) || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        [VMAPpoint,newline,newpoint,newtext]= vmap0styles(VMAPpoint);
        
        h.extracteddata = catmlayerscell(h.extracteddata,VMAPpoint,[feature{:} '_subset']);
        h.extracteddata = catmlayerscell(h.extracteddata,newline,[feature{:} '_subset_line']);
        h.extracteddata = catmlayerscell(h.extracteddata,newpoint,[feature{:} '_subset_patch']);
        h.extracteddata = catmlayerscell(h.extracteddata,newtext,[feature{:} '_subset_text']);
        
        nstepsdone = nstepsdone+1;
        
        if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        if ~isempty(VMAPpoint)
            vmap0display(h, VMAPpoint);
            drawnow;
        end
        vmap0display(h, newline);        
        vmap0display(h, newpoint);        
        vmap0display(h, newtext);
        
    case 'text'
        
        VMAPtext = ...
            vmap0data(h.devicename,h.library,thislatlim,thislonlim,...
            theme,'text',feature,propval);
        
        if ~ishghandle(hwaitbar) || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        h.extracteddata = catmlayerscell(h.extracteddata,VMAPtext,[feature{:} '_subset']);
        nstepsdone = nstepsdone+1;
        
        if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        if ~isempty(VMAPtext)
            vmap0display(h, VMAPtext);
            drawnow; 
        end
end

if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
    if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
end

%--------------------------------------------------------------------------

function [h,nstepsdone] = getfeature(h,hwaitbar,thislatlim,thislonlim,theme,feature,nstepsdone,nsteps)

feature = lower(feature);

% use extension of feature table filename to identify topology levels

for i=1:length(feature)
    
    switch feature{i}(end-2:end)
        case 'aft'
            topolevel{i} = 'patch';
        case 'lft'
            topolevel{i} = 'line';
        case 'pft'
            topolevel{i} = 'point';
        case 'tft'
            topolevel{i} = 'text';
        otherwise
            nstepsdone = nstepsdone+1;
            waitbar(nstepsdone/nsteps)
            return
    end
    
    feature{i}(end-3:end) = [];
    
end


% get data:

% Patch

indx = strmatch('patch',topolevel); %#ok<*MATCH2>
if ~isempty(indx)
    
    for i=1:length(indx)
        
        VMAPpatch = ...
            vmap0data(h.devicename,h.library,thislatlim,thislonlim,theme,...
            'patch',feature(indx(i)));
        
        if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        [VMAPpatch,newline,newpoint,newtext] = vmap0styles(VMAPpatch);
        
        h.extracteddata = catmlayerscell(h.extracteddata,VMAPpatch,[theme,'_',feature{indx(i)}]);
        h.extracteddata = catmlayerscell(h.extracteddata,newline  ,[theme,'_',feature{indx(i)} '_line']);
        h.extracteddata = catmlayerscell(h.extracteddata,newpoint ,[theme,'_',feature{indx(i)} '_patch']);
        h.extracteddata = catmlayerscell(h.extracteddata,newtext,[theme,'_',feature{indx(i)} '_text']);
        
        nstepsdone = nstepsdone+1/length(feature);
        
        if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        if ~isempty(VMAPpatch); hpatch = vmap0display(h, VMAPpatch);zdatam(hpatch,-.25); end
        vmap0display(h, newline);
        vmap0display(h, newpoint);
        vmap0display(h, newtext);
        
    end
end

% Line

indx = strmatch('line',topolevel);
if ~isempty(indx)
    
    for i=1:length(indx)
        
        VMAPline = ...
            vmap0data(h.devicename,h.library,thislatlim,thislonlim,theme,...
            'line',feature(indx(i)));
        
        if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        [VMAPline,newline,newpoint,newtext] = vmap0styles(VMAPline);
        
        h.extracteddata = catmlayerscell(h.extracteddata,VMAPline,[theme,'_',feature{indx(i)}]);
        h.extracteddata = catmlayerscell(h.extracteddata,newline  ,[theme,'_',feature{indx(i)} '_line']);
        h.extracteddata = catmlayerscell(h.extracteddata,newpoint ,[theme,'_',feature{indx(i)} '_patch']);
        h.extracteddata = catmlayerscell(h.extracteddata,newtext,[theme,'_',feature{indx(i)} '_text']);
        
        nstepsdone = nstepsdone+1/length(feature);
        
        if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        if ~isempty(VMAPline); vmap0display(h, VMAPline); end
        vmap0display(h, newline);
        vmap0display(h, newpoint);
        vmap0display(h, newtext);
        
    end
    
end

% Point

indx = strmatch('point',topolevel);
if ~isempty(indx)
    
    for i=1:length(indx)
        
        VMAPpoint = ...
            vmap0data(h.devicename,h.library,thislatlim,thislonlim,...
            theme,'point',feature(indx(i)));
        
        if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        [VMAPpoint,newline,newpoint,newtext] = vmap0styles(VMAPpoint);
        
        h.extracteddata = catmlayerscell(h.extracteddata,VMAPpoint,[theme,'_',feature{indx(i)}]);
        h.extracteddata = catmlayerscell(h.extracteddata,newline  ,[theme,'_',feature{indx(i)} '_line']);
        h.extracteddata = catmlayerscell(h.extracteddata,newpoint ,[theme,'_',feature{indx(i)} '_patch']);
        h.extracteddata = catmlayerscell(h.extracteddata,newtext,[theme,'_',feature{indx(i)} '_text']);
        
        nstepsdone = nstepsdone+1/length(feature);
        
        if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        if ~isempty(VMAPpoint); vmap0display(h, VMAPpoint);drawnow; end
        vmap0display(h, newline);
        vmap0display(h, newpoint);
        vmap0display(h, newtext);
        
    end
    
end

indx = strmatch('text',topolevel);
if ~isempty(indx)
    
    for i=1:length(indx)
        
        VMAPtext = ...
            vmap0data(h.devicename,h.library,thislatlim,thislonlim,...
            theme,'text',feature(indx(i)));
        
        if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        h.extracteddata = catmlayerscell(h.extracteddata,VMAPtext,[theme,'_',feature{indx(i)}]);
        nstepsdone = nstepsdone+1/length(feature);
        
        if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
            if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
            return;
        else
            waitbar(nstepsdone/nsteps)
        end
        
        if ~isempty(VMAPtext); vmap0display(h, VMAPtext);drawnow; end
        
    end
    
end


if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
    if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
    return;
end

%--------------------------------------------------------------------------

function [h,nstepsdone] = gettheme(h,hwaitbar,thislatlim,thislonlim,theme,nstepsdone,nsteps)

% get data

[VMAPpatch,VMAPline] = ...
    vmap0data(h.devicename,h.library,thislatlim,thislonlim,theme,{'patch','line'});

nstepsdone = nstepsdone+1;
if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
    if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
    return;
else
    waitbar(nstepsdone/nsteps)
end

[VMAPpatch,newline,newpoint,newtext] = vmap0styles(VMAPpatch);

if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
    if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
    return;
else
    waitbar(nstepsdone/nsteps)
end

h.extracteddata = catmlayerscell(h.extracteddata,VMAPpatch,[theme 'patch']);
h.extracteddata = catmlayerscell(h.extracteddata,newline ,[theme '_line']);
h.extracteddata = catmlayerscell(h.extracteddata,newpoint,[theme '_patch']);
h.extracteddata = catmlayerscell(h.extracteddata,newtext ,[theme '_text']);

if ~isempty(VMAPpatch); hpatch = vmap0display(h, VMAPpatch);zdatam(hpatch,-.25); end
vmap0display(h, newline);
vmap0display(h, newpoint);
vmap0display(h, newtext);

nstepsdone = nstepsdone+1;
if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
    if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
    return;
else
    waitbar(nstepsdone/nsteps)
end

[VMAPline,newline,newpoint,newtext] = vmap0styles(VMAPline);

if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
    if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
    return;
else
    waitbar(nstepsdone/nsteps)
end

h.extracteddata = catmlayerscell(h.extracteddata,VMAPline,[theme 'line']);
h.extracteddata = catmlayerscell(h.extracteddata,newline ,[theme '_line']);
h.extracteddata = catmlayerscell(h.extracteddata,newpoint,[theme '_patch']);
h.extracteddata = catmlayerscell(h.extracteddata,newtext ,[theme '_text']);



if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
    if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
    return;
else
    waitbar(nstepsdone/nsteps)
end

if ~isempty(VMAPline); vmap0display(h, VMAPline);drawnow; end
vmap0display(h, newline);
vmap0display(h, newpoint);
vmap0display(h, newtext);

VMAPpoint = ...
    vmap0data(h.devicename,h.library,thislatlim,thislonlim,theme,'point');

nstepsdone = nstepsdone+1;
if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
    if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
    return;
else
    waitbar(nstepsdone/nsteps)
end

[VMAPpoint,newline,newpoint,newtext] = vmap0styles(VMAPpoint);

h.extracteddata = catmlayerscell(h.extracteddata,VMAPpoint,[theme 'point']);
h.extracteddata = catmlayerscell(h.extracteddata,newline ,[theme '_line']);
h.extracteddata = catmlayerscell(h.extracteddata,newpoint,[theme '_patch']);
h.extracteddata = catmlayerscell(h.extracteddata,newtext ,[theme '_text']);

if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
    if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
    return;
else
    waitbar(nstepsdone/nsteps)
end

if ~isempty(VMAPpoint); vmap0display(h, VMAPpoint);drawnow; end
vmap0display(h, newline);
vmap0display(h, newpoint);
vmap0display(h, newtext);

VMAPtext = ...
    vmap0data(h.devicename,h.library,thislatlim,thislonlim,theme,'text');

nstepsdone = nstepsdone+1;
if ~ishghandle(hwaitbar)  || getappdata(hwaitbar,'canceled')
    if ishghandle(hwaitbar,'figure'); close(hwaitbar); end
    return;
else
    waitbar(nstepsdone/nsteps)
end

h.extracteddata = catmlayerscell(h.extracteddata,VMAPtext,[theme 'text']);
if ~isempty(VMAPtext); vmap0display(h, VMAPtext);drawnow; end

%--------------------------------------------------------------------------

function [theme,feature,propval,nsteps]=assembleRequests(indx,n,VMAPnames,objhndl,objparent,h)

theme = [];
feature = [];
propval = [];
nsteps = 0;

k=0;
for i=1:length(n)
    
    switch n(i)
        case 0
            
            k=k+1;
            theme{k} = VMAPnames{i}.coverage_name;
            feature{k} = [];
            propval{k} = [];
            nsteps = nsteps+4;
            
        case 1
            
            thisfeaturename = lower(VMAPnames{i}.name);
            thisthemename = h.VMAPnames{ ...
                find( objhndl == objparent(indx(i)) ) ...
                }.coverage_name; %#ok<*FNDSB>
            indxtheme = strmatch(thisthemename,theme);
            for j=length(indxtheme):-1:1
                if ~isempty(propval{indxtheme(j)}); indxtheme(j) = []; end
            end
            
            if isempty(indxtheme)
                k=k+1;
                nsteps = nsteps + 1;
                theme{k} = thisthemename;
                feature{k} = {thisfeaturename};
                propval{k} = [];
            else
                fcell = feature{indxtheme};
                feature{indxtheme} = {fcell{:},thisfeaturename}; %#ok<CCAT>
            end
            
        case 2
            
            thisthemename = h.VMAPnames{...
                find( objhndl == ...
                objparent( ...
                find( objhndl == objparent(indx(i)) ) ...
                ) ...
                ) ...
                }.coverage_name;
            
            thisfeaturename = ...
                lower( ...
                h.VMAPnames{...
                find( objhndl == objparent(indx(i)) ) ...
                }.name ...
                );
            
            indxtheme = strmatch(thisthemename,theme);
            indxfeature = [];
            for j=1:length(indxtheme)
                indxfeature = strmatch(thisfeaturename,feature{indxtheme(j)});
                if ~isempty(indxfeature)
                    % indxtheme = indxtheme(j);
                    break;
                end
            end
            
            if isempty(indxfeature)
                k=k+1;
                nsteps = nsteps + 1;
                theme{k} = thisthemename;
                feature{k} = {thisfeaturename};
                propval{k} = {VMAPnames{i}.attribute,VMAPnames{i}.value};
            else
                propval{k} = {propval{k}{:},VMAPnames{i}.attribute,VMAPnames{i}.value}; %#ok<CCAT>
            end
            
            
    end
end

%--------------------------------------------------------------------------

function mcell = catmlayerscell(mcell,struc,name)

% CATMLAYERSCELL concatenates a structure to a MLAYERS-style cell array.
% This cell array is N by 2 in size, with the first column containing
% display structures, while the second contains associated variable names.
% If the structure to be added matches an existing name, the structure is
% merged with that existing structure. Otherwise, a new entry is added to
% the cell array.

if isempty(mcell) && isempty(struc)
    return
elseif isempty(mcell) && ~isempty(struc)
    mcell = {struc,name};
    return
elseif ~isempty(mcell) && isempty(struc)
    return
end

indx = strmatch(name,mcell(:,2),'exact');

if isempty(indx) && ~isempty(struc)
    mcell{end+1,1} = struc;
    mcell{end,2} = name;
elseif ~isempty(struc)
    mcell{indx(1),1} = catstructures(mcell{indx(1),1},struc);
end

%--------------------------------------------------------------------------

function s1 = catstructures(s1,s2)

start = length(s1);
if start ==0
    s1 = s2;
elseif ~isempty(s2)
   
    names = union(fieldnames(s1),fieldnames(s2));
    
    % enforce same fieldnames for each structure
    
    l1 = length(s1);
    l2 = length(s2);
    for i=1:length(names)
        s1 = setfield(s1,{l1+1},names{i},[]);
        s2 = setfield(s2,{l2+1},names{i},[]);
    end
    s1(l1+1) = [];
    s2(l2+1) = [];
    
    % convert structures to cells
    [~,indx1] = sort(fieldnames(s1));
    cell1 = struct2cell(s1);
    cell1 = cell1(indx1,:,:);
    
    [~,indx2] = sort(fieldnames(s2));
    cell2 = struct2cell(s2);
    cell2 = cell2(indx2,:,:);
    
    % concatenate cells
    
    cell1(:,:,l1 + (1:l2)) = deal(cell2(:,:,1:l2));
    
    s1 = cell2struct(cell1,names,1);
    
end

%--------------------------------------------------------------------------

function vmap0uilist(hsrc,~)
% Manages insertions and deletions to the list of themes, features and
% property-value pairs

hfig = ancestor(hsrc,'figure');
h = get(hfig,'userdata');

switch get(hfig,'SelectionType')
    case 'open'
        
        value = get(hsrc, 'Value');
        strs  = get(hsrc, 'string');
        
        % do operation on top level objects only
        ph = h.objhndl(value);
        gens = gennum(ph,h.objhndl,h.objparent);
        value = value(gens==min(gens));
        
        selected = value;
        
        for i=length(value):-1:1
            
            switch gennum( h.objhndl(value(i)) ,h.objhndl,h.objparent)+1
                
                case 1 % 'theme'
                    
                    switch h.expandable(value(i))
                        case 0                            % remove subclasses
                            
                            strs(value(i),2) = '+';
                            
                            h.expandable(value(i)) = 1;
                            
                            chil = allekinder(h.objhndl(value(i)),h.objhndl,h.objparent);
                            rowsToDelete = find(ismember(h.objhndl,chil));
                            
                            strs(rowsToDelete,:) = [];
                            selected = value(i);
                            
                            h.objhndl(rowsToDelete) = [];
                            h.objparent(rowsToDelete) = [];
                            h.VMAPnames(rowsToDelete) = [];
                            h.expandable(rowsToDelete) = [];
                            
                        case 1                            % insert subclasses
                            
                            h.expandable(value(i)) = 0;
                            
                            suffixstr = '     +   ';
                            names = char(h.FTfilenames{h.objhndl(value(i))}.description);
                            newstrs = [repmat(suffixstr,size(names,1),1) names];
                            strs = char( ...
                                strs(1:value(i),:) , ...
                                newstrs , ...
                                strs(value(i)+1:end,:) ...
                                );
                            
                            pseudohandle = h.objhndl(value(i));
                            hvec = h.objhndl;
                            pvec = h.objparent;
                            [hvec,pvec] = insertkinder(pseudohandle,size(names,1),hvec,pvec);
                            
                            h.objhndl = hvec ;
                            h.objparent = pvec;
                            
                            struct2insert = h.FTfilenames{h.objhndl(value(i))};
                            for ii=1:length(struct2insert)
                                cells2insert{ii} = struct2insert(ii);
                            end
                            h.VMAPnames = { ...
                                h.VMAPnames{1:value(i)},...
                                cells2insert{:},...
                                h.VMAPnames{value(i)+1:end} ...
                                }; %#ok<CCAT>
                            
                            h.expandable = [ ...
                                h.expandable(1:value(i)),...
                                ones(1,length(cells2insert)),...
                                h.expandable(value(i)+1:end) ...
                                ];
                            
                    end % switch on whether expandable
                    
                    set(hsrc,'String',strs,'Value',selected)
                    
                case 2 % 'Feature'
                    
                    switch h.expandable(value(i)) % strs(value(i),2)
                        case 0                            % remove subclasses
                            
                            strs(value(i),6) = '+';
                            
                            h.expandable(value(i)) = 1;
                            
                            chil = allekinder(h.objhndl(value(i)),h.objhndl,h.objparent);
                            rowsToDelete = find(ismember(h.objhndl,chil));
                            
                            strs(rowsToDelete,:) = [];
                            selected = value(i);
                            
                            h.objhndl(rowsToDelete) = [];
                            h.objparent(rowsToDelete) = [];
                            h.VMAPnames(rowsToDelete) = [];
                            h.expandable(rowsToDelete) = [];
                            
                        case 1                            % add subclasses
                            
                            strs(value(i),6) = '-';
                            
                            h.expandable(value(i)) = 0;
                            
                            themenum = h.objparent(value(i));
                            featnum = sum(h.objparent(h.objparent(value(i)):value(i))== h.objparent(value(i)));
                            
                            FT = h.FTfilenames{themenum};
                            
                            featuretablename = lower(FT(featnum).name);
                            FTattributes = {FT(featnum).fields.name};
                            ivdt = h.ivdt{themenum};
                            cvdt = h.cvdt{themenum};
                            
                            indx = [];
                            if ~isempty(ivdt)
                                indx = strmatch(featuretablename,{ivdt.table});
                            end
                            
                            if ~isempty(indx)
                                ivdtnames = char(ivdt(indx).description);
                                
                                
                                iattributeDescription = {};
                                for j=1:length(ivdt(indx))
                                    thisvdt = ivdt(indx(j));
                                    [~,FTindx] = intersect(FTattributes,{thisvdt.attribute});
                                    iattributeDescription{j} = FT(featnum).fields(FTindx).description;
                                end
                                iattributeDescription = char(iattributeDescription{:});
                                
                                
                            else
                                ivdtnames = '';
                                iattributeDescription = '';
                            end
                            iindx = indx;
                            
                            
                            indx = [];
                            if ~isempty(cvdt)
                                indx = strmatch(featuretablename,{cvdt.table});
                            end
                            
                            if ~isempty(indx)
                                cvdtnames = char(cvdt(indx).description);
                                
                                cattributeDescription = {};
                                for j=1:length(cvdt(indx))
                                    thisvdt = cvdt(indx(j));
                                    [~,FTindx] = intersect(FTattributes,{thisvdt.attribute});
                                    cattributeDescription{j} = FT(featnum).fields(FTindx).description;
                                end
                                cattributeDescription = char(cattributeDescription{:});
                                
                            else
                                cvdtnames = '';
                                cattributeDescription = '';
                            end
                            cindx = indx;
                            
                            names = strvcat(ivdtnames,cvdtnames);
                            attdescriptions = strvcat(iattributeDescription,cattributeDescription);
                            
                            suffixstr = '             ';
                            
                            nrows = size(names,1);
                            newstrs = [repmat(suffixstr,nrows,1) attdescriptions repmat(': ',nrows,1) names];
                            
                            if nrows > 0
                                strs = char( ...
                                    strs(1:value(i),:) , ...
                                    newstrs , ...
                                    strs(value(i)+1:end,:) ...
                                    );
                            else
                                % nothing to expand, so remove indication
                                % that there might be more
                                strs(value(i),2) = ' ';
                            end
                            
                            pseudohandle = h.objhndl(value(i));
                            hvec = h.objhndl;
                            pvec = h.objparent;
                            
                            [hvec,pvec] = insertkinder(pseudohandle,size(names,1),hvec,pvec);
                            
                            h.objhndl = hvec;
                            h.objparent = pvec;
                            
                            cells2insert = [];
                            for ii=1:length(iindx)
                                cells2insert{ii} = ivdt(iindx(ii));
                            end
                            for ii=1:length(cindx)
                                cells2insert{ii+length(iindx)} = cvdt(cindx(ii));
                            end
                            
                            if ~isempty(cells2insert)
                                h.VMAPnames = { ...
                                    h.VMAPnames{1:value(i)},...
                                    cells2insert{:},...
                                    h.VMAPnames{value(i)+1:end} ...
                                    }; %#ok<CCAT>
                            end
                            
                            h.expandable = [ ...
                                h.expandable(1:value(i)),...
                                zeros(1,length(cells2insert)),...
                                h.expandable(value(i)+1:end) ...
                                ];
                            
                            
                            
                    end % switch on +/- (whether expanded)
                    
                    set(hsrc,'String',strs,'Value',selected)
                    
            end % switch on level
            
        end % for
        
        
end % switch selection type

set(hfig,'UserData',h)

%--------------------------------------------------------------------------

function hc = allekinder(h,hvec,pvec)
% ALLEKINDER descendants of an object based on pseudohandles
%
% hc = ALLEKINDER(h,hvec,pvec) finds the descendants of an object with
% pseudohandle h given the vector of pseudohandles hvec and the associated
% vector of parent pseudohandles pvec.
%
% Pseudohandles are unique numbers associated with a set of hierarchical
% objects. They are tracked by means of the object and parent vectors hvec
% and pvec. For example, three objects, the second of which has two
% subobjects, might be described by the following vectors:
%
%      hvec = [ 1 2 4 5 3] and pvec = [ 0 0 2 2 0]
%
% The pseudohandles of the children of the object with the pseudohandle 2
% are then [4 5].

hc = [];

while 1
    
    thesekids = hvec(find(ismember(pvec,h)));
    if isempty(thesekids); break; end;
    hc = [hc thesekids];
    h = thesekids;
    
end

%--------------------------------------------------------------------------

function n = gennum(h,hvec,pvec)
% GENNUM generation number of an object based on pseudohandles
%
% n = GENNUM(h,hvec,pvec) finds the generation of an object with
% pseudohandle h given the vector of pseudohandles hvec and the associated
% vector of parent pseudohandles pvec. Objects that have no parents have a
% generation number of 0, while the grandchildren of such objects have a
% generation number of 2
%
% Pseudohandles are unique numbers associated with a set of hierarchical
% objects. They are tracked by means of the object and parent vectors hvec
% and pvec. For example, three objects, the second of which has two
% subobjects, might be described by the following vectors:
%
%      hvec = [ 1 2 4 5 3] and pvec = [ 0 0 2 2 0]
%
% The pseudohandles of the children of the object with the pseudohandle 2
% are then [4 5].

n = -ones(size(h));

for i=1:length(h)
    while 1
        
        indx = find(ismember(hvec,h(i)));
        theseparents = pvec(indx);
        if isempty(theseparents); break; end
        h(i) = unique(theseparents);
        n(i) = n(i)+1;
        
    end
end

%--------------------------------------------------------------------------

function [hvec,pvec] = insertkinder(h,nchildren,hvec,pvec)

if length(h) > 1
    error('map:vmap0ui:nonscalarHandle', 'One object at a time, please.')
end

indx = find(h==hvec);

hvec = hvec(:)';
pvec = pvec(:)';


hchildren = max(hvec) + (1:nchildren);
hparents  = h * ones(size(hchildren));

pvec = ...
    [ ...
    pvec(1:indx)  ...
    hparents  ...
    pvec(indx+1:end) ...
    ];

hvec = [ ...
    hvec(1:indx)  ...
    hchildren  ...
    hvec(indx+1:end) ...
    ];

%--------------------------------------------------------------------------

function [latlim, lonlim] = pcarreeInverse(x, y)
% Special case of inverse Plate Carree projection.

latlim = rad2deg(y);
latlim(1) = max(latlim(1), -90);
latlim(2) = min(latlim(2),  90);

lonlim = rad2deg(x);
lonlim(1) = max(lonlim(1), -180);
lonlim(2) = min(lonlim(2),  180);

%--------------------------------------------------------------------------

function h = vmap0display(state, data)
% Display VMAP0 data.

if ~isempty(data)
    % displaym does not allow the axes to be passed into the function.
    % Set the VMAP0 figure to be the current figure and set the handle
    % visibility to ensure that displaym can find the VMAP0 axes.
    hfig = state.fig;
    set(hfig, 'HandleVisibility', 'on')
    hcurrent = get(0,'CurrentFigure');
    figure(hfig)
    obj = onCleanup(@(~,~) resetFigure(hfig, hcurrent));
    
    % Display the data.
    h = displaym(data);
    
    % Set the Tag value.
    set(h, 'Tag', state.tag);
    drawnow
else
    h = [];
end

%--------------------------------------------------------------------------

function resetFigure(hfig, hcurrent)
% Reset handle visibility of hfig to off and reset hcurrent to be the
% current figure.

set(hfig, 'HandleVisibility', 'off')
if ishghandle(hcurrent, 'figure')
    set(0, 'CurrentFigure', hcurrent)
end

%--------------------------------------------------------------------------

function zoomCallback(~, hsrc)
% After a zoom event, reset the frame limits to the axes limits.

haxes = hsrc.Axes;
if ishghandle(haxes, 'axes')
    % Allow for only one zoom event at a time.
    if isappdata(haxes, 'zoom')
        return
    end
    setappdata(haxes, 'zoom', 'on')
    
    % Obtain current X and Y limits.
    xLimits = get(haxes, 'XLim');
    yLimits = get(haxes, 'YLim');
        
    % Obtain the frame's handle.
    hframe = findobj(haxes, 'tag', 'Frame');
    
    % Save LineWidth property.
    lineWidth = get(hframe, 'LineWidth');

    % Delete the old frame.
    delete(hframe);

    % Create a new frame using patch rather than setm.
    x = xLimits([1 1 2 2 1]);
    y = yLimits([1 2 2 1 1]);
    patch('XData', x, 'YData', y, 'FaceColor', 'none', 'EdgeColor','k', ...
        'Parent', haxes, 'Tag', 'Frame', 'LineWidth', lineWidth);
    
    % Ensure the X and Y limits are set to original values.
    set(haxes, 'XLim', xLimits, 'YLim', yLimits);
    
    % Rest to allow additional zoom events.
    rmappdata(haxes, 'zoom')
        
    % Ensure the graphics are updated.
    drawnow
end
 
