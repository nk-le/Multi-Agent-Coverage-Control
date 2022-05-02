function demdataui
%DEMDATAUI UI for selecting digital elevation data
%   DEMDATAUI is a Graphical User Interface to extract Digital Elevation
%   Map data from a number of external data files. DEMDATAUI reads GTOPO30,
%   GLOBE, and DTED data. DEMDATAUI looks for these external data files on
%   the MATLAB path and, for some operating systems, on CD-ROM disks. Click
%   the HELP button for more information on use of the GUI and how
%   DEMDATAUI recognizes data sources.

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  W. Stumpf

uistart;

%--------------------------------------------------------------------------

function demdatauiget(hsrc, ~)
% Extract data from the external matrix data interfaces.

% Set watch pointer.
hfig = get(hsrc, 'Parent');
pointer = get(hfig, 'Pointer');
set(hfig, 'Pointer', 'watch')
drawnow

extracteddata = struct(...
    'type', '', ...
    'tag', '', ...
    'map', [], ...
    'maplegend', [], ...
    'meshgrat', [], ...
    'lat', [], ...
    'long', [], ...
    'altitude', [], ...
    'otherproperty', []);
extracteddata.otherproperty = {};
    
try
    % Retrieve handles and such from the GUI user data slot
    h = get(hfig,'userdata');
    
    % Which database
    liststrs = get(h.list,'String');
    if isempty(liststrs)
        error(message('map:demdataui:noDataFound'));
    end
    indx = get(h.list,'value');
    database = liststrs{indx};
    
    % determine size of region to be extracted
    [nrows,ncols] = demdatauislider(hsrc);
    
    % verify for large matrices
    if nrows*ncols > 500*500
        answer = questdlg(['Are you sure you want to extract a ' num2str(nrows) ' by ' num2str(ncols) ' matrix?' ...
            ' You can use the mouse to zoom into a smaller region'], ...
            ' DEMDATAUI Warning','Cancel','Continue','Cancel');
        
        if strcmp(answer,'Cancel')
            set(gcbf,'pointer',pointer)
            return
        end
        drawnow
    end
    
    % Determine latitude and longitude limits from current axis limits
    xLimits = get(h.axes,'XLim');
    yLimits = get(h.axes,'Ylim');
    
    % Special case of inverse Plate Carree projection.
    [latlim, lonlim] = pcarreeInverse(xLimits, yLimits);
    
    % Scalefactor
    h = get(hfig,'userdata');
    scalefactor = round(get(h.slider,'Value'));    
    
    readingDataWithGraticule = false;
    switch database
        case 'TerrainBase'
            [map,refvec] = tbase(scalefactor,latlim,lonlim);
            extracteddata.tag = 'TerrainBase data';
            
        case 'ETOPO5'
            % Use a subfunction that wraps the public ETOPO function.
            [map,refvec] = etopo5read(scalefactor,latlim,lonlim);
            extracteddata.tag = 'ETOPO5 data';
            
        case 'GTOPO30'
            pth = h.path{indx};
            if ~strcmp(pth(end),filesep)
                pth = [pth filesep];
            end
            
            [map,refvec] = gtopo30(pth,scalefactor,latlim,lonlim);
            map(isnan(map)) = -1;
            extracteddata.tag = 'GTOPO30 data';
            
        case 'GLOBE'
            pth = h.path{indx};
            if ~strcmp(pth(end),filesep)
                pth = [pth filesep];
            end
            
            [map,refvec] = globedem(pth,scalefactor,latlim,lonlim);
            map(isnan(map)) = -1;
            extracteddata.tag = 'GLOBEDEM data';
            
        case 'DTED'
            pth = [fileparts(h.path{indx}) filesep];
            [map,refvec] = dted(pth,scalefactor,latlim,lonlim);
            map(map==0) = -1;
            extracteddata.tag = 'DTED data';
            
        case 'SatBath'
            readingDataWithGraticule = true;
            [latlim, lonlim] = satbathLimits(latlim, lonlim);
            [latgrat,longrat,map] = satbath(scalefactor,latlim,lonlim);
            extracteddata.tag = 'SatBath data';
    end
    
    if ~isempty(map)
        extracteddata.map = map;
        h.tag = 'importdata';
        if ~readingDataWithGraticule
            geoshow(map, refvec, 'DisplayType', 'texturemap', ...
                'Parent', h.axes, 'Tag', h.tag);
            extracteddata.type = 'regular';
            extracteddata.maplegend = refvec;
        else
            geoshow(latgrat, longrat, map, 'DisplayType', 'texturemap', ...
                'Parent', h.axes, 'Tag', h.tag);
            extracteddata.type = 'surface';
            extracteddata.lat = latgrat;
            extracteddata.long = longrat;
        end
        [cmap0, clim0] = demcmap('inc',[-10000 8000],100);
        set(h.axes, 'CLim', clim0);
        set(hfig, 'Colormap', cmap0);
    end
