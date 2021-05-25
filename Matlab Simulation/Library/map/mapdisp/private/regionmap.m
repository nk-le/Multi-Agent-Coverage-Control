function h = regionmap(mapFunctionName, args)
%REGIONMAP Construct a map axes for a region of the world or USA.

%   Parse and process inputs for either 'worldmap' or 'usamap'.
%   MAPFUNCTIONNAME is the name of one of these functions.  This
%   implementation errors on any of the following obsolete syntaxes:
%
%   1) First argument matches a string in {'hi', 'lo', 'allhi'}
%
%   2) Last argument matches a "type" string:
%        {'patch','line','patchonly','lineonly','none','mesh',...
%        'meshonly','mesh3d','dem','demonly','dem3d','dem3donly',..
%        'ldem3d','ldem3donly','lmesh3d','lmesh3donly'}
%
%   3) 'only' is appended to a region or state name

% Copyright 2004-2020 The MathWorks, Inc.

if nargin > 1
   [args{:}] = convertStringsToChars(args{:});
end

% Error on leading argument 'hi', 'lo', or 'allhi' (worldmap only).
if strcmp(mapFunctionName,'worldmap')
    checkForObsoleteFirstArg(args)
end

% Error on trailing "type" argument.
checkForObsoleteTypeString(mapFunctionName, args);

% Set parameters specific to worldmap or usamap
regionsMAT = fullfile(toolboxdir("map"),"mapdisp","private","regions.mat");
if strcmp(mapFunctionName,'worldmap')
    load(regionsMAT,'worldRegions');
    validRegions =  worldRegions;
    load(regionsMAT,'worldAbbreviations')
    abbreviations = worldAbbreviations;
    specialRegions = {};
    constructMapAxes = @constructMapAxesWorld;
    mapLimitIncrement = 5;  % Degrees
else
    load(regionsMAT,'stateRegions');
    validRegions =  stateRegions;
    load(regionsMAT,'stateAbbreviations')
    abbreviations = stateAbbreviations;
    specialRegions = {'conus', 'all', 'allequal'};
    constructMapAxes = @constructMapAxesUSA;
    mapLimitIncrement = 1;  % Degrees
end

% Set the ellipsoid to a reference sphere that models the Earth.
e = referenceSphere('earth','meters');

switch(numel(args))
    
    case 0    
        % Syntax: WORLDMAP or USAMAP
        
        % Ask the user to select a region from a dialog box, returning the
        % result in the string regionName. If the user cancels, regionName
        % will be empty and worldmap (or usamap) is done.
        dialogList = [specialRegions, {validRegions.name}];
        regionName = getRegionFromDialog(dialogList);
        if isempty(regionName)
            h = [];
            return
        else
            % Check for special (USA) map regions.
            if any(strcmpi(regionName,specialRegions))
                % Construct one ('conus') or three ('all','allequal') map
                % axes with hard-coded map projections and limits.
                h = constructSpecialMapAxes(regionName, e);
            else
                % Lookup the latitude/longitude limits for the region.
                % Embed regionName in a cell array before calling
                % getLimitsFromRegions, because it expects a list of
                % regions.
                [latlim, lonlim] = getLimitsFromRegions(...
                    {regionName}, validRegions, mapLimitIncrement);
                h = constructMapAxes(latlim, lonlim, e);
            end
        end
        
    case 1   
        % Syntax: WORLDMAP REGION or WORLDMAP(REGIONS) or
        %           USAMAP STATE  or   USAMAP(STATES)
        
        % If necessary, convert REGIONS from a string or "padded
        % string matrix" to a cell array of strings.
        regionNames = checkMapRegions(args{1});
        
        % Check for special (USA) map regions.
        if isSpecialRegion(mapFunctionName, regionNames, specialRegions)
            % Construct one ('conus') or three ('all','allequal') map
            % axes with hard-coded map projections and limits.
            h = constructSpecialMapAxes(regionNames{1}, e);
        else
            % If necessary, translate from short list of permissible
            % abbreviations.
            if ~isempty(abbreviations)
                regionNames = expandAbbreviations(regionNames, abbreviations);
            end
            
            % Lookup the latitude/longitude limits for the region and
            % combine limits from multiple regions.
            [latlim, lonlim] = getLimitsFromRegions(...
                regionNames, validRegions, mapLimitIncrement);
            h = constructMapAxes(latlim, lonlim, e);
        end
        
    otherwise
        % Syntax: WORLDMAP(Z, R) or WORLDMAP(LATLIM, LONLIM) or
        %           USAMAP(Z, R)  or  USAMAP(LATLIM, LONLIM)
        
        s = size(args{2});
        arg2IsRefVectorOrMatrix = isequal(s, [1 3]) || isequal(s, [3 2]);
        if arg2IsRefVectorOrMatrix || isobject(args{2})
            % WORLDMAP(Z, R)
            [latlim, lonlim] = getLimitsFromDataGrid(args{:}, mapFunctionName);
        else
            % WORLDMAP(LATLIM, LONLIM)
            [latlim, lonlim] = checkMapLimits(args{:}, mapFunctionName);
        end
        h = constructMapAxes(latlim, lonlim, e);
        
