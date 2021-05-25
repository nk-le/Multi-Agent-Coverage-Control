function scirclui(ax)
%SCIRCLUI  Interactive tool for adding small circles to a map
%
%   SCIRCLUI activates the interactive tool and associates it with the
%   current axes. The current axes must be a map axes.
%
%   SCIRCLUI(AX) activates the interactive tool and associates it with
%   the axes specified by the map axes with handle AX.
%
%   See also SCIRCLEG, TRACKG

% Copyright 1996-2016 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

if nargin == 0
    ax = gca;
end

% Validate map axes
gcm(ax);

 %  Construct the gui
scircluiBox(ax) 

%--------------------------------------------------------------------------

function close_cb(uiFigure,~)
%  Close Request Function

h = get(uiFigure,'UserData');
delete(h.figure)

% Return to call fig if it exists
if ishghandle(h.mapaxes)
    figure(get(h.mapaxes,'Parent'));
end

%--------------------------------------------------------------------------

function select_cb(uiFigure)
%  Callback associated with the Mouse Select button

h = get(uiFigure,'UserData');
if ~ishghandle(h.mapaxes)     %  Abort tool if axes is gone
    uiwait(errordlg({'Associated Map Axes has been deleted',' ',...
        'Circle Tool No Longer Appropriate'},...
        'Circle Tool Error','modal'));
    close_cb(uiFigure)
    return
end
btn = get(h.figure,'CurrentObject');
editboxes = get(btn,'UserData');      %  Get associated edit boxes

%  Get a point from the map and convert it to degrees.
[lat,lon] = inputm(1,h.mapaxes);
mstruct = gcm(h.mapaxes);
datapoint = toDegrees(mstruct.angleunits,[lat lon]);

set(editboxes(1),'String',num2str(datapoint(1),'%6.2f'))  %  Update
set(editboxes(2),'String',num2str(datapoint(2),'%6.2f'))  %  display
figure(h.figure)

%--------------------------------------------------------------------------

function circlestyle_cb(hSrc,~)

% Toggle UserData values between 0 and 1 for a pair of linked uicontrols
set(hSrc,'Value',1)
t = get(hSrc,'UserData');
set(t,'Value',0)

%--------------------------------------------------------------------------

function onepoint_cb(uiFigure)
%  Callback for the one point mode radio button

h = get(uiFigure,'UserData');

%  Make mode radio buttons mutually exclusive

set(h.onept,'Value',1);
set(h.twopt,'Value',0)

%  Set the strings and callbacks to correspond to one point mode

set(h.endORdirtitle,'String','Size and Sector:')
set(h.latORrnglabel,'String','Rad', ...
    'CallBack',@(hsrc,~) expandedEdit(hsrc,'Radius'))
set(h.lonORazlabel,'String','Az', ...
    'CallBack',@(hsrc,~) expandedEdit(hsrc,'Azimuth'))
set(h.endselect,'String','Radius Units', ...
    'CallBack',@(~,~) rangeunits_cb(uiFigure))
set([h.latORrng; h.lonORaz],'String','')
rangestring(h)    %  Update the unit string

% Set help to correspond to one point mode

set(h.endORdirtitle, 'TooltipString', tooltipHelpStrings('CircleDefinition'))
set(h.endselect,     'TooltipString', tooltipHelpStrings('RangeUnits'))

%--------------------------------------------------------------------------

function twopoint_cb(uiFigure)
%  Callback for the two point mode radio button

h = get(uiFigure,'UserData');

%  Make mode radio buttons mutually exclusive

set(h.onept,'Value',0);
set(h.twopt,'Value',1)

%  Set the strings and callbacks to correspond to two point mode

set(h.endORdirtitle,'String','Circle Point:')
set(h.latORrnglabel,'String','Lat', ...
    'CallBack',@(hsrc,~) expandedEdit(hsrc,'Circle Latitude'))
set(h.lonORazlabel,'String','Lon', ...
    'CallBack',@(hsrc,~) expandedEdit(hsrc,'Circle Longitude'))
set(h.endselect,'String','Mouse Select', ...
    'CallBack',@(~,~) select_cb(uiFigure))
