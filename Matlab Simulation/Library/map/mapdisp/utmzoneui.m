function zoneString = utmzoneui(initialZoneString)
%UTMZONEUI Choose or identify UTM zone by clicking on map
%
%   ZONE = UTMZONEUI will create an interface for choosing a UTM zone on
%   a world map. It allows for clicking on an area for its appropriate
%   zone, or entering a valid zone to identify the zone on the map.
%
%   ZONE = UTMZONEUI(INITZONE) initializes the displayed zone to the zone
%   character vector or scalar string given in INITZONE.
%
%   See also UTMZONE

% Copyright 1996-2020 The MathWorks, Inc.

if nargin == 0
    initialZoneString = '';
else
    initialZoneString = validateInitialZoneString(initialZoneString);
end

gui = layoutInterface();
setUpdateCallbacks(gui)
gui = initializeInterface(gui, initialZoneString);
zoneString = mainLoop(gui);

%----------------------------- Validate Input -----------------------------

function initialZoneString = validateInitialZoneString(initialZoneString)

try
    validateattributes(initialZoneString,{'char','string'},{'scalartext'},'','INITZONE')
    utmzone(initialZoneString);
    initialZoneString = upper(initialZoneString);
catch exception
    throwAsCaller(exception)
end

%--------------------- Construction & Initialization ----------------------

function gui = layoutInterface()
% Returns a struct with fields:
%
%    Figure
%    MapAxes
%    ZoneEditBox
%    AcceptButton
%    CancelButton
%
% The value of each field is a scalar handle to an object that remains
% present through the lifecyle of the GUI.

gui.Figure = figure('NumberTitle','off', 'Name','Pick UTM Zone', ...
    'Units','Points', 'Position',[96 128 894 616], ...
    'Resize','off', 'Visible','off');

% Adjust window position if corners are offscreen
shiftwin(gui.Figure)

colordef(gui.Figure,'white')
figclr = get(gui.Figure,'Color');
frameclr = brighten(figclr,0.5);

gui.MapAxes = constructBaseMap(gui.Figure);

uicontrol(gui.Figure, 'Style','frame', ...
    'Units','normalized', 'Position',[0.2 0.02 0.15 0.08], ...
    'FontSize',12, 'FontWeight','bold', ...
    'BackgroundColor',frameclr, 'ForegroundColor','black');

uicontrol(gui.Figure, 'Style','text', 'String','Zone:', ...
    'Units','normalized', 'Position',[0.21 0.03 0.065 0.05], ...
    'FontSize',12, 'FontWeight','bold', ...
    'HorizontalAlignment','left',  ...
    'BackgroundColor',figclr, 'ForegroundColor','black');

gui.ZoneEditBox = uicontrol(gui.Figure, 'Style','edit', ...
    'Units','normalized', 'Position',[0.28 .035 0.06 0.05], ...
    'FontSize',12,    'FontWeight','bold', ...
    'HorizontalAlignment','center', ...
    'BackgroundColor',figclr, 'ForegroundColor','red');

gui.AcceptButton = uicontrol(gui.Figure, 'Style','push', 'String','Accept', ...
    'Units','normalized', 'Position',[0.46 0.02 0.1 0.08], ...
    'ForegroundColor','black', 'BackgroundColor',figclr, ...
    'FontName','Helvetica', 'FontSize',12, ...
    'FontWeight','bold', 'Callback',@(~,~) uiresume);

uicontrol(gui.Figure, 'Style','push', 'String','Help', ...
    'Units','normalized', 'Position',[0.58 0.02 0.1 0.08], ...
    'ForegroundColor','black', 'BackgroundColor',figclr, ...
    'FontName','Helvetica', 'FontSize',12, ...
    'FontWeight','bold',  'Interruptible','on', ...
    'Callback', @(~,~) doc('utmzoneui'));

gui.CancelButton = uicontrol(gui.Figure, 'Style','push', 'String','Cancel', ...
    'Units','normalized', 'Position',[0.7 0.02 0.1 0.08], ...
    'ForegroundColor','black', 'BackgroundColor',figclr, ...
    'FontName','Helvetica', 'FontSize',12, ...
    'FontWeight','bold', 'Callback',@(~,~) uiresume);

set(gui.Figure,'Visible','on')

%--------------------------------------------------------------------------

function setUpdateCallbacks(gui)
% Users update the state by editing the zone string in the zone edit box
% or by clicking on the map.

gui.ZoneEditBox.Callback = @(~,~) zoneEditCallback(gui);
gui.MapAxes.ButtonDownFcn = @(~,~) zoneClickCallback(gui);
mapAxesChildren = get(gui.MapAxes,'Children');
set(mapAxesChildren,'ButtonDownFcn',@(~,~) zoneClickCallback(gui))

%--------------------------------------------------------------------------

function gui = initializeInterface(gui, initialZoneString)

gui.InitialZoneString = initialZoneString;
updateZone(gui, initialZoneString)