end

%--------------------------------------------------------------------------

function checkForObsoleteFirstArg(args)
% Issue an error if the initial argument is 'hi', 'lo', or 'allhi'.

obsoleteLeadingArgs = {'hi', 'lo', 'allhi'};

firstArgMatchesObsoleteLeadingArgs = ...
    numel(args) > 0 && ...
    ischar(args{1}) && ...
    any(strcmpi(args{1},obsoleteLeadingArgs));

if firstArgMatchesObsoleteLeadingArgs
    error(message('map:regionmap:invalidFirstArg',args{1},'WORLDMAP'))
end

%--------------------------------------------------------------------------

function checkForObsoleteTypeString(mapFunctionName, args)
% Issue an error if the argument list includes a trailing "type" string.

typeStrings = {'patch','line','patchonly','lineonly','none','mesh',...
               'meshonly','mesh3d','dem','demonly','dem3d','dem3donly',...
               'ldem3d','ldem3donly','lmesh3d','lmesh3donly'};
           
lastArgMatchesTypeString = ...
    numel(args) > 0 && ...
    ischar(args{end}) && ...
    any(strcmpi(args{end},typeStrings));

if lastArgMatchesTypeString
    error(message('map:regionmap:invalidTrailingArg', ...
         args{end}, upper(mapFunctionName)))
end
   
%--------------------------------------------------------------------------

function region = getRegionFromDialog(regionlist)
% Ask the user to select a region by name from a list dialog.  Return a
% string containing the name of the region.  If the user cancels, return
% empty.

indx = listdlg('ListString',     regionlist,...
               'SelectionMode', 'single',...
               'Name',          'Select a region');

if isempty(indx)
    region = '';
else
    region = regionlist{indx};
end

%--------------------------------------------------------------------------

function result = isSpecialRegion(...
    mapFunctionName, regionNames, specialRegions)
% Check to see if there single region name that matches one of the special
% regions.  However, if multiple regions names are given, then _none_ of
% them may match a special region.

if numel(regionNames) == 1
    result = any(strcmpi(regionNames{1},specialRegions));
elseif numel(regionNames) > 1
    for k = 1:numel(regionNames)
        if any(strcmpi(regionNames{k},specialRegions))
            error(message('map:regionmap:specialRegionWithOthers', ...
                regionNames{k}, mapFunctionName))
        end
    end
    result = false;
else
    result = false;
end

%--------------------------------------------------------------------------

function regions = expandAbbreviations(regions, abbreviations)
% For each string in REGIONS, translate from a short list of acceptable
% abbreviations if a match is found.  Otherwise, leave the string as-is.

short = abbreviations(:,1);
full  = abbreviations(:,2);
for k = 1:numel(regions)
    index = strcmpi(regions{k}, short);
    if any(index)
        index = find(index);
        regions{k} = full{index(1)};
    end
end

%--------------------------------------------------------------------------

function regionNames = checkMapRegions(regionNames)
% Validate and convert REGIONNAMES to a cell array of strings, removing
% padded blanks, if present. Error if there's a suffix 'only'. REGIONNAMES
% may be input as a string, a "padded string matrix" (an old syntax that is
% no longer publicized but still supported), or a cell array of strings.

