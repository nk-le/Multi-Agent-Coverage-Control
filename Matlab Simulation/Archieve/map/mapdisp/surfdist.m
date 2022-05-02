function surfdist(ax)
%SURFDIST Interactive distance, azimuth and reckoning calculations
%
%  SURFDIST activates an interactive tool.  If the current axes have a
%  proper map definition, then the tool will be associated with the axes.
%  Otherwise, the tool will not be associated with any axes.
%
%  SURFDIST(AX) activates the interactive tool and associates it with the
%  axes specified by AX. The axes specified by AX must be a map axes.
%
%  SURFDIST([]) activates the tool and does not associate it with any
%  axes, regardless of whether the current axes has a valid map definition.
%
%  See also TRACKG

% Copyright 1996-2016 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Parse the inputs

if nargin == 0
    if ~isempty(get(0,'CurrentFigure')) && ...
	   ~isempty(get(get(0,'CurrentFigure'),'CurrentAxes')) && ...
	    ismap(get(get(0,'CurrentFigure'),'CurrentAxes'))
          ax = gca;
	else
        ax = [];
    end
end

if ~isempty(ax)
    % Validate map axes
    gcm(ax);
end

%  Construct the GUI
surfdistBox(ax)

%--------------------------------------------------------------------------

function close_cb(uiFigure,~)

% Get structure containing handles to the UI objects
h = getSurfaceDistanceStructure(uiFigure);

%  Close Request Function;  Return to call fig if it exists
delete(h.figure)
if ishghandle(h.mapaxes)
    figure(get(h.mapaxes,'Parent'))   %% WHY THIS?
    if isfield(h,'trackline')
        if ishghandle(h.trackline)
            f = get(get(h.trackline,'Parent'),'Parent');  %% Use ANCESTOR
            delete(h.trackline);
            refresh(f)
        end
    end
end

%--------------------------------------------------------------------------

function select_cb(uiFigure)

% Get structure containing handles to the UI objects
h = getSurfaceDistanceStructure(uiFigure);

%  Callback associated with the Mouse Select button
if ~ishghandle(h.mapaxes)     %  Abort tool if axes is gone
    uiwait(errordlg({'Associated Map Axes has been deleted',' ',...
        'Distance Tool No Longer Appropriate'},...
        'Distance Tool Error','modal'));
    trackui('close');
    return
end
btn = get(h.figure,'CurrentObject');
editboxes = get(btn,'UserData');

% Get a point from the map and convert it to degrees.
[lat,lon] = inputm(1,h.mapaxes);
mstruct = gcm(h.mapaxes);
datapoint = toDegrees(mstruct.angleunits,[lat lon]);

set(editboxes(1),'String',num2str(datapoint(1),'%6.2f'))  %  Update
set(editboxes(2),'String',num2str(datapoint(2),'%6.2f'))  %  display
set([h.rngedit;h.azedit],'String','')
figure(h.figure)

%--------------------------------------------------------------------------

function trackstyle_cb(hSrc,uiFigure)

% Toggle UserData values between 0 and 1 for a pair of linked uicontrols
set(hSrc,'Value',1)
t = get(hSrc,'UserData');
set(t,'Value',0)

% Get structure containing handles to the UI objects
h = getSurfaceDistanceStructure(uiFigure);

%  Callback for the style radio buttons
if get(h.twopt,'Value')
    if ~(isempty(get(h.stlatedit,'String')) && ...
            isempty(get(h.stlonedit,'String')) && ...
            isempty(get(h.endlatedit,'String')) && ...
            isempty(get(h.endlonedit,'String')))
        twopointcalc(uiFigure)
    end
else
    if ~(isempty(get(h.stlatedit,'String')) && ...
            isempty(get(h.stlonedit,'String')) && ...
            isempty(get(h.azedit,'String')) && ...
            isempty(get(h.rngedit,'String')))
        onepointcalc(uiFigure)
    end
end

%--------------------------------------------------------------------------

function onepoint_cb(uiFigure)

% Get structure containing handles to the UI objects
h = getSurfaceDistanceStructure(uiFigure);

%  Callback for the one point mode radio button
%  Make mode radio buttons mutually exclusive
set(h.onept,'Value',1);
set(h.twopt,'Value',0)

%  Set the strings and callbacks to correspond to one point mode
set([h.endlatedit; h.endlonedit],'Style','text')
set([h.azedit; h.rngedit],'Style','edit')
set(h.endselect,'Enable','off')
set(h.apply,'Callback',@(~,~) onepointcalc(uiFigure))

%--------------------------------------------------------------------------

function twopoint_cb(uiFigure)