set([h.latORrng; h.lonORaz],'String','')
set(h.anglabel,'String','Angles in degrees')

% Set help to correspond to two point mode

set(h.endORdirtitle, 'TooltipString', tooltipHelpStrings('CirclePoint'))
set(h.endselect,     'TooltipString', tooltipHelpStrings('MouseSelect'))

%--------------------------------------------------------------------------

function apply_cb(uiFigure)
%  Apply the currently defined small circle to the map

h = get(uiFigure,'UserData');

%  Close tool if axes is gone.
if ~ishghandle(h.mapaxes)
    uiwait(errordlg({'Associated Map Axes has been deleted',' ',...
        'Circle Tool No Longer Appropriate'},...
        'Circle Tool Error','modal'));
    close_cb(uiFigure)
    return
end

mapstruct = getMapstruct(h.mapaxes);    %  Associated map structure

if get(h.gc,'Value')
    trackstr = 'gc';   %  Define circle type
    tagstr   = 'Small Circle';
else
    trackstr = 'rh';
    tagstr   = 'Rhumb Line Small Circle';
end

%  Get the edit box entries.  If the entries are required, abort if empty

startlat = get(h.stlatedit,'String');
startlon = get(h.stlonedit,'String');
if isempty(startlat) || isempty(startlon)
    uiwait(errordlg('Center Latitude and Longitude Required',...
        'Small Circle Error','modal'));
    return
end

latORrng  = get(h.latORrng,'String');            %  Empty entries are allowed
if isempty(latORrng)
    latORrng = '[]';
end

lonORaz = get(h.lonORaz,'String');
if isempty(lonORaz)
    lonORaz = '[]';
end

zplane = get(h.altedit,'String');      %  Plotting altitude
znumber = str2double(zplane);
if isempty(zplane)
    znumber = 0;
elseif isempty(znumber)
    uiwait(errordlg('Invalid Z Plane',...
        'Small Circle Error','modal'))
    return
end

otherprop = get(h.propedit,'String');    %  Other line property string

%  Make a potentially multi-line strings into a single row vector.
%  Eliminate any padding 0s since they mess up a string

startlat = startlat(:)';
startlat(startlat == 0) = [];

startlon = startlon(:)';
startlon(startlon == 0) = [];

latORrng = latORrng(:)';
latORrng(latORrng == 0) = [];

lonORaz = lonORaz(:)';
lonORaz(lonORaz == 0) = [];

otherprop = otherprop(:)';
otherprop(otherprop == 0) = [];

% Convert to cell string form
otherprop = eval(['{',otherprop,'}']);

%  Reset the last error function and set the axes pointer to the
%  associated map axes.  This setting process directs the plot
%  commands to the proper axes without activating the axes figure window.

set(0,'CurrentFigure',get(h.mapaxes,'Parent'));
set(get(h.mapaxes,'Parent'),'CurrentAxes',h.mapaxes)

if get(h.twopt,'Value')   %  Two point track definition
    try
        [lat,lon] = scircle2(trackstr, ...
            str2double(startlat),str2double(startlon),...
            str2double(latORrng), str2double(lonORaz),...
            mapstruct.geoid,'degrees');
    catch e
        uiwait(errordlg(e.message,'Small Circle Error','modal'))
        return
    end
    