% If regionNames is a cell array, make sure it contains only strings.
if iscell(regionNames)
    for k = 1:numel(regionNames)
        if ~isString(regionNames{k})
            error(message('map:regionmap:nonStringsInRegion','REGION'))
        end
    end
end
  
% If regionNames is a string or "padded string matrix", convert it to a cell array.
if ischar(regionNames)
    regionNames = cellstr(regionNames);
end

% Error if the suffix 'only' is included in a region name. Otherwise,
% just remove any leading or trailing blanks.
for k = 1:numel(regionNames)
    regionName = deblank(regionNames{k});
    endsInOnly = (numel(regionName) > 4) && strcmpi(regionName((end-3):end),'only');
    if endsInOnly
        error(message('map:regionmap:invalidSuffixOnly',regionNames{k},'only'))
    end
    
    % Remove leading blanks and possible trailing blanks
    regionNames{k} = strtrim(regionName);
end

%--------------------------------------------------------------------------

function q = isString(s)
% Return true iff input S is a 1-by-N array of class char.

q = ischar(s) && (size(s,1) == 1) && (ismatrix(s));

%--------------------------------------------------------------------------

function [latlim, lonlim] = getLimitsFromDataGrid(Z, R, mapFunctionName)
% Compute latitude and longitude limits from a regular data grid and its
% referencing vector or matrix, R.

R = internal.map.convertToGeoRasterRef( ...
    R, size(Z), 'degrees', mapFunctionName, 'R', 2);

latlim = R.LatitudeLimits;
lonlim = R.LongitudeLimits;

% Avoid trims if displaying subset of world.
if abs(diff(lonlim)) ~= 360
    lonlim = lonlim + [-1 0]*(10*epsm('deg')); % avoids trimming
end

%--------------------------------------------------------------------------

function [latlim, lonlim] = checkMapLimits(latlim, lonlim, mapFunctionName)
% Check type, size, and values of latitude and longitude limits.

checkgeoquad(latlim, lonlim, mapFunctionName, 'LATLIM', 'LONLIM', 1, 2)

if lonlim(2) > lonlim(1) + 360
    lonlim(2) = lonlim(1) + 360;
end

%--------------------------------------------------------------------------

function [latlim, lonlim] = getLimitsFromRegions(...
    regionNames, validRegions, inc)
% Return the most compact possible latitude and longitude limits that
% encompass the regions listed by name in cell array regionNames.

latlim = [];
lonlim = [];

validRegionNames = {validRegions.name};

for k = 1:numel(regionNames)
    index = strncmpi(regionNames{k},validRegionNames,numel(regionNames{k}));
    if ~any(index)
        error(message('map:regionmap:unknownRegion',regionNames{k}))
    elseif nnz(index) > 1
        validatestring(regionNames{k},validRegionNames(index))
    end
    index = find(index);
    latlim = mergelatlimits(latlim, validRegions(index).latlim);
    lonlim = mergelonlimits(lonlim, validRegions(index).lonlim);
    % Possible enhancements:  Merge all the regions simultaneously to
    % ensure that the longitude limit result is independent of the
    % processing order.  Also ensure that the longitude limits do not span
    % more than 360 degrees.
end

% Snap map limits to increments of INC, with a 1 degree buffer, except
% for limits that are already exact multiples of INC.
buffer = 1;

if mod(latlim(1),inc) ~= 0
    latlim(1) = inc * floor((latlim(1) - buffer)/inc);
end
if mod(lonlim(1),inc) ~= 0
    lonlim(1) = inc * floor((lonlim(1) - buffer)/inc);
end
if mod(latlim(2),inc) ~= 0
    latlim(2) = inc * ceil((latlim(2) + buffer)/inc);
end
if mod(lonlim(2),inc) ~= 0
    lonlim(2) = inc * ceil((lonlim(2) + buffer)/inc);
end

if latlim(1) < -90
    latlim(1) = -90;
end
if latlim(2) > 90
    latlim(2) = 90;
end

%--------------------------------------------------------------------------

function latlim = mergelatlimits(latlim1, latlim2)

% Compute the tightest possible latitude limits encompassing both the
% interval defined by 1-by-2 vector LATLIM1 and the interval defined by
% 1-by-2 vector in LATLIM2.  Note that either input could be empty.
limits = [latlim1 latlim2];
latlim = [min(limits) max(limits)];