% Get structure containing handles to the UI objects
h = getSurfaceDistanceStructure(uiFigure);

%  Callback for the two point mode radio button
%  Make mode radio buttons mutually exclusive
set(h.onept,'Value',0);
set(h.twopt,'Value',1)

%  Set the strings and callbacks to correspond to two point mode
set([h.endlatedit; h.endlonedit],'Style','edit')
set([h.azedit; h.rngedit],'Style','text')
if ~isempty(h.mapaxes)
    set(h.endselect,'Enable','on')
end
set(h.apply,'Callback',@(~,~) twopointcalc(uiFigure))

%--------------------------------------------------------------------------

function twopointcalc(uiFigure)

% Get structure containing handles to the UI objects
h = getSurfaceDistanceStructure(uiFigure);

%  Compute distance and azimuth
commastr  = ',';                        %  Useful string needed later
if get(h.gc,'Value')
    trackstr = '''gc''';   %  Define measurement type
else
    trackstr = '''rh''';
end

%  Get the edit box entries.  If the entries are required, abort if empty
startlat = get(h.stlatedit,'String');
startlon = get(h.stlonedit,'String');
if isempty(startlat) || isempty(startlon)
    uiwait(errordlg('Starting Latitude and Longitude Required',...
        'Surface Distance Error','modal'));  return
end

endlat = get(h.endlatedit,'String');
endlon = get(h.endlonedit,'String');
if isempty(endlat) || isempty(endlon)
    uiwait(errordlg('Ending Latitude and Longitude Required',...
        'Surface Distance Error','modal'));  return
end

%  Make a potentially multi-line strings into a single row vector.
%  Eliminate any padding 0s since they mess up a string
startlat = startlat(:)';
startlat(startlat == 0) = [];

startlon = startlon(:)';
startlon(startlon == 0) = [];

endlat = endlat(:)';
endlat(endlat == 0) = [];

endlon = endlon(:)';
endlon(endlon == 0) = [];

%  Reset the last error function and evaluate the function calls
rngv = [];
evalstr = ['rngv = distance(',trackstr,commastr,startlat,commastr,...
    startlon,commastr,endlat,commastr,endlon,commastr,...
    '[',num2str(h.basegeoid),']',commastr,'''degrees'');'];
try
    eval(evalstr);
catch e
    uiwait(errordlg(e.message,'Surface Distance Error','modal'))
    return;
end

az = [];
evalstr = ['az = azimuth(',trackstr,commastr,startlat,commastr,...
    startlon,commastr,endlat,commastr,endlon,commastr,...
    '[',num2str(h.basegeoid),']',commastr,'''degrees'');'];
try
    eval(evalstr);
catch e
    uiwait(errordlg(e.message,'Surface Distance Error','modal'))
    return;
end

%  Determine the geoid/radius to use as the normalizing radius for
%  the range entries.
if strcmp(h.unitstring,'Radians')
    normalize = 1;
else
    normalize = [];
    eval(['normalize = ',h.geoidstr,';'])
end

%  Compute the range in the proper units
if get(h.gc,'Value')
    if ~strcmp(h.unitstring,'Radians')
        diststr = h.unitstring;
        diststr(diststr==' ') = [];
        normalize = km2dist(normalize(1),diststr);
    end
    rngv = rngv*normalize/h.basegeoid(1);
else
    radius = rsphere('rectifying',h.basegeoid);
    normalize = rsphere('rectifying',normalize);
    if ~strcmp(h.unitstring,'Radians')
        diststr = h.unitstring;
        diststr(diststr==' ') = [];
        normalize = km2dist(normalize(1),diststr);
    end
    
    rngv = rngv*normalize/radius;
end

set(h.rngedit,'String',num2str(rngv,'%6.1f'))
set(h.azedit,'String',num2str(az,'%6.1f'))

%  Display the track if requested.

if isfield(h,'trackline') && ~isempty(h.trackline) && ishghandle(h.trackline)
    delete(h.trackline)
end

if ismap(h.mapaxes) && get(h.showtrack,'Value')
    trackstr([1 length(trackstr)]) = [];
    [lat,lon] = track2(trackstr,eval(startlat),eval(startlon),...
        eval(endlat),eval(endlon),h.basegeoid,'degrees',40);
    h.trackline = linem(lat,lon,max(get(h.mapaxes,'Zlim')),'r','Parent',h.mapaxes);
    set(h.figure,'UserData',h)
end

%--------------------------------------------------------------------------

function onepointcalc(uiFigure)

% Get structure containing handles to the UI objects
h = getSurfaceDistanceStructure(uiFigure);