%---------------------------- Main Loop -----------------------------------

function zoneString = mainLoop(gui)

while true
    uiwait(gui.Figure);
    
    if ~ishghandle(gui.Figure)
        % User pressed the figure close button
        zoneString = gui.InitialZoneString;
        break
    end

    currentObject = get(gui.Figure,'CurrentObject');
    if currentObject == gui.CancelButton
        zoneString = gui.InitialZoneString;
        delete(gui.Figure)
        break
    elseif currentObject == gui.AcceptButton
        zoneString = getZoneString(gui);
        delete(gui.Figure)
        break
    end
end

%------------------------- Update Callbacks -------------------------------

function zoneString = zoneClickCallback(gui)

try
    zoneString = selectedZone(gui);
    updateZone(gui,zoneString)
catch e
    zoneString = '';
    uiwait(errordlg(e.message,'Invalid Zone','modal'))
end

%--------------------------------------------------------------------------

function zoneString = selectedZone(gui)

ax = gui.MapAxes;    
selectedPoint = gcpmap(ax);
lat = selectedPoint(1,1);
lon = selectedPoint(1,2);
zoneString = utmzone(lat,lon);
currentXYZ = get(ax,'CurrentPoint');
x = currentXYZ(1,1);
if x > pi || x < -pi
    e = MException('map:utmzone:outsideUTMLimits', ...
        'Coordinates not within UTM zone limits.');
    throw(e)
end

%--------------------------------------------------------------------------

function zoneEditCallback(gui)

try
    zoneStringWithUserEdits = gui.ZoneEditBox.String;
    utmzone(zoneStringWithUserEdits);
    updateZone(gui, zoneStringWithUserEdits)
catch e
    uiwait(errordlg(e.message,'Invalid Zone','modal'))
    restoreZoneEditBox(gui)
end

%------------------ Respond to Change in Current Zone ---------------------

function updateZone(gui, zoneString)
setZoneString(gui, zoneString)
updateZoneDisplay(gui)

%--------------- Restore Zone Edit Box to Its Previous Value --------------

function restoreZoneEditBox(gui)
gui.ZoneEditBox.String = getZoneString(gui);

%--------------------- Set/Get Current Zone String ------------------------

function setZoneString(gui, zoneString)
gui.ZoneEditBox.String = zoneString;
setappdata(gui.ZoneEditBox,'ZoneString',zoneString)

%--------------------------------------------------------------------------

function zoneString = getZoneString(gui)
zoneString = getappdata(gui.ZoneEditBox,'ZoneString');

%------------------ Indicate Current Zone via Map Display -----------------

function updateZoneDisplay(gui)
currentZoneFill = getZoneFill(gui);
if ~isempty(currentZoneFill)
    delete(currentZoneFill)
end
zoneString = getZoneString(gui);
hZoneFill = fillZoneQuadrangle(gui.MapAxes, zoneString);
setZoneFill(gui, hZoneFill)

%--------------------------------------------------------------------------

function setZoneFill(gui, hZoneFill)
setappdata(gui.Figure,'ZoneFill',hZoneFill)

%--------------------------------------------------------------------------

function hZoneFill = getZoneFill(gui)
hZoneFill = getappdata(gui.Figure,'ZoneFill');

%----------------------------- Map Display --------------------------------

function ax = constructBaseMap(figureHandle) %#ok<INUSD>
% We'd like to tell axesm which figure to use, but that's not yet possible.
% For now we have to just let it use the current figure and ignore the
% input figure handle.

%  Display map of world with utm zone designations
lts = [-80:8:72 84]';
lns = (-180:6:180)';

ax = axesm('miller','maplatlim',[-80 84],'maplonlim',[-180 180],...
    'mlinelocation',lns,'plinelocation',lts,...
    'mlabellocation',-180:24:180,'plabellocation',lts, ...
    'Frame','on','Grid','on','MeridianLabel','on','ParallelLabel','on');

set(ax,'Position',[.02 .12 .96 .87],'XLim',[-3.5 3.3],'YLim',[-2 2.2])

% Disable interactions and AxesToolbar
if ~isempty(ax.Toolbar)
    ax.Toolbar.Visible = 'off';
end
disableDefaultInteractivity(ax);

coast = load('coastlines.mat');
geoshow(ax,coast.coastlat,coast.coastlon,'Color','k');

%--------------------------------------------------------------------------

function hZoneFill = fillZoneQuadrangle(ax, zoneString)

if isempty(zoneString)
    hZoneFill = gobjects(0);
else
    [latlim, lonlim] = utmzone(zoneString);
    lat = latlim([1 2 2 1 1]);
    lon = lonlim([1 1 2 2 1]);
    [x,y] = map.crs.internal.mfwdtran(getm(ax),lat,lon);
    hZoneFill = patch('XData',x,'YData',y,'FaceColor',[1 .2 .2],'Tag','Fill');
end