%--------------------------------------------------------------------------

function lonlim = mergelonlimits(lonlim1, lonlim2)

% Compute the tightest possible longitude limits encompassing both the
% interval defined by 1-by-2 vector LONLIM1 and the interval defined by
% 1-by-2 vector LONLIM2.  In addition, LONLIM1, LONLIM2, or both may be
% empty.

if isempty(lonlim1)
    lonlim = lonlim2;  
elseif isempty(lonlim2)
   lonlim = lonlim1;
else
    % Shift both intervals such that the first one starts at zero.  Call
    % the shifted versions i1 and i2.
    s1 = lonlim1(1);
    i1 = zero22pi(lonlim1 - s1);
    i2 = lonlim2 - s1;
    if zero22pi(i2(1)) <= i1(2)
        % We have overlap, with interval 2 starting within interval 1
        s2 = i2(1) - zero22pi(i2(1));
        % If necessary, shift i2 by a multiple of 360 degrees, so that
        % i2(1) falls within i1.  Call the result j2.
        j2 = i2 - s2;
        % Merge i1 and j2
        j = [0, max(i1(2),j2(2))];
    elseif zero22pi(i2(2)) <= i1(2)
        % We have overlap, with interval 2 ending within interval 1
        s2 = i2(2) - zero22pi(i2(2));
        % If necessary, shift i2 by a multiple of 360 degrees, so that
        % i2(2) falls within i1.  Call the result j2.
        j2 = i2 - s2;
        % Merge i1 and j2
        j = [min(0,j2(1)) i1(2)];
    else
        % Neither overlap condition was met; there is no overlap. We can
        % define j (shifted output interval) by either putting i2 to the
        % east of i1, or by putting it to the west.  We'll make the choice
        % that minimizes the width of j.
        width1 = zero22pi(i2(2));   % Width putting i2 to the east
        width2 = i1(2) - (zero22pi(i2(1)) - 360);  % Width putting i2 to the west
        if width1 <= width2
            j = [0 width1];
        else
            j = i1(2) + [-width2 0];
        end
    end
    % Undo the shift s1
    lonlim = j + s1;
end


%--------------------------------------------------------------------------

function ax = constructMapAxesWorld(latlim, lonlim, e)

% Construct a map axes suitable to the specified latitude and longitude limits.

% Ensure row vectors.
latlim = latlim(:)';
lonlim = lonlim(:)';

% Ensure ascending lonlim.
if lonlim(1) > lonlim(2)
    if lonlim(1) > 180
        lonlim(1) = lonlim(1) - 360;
    else
        lonlim(2) = lonlim(2) + 360;
    end
end

% Compute a nice increment for labels and grid.
% Pick a ticksize that gives at least 3 grid lines
mindiff = min(abs([diff(latlim) diff(lonlim)]));
ticcandidates = [.1 .5 1 2 2.5 5 10 15 20 30 45 ] ;
[~,indx] = min( abs( 3 - (mindiff ./ ticcandidates) ));

ticksize = ticcandidates(indx);
roundat = 0;
if mod(ticksize,1) ~= 0; roundat = -1; end

% Select a projection based on latlim,lonlim.
projection = selectProjection(latlim, lonlim);

% Delete existing map axes if necessary
if ismap(gca) == 1
    delete(get(gca,'Children'));
end

% Set up the axes with the selected projection and parameters.
% More than one path because of error messages setting parallels
% when projections don't have any.
if strcmp(projection,'upsnorth') || strcmp(projection,'upssouth')
    
    ax = axesm( ...
        'MapProjection','ups', ...
        'Zone',projection(4:end), ...
        'Frame','on',...
        'Grid','on',...
        'LabelRotation','on',...
        'MeridianLabel','on',...
        'ParallelLabel','on',...
        'MLabelParallel',0, ...
        'Spheroid', e);
    