%  Compute reckoning measurements
commastr  = ',';                        %  Useful string needed later

if get(h.gc,'Value')
    trackstr = '''gc''';   %  Define measurement type
else
    trackstr = '''rh''';
end

%  Get the edit box entries.  If the entries are required, abort if empty

startlat = get(h.stlatedit,'String');
startlon = get(h.stlonedit,'String');
if isempty(startlat) || isempty(startlon)
    uiwait(errordlg('Starting Latitude and Longitude Required',...
        'Surface Distance Error','modal'));  return
end

az = get(h.azedit,'String');
rngv = get(h.rngedit,'String');
if isempty(az) || isempty(rngv)
    uiwait(errordlg('Azimuth and Range Required',...
        'Surface Distance Error','modal'));  return
end

%  Make a potentially multi-line strings into a single row vector.
%  Eliminate any padding 0s since they mess up a string

startlat = startlat(:)';
startlat(startlat == 0) = [];

startlon = startlon(:)';
startlon(startlon == 0) = [];

az = az(:)';
az(az == 0) = [];

rngv = rngv(:)';
rngv(rngv == 0) = [];

%  Determine the geoid/radius to use as the normalizing radius for
%  the range entries.

if strcmp(h.unitstring,'Radians')
    normalize = 1;
else
    normalize = [];
    eval(['normalize = ',h.geoidstr,';'])
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
    radfact = ['*',num2str(h.basegeoid(1)/normalize(1),'%16.12f')];
else
    radius = rsphere('rectifying',h.basegeoid);
    normalize = rsphere('rectifying',normalize);
    radfact = ['*',num2str(radius/normalize,'%16.12f')];
end

%  Construct the range string.  Account for unit changes if necessary.

diststr = h.unitstring;
diststr(diststr==' ') = [];
if strcmp(h.unitstring,'Radians')
    diststr = rngv;
