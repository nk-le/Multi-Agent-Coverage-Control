function hndl = gridm(varargin)
%GRIDM Toggle and control display of graticule lines
%
%   GRIDM toggles the display of a latitude-longitude graticule.
%   The choice of meridians and parallels, as well as their graphics
%   properties, depends on the property settings of the map axes.
%
%   GRIDM ON makes the graticule visible, and creates it if it does not
%   yet exist.
%
%   GRIDM OFF makes the graticule invisible.
%
%   GRIDM RESET redraws the graticule using the current map axes
%   properties.
%
%   GRIDM(LINESPEC) uses any valid LineSpec to control the graphics
%   properties of the lines in the graticule.
%
%   GRIDM('MapAxesPropertyName',PropertyValue,...) uses the specified
%   Map Axes properties to control the display of the graticule (and
%   updates those properties in the map axes itself).
%
%   h = GRIDM(...) returns the handles of the graticule lines. If both
%   parallels and meridians have been drawn, then h is a two-element
%   vector: h(1) is the handle to the line comprising the parallels and
%   h(2) is the handle to the line comprising the meridians.
%
%   See also AXESM, SETM

% Copyright 1996-2019 The MathWorks, Inc.

%  Make sure there's a map axes
mstruct = gcm;

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end
if nargin == 0
    h = graticule_(mstruct);
elseif nargin == 1
    switch(varargin{1})
        case 'on'
            h = graticule_on(mstruct);
        case 'off'
            h = graticule_off(mstruct);
        case 'reset'
            h = graticule_reset(mstruct);
        otherwise
            h = graticule_linespec(mstruct,varargin{1});
    end
elseif rem(nargin,2) == 0
    h = graticule_props(mstruct,varargin);
else
    error(message('map:validate:invalidArgCount'))
end

if nargout > 0
    %  Set handle return argument if necessary
    hndl = h;
end

%-----------------------------------------------------------------------

function h = graticule_(mstruct)
% Usage: GRIDM or h = GRIDM

h = handlem('Grid');
if isempty(h)
    % There is no graticule -- create one
    h = drawGraticule(mstruct);
else
    if strcmp(get(h,'Visible'),'off')
        % There is an invisible graticule -- make it visible
        makeGraticuleVisible(mstruct)
    else
        % There is a visible graticule -- make it invisible
        makeGraticuleInvisible(mstruct)
    end
end

%-----------------------------------------------------------------------

function h = graticule_on(mstruct)
% Usage: GRIDM ON or h = GRIDM('on');

h = handlem('Grid');
if isempty(h)
    % There is no graticule -- create one
    h = drawGraticule(mstruct);
else
    % There is an invisible graticule -- make it visible
    makeGraticuleVisible(mstruct)
end

%-----------------------------------------------------------------------

function h = graticule_off(mstruct)
% Usage: GRIDM OFF or h = GRIDM('off');

h = handlem('Grid');
makeGraticuleInvisible(mstruct)

%-----------------------------------------------------------------------

function h = graticule_reset(mstruct)
% Usage: GRIDM RESET or h = GRIDM('reset');

deleteGraticule
h = drawGraticule(mstruct);

%-----------------------------------------------------------------------

function h = graticule_linespec(mstruct,linespec)
% Usage: GRIDM LINESPEC or h = GRIDM(LINESPEC);

props = colorAndLineStyle(linespec);
h = graticule_props(mstruct, props);

%-----------------------------------------------------------------------

function h = graticule_props(mstruct,props)
% Usage: h = GRIDM(PROPERTY1,VALUE1,PROPERTY,VALUE2,...);
% PROPS is a cell array comprising property name-value pairs.

if ~isempty(props)
    % AXESM recursively calls GRIDM to display the graticule
    axesm(mstruct,'Grid','reset',props{:});
    h = handlem('Grid');
else
    deleteGraticule
    h = drawGraticule(mstruct);
end 

%-----------------------------------------------------------------------