else
    
    mstruct = defaultm(projection);
    
    if strcmp(projection,'eqdazim')
      
        ax = axesm(...
            'MapProjection',projection,...
            'FLatLimit',[-Inf abs(diff(latlim))],...
            'Origin',[90*sign(latlim(2)) mean(lonlim) 0], ...
            'Spheroid', e);
        
        % Set common properties.
        setCommonMapAxesProperties(ax, ticksize, roundat);
        
        % Separate graticule meridians and meridian labels by 30 degrees
        % for polar azimuthal projections.
        lonGratSpacingAzimuthal = 30;
        setm(ax, ...
            'MLabelLoc',lonGratSpacingAzimuthal,...
            'MLineLoc', lonGratSpacingAzimuthal);
        
    elseif mstruct.nparallels > 0       
        ax = axesm(...
            'MapProjection',projection,...
            'MapLatLimit',latlim,...
            'MapLonLimit',lonlim,...
            'MapParallels',[], ...
            'Spheroid', e);
        
        % Set common properties.
        setCommonMapAxesProperties(ax, ticksize, roundat);
        
    else
        ax = axesm(...
            'MapProjection',projection,...
            'MapLatLimit',latlim,...
            'MapLonLimit',lonlim, ...
            'Spheroid', e);
        
        % Set common properties.
        setCommonMapAxesProperties(ax, ticksize, roundat);
    end
end

set(ax, 'Visible', 'off')
set(get(ax,'Title'), 'Visible', 'on')

% On maps of the whole world, move the meridian labels south a little
% to keep them from overwriting the parallel labels for the equator.
if strcmpi(getm(ax,'MapProjection'),'robinson')
    setm(ax,'MLabelParallel',-10)
end

% Adjust the axes settings to create a more pleasing map figure. 
tightmap

%--------------------------------------------------------------------------

function setCommonMapAxesProperties(ax, ticksize, roundat)
% Set common map axes properties.

setm(ax, ...
    'Frame', 'on',...
    'Grid',  'on',...
    'LabelRotation', 'on',...
    'MeridianLabel', 'on',...
    'ParallelLabel', 'on',...
    'MLabelParallel', 0, ...
    'MLabelLoc', ticksize,...
    'MLineLoc',  ticksize,...
    'PLabelLoc', ticksize,...
    'PLineLoc',  ticksize,...
    'MLabelRound', roundat,...
    'PLabelRound', roundat,...
    'GColor', [.75 .75 .75],...
    'GLineStyle', ':');
    
%--------------------------------------------------------------------------

function projection = selectProjection(latlim, lonlim)
% Select a reasonable projection based on the coordinate limits.

if isequal(latlim,[-90 90]) && diff(lonlim) >= 360
    % entire globe
    projection = 'robinson';
    
elseif max(abs(latlim)) < 20
    % straddles equator, but doesn't extend into extreme latitudes
    projection = 'mercator';
    
elseif abs(diff(latlim)) <= 90 && abs(sum(latlim)) > 20 && max(abs(latlim)) < 90
    % doesn't extend to the pole, not straddling equator
    projection = 'eqdconic';
    
elseif abs(diff(latlim)) < 85 && max(abs(latlim)) < 90
    % doesn't extend to the pole, not straddling equator
    projection = 'sinusoid';
    
elseif max(latlim) == 90 && min(latlim) >= 84
    projection = 'upsnorth';
    
elseif min(latlim) == -90 && max(latlim) <= -80
    projection = 'upssouth';
    
elseif max(abs(latlim)) == 90 && abs(diff(lonlim)) < 180
    projection = 'polycon';
    
elseif max(abs(latlim)) == 90 && abs(diff(latlim)) < 90
    projection = 'eqdazim';
    
else
    projection = 'miller';
end

%--------------------------------------------------------------------------

function h = constructMapAxesUSA(latlim, lonlim, e)
% Construct a map axes suitable to the specified latitude and longitude
% limits, for maps covering all or part of the Conterminous U.S.

% Ensure row vectors.
latlim = latlim(:)';
lonlim = lonlim(:)';

% Ensure ascending lonlim.
if lonlim(1) > lonlim(2)
    if lonlim(1) > 180
        lonlim(1) = lonlim(1) - 360;
    else
        lonlim(2) = lonlim(2) + 360;
    end
end

% Compute a nice increment for labels and grid.
% Pick a ticksize that gives at least 3 grid lines