else
    diststr = ['distdim(',rngv,',''',diststr,''',''kilometers'')'];
end

%  Reset the last error function and evaluate the function calls
endlat = [];
endlon = [];
evalstr = ['[endlat,endlon]=reckon(',trackstr,commastr,startlat,commastr,...
    startlon,commastr,diststr,radfact,commastr,az,commastr,...
    '[',num2str(h.basegeoid),'],''degrees'');'];
try
    eval(evalstr);
catch e
    uiwait(errordlg(e.message,'Surface Distance Error','modal'))
    return;
end

set(h.endlatedit,'String',num2str(endlat,'%6.1f'))
set(h.endlonedit,'String',num2str(endlon,'%6.1f'))

%  Display the track if requested.

if isfield(h,'trackline')
    if ishghandle(h.trackline);  delete(h.trackline);  end
end
if ismap(h.mapaxes) && get(h.showtrack,'Value')
    lat = [];
    lon = [];
    evalstr = ['[lat,lon]=track1(',trackstr,commastr,startlat,...
        commastr,startlon,commastr,az,commastr,diststr,radfact,commastr,...
        '[',num2str(h.basegeoid),'],''degrees'');'];
    try
        eval(evalstr);
    catch e
        uiwait(errordlg(e.message,'Surface Distance Error','modal'))
        return;
    end
    h.trackline = linem(lat,lon,max(get(h.mapaxes,'Zlim')),'r','Parent',h.mapaxes);
    set(h.figure,'UserData',h)
end

%--------------------------------------------------------------------------

function rangeunits_cb(uiFigure)
%  Callback for the range units button

% Get structure containing handles to the UI objects
h = getSurfaceDistanceStructure(uiFigure);

%  Display the modal dialog box
hmodal = lengthUnitDialog(h.unitstring,h.geoidstr,h.basegeoid);
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
    oldunits = h.unitstring;
    h.unitstring = units{indx};
    h.geoidstr = geoidstr;
    set(h.figure,'UserData',h)
    %  Update units string display
    rangestring(h)
    if get(h.twopt,'Value')
        twopointcalc(uiFigure)
    else
        rngv = str2double(get(h.rngedit,'String'));
        if ~isnan(rngv)
            % The range has been initialized, so rescale it.
            oldUnitsPerKilometer = km2dist(1,oldunits);
            newUnitsPerKilometer = km2dist(1,h.unitstring);
            rngv = rngv * newUnitsPerKilometer / oldUnitsPerKilometer;
            set(h.rngedit,'String',num2str(rngv,'%6.1f'))
        end
    end
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

function s = getSurfaceDistanceStructure(uiFigure)
% Return scalar structure with information on the UI components and status
% of the surfdist GUI. The structure was constructed by surfdistBox and
% stored in the UserData of the GUI figure.

% If the UserData 'basegeoid' field contains a spheroid object, convert it
% to an ellipsoid vector.
s = get(uiFigure,'UserData');
if ~isempty(s) && isfield(s, 'basegeoid')
    spheroid = s.basegeoid;
    if isobject(spheroid)
        s.basegeoid = [spheroid.SemimajorAxis spheroid.Eccentricity];
    end
end

%--------------------------------------------------------------------------

function surfdistBox(axeshandle)
% SURFDISTBOX constructs the surfdist GUI.

h.mapaxes = axeshandle;              %  Save associated map axes handle
h.unitstring = 'Kilometers';         %  Initialize range units string
h.geoidstr = 'earthRadius(''kilometers'')';    %  and normalizing geoid definition

h.figure = figure('Units','points','Position',[40 80 280 350], ...
	'NumberTitle','off', 'Name','Surface Distance','MenuBar','none', ...
	'CloseRequestFcn',@close_cb,'Resize','off','Visible','off');

colordef(h.figure,'white');
figclr = get(h.figure,'Color');
frameclr = brighten(figclr,0.5);

% shift window if it comes up partly offscreen

shiftwin(h.figure)

%  Mode and style frame

h.modeframe = uicontrol(h.figure, 'Style','frame', ...
	'Units','points',  'Position',[10 250 260 90], ...
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
	'CallBack', @(hSrc,~) trackstyle_cb(hSrc,h.figure));

h.rh = uicontrol(h.figure, 'Style','radio', 'String', 'Rhumb Line', ...
	'Units','points',  'Position',[170 318 90 15], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Value', 0, ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left', ...
	'CallBack', @(hSrc,~) trackstyle_cb(hSrc,h.figure));

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
	'Value', 0, 'CallBack', @(~,~) onepoint_cb(h.figure));

h.twopt = uicontrol(h.figure, 'Style','radio', 'String', '2 Point', ...
	'Units','points',  'Position',[170 298 90 15], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left', ...
	'Value', 1, 'CallBack', @(~,~) twopoint_cb(h.figure));

%  Show Track check box

h.showtrack = uicontrol(h.figure, 'Style','check', 'String', 'Show Track', ...
	'Units','points',  'Position',[15 276 100 18], 'Value',0, ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Angle Units label and text

h.anglabel = uicontrol(h.figure, 'Style','text', 'String', '', ...
	'Units','points',  'Position',[15 255 253 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Starting point frame and title

h.stframe = uicontrol(h.figure, 'Style','frame', ...
	'Units','points',  'Position',[10 185 260 60], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black');

h.sttitle = uicontrol(h.figure, 'Style','text', 'String', 'Starting Point:', ...
	'Units','points',  'Position',[15 220 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Starting latitude text and edit box

h.stlatlabel = uicontrol(h.figure, 'Style','text', 'String', 'Lat:', ...
	'Units','points',  'Position',[15 195 30 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.stlatedit = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[50 195 85 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max', 1, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Starting longitude text and edit box

h.stlonlabel = uicontrol(h.figure, 'Style','text', 'String', 'Lon:', ...
	'Units','points',  'Position',[145 195 30 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.stlonedit = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[180 195 85 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max', 1, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Starting point select button

h.stselect = uicontrol(h.figure, 'Style','push', 'String', 'Mouse Select', ...
	'Units','points',  'Position',[165 220 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
	'UserData',[h.stlatedit h.stlonedit], 'Callback', @(~,~) select_cb(h.figure));

%  Ending point frame and title

h.endframe = uicontrol(h.figure, 'Style','frame', ...
	'Units','points',  'Position',[10 120 260 60], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black');

h.endtitle = uicontrol(h.figure, 'Style','text', 'String', 'Ending Point:', ...
	'Units','points',  'Position',[15 155 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Ending latitude text and edit box

h.endlatlabel = uicontrol(h.figure, 'Style','text', 'String', 'Lat:', ...
	'Units','points',  'Position',[15 130 30 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.endlatedit = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[50 130 85 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max', 1, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Ending longitude text and edit box

h.endlonlabel = uicontrol(h.figure, 'Style','text', 'String', 'Lon:', ...
	'Units','points',  'Position',[145 130 30 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.endlonedit = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[180 130 85 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max', 1, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Ending point select button

h.endselect = uicontrol(h.figure, 'Style','push', 'String', 'Mouse Select', ...
	'Units','points',  'Position',[165 155 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
	'UserData',[h.endlatedit h.endlonedit],  'Callback', @(~,~) select_cb(h.figure));

%  Direction frame and title

h.dirframe = uicontrol(h.figure, 'Style','frame', ...
	'Units','points',  'Position',[10 55 260 60], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black');

h.dirtitle = uicontrol(h.figure, 'Style','text', 'String', 'Direction:', ...
	'Units','points',  'Position',[15 90 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Azimuth text and edit box

h.azlabel = uicontrol(h.figure, 'Style','text', 'String', 'Az:', ...
	'Units','points',  'Position',[15 65 30 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.azedit = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[50 65 85 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max', 1, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Range text and edit box

h.rnglabel = uicontrol(h.figure, 'Style','text', 'String', 'Rng:', ...
	'Units','points',  'Position',[145 65 30 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.rngedit = uicontrol(h.figure, 'Style','edit', 'String', '', ...
	'Units','points',  'Position',[180 65 85 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', 'Max', 1, ...
	'FontSize',9,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Range units select button

h.rngselect = uicontrol(h.figure, 'Style','push', 'String', 'Range Units', ...
	'Units','points',  'Position',[165 90 100 18], ...
	'BackgroundColor',frameclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
 	'UserData',[h.azedit h.rngedit],'Callback',@(~,~) rangeunits_cb(h.figure));

%  Apply, help and cancel buttons

h.cancel = uicontrol(h.figure, 'Style','push', 'String', 'Close', ...
	'Units','points',  'Position',[23 15 65 30], ...
	'BackgroundColor',figclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
	'Callback', @(~,~) close_cb(h.figure));

h.help = uicontrol(h.figure, 'Style','push', 'String', 'Help', ...
	'Units','points',  'Position',[108 15 65 30], ...
	'BackgroundColor',figclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
	'Callback', @(~,~) doc('surfdist'));

% Callback for the 'Compute' button will be set later.
h.apply = uicontrol(h.figure, 'Style','push', 'String', 'Compute', ...
	'Units','points',  'Position',[193 15 65 30], ...
	'BackgroundColor',figclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold');

%  Enable mouse select buttons if tool is linked to a map
if isempty(h.mapaxes)
    set([h.stselect;h.endselect;h.showtrack],'Enable','off')
    h.basegeoid = [1 0];
else
    set([h.stselect;h.endselect;h.showtrack],'Enable','on')
	mstruct = gcm(h.mapaxes);
	h.basegeoid = mstruct.geoid;
	h.trackline = [];
end

% Set TooltipString values to provide help for certain UI elements.

set(h.styletext, 'TooltipString', tooltipHelpStrings('SurfaceStyle'))
set(h.modetext,  'TooltipString', tooltipHelpStrings('SurfaceMode'))
set(h.anglabel,  'TooltipString', tooltipHelpStrings('AngleLabel'))
set(h.showtrack, 'TooltipString', tooltipHelpStrings('ShowTrack'))

set(h.sttitle,   'TooltipString', tooltipHelpStrings('DistanceStart'))
set(h.stselect,  'TooltipString', tooltipHelpStrings('MouseSelect'))

set(h.endtitle,  'TooltipString', tooltipHelpStrings('DistanceEnd'))
set(h.endselect, 'TooltipString', tooltipHelpStrings('MouseSelect'))

set(h.dirtitle,  'TooltipString', tooltipHelpStrings('DistanceDirection'))
set(h.rngselect, 'TooltipString', tooltipHelpStrings('RangeUnits'))

set(h.cancel,    'TooltipString', tooltipHelpStrings('Close'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Compute'))
set(h.help,      'TooltipString', tooltipHelpStrings('surfdistHelp'))

% Save object handles and make figure visible.
set(h.figure,'Visible','on','UserData',h)
    
%  Initialize for two point operation. (This sets the callback for the
%  'Compute' push button.)
twopoint_cb(h.figure)

%  Update the unit string
rangestring(h) 

set(h.figure,'HandleVisibility','Callback')

%--------------------------------------------------------------------------

function dist = km2dist(km, units)
%KM2DIST  Convert km to another length unit or spherical distance
%
%   DIST = KM2DIST(KM, UNITS) converts distances in km to another unit
%   of length, as specified by the string UNITS, or to a spherical
%   distance distance, measured along a great circle on a sphere with a
%   radius of 6371 km, the mean radius of the Earth, if UNITS is
%   'degrees' or 'radians'.

angleUnits = {'degrees','radians'};
k = find(strncmpi(deblank(units), angleUnits, numel(deblank(units))));
if numel(k) == 1
    % In case units is 'degrees' or 'radians'.
    dist = fromRadians(angleUnits{k}, km2rad(km));
else
    % Assume that units specifies a length unit
    dist = unitsratio(units,'km') * km;
end