function makeGraticuleVisible(mstruct)
showm('Grid');
mstruct.grid = 'on';
set(gca,'UserData',mstruct);

%-----------------------------------------------------------------------

function makeGraticuleInvisible(mstruct)
hidem('Grid');
mstruct.grid = 'off';
set(gca,'UserData',mstruct);

%-----------------------------------------------------------------------

function props = colorAndLineStyle(linespec)
% Property name-value pairs for input to AXESM

[lstyle, lcolor] = internal.map.parseLineSpec(linespec);

props = {};
if ~isempty(lcolor)
    props{end+1} = 'GColor';
    props{end+1} = lcolor;
end
if ~isempty(lstyle)
    props{end+1} = 'GLineStyle';
    props{end+1} = lstyle;
end

%-----------------------------------------------------------------------

function deleteGraticule
% Delete the graticule, if it exists

h = handlem('Grid');
delete(h)

%-----------------------------------------------------------------------
   
function h = drawGraticule(mstruct)

%  Initialize handles
hParallel = gobjects(0);
hMeridian = gobjects(0);

alt = mstruct.galtitude;
if isinf(alt)
    alt = 0;
end

%  Compute & display parallels
if all(isfinite(mstruct.plinelocation))
    [lat,lon] = parallels(mstruct);
    if ~isempty(lat)
        hParallel = graticuleLine(mstruct, lat, lon, alt, 'Parallel');
    end
end

%  Compute & display meridians
if all(isfinite(mstruct.mlinelocation))
    [lat,lon] = meridians(mstruct);
    if ~isempty(lat)
        hMeridian = graticuleLine(mstruct, lat, lon, alt, 'Meridian');
    end
end

%  Set the display flag to on if either line is drawn
if isempty(hParallel) && isempty(hMeridian)
    mstruct.grid = 'off';
else
    mstruct.grid = 'on';
    %  Restack to ensure standard child order in the map axes.
    map.graphics.internal.restackMapAxes([hParallel; hMeridian])
end
set(gca,'UserData',mstruct)

h = [hParallel; hMeridian];

%-----------------------------------------------------------------------

function h = graticuleLine(mstruct, lat, lon, alt, tag)

% Trim and project the graticule lines, with special handling in the case
% of 'globe'.
projName = mstruct.mapprojection;
if strcmpi(projName,'globe')
    spheroid = map.internal.mstruct2spheroid(mstruct);
    [lat, lon] = toDegrees(mstruct.angleunits, lat, lon);
    [x, y, z] = geodetic2ecef(spheroid, lat, lon, alt);
else
    [x, y] = feval(projName, mstruct, lat, lon, 'geoline' , 'forward');
    z = alt + zeros(size(x));
    z(isnan(x)) = NaN;
end

% Display trimmed and projected lines
if strcmp(tag,'Parallel')
    vis = mstruct.plinevisible;
else
    vis = mstruct.mlinevisible;
end

h = line(x, y, z, ...
    'ButtonDownFcn', @uimaptbx,...
    'Tag',       tag,...
    'Color',     mstruct.gcolor,...
    'LineWidth', mstruct.glinewidth,...
    'LineStyle', mstruct.glinestyle,...
    'Visible',   vis, ...
    'Clipping', 'off');

%-----------------------------------------------------------------------

function [latout,lonout] = parallels(mstruct)

%  Retrieve parameters
latdelta   = mstruct.plinelocation;
limits     = mstruct.plinelimit;
exception  = mstruct.plineexception;
fillpts    = mstruct.plinefill;
[maplat, maplon] = gratbounds(mstruct);

%  Convert to degrees
[maplat, maplon, latdelta, limits, exception] = toDegrees( ...
    mstruct.angleunits, maplat, maplon, latdelta, limits, exception);

%  Latitude locations for the whole world
latlim = [-90 90];

%  Compute the latitudes at which to draw parallels
if length(latdelta) == 1
    latline  = [fliplr(0:latdelta:max(latlim)), ...
        -latdelta:-latdelta:min(latlim) ];