catch e
    herr = errordlg(e.message,'Error reading data');
    herr.Tag = 'demdatauiErrorReadingData';
end

if isempty(h.extracteddata)
    h.extracteddata = extracteddata;
else
    h.extracteddata(end+1) = extracteddata;
end

set(h.fig, 'userdata', h)
set(hfig, 'pointer', pointer)

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

function [latlim, lonlim] = satbathLimits(latlim, lonlim)
% Compute limits for satbath data. For details, see:
% ftp://topex.ucsd.edu/pub/global_topo_1min/README_V15.1.txt

% Longitude limits range: [0 360]
if isequal(lonlim, [-180 180])
    lonlim = [0 360];
end

% Latitude limits range: [-72.006 72.006]
latRange = [-72.006, 72.006];
latlim = [max(latlim(1), latRange(1)), min(latlim(2), latRange(2))];

%--------------------------------------------------------------------------

function uilist(hsrc, ~)
% Actions as a result of clicking on the list

% Retrieve handles and such from the GUI user data slot
if ~ishghandle(hsrc, 'figure')
    hfig = get(hsrc,'Parent');
else
    hfig = hsrc;
end
h = get(hfig,'userdata');

% Which database
liststrs = get(h.list,'String');
if ~isempty(liststrs)
    indx = get(h.list,'value');
    database = liststrs{indx};
    
    % hide all tiles
    if ~isempty(h.tiles)
        hidem(cat(2,h.tiles{:}))
    end
    
    hframe = handlem('Frame', h.axes);
    if any(strcmpi(database, {'TerrainBase','ETOPO5'}))
        set(hframe,'Facecolor',[0.99 1.00 0.85])
    else
        set(hframe,'Facecolor','w')
        showm(h.tiles{indx})
    end
end

%--------------------------------------------------------------------------

function [nrowsout,ncolsout] = demdatauislider(hsrc, ~)
% Update calculation of resulting matrix size based on slider action.

if ~ishghandle(hsrc, 'figure')
    hfig = get(hsrc,'Parent');
else
    hfig = hsrc;
end

if ~strcmp(get(hfig,'tag'),'DEMDATAUI')
    return
end

h = get(hfig,'userdata');

% Scalefactor
scalefactor = round(get(h.slider,'Value'));
set(h.slider,'Value',scalefactor)

% Show number superimposed on slider button
pos = get(h.slidervalue,'Position');
%pos(2) = 0.23 + scalefactor/99*(0.81-0.23);
pos(2) = 0.19 + 1.05*scalefactor/99*(0.81-0.19);
set(h.slidervalue,'Position',pos,'String',num2str(scalefactor))

% Determine latitude and longitude limits from current axis limits
xLimits = get(h.axes,'XLim');
yLimits = get(h.axes,'Ylim');
[latlim, lonlim] = pcarreeInverse(xLimits, yLimits);

% Determine current database
liststrs = get(h.list,'String');
if isempty(liststrs); return; end
indx = get(h.list,'value');
database = liststrs{indx};

% Determine size for latlim and lonlim
if strcmpi(database, 'SatBath')
    [latlim, lonlim] = satbathLimits(latlim, lonlim);
    [nrows, ncols] = satbath('size',scalefactor,latlim,lonlim);