else
    %  One point track definition.  Requires processing of
    %  the range data based on range units and geoid definition
    
    %  Determine the geoid/radius to use as the normalizing radius for
    %  the range entries.
    
    if strcmp(h.unitstring,'Radians')
        normalize = 1;
    else
        try
            normalize = eval(h.geoidstr);
        catch e
            uiwait(errordlg(e.message,'Small Circle Error','modal'))
            return
        end
    end
    
    %  Compute the normalizing factor.  The range needs to be normalized
    %  to radians and then scaled by the appropriate radius as defined by
    %  the current map geoid.
    %
    %   range = range/(normalize radius) * (geoid radius)
    %
    %  The geoid radius multiplies the expression above because the
    %  track1 routine (actually reckon) will divide the range entry
    %  by (geoid radius) since [0 0] is not used as the input geoid in track1
    
    %  When a rhumb line is requested, the radius of the rectifying sphere must be
    %  used, since reckon is aware of the rectifying sphere.  For the great
    %  circles, only the radius (or semimajor axis) is used because this
    %  is the factor used in reckon/reckongc.  Great circle reckoning is
    %  not aware of ellipsoids.  If that ever changes, be sure to
    %  adjust the radfact construction below.
    
    if get(h.gc,'Value')
        radfact = mapstruct.geoid(1)/normalize(1);
    else
        radius = rsphere('rectifying',mapstruct.geoid);
        normalize = rsphere('rectifying',normalize);
        radfact = radius/normalize;
    end
    
    %  Construct the range string.  Account for unit changes if necessary.
    
    unitstr = h.unitstring;
    unitstr(unitstr==' ') = [];
    if strcmp(unitstr,'Radians')
        dist = str2double(latORrng);
    else
        dist = str2double(latORrng) * unitsratio('kilometers',unitstr);        
    end
    
    try
        [lat,lon] = scircle1(trackstr, ...
            str2double(startlat), str2double(startlon), ...
            dist*radfact, str2double(lonORaz), mapstruct.geoid, 'degrees');
    catch e
        uiwait(errordlg(e.message,'Small Circle Error','modal'))
        return
    end
end

%  If no errors, then the scircle1 or scircle2 command successfully
%  completed.  Now display the small circle(s).

[lat,lon] = fromDegrees(mapstruct.angleunits,lat,lon);

try
    linem(lat,lon,znumber,otherprop{:},'Tag',tagstr)
catch e
    uiwait(errordlg(e.message,'Small Circle Error','modal'))
end

set(0,'CurrentFigure',h.figure);

%--------------------------------------------------------------------------

function rangeunits_cb(uiFigure)
%  Callback for the range units button

h = get(uiFigure,'UserData');

if ~ishghandle(h.mapaxes)     %  Close tool if axes is gone.
    uiwait(errordlg({'Associated Map Axes has been deleted',' ',...
        'Circle Tool No Longer Appropriate'},...
        'Circle Tool Error','modal'));
    close_cb(uiFigure)
    return
end

mapstruct = getMapstruct(h.mapaxes);
hmodal = lengthUnitDialog(h.unitstring,h.geoidstr,mapstruct.geoid);
uiwait(hmodal.figure)         %  Wait until closed

if ~ishghandle(hmodal.figure)
    return
end

btn      = get(hmodal.figure,'CurrentObject');   %  Get needed info
indx     = get(hmodal.poprng,'Value');           %  before deleting
units    = get(hmodal.poprng,'String');          %  dialog
geoidstr = get(hmodal.geoidedit,'String');

delete(hmodal.figure)

if btn == hmodal.apply    %  Apply button pushed.  Update units definition
    h.unitstring = units{indx};
    h.geoidstr = geoidstr;
    set(h.figure,'UserData',h)
    rangestring(h)       %  Update units string display
end

%--------------------------------------------------------------------------

function rangestring(h)

% h is a scalar structure containing handles to the UI objects

%  Update the range string display
switch h.unitstring
    case 'Kilometers'
        set(h.anglabel,'String','Angles in degrees;  Range in kilometers')
    case 'Statute Miles'
        set(h.anglabel,'String','Angles in degrees;  Range in statute miles')
    case 'Nautical Miles'
        set(h.anglabel,'String','Angles in degrees;  Range in nautical miles')
    case 'Radians'
        set(h.anglabel,'String','Angles in degrees;  Range in radians')
    otherwise
        error(['map:' mfilename ':mapdispError'], ...
            'Unrecognized range unit string')
end

%--------------------------------------------------------------------------

function scircluiBox(axeshandle)
% SCIRCLUIBOX constructs the scirclui GUI

h.mapaxes = axeshandle;              %  Save associated map axes handle
h.unitstring = 'Kilometers';         %  Initialize range units string
h.geoidstr = 'earthRadius(''kilometers'')';    %  and normalizing geoid definition

h.figure =  figure('Units','points',  'Position',[40 80 280 350], ...
	'NumberTitle','off', 'Name','Define Small Circles','MenuBar','none', ...
	'CloseRequestFcn',@close_cb,'Resize','off',  'Visible','off');