else
    %  Vector of points supplied
    latline = latdelta;
end

latline = latline(latline >= min(maplat) & latline <= max(maplat));

%  Compute the longitude fill points for each parallel
lonline = linspace(min(maplon), max(maplon), fillpts);

%  Use meshgrid to fill in the points on each parallel. The insertion of
%  NaN provides a break between the end of one parallel and the
%  beginning of the next.
[lonline,latline] = meshgrid([lonline NaN], latline);

%  Keep NaN positions consistent
latline(isnan(lonline)) = NaN;

%  Transpose arrays, then convert to vectors
latline = latline';
lonline = lonline';
latline = latline(:);
lonline = lonline(:);

%  "Process any grids which are restricted from the entire map display"
if ~isempty(limits)
    indxlow = find(lonline < min(limits));
    indxup  = find(lonline > max(limits));

    if ~isempty([indxlow; indxup])
        epsilon = 100*epsm('degrees');
        for i = 1:length(exception)      %  Exceptions to the limit process
            exceptindx = (abs(latline(indxlow) - exception(i)) <= 10*epsilon);
            indxlow(exceptindx) = [];
            exceptindx = (abs(latline(indxup) - exception(i)) <= 10*epsilon);
            indxup(exceptindx) = [];
        end
    end

    lonline(indxlow) = min(limits);
    lonline(indxup)  = max(limits);
end

[latout, lonout] = fromDegrees(mstruct.angleunits, latline, lonline);

%-----------------------------------------------------------------------

function [latout,lonout] = meridians(mstruct)

%  Retrieve meridian parameters
londelta   = mstruct.mlinelocation;
limits     = mstruct.mlinelimit;
exception  = mstruct.mlineexception;
fillpts    = mstruct.mlinefill;
[maplat, maplon] = gratbounds(mstruct);

%  Convert the input data into degrees.
[maplat, maplon, londelta, limits, exception] = toDegrees( ...
    mstruct.angleunits, maplat, maplon, londelta, limits, exception);

%  Longitude locations for the whole world and then some
%  Will be truncated later.  Use more than the whole world
%  to ensure capturing the data range of the current map.
lonlim = [-360 360];

%  Compute the longitudes at which to draw meridians
if length(londelta) == 1
    lonline = [fliplr(-londelta:-londelta:min(lonlim)), ...
        0:londelta:max(lonlim) ];
else
    lonline = londelta;           %  Vector of points supplied
end

lonline = lonline(lonline >= min(maplon) & lonline <= max(maplon));

%  Compute the latitude fill points for each meridian.
%  Adjust by delta so as to not loose lines at the edge of the map.
latline = linspace(max(maplat), min(maplat), fillpts);

%  Use meshgrid to fill in the points on each graticule line. The
%  insertion of NaN provides a break between the end of one meridian and
%  the beginning of the next.
[lonline,latline] = meshgrid(lonline, [latline NaN]);

%  Keep NaN positions consistent
lonline(isnan(latline)) = NaN;

%  Convert to vectors
lonline = lonline(:);
latline = latline(:);

%  "Process any grids which are restricted from the entire map display"
if ~isempty(limits)
    indxlow = find(latline < min(limits));
    indxup  = find(latline > max(limits));

    if ~isempty([indxlow; indxup])
        %  Exceptions to the limit process
        epsilon = 100*epsm('degrees');
        for i = 1:length(exception)
            exceptindx ...
                = (abs(lonline(indxlow) - exception(i)) <= 10*epsilon);
            indxlow(exceptindx) = [];
            exceptindx ...
                = (abs(lonline(indxup) - exception(i)) <= 10*epsilon);
            indxup(exceptindx) = [];
        end
    end

    latline(indxlow) = min(limits);
    latline(indxup)  = max(limits);
end

[latout, lonout] = fromDegrees(mstruct.angleunits, latline, lonline);