else
    resolutionInDegrees = h.resolution(indx);
    scale = scalefactor * resolutionInDegrees;
    nrows = ceil(diff(latlim) / scale);
    ncols = ceil(diff(lonlim) / scale);
end

set(get(h.axes,'title'), 'String', ...
    [num2str(nrows) ' by ' num2str(ncols) ' matrix'])
set(h.fig,'userdata',h)

if nargout > 0
    [nrowsout,ncolsout] = deal(nrows,ncols);
end

%--------------------------------------------------------------------------

function demdatauiclear(hsrc, ~)
% Remove extracted data from the plot and storage.

hfig = get(hsrc,'Parent');
h = get(hfig,'userdata');
if isfield(h,'tag')
    htag = findall(h.axes, 'tag', h.tag);
    delete(htag);
end
h.extracteddata = [];
set(h.fig,'userdata',h)

%--------------------------------------------------------------------------

function uistart
% Initialize GUI

sources = {};
h.resolution = [];
h.path = {};
h.tiledata = {};
h.tiles = [];

% Check for tbase
if exist('tbase.bin','file')==2
    sources{end+1} = 'TerrainBase';
    h.resolution(end+1) = dms2degrees([0 5 0]); % 5-minute grid spacing
    h.tiledata{end+1} = 0;
end

% Check for etopo5
if exist('new_etopo5.bil','file') ||...
        exist('etopo5.bil','file')||...
        (exist('etopo5.northern.bat','file') &&...
        exist('etopo5.southern.bat','file'))
    sources{end+1} = 'ETOPO5';
    h.resolution(end+1) = dms2degrees([0 5 0]); % 5-minute grid spacing
    h.tiledata{end+1} = 0;
end

% Check for GTOPO30
[g30pth,sgtopo30] = gtopo30path;
if ~isempty(g30pth) && ~isequal(g30pth,{''})
    for i=1:length(g30pth)
        sources{end+1} = 'GTOPO30'; %#ok<AGROW>
        h.resolution(end+1) = dms2degrees([0 0 30]); % 30 arc-second spacing
        h.path{length(sources)} = g30pth{i};
        h.tiledata{end+1} = sgtopo30;
    end
end

% Check for GLOBEDEM
[gdpth,sgd] = globedempath;
if ~isempty(gdpth) && ~isequal(gdpth,{''})
    for i=1:length(gdpth)
        sources{end+1} = 'GLOBE'; %#ok<AGROW>
        h.resolution(end+1) = dms2degrees([0 0 30]); % 30 arc-second spacing
        h.path{length(sources)} = gdpth{i};
        h.tiledata{end+1} = sgd{i};
    end
end

% Check for satbath
if exist('topo_8.2.img','file')
    sources{end+1} = 'SatBath';
    h.resolution(end+1) = NaN; % Variable spacing (mercator projection)
    h.tiledata{end+1} = 0;
end

% Check for DTED
[dtedpth] = unique(dtedpath);
if ~isempty(dtedpth) && ~isequal(dtedpth,{''})
    
    for i=1:length(dtedpth)
        sdted = dtedtiles(dtedpth{i});
        
        if ~isempty(sdted) % might have an empty directory named dted
            switch(sdted(1).level)
                case 0
                    h.resolution(end+1) = 1/120;   % 30 arc-second spacing
                case 1
                    h.resolution(end+1) = 1/1200;  % 3 arc-second spacing
                case 2
                    h.resolution(end+1) = 1/3600;  % 1 arc-second spacing
                otherwise
                    h.resolution(end+1) = NaN;
            end
            
            sources{end+1} = 'DTED'; %#ok<AGROW>
            h.path{length(sources)} = dtedpth{i};
            h.tiledata{end+1} = sdted;
        end
    end
end

% Construct UI
h = constructUI(sources,h);

% Setup tags structure.
tags = struct( ...
    'GTOPO30', 'gtopo30tiles', ...
    'GLOBE',   'globedemtiles', ...
    'DTED',    'dtedtiles', ...
    'SatBath', 'satbathtile');