mindiff = min(abs([diff(latlim) diff(lonlim)]));
ticcandidates = [.1 .5 1 2 2.5 5 10 15 20 30 45 ] ;
[~,indx] = min( abs( 4 - (mindiff ./ ticcandidates) ));

ticksize = ticcandidates(indx);
roundat = 0;
if mod(ticksize,1) ~= 0; roundat = -1; end

% States are small enough to display conformally with little error
projection = 'lambert';

% set up the map axes
h = axesm(...
    'MapProjection',projection,...
    'MapLatLimit',latlim,...
    'MapLonLimit',lonlim,...
    'MapParallels',[], ...
    'Spheroid', e);
    
setCommonMapAxesProperties(h, ticksize, roundat);

set(h, 'Visible', 'off')
set(get(h,'Title'), 'Visible', 'on')

tightmap('loose')

%--------------------------------------------------------------------------

function h = constructSpecialMapAxes(region, e)
% Construct map axes for the United States for three special
% region designations:  'all', 'allequal', or 'conus'.

% Construct either one or three axes, with carefully-defined positions.
if strcmpi(region, 'conus')
    % region is conus  
    conusPosition = [ -0.0078125  0.13542  1.0156  0.73177 ];
    h = constructConusMapAxes(conusPosition, e);    
else
    % region is all or allequal
    conusPosition  = [0.1   0.25  0.85  0.6];
    alaskaPosition = [0.03  0.03  0.2   0.2];
    hawaiiPosition = [0.6   0.15  0.2   0.2];
    hConus =  constructConusMapAxes(conusPosition, e);
    hAlaska = constructAlaskaMapAxes(alaskaPosition, e);
    hHawaii = constructHawaiiMapAxes(hawaiiPosition, e);
    h = [hConus hAlaska hHawaii];
    axesscale(hConus) % Resize axes for Alaska and Hawaii.
    set(gcf,'CurrentAxes',hConus)
end

% Hide the axes, but not the title of the first (CONUS) axes.
set(h, 'Visible', 'off')
set(get(h(1),'Title'), 'Visible', 'on')

%--------------------------------------------------------------------------

function hConus = constructConusMapAxes(position, e)
% Map axes for CONUS.

hConus = axes('Position', position);

axesm(...
    'MapProjection','eqaconic',...
    'MapParallels', [29.5 49.5],...
    'Origin', [0 -100 0],...
    'FLatLimit', [23 50],...
    'FLonLimit', [-27  35], ...
    'Spheroid', e);

ticksize = 10;
roundat = 0; % default value
setCommonMapAxesProperties(hConus, ticksize, roundat)

 % Put nice amount of white space around CONUS, and lock down limits to
 % disable autoscaling. Use AXIS AUTO to undo.
xlim(e.Radius * [-0.5 0.6])  
ylim(e.Radius * [ 0.30 0.92]) 

%--------------------------------------------------------------------------

function hAlaska = constructAlaskaMapAxes(position, e)
% Map axes for Alaska. Scale is considerably different from CONUS.
        
hAlaska = axes('Position', position);

ax = axesm(...
    'MapProjection','eqaconic',...
    'MapParallels', [55 65],...
    'Origin', [0 -150 0],...
    'FLatLimit', [50 75],...
    'FLonLimit', [-25  25], ...
    'Spheroid', e);
    
ticksize = 10;
roundat = 0; % default value
setCommonMapAxesProperties(ax, ticksize, roundat)

xlim(e.Radius * [-0.3 0.3 ])
ylim(e.Radius * [ 0.7  1.3])

%--------------------------------------------------------------------------

function hHawaii = constructHawaiiMapAxes(position, e)
% Map axes for Hawaii.

hHawaii = axes('Position',position);

ax = axesm(...
    'MapProjection','eqaconic',...
    'MapParallels', [8 18],...
    'Origin', [0 -157 0],...
    'FLatLimit', [18 24],...
    'FLonLimit', [-3  3], ...
    'Spheroid', e);

ticksize = 1;
roundat = 0; % default value
setCommonMapAxesProperties(ax, ticksize, roundat)

setm(ax, ...
    'MLabelParallel', 24, ...
    'MLabelLocation', 5, ...
    'PLabelLocation', 5)

xlim(e.Radius * [-0.064103  0.058974])
ylim(e.Radius * [ 0.305190  0.440260])