colordef(h.figure,'white');
figclr = get(h.figure,'Color');
frameclr = brighten(figclr,0.5);

% shift window if it comes up partly offscreen

shiftwin(h.figure)

%  Mode and style frame

h.modeframe = uicontrol(h.figure, 'Style','frame', ...
	'Units','points',  'Position',[10 270 260 70], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black');

%  Style title and radio buttons

h.styletext = uicontrol(h.figure, 'Style','text', 'String', 'Style:', ...
	'Units','points',  'Position',[15 315 45 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.gc = uicontrol(h.figure, 'Style','radio', 'String', 'Great Circle', ...
	'Units','points',  'Position',[70 318 90 15], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Value', 1, ...
	'FontSize',10,  'FontWeight', 'bold', 'HorizontalAlignment','left', ...
    'CallBack', @circlestyle_cb);

h.rh = uicontrol(h.figure, 'Style','radio', 'String', 'Rhumb Line', ...
	'Units','points',  'Position',[170 318 90 15], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Value', 0, ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left', ...
    'CallBack', @circlestyle_cb);

set(h.gc,'UserData',h.rh)     %  Set userdata for callback operation
set(h.rh,'UserData',h.gc)

%  Mode title and radio buttons

h.modetext = uicontrol(h.figure, 'Style','text', 'String', 'Mode:', ...
	'Units','points',  'Position',[15 295 45 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.onept = uicontrol(h.figure, 'Style','radio', 'String', '1 Point', ...
	'Units','points',  'Position',[70 298 90 15], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left', ...
	'Value', 0, 'CallBack',@(~,~) onepoint_cb(h.figure));

h.twopt = uicontrol(h.figure, 'Style','radio', 'String', '2 Point', ...
	'Units','points',  'Position',[170 298 90 15], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left', ...
	'Value', 1, 'CallBack',@(~,~) twopoint_cb(h.figure));

%  Angle Units label and text

h.anglabel = uicontrol(h.figure, 'Style','text', ...
    'String', 'All Angles are in Degrees', ...
	'Units','points',  'Position',[15 275 253 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Starting point frame and title

h.stframe = uicontrol(h.figure, 'Style','frame', ...
	'Units','points',  'Position',[10 205 260 60], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black');

h.sttitle = uicontrol(h.figure, 'Style','text', 'String', 'Center Point:', ...
	'Units','points',  'Position',[15 240 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Starting latitude text and edit box

h.stlatlabel = uicontrol(h.figure, 'Style','push', 'String', 'Lat', ...
	'Units','points',  'Position',[15 215 30 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left', ...
	'Interruptible','on',...
	'CallBack',@(hsrc,~) expandedEdit(hsrc,'Center Latitude'));

h.stlatedit = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[50 215 85 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max', 2, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Starting longitude text and edit box

h.stlonlabel = uicontrol(h.figure, 'Style','push', 'String', 'Lon', ...
	'Units','points',  'Position',[145 215 30 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left', ...
	'Interruptible','on',...
	'CallBack',@(hsrc,~) expandedEdit(hsrc,'Center Longitude'));

h.stlonedit = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[180 215 85 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max', 2, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Starting point select button

h.stselect = uicontrol(h.figure, 'Style','push', 'String', 'Mouse Select', ...
	'Units','points',  'Position',[165 240 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
	'UserData',[h.stlatedit h.stlonedit], 'Callback', @(~,~) select_cb(h.figure));

%  Ending point frame and title

h.endframe = uicontrol(h.figure, 'Style','frame', ...
	'Units','points',  'Position',[10 140 260 60], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black');

h.endORdirtitle = uicontrol(h.figure, 'Style','text', 'String', '', ...
	'Units','points',  'Position',[15 175 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Ending latitude text and edit box

h.latORrnglabel = uicontrol(h.figure, 'Style','push', 'String', '', ...
	'Units','points',  'Position',[15 150 30 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left', ...
	'Interruptible','on');

h.latORrng = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[50 150 85 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max', 2, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Ending longitude text and edit box

h.lonORazlabel = uicontrol(h.figure, 'Style','push', 'String', '', ...
	'Units','points',  'Position',[145 150 30 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left', ...
	'Interruptible','on');

h.lonORaz = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[180 150 85 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max', 2, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Ending point select button

h.endselect = uicontrol(h.figure, 'Style','push', 'String', 'Mouse Select', ...
	'Units','points',  'Position',[165 175 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
	'UserData',[h.latORrng h.lonORaz],  'Callback', @(~,~) select_cb(h.figure));

%  Other properties frame

h.endframe = uicontrol(h.figure, 'Style','frame', ...
	'Units','points',  'Position',[10 45 260 90], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black');

%  Altitude label and edit

h.altlabel = uicontrol(h.figure, 'Style','text', 'String', 'Z Plane:', ...
	'Units','points',  'Position',[15 110 60 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.altedit = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[80 110 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max',1, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Other Property label and edit

h.proplabel = uicontrol(h.figure, 'Style','text', 'String', 'Other Properties:', ...
	'Units','points',  'Position',[15 85 125 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.propedit = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[15 50 250 33], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max',2, ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Apply, help and cancel buttons

h.cancel = uicontrol(h.figure, 'Style','push', 'String', 'Close', ...
	'Units','points',  'Position',[23 8 65 30], ...
	'BackgroundColor',figclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
	'Callback',@(~,~) close_cb(h.figure));

h.help = uicontrol(h.figure, 'Style','push', 'String', 'Help', ...
	'Units','points',  'Position',[108 8 65 30], ...
	'BackgroundColor',figclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
    'Callback', @(~,~) doc('scirclui'));

h.apply = uicontrol(h.figure, 'Style','push', 'String', 'Apply', ...
	'Units','points',  'Position',[193 8 65 30], ...
	'BackgroundColor',figclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
	'Callback', @(~,~) apply_cb(h.figure));

%  Save handle links for Expanded Edit calls

set(h.stlatlabel,'UserData',h.stlatedit)
set(h.stlonlabel,'UserData',h.stlonedit)
set(h.latORrnglabel,'UserData',h.latORrng)
set(h.lonORazlabel,'UserData',h.lonORaz)

% Set TooltipString values to provide help for certain UI elements.

set(h.styletext, 'TooltipString', tooltipHelpStrings('CircleStyle'))
set(h.modetext,  'TooltipString', tooltipHelpStrings('CircleMode'))
set(h.anglabel,  'TooltipString', tooltipHelpStrings('AngleLabel'))

set(h.sttitle,  'TooltipString', tooltipHelpStrings('CircleCenter'))
set(h.stselect, 'TooltipString', tooltipHelpStrings('MouseSelect'))

set(h.stlatlabel,    'TooltipString', tooltipHelpStrings('BigEdit'))
set(h.stlonlabel,    'TooltipString', tooltipHelpStrings('BigEdit'))
set(h.latORrnglabel, 'TooltipString', tooltipHelpStrings('BigEdit'))
set(h.lonORazlabel,  'TooltipString', tooltipHelpStrings('BigEdit'))

set(h.endORdirtitle, 'TooltipString', tooltipHelpStrings('CircleDefinition'))
set(h.endselect,     'TooltipString', tooltipHelpStrings('RadiusUnits'))

set(h.altlabel,  'TooltipString', tooltipHelpStrings('ScalarAltitude'))
set(h.proplabel, 'TooltipString', tooltipHelpStrings('OtherProperties'))

set(h.cancel,    'TooltipString', tooltipHelpStrings('Close'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.help,      'TooltipString', tooltipHelpStrings('scircluiHelp'))

%  Save object handles and make figure visible
set(h.figure,'Visible','on','UserData',h)

%  Initialize for one point operation.
onepoint_cb(h.figure)          
    
set(gcf,'HandleVisibility','Callback')

%--------------------------------------------------------------------------

function mapstruct = getMapstruct(h)
% Obtain MAPSTRUCT from handle H.

mapstruct = get(h,'UserData');  %  Associated map structure

% If the UserData 'geoid' field contains a spheroid object, convert it
% to an ellipsoid vector.
if ~isempty(mapstruct) && isfield(mapstruct, 'geoid')
    spheroid = mapstruct.geoid;
    if isobject(spheroid)
        mapstruct.geoid = [spheroid.SemimajorAxis spheroid.Eccentricity];
    end
end