% Add tiles for tiled datasets
for i = 1:length(sources)
    switch(sources{i})
        case 'GTOPO30'
            pth = h.path{i};
            s = h.tiledata{i};
            
            % check which ones are on the CD or in the directory
            d = dir(pth);
            d(~[d.isdir]) = [];
            
            tilepresent = ismember(lower({s.name}),lower({d.name}));            
            s(~tilepresent) = [];
            
            latlim = cat(1,s.latlim);
            lonlim = cat(1,s.lonlim);
            htemp = patchesm( ...
                [latlim(:,1)'; latlim(:,2)'; latlim(:,2)'; latlim(:,1)'; latlim(:,1)'], ...
                [lonlim(:,1)'; lonlim(:,1)'; lonlim(:,2)'; lonlim(:,2)'; lonlim(:,1)'], ...
                'y', 'Tag', tags.(sources{i}));
            zdatam(htemp,-1);
            uistack(htemp,'bottom')
            set(htemp,'facecolor',[0.99  1.00  0.85],'edgecolor',.75*[1 1 1])
            
            h.tiles{i} = htemp;
            
        case 'GLOBE'
            s = h.tiledata{i};
            
            latlim = cat(1,s.latlim);
            lonlim = cat(1,s.lonlim);
            htemp = patchesm( ...
                [latlim(:,1)'; latlim(:,2)'; latlim(:,2)'; latlim(:,1)'; latlim(:,1)'],...
                [lonlim(:,1)'; lonlim(:,1)'; lonlim(:,2)'; lonlim(:,2)'; lonlim(:,1)'], ...
                'y', 'Tag', tags.(sources{i}));
            zdatam(htemp,-1);
            uistack(htemp,'bottom')
            set(htemp,'facecolor',[0.99  1.00 0.85],'edgecolor',.75*[1 1 1])
            
            h.tiles{i} = htemp;
            
        case 'DTED'
            s = h.tiledata{i};
            
            latlim = cat(1,s.latlim);
            lonlim = cat(1,s.lonlim);
            
            htemp = patchesm( ...
                [latlim(:,1)'; latlim(:,2)'; latlim(:,2)'; latlim(:,1)'; latlim(:,1)'],...
                [lonlim(:,1)'; lonlim(:,1)'; lonlim(:,2)'; lonlim(:,2)'; lonlim(:,1)'], ...
                'y', 'Tag', tags.(sources{i}));
            zdatam(htemp,-1);
            uistack(htemp,'bottom')
            set(htemp,'facecolor',[0.99 1.00 0.85],'edgecolor',.75*[1 1 1])
            
            h.tiles{i} = htemp;
            
        case 'SatBath'
            latlim = [-72 72];
            lonlim = [-180 180];
            lat = latlim([1 2 2 1 1])';
            lon = lonlim([1 1 2 2 1])';
            [x, y] = map.crs.internal.mfwdtran(lat, lon);
            htemp = patch('XData', x, 'YData', y, 'FaceColor', 'y', 'Tag', tags.(sources{i}));
            zdatam(htemp,-1);
            uistack(htemp,'bottom')
            set(htemp,'facecolor',[0.99 1.00 0.85],'edgecolor',.75*[1 1 1])
            
            h.tiles{i} = htemp;
    end
end

set(h.fig,'Userdata',h)

demdatauislider(h.fig);
uilist(h.fig);

liststrs = get(h.list,'String');
if isempty(liststrs)
    msg = sprintf([
        'DEMDATAUI searches for high resolution digital elevation data files on the MATLAB path. ' ...
        'On some computers, DEMDATAUI will also check for data files on the root level of letter drives. ' ...
        'DEMDATAUI looks for the following data: ' ...
        '\n\nETOPO5: new_etopo5.bil or etopo5.northern.bat and etopo5.southern.bat files. ' ...
        '\n\nTBASE: tbase.bin file. ' ...
        '\n\nSATBATH: topo_8.2.img file. ' ...
        '\n\nGTOPO30: a directory that contains subdirectories with the datafiles. ' ...
        'For example, DEMDATAUI would detect GTOPO30 data if a directory on the path contained the directories E060S10 and E100S10, each of which holds the uncompressed data files. ' ...
        '\n\nGLOBEDEM: a directory that contains data files and in the subdirectory "/esri/hdr" the "*.hdr" header files. ' ...
        '\n\nDTED: a directory that has a subdirectory named DTED. ' ...
        'The contents of the DTED directory are more subdirectories organized by longitude and, below that, the DTED data files for each latitude tile. ' ...
        '\n\n']);
    
    herr = errordlg('No external DEM data found.','DEMDATAUI Error');
    uiwait(herr);
    hwarn = warndlg(msg,'DEMDATAUI Data Sources');
    hwarn.Tag = 'demdatauiDataSourceWarning';
end

set(h.fig,'HandleVis','callback')
set(h.zoom, 'Enable', 'on')

%--------------------------------------------------------------------------

function [foundpth,s] = gtopo30path
% Return the path to a directory of gtopo 30 data.

% Obtain GTOPO30 tile data.
[name, latlimS, latlimN, lonlimW, lonlimE] = gtopo30tiles();

% Convert to a structure.
s(1:numel(name)) = struct( 'name', '', 'latlim', [], 'lonlim', []);
for k=1:numel(name)
    s(k).name = name{k};
    s(k).latlim(1) = latlimS(k);
    s(k).latlim(2) = latlimN(k);
    s(k).lonlim(1) = lonlimW(k);
    s(k).lonlim(2) = lonlimE(k);
end

% Search the path.
foundpth = unique(searchpath(s));

%--------------------------------------------------------------------------

function [foundpth,sout] = globedempath
% Return the path to a directory of GLOBEDEM data.

% Obtain GLOBE DEM tile data.
[name, latlimS, latlimN, lonlimW, lonlimE, rtile, ctile] = globetiles();

% Convert to a structure.
s(1:numel(name)) = struct( ...
    'name', '', 'latlim', [], 'lonlim', [], 'tilerowcol',[]);
for k=1:numel(name)
    s(k).name = name{k};
    s(k).latlim(1) = latlimS(k);
    s(k).latlim(2) = latlimN(k);
    s(k).lonlim(1) = lonlimW(k);
    s(k).lonlim(2) = lonlimE(k);
    s(k).tilerow(1) = rtile(k);
    s(k).tilerow(2) = ctile(k);
end

% Can't search for files without extensions on PCs
sold = s;
for i=1:length(s)
    s(i).name = [s(i).name '.'];
end

% Search the path (and for PCs, the letter drives root) for the data files
foundpth = unique(searchfile(s));

% But PC's report out file names without the extension dot, go figure
s = sold;

% For each directory found, determine which files are in there
sout = {};
if ~isempty(foundpth)
    for i = 1:length(foundpth)
        d = dir(foundpth{i});
        sout{i} = s(ismember({s.name},{d.name})); %#ok<AGROW>
    end
end

%--------------------------------------------------------------------------

function foundpth = searchfile(s)
% Search for specified directory names
%
% foundpath = SEARCHFILES(s) searches PWD, the MATLAB path and PC device
% names for specified file names. File names are specified in
% an arrayed structure s with the required field 'name' containing the
% names of the directories as a string. The names of the directories
% in which the files were found are returned in foundpath.

foundpth = {};

% What's on the MATLAB path (which includes pwd)
for i=1:length(s)
    foundfiles = which('-all',s(i).name);
    for j=1:length(foundfiles)
        foundpth{end+1} = fileparts(foundfiles{j}); %#ok<AGROW>
    end
end

%--------------------------------------------------------------------------

function foundpth = searchpath(s)
% Search for specified directory names
%
% foundpath = SEARCHPATH(s) searches PWD, the MATLAB path and PC device
% names for specified directory names. Directory names are specified in
% an arrayed structure s with the required field 'name' containing the
% names of the directories as a string.
%
% At the moment, the search is broken off upon finding a match.

% Check for existence of directories of expected names
foundpth = {};

% I thought I could do
%  if exist(s(i).name,'dir') == 7 || exist(upper(s(i).name),'dir') == 7
% but that didn't work reliably (OK for gtopo30 when PWD, but not if on
% path when called from here, and EXIST works OK from command line - go
% figure) Then would have had to test each directory on the path only when
% a match was found. So have to use brute force approach: Search through
% the MATLAB path to find the location of the gtopo30 directory.

% Here we assume that the individual directories containing the necessary
% files are themselves on the MATLAB path. The way this used to work is
% that the code searched to see if the parent directory was on the path.
% From results of running this through the profiler, this was definitely
% slowing things down.
for n = 1:length(s)
    dir_name = deblank(s(n).name);
    % UNIX is case sensitive so we check for upper cases as well.
    udir_name = upper(dir_name);
    if exist(dir_name,'dir') || exist(udir_name,'dir')
        wstruct = what(dir_name);
        
        % We check the upper cased directory names
        if isempty(wstruct), wstruct = what(udir_name);end
        
        num_of_paths = length(wstruct);
        for m = 1:num_of_paths
            singlepath = wstruct(m).path;
            ind = strfind(singlepath, filesep);
            foundpth{end+1} = singlepath(1:ind(end)-1); %#ok<AGROW>
        end
    end
end

foundpth = unique(foundpth);

%--------------------------------------------------------------------------

function [foundpth] = dtedpath
% Return the path to a directory of DTED data.

s.name = 'dted';

foundpth = unique(searchpath(s));
for n = 1:length(foundpth)
    foundpth{n} = fullfile(foundpth{n},s.name);
end

%--------------------------------------------------------------------------

function s = dtedtiles(dtedpth)
% Return the information on dted files within a given directory.

d = dir(dtedpth);
d(~[d.isdir]) = [];

s = [];
for i=1:length(d)
    
    % look for directory names with leading w or e
    switch lower(d(i).name(1))
        case 'w'
            sgn = -1;
        case 'e'
            sgn = 1;
        otherwise
            sgn = NaN;
    end
    
    % look for directory names with trailing numbers
    lllon = str2double(d(i).name(2:end));
    if ~isnan(sgn) && ~isempty(lllon)
        
        dtedpth2 = [dtedpth filesep d(i).name];
        
        dd = dir(dtedpth2);
        dd([dd.isdir]) = [];
        
        %Look inside that directory
        for j=1:length(dd)
            
            switch lower(dd(j).name(1))
                case 's'
                    sgn2 = -1;
                case 'n'
                    sgn2 = 1;
                otherwise
                    sgn2 = NaN;
            end
            
            % look for file names with trailing numbers
            [~,name,ext] = fileparts(dd(j).name(2:end));
            
            lllat = str2double(name);
            if ~isempty(lllat) && length(ext)==4 && strcmpi(ext(2:3),'dt')
                s(end+1).latlim = [sgn2*lllat sgn2*lllat+1]; %#ok<AGROW>
                s(end).lonlim   = [sgn*lllon sgn*lllon+1];
                s(end).level    = str2double(ext(end));
            end
        end
    end
end

%--------------------------------------------------------------------------

function h = constructUI(sources,h)
% Construct the UI.

% Create the dialog window.
h.fig = figure('Color',[0.8 0.8 0.8], ...
    'units','pixels',...
    'Position', [51 36 804 663],...
    'Tag','DEMDATAUI','Visible','off',...
    'Menubar','none','Name','DEMDATAUI','NumberTitle','off');

colordef(h.fig,'white');
figclr = get(h.fig,'Color');
frameclr = brighten(figclr,0.5);

% Overview map
p = uipanel('units','normalized',...
    'Position',[.3 .15 .65 .7],...
    'Parent', h.fig);
c = get(h.fig, 'Color');

% Insert axes into a panel.
set(p, ...
    'BackgroundColor',c, ...
    'ForegroundColor',c, ...
    'HighlightColor',c', ...
    'ShadowColor',c)

h.axes = axes( 'Parent', p, ...
    'Position', [0 0 1 1], ...
    'Tag','samplemapaxes', ...
    'Units','normalized');

axesm('pcarree', 'Frame','on', ...
    'FLatLimit', [-90 90], 'FLonLimit', [-180 180], 'Frame', 'on')
tightmap
zdatam('frame', -2);
set(handlem('alltext'),'clipping','on')

% Base map data.
coast = load('coastlines.mat');
hold on
geoshow(coast.coastlat, coast.coastlon, 'Color',.65*[1 1 1], 'Parent', h.axes);
clear coast

% Build the GUI panel.
h.list = uicontrol('Style','list','units','Normalized',...
    'Position',[.02 .15 .15 .77],'Max',1,...
    'Interruptible','off','BackgroundColor','w',...
    'String',sources,'Callback',@uilist);

h.selected = 1;

h.listlabel = uicontrol('Style','text','Units','normalized',...
    'Position',[0.05 0.93 0.1 .03],'String','Source  ', ...
    'FontWeight','bold','backgroundColor',get(h.fig,'Color'));

h.axeslabel = uicontrol('Style','text','Units','normalized',...
    'Position',[0.5 0.93 0.2 .03],'String','Geographic Limits  ', ...
    'FontWeight','bold','backgroundColor',get(h.fig,'Color'));

h.sliderlabel = uicontrol('Style','text','Units','normalized',...
    'Position',[0.14 0.93 0.2 .03],'String','Samplefactor  ', ...
    'FontWeight','bold','backgroundColor',get(h.fig,'Color'));

h.slider = uicontrol('Style','Slider','Units','Normalized',...
    'Position',[0.213 0.15 0.04 0.77],'Min',1,'Max',100,'Value',1,...
    'SliderStep',[.01/0.99 0.20/0.99],...
    'backgroundColor',get(h.fig,'Color'),'Callback', @demdatauislider);

h.slidervalue = uicontrol('Style','text','Units','normalized',...
    'Position',[0.218 0.23 0.03 .03],'String','1','HorizontalAlignment','Center');

%.23 min, 0.81 max

% buttons

h.helpbtn = uicontrol('Parent',h.fig, ...
    'Units','normalized', ...
    'Position',0.8415*[0.05 0.03 .14 0.1], ...
    'Style','push', ...
    'String','Help', ...
    'Tag','helpbtn',...
    'Callback', @(~,~) doc('demdataui'),...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

h.clearbtn = uicontrol('Parent',h.fig, ...
    'Units','normalized', ...
    'Position',0.8415*[0.05+3*0.15 0.03 .14 0.1], ...
    'Style','push', ...
    'String','Clear', ...
    'Tag','clearbtn',...
    'Callback', @demdatauiclear,...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

h.getbtn = uicontrol('Parent',h.fig, ...
    'Units','normalized', ...
    'Position',0.8415*[0.05+1*0.15 0.03 .14 0.1], ...
    'Style','push', ...
    'String','Get', ...
    'Tag','getbtn',...
    'Callback', @demdatauiget,...
    'Interruptible','on',...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

h.savebtn = uicontrol('Parent',h.fig, ...
    'Units','normalized', ...
    'Position',0.8415*[0.05+5*0.15 0.03 .14 0.1], ...
    'Style','push', ...
    'String','Save', ...
    'Tag','getbtn',...
    'Callback', @uisave,...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

h.closebtn = uicontrol('Parent',h.fig, ...
    'Units','normalized', ...
    'Position',0.8415*[0.05+6*0.15 0.03 .14 0.1], ...
    'Style','push', ...
    'String','Close', ...
    'Callback', @(~, ~)close(h.fig),...
    'Tag','getbtn',...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

% Make figure resizeable.
set([...
    h.helpbtn,...
    h.clearbtn,...
    h.getbtn,...
    h.savebtn,...
    h.closebtn,...
    h.axes],'units','normalized')

set([...
    h.helpbtn,...
    h.clearbtn,...
    h.getbtn,...
    h.savebtn,...
    h.closebtn,...
    ],'fontunits','normalized')

% Initialize saved data.
h.extracteddata = [];

% Turn on zoom.
h.zoom = zoom(h.fig);
set(h.zoom, 'ActionPostCallback', @zoomCallback, 'Enable','on')

% Save UserData and set window button motion function.
set(h.fig, 'UserData', h, 'Visible','on', ...
    'WindowButtonMotionFcn', @demdatauislider)

%--------------------------------------------------------------------------

function uisave(hsrc, ~)
% Save data to a MAT-File or workspace.

if ishghandle(hsrc)
    hfig = get(hsrc, 'Parent');
    h = get(hfig,'userdata');
    
    if isempty(h.extracteddata)
        warndlg('No data to save','DEMDATAUI warning')
        return
    end
    
    answer = questdlg('Save data to a MAT-File or the base workspace?', ...
        'DEMDATAUI Save',...
        'MAT-File','Workspace','Cancel','MAT-File');
    
    switch answer
        case 'MAT-File'
            uifilesave(h.extracteddata)
        case 'Workspace'
            uiworkspacesave(h.extracteddata)
        case 'Cancel'
            return
    end
end

%--------------------------------------------------------------------------

function uiworkspacesave(extracteddata)

done = 0;
while ~done
    answer=inputdlg({'Name of saved data in base workspace'},'DEMDATAUI SAVE',1,{'demdata'});
    if ~isempty(answer)
        try
            assignin('base',answer{1},extracteddata)
            done = 1;
        catch e
            errordlg(e.message,'DEMDATAUI SAVE ERROR','modal');
        end
    else
        return
    end
end

%--------------------------------------------------------------------------

function uifilesave(data) %#ok<INUSD>

curpwd = pwd;
[filename,pathname] = uiputfile('*.mat', 'Save the data in MAT-file:');

if filename == 0
    return
end

done = 0;
while ~done
    answer=inputdlg({'Name of saved data in MAT-file'},'DEMDATAUI SAVE',1,{'demdata'});
    if ~isempty(answer)
        answer = answer{1};
        try
            eval([answer ' = data;'])
            save([pathname filename],answer)
            done = 1;
        catch e
            errordlg(e.message,'DEMDATAUI SAVE ERROR','modal')
        end
    else
        return
    end
end

cd(curpwd)

%--------------------------------------------------------------------------

function [Z, refvec] = etopo5read(scalefactor, latlim, lonlim)
% We need to support longitude limits in the interval [-180 180], but
% function ETOPO will only read ETOPO5 for limits in [0 360].  Therefore
% we may have to:
%
% * Shift the longitude limits from the interval [180 360] to the
%   interval [-180 0]
%
% * Read the data in two parts with two separate calls to ETOPO.
%
% Assume that the input lonlim is ascending and in the interval [-180 180].

if 0 <= lonlim(1)
    % Eastern hemisphere only
    [Z, refvec] = etopo(scalefactor, latlim, lonlim);
elseif lonlim(2) <= 0
    % Western hemisphere only
    [Z, refvec] = etopo(scalefactor, latlim, lonlim + 360);
    refvec(3) = refvec(3) - 360;
else
    % Both hemispheres
    [Z_west, refvec] = etopo(scalefactor, latlim, 360 + [lonlim(1) 0]);
    Z_east = etopo(scalefactor, latlim, [0 lonlim(2)]);
    Z = [Z_west Z_east];
    refvec(3) = refvec(3) - 360;
end

%--------------------------------------------------------------------------

function zoomCallback(~, hsrc)
% After a zoom event, reset the frame limits to the axes limits.

haxes = hsrc.Axes;
if ishghandle(haxes, 'axes')
    % Obtain current X and Y limits.
    xLimits = get(haxes, 'XLim');
    yLimits = get(haxes, 'YLim');
    
    % Inverse project X,Y limits to latitude and longitude.
    [latlim, lonlim] = pcarreeInverse(xLimits, yLimits);
    
    % Save the current frame's FaceColor and Visible properties.
    h = handlem('frame', haxes);
    frameColor   = get(h, 'FaceColor');
    frameVisible = get(h, 'Visible');
    
    % Reset the frame's properties.
    setm(haxes, 'FLatLimit', latlim, 'FlonLimit', lonlim, ...
        'FFaceColor', frameColor, 'Frame', frameVisible);
    
    % Ensure the X and Y limits are set to frame's limits.
    h = handlem('frame', haxes);
    xData = get(h, 'XData');
    yData = get(h, 'YData');
    xLimits = [min(xData) max(xData)];
    yLimits = [min(yData) max(yData)];
    set(haxes, 'XLim', xLimits, 'YLim', yLimits);
    
    % Ensure the graphics are updated.
    drawnow
end
 