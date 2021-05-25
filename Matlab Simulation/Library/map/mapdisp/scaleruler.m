function varargout = scaleruler(varargin)
%SCALERULER Add or modify graphic scale on map axes
%
%   SCALERULER toggles the display of a graphic scale.  A graphic scale is
%   a ruler-like graphic object that shows distances on the ground at the
%   correct size for the projection.  If no graphic scale is currently
%   displayed in the current map axes, one will be added.  If any graphic
%   scales are currently displayed, they will be removed.
%
%   SCALERULER ON adds a graphic scale to the current map axes. Multiple
%   graphic scales can be added to the same map axes.
%
%   SCALERULER OFF removes any currently displayed graphic scales.
%
%   SCALERULER(Name,Value,...) adds a graphic scale and sets the
%   properties to the values specified. A list of graphic scale properties
%   is  displayed by the command SETM(h), where h is the handle to a
%   graphic scale object. The current values for a displayed graphic scale
%   object can be retrieved using GETM.  The properties of a displayed
%   graphic scale object can be modified using SETM.
%
%   The graphic scale object can be repositioned by dragging the scaleruler
%   with the mouse. The position can also be changed by modifying the
%   'XLoc' and 'YLoc' properties using SETM.
%
%   H = SCALERULER(...) returns the hggroup handle to the graphic scale
%   object.
%
%   See also DISTANCE, SURFDIST, AXESSCALE, PAPERSCALE, DISTORTCALC,
%            MDISTORT

% Copyright 1996-2020 The MathWorks, Inc.

nargoutchk(0,1)
if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end
if nargin == 0
    % scaleruler
    if countRulers(gca) == 0
        % No scalerulers: Make one
        s = newPropertiesStructure(varargin{:});
        h = scalerulerOn(s,gca);
    else
        % Found at least one scaleruler: Turn them all off
        h = scalerulerOff(gca);
    end
elseif nargin == 1
    % scaleruler 'on'
    % scaleruler 'off'
    action = varargin{1};
    switch lower(action)
        case 'off'
            h = scalerulerOff(gca);
        case 'on'
            s = newPropertiesStructure(varargin{:});
            h = scalerulerOn(s,gca);
        otherwise
            error('map:scaleruler:invalidAction', ...
                'Recognized scaleruler actions are ON and OFF')
    end
elseif nargin >=1 && strcmp(varargin{1},'setm')
    % scaleruler('setm',h,Name,Value,...) is an undocumented syntax that
    % supports setm(h,Name,Value,...), where h is a handle to a scaleruler
    % group.
    h = varargin{2};
    validateattributes(h,{'matlab.graphics.primitive.Group'},{})
    nameValuePairs = varargin(3:end);
    setScaleRulerProperties(h, nameValuePairs)
elseif nargin >= 2 && (mod(nargin,2) == 0)
    % scaleruler(Name,Value,...) constructs a new scaleruler group using
    % name-value pairs.
    s = newPropertiesStructure(varargin{:});
    h = scalerulerOn(s, gca);
else
    error(message('map:validate:invalidArgCount'))
end

if nargout == 1
    varargout{1} = h;
end

%--------------------------------------------------------------------------

function hScaleRuler = scalerulerOn(s,ax)


% check for globe
if strcmp(getm(ax,'mapprojection'),'globe')
    error('map:scaleruler:globe','Scale rulers are not supported for globe axes.')
end

s = defaultScaleRulerProperties(s,ax);

hScaleRuler = hggroup('Parent', ax, 'UserData', s, ...
    'ButtonDownFcn', @scaleRulerButtonDown, ...
    'HitTestArea', 'on', 'Tag', uniqueTagString(ax));

makeparts(hScaleRuler)

%--------------------------------------------------------------------------

function s = newPropertiesStructure(varargin)
s = emptyPropertiesStructure;
if nargin > 1
    s = updatePropertiesStructure(s, varargin);
end

%--------------------------------------------------------------------------

function hScaleRuler = scalerulerOff(ax)

% Check for 20 possible scale ruler tags: 'scaleruler1', 'scaleruler2', 
% 'scaleruler3', ..., 'scaleruler20', and delete them if found.
for k = 1:20
    tagstr = ['scaleruler' num2str(k)];
    h = findobj(ax,'Tag',tagstr,'Type','hggroup');
    if ~isempty(h)
        delete(h)
    end
end

% Return empty.
hScaleRuler = gobjects(0);

%--------------------------------------------------------------------------

function numRulers = countRulers(ax)
% Check for up to 20 scale rulers.

numRulers = 0;
for k = 1:20
    tagstr = ['scaleruler' num2str(k)];
    h = findobj(ax,'Tag',tagstr,'Type','hggroup');
    if ~isempty(h)
        numRulers = numRulers + 1;
    end
end

%--------------------------------------------------------------------------

function setScaleRulerProperties(hScaleRuler, nameValuePairs)

s = hScaleRuler.UserData;
s = updatePropertiesStructure(s, nameValuePairs);
ax = ancestor(hScaleRuler,'axes');
s = defaultScaleRulerProperties(s,ax);
hScaleRuler.UserData = s;

delete(hScaleRuler.Children)
makeparts(hScaleRuler)

%--------------------------------------------------------------------------

function s = updatePropertiesStructure(s, nameValuePairs)

% Work through property value pairs
scaleRulerProperties = fields(emptyPropertiesStructure);
for k = 1:2:length(nameValuePairs)
   propertyName = nameValuePairs{k};
   try
       %  Make sure that a valid property name is supplied.
       propertyName = validatestring(propertyName, ...
           scaleRulerProperties, '', 'PropertyName');
   catch e
       if mnemonicMatches(e.identifier, {'unrecognizedStringChoice'})
           error(message('map:validate:unrecognizedPropertyName', ...
               propertyName, 'ScaleRuler'))
       elseif mnemonicMatches(e.identifier, {'ambiguousStringChoice'})
           error(message('map:validate:ambiguousPropertyName', ...
               propertyName, 'ScaleRuler'))
       else
           e.rethrow();
       end
   end
   
   %  Handle special cases
   switch propertyName
      case {'MajorTick','MinorTick'}
         s.TickMode = 'manual';
         s.MajorTickLabel = [];
         s.MinorTickLabel = [];
      case 'Children'
          error(message('map:validate:readOnlyProperty','Children'))
   end
   
   % Not much error checking yet: This may require cases for each property.
   s.(propertyName) = nameValuePairs{k+1};
end

%-----------------------------------------------------------------------

function tf = mnemonicMatches(identifier, options)
% Return true if the last part of the colon-delimited string IDENTIFIER,
% typically called the mnemonic, is an exact match for any of the strings
% in the cell string OPTIONS.

parts = textscan(identifier,'%s','Delimiter',':');
mnemonic = parts{1}{end};
tf = any(strcmp(mnemonic,options));

%--------------------------------------------------------------------------

function makeparts(hScaleRuler)

switch getRulerStyle(hScaleRuler)
    case 'ruler'
        normalruler(hScaleRuler)

    case 'lines'
        lineruler(hScaleRuler)

    case 'patches'
        patchruler(hScaleRuler)
end

set(hScaleRuler.Children,'HandleVisibility','on','Clipping','off', ...
    'ButtonDownFcn',@scaleRulerButtonDown)

map.graphics.internal.restackMapAxes(hScaleRuler)

%--------------------------------------------------------------------------

function style = getRulerStyle(hScaleRuler)
s = hScaleRuler.UserData;
style = validatestring(s.RulerStyle, {'ruler','lines','patches'});
s.RulerStyle = style;
hScaleRuler.UserData = s;

%--------------------------------------------------------------------------

function s = emptyPropertiesStructure

s = struct(...
    'Azimuth',				[],...
    'Children',             [],...
    'Color',				[],...
    'FontAngle',			[],...
    'FontName',				[],...
    'FontSize',				[],...
    'FontUnits',			[],...
    'FontWeight',			[],...
    'Label',				[],...
    'Lat',					[],...
    'Long',					[],...
    'LineWidth',			[],...
    'MajorTick',			[],...
    'MajorTickLabel',		[],...
    'MajorTickLength',		[],...
    'MinorTick',			[],...
    'MinorTickLabel',		[],...
    'MinorTickLength',		[],...
    'Radius',				[],...
    'RulerStyle',			[],...
    'TickDir',				[],...
    'TickMode',				[],...
    'Units',				[],...
    'XLoc',					[],...
    'YLoc',					[], ...
    'ZLoc',					[] ...
    );

%--------------------------------------------------------------------------

function s = defaultScaleRulerProperties(s,ax)
% Set unset properties to their defaults and set derived properties.

if isempty(s.Color);				s.Color = [0 0 0];				end
if isempty(s.FontAngle);			s.FontAngle = 'normal';			end
if isempty(s.FontName);				s.FontName = 'Helvetica';		end
if isempty(s.FontSize);				s.FontSize = 9;				    end
if isempty(s.FontUnits);			s.FontUnits = 'points';			end
if isempty(s.FontWeight);			s.FontWeight = 'normal';		end
if isempty(s.Label);				s.Label = '';					end
if isempty(s.Lat);					s.Lat = [];						end
if isempty(s.LineWidth);			s.LineWidth = 0.5;			    end
if isempty(s.Long);					s.Long = [];					end
if isempty(s.MajorTick);			s.MajorTick = [];				end
if isempty(s.MajorTickLabel);		s.MajorTickLabel = [];			end
if isempty(s.MajorTickLength);		s.MajorTickLength = [];			end
if isempty(s.MinorTick);			s.MinorTick = [];				end
if isempty(s.MinorTickLabel);		s.MinorTickLabel = [];			end
if isempty(s.MinorTickLength);		s.MinorTickLength = [];			end
if isempty(s.Radius);				s.Radius = 'earth';				end
if isempty(s.RulerStyle);			s.RulerStyle = 'ruler';			end
if isempty(s.TickMode);		        s.TickMode = 'auto';			end
if isempty(s.TickDir);		        s.TickDir = 'up';				end
if isempty(s.Units);				s.Units = 'km';					end
if isempty(s.XLoc);					s.XLoc = [];					end
if isempty(s.YLoc);					s.YLoc = [];					end


% Default location at which scale is computed: just off center of x and y limits
if isempty(s.Lat) || isempty(s.Long) || isempty(s.Azimuth)
    xlim = get(ax,'xlim');
    ylim = get(ax,'ylim');
    x = min(xlim) + .4*abs(diff(xlim));
    y = min(ylim) + .4*abs(diff(ylim));
    if isempty(s.Lat) || isempty(s.Long)
        [s.Lat,s.Long] = map.crs.internal.minvtran(x,y);
    end
    if isempty(s.Azimuth)
        s.Azimuth = 0;
    end
end

% Default tic mark locations
if isempty(s.MajorTick) || isempty(s.MinorTick) || isempty(s.TickMode)
    s.TickMode = 'auto';
end

if strcmp(s.TickMode,'auto')
    nmajticks = 5;
    nminticks = 4;

    angleunits = getm(ax,'angleunits');

    flatlim = getm(ax,'fLatLim');
    flatlim(isinf(flatlim)) = 0;

    flonlim = getm(ax,'fLonLim');

    lonrange = min(abs(diff(flatlim)),abs(diff(flonlim)));

    % convert to degrees and then to distance units
    lonrange = deg2dist(toDegrees(angleunits,lonrange),s.Units);
    
    maxtick = (10^floor(log10(lonrange)));
    MajorTickLim = [ 0 maxtick/2];

    majinc = maxtick/nmajticks;
    MinorTickLim = [ 0 majinc/2];

    % construct major tics and ticlabels in auto mode
    lim = MajorTickLim;
    inc = abs(lim(2))/nmajticks;
    s.MajorTick = lim(1):inc:lim(2);

    % construct minor tics  in auto mode
    lim = MinorTickLim;
    inc = abs(lim(2))/nminticks;
    s.MinorTick = lim(1):inc:lim(2);
    s.MajorTickLabel = [];
end

% Major tick labels
if isempty(s.MajorTickLabel)
    s.MajorTickLabel = num2cell(num2str(s.MajorTick'),2); % need to remove leading blanks
end

% Minor tick labels
if isempty(s.MinorTickLabel)
    tics = s.MinorTick';
    s.MinorTickLabel = num2str(tics(end));
end

% Tick lengths
if isempty(s.MajorTickLength)
    tics = s.MajorTick;
    inc = diff(tics(1:2));
    s.MajorTickLength = inc/5;
end
if isempty(s.MinorTickLength)
    tics = s.MinorTick;
    inc = diff(tics(1:2));
    s.MinorTickLength = inc/2;
end

% default location of scale: 15 percent in from lower left corner of axes
if isempty(s.XLoc) || isempty(s.YLoc)
    xlim = get(ax,'xlim');
    ylim = get(ax,'ylim');
    limx = xlim;
    s.XLoc = limx(1) + 0.15*diff(limx);
    limy = ylim;
    s.YLoc = limy(1) + 0.15*diff(limy);
end

%--------------------------------------------------------------------------

function dist = deg2dist(deg,units)
% Convert from spherical distance in degrees
%
%   DIST = DEG2DIST(DEG, UNITS) converts distances from degrees, as
%   measured along a great circle on a sphere with a radius of 6371 km
%   (the mean radius of the Earth) to the UNITS of length or angle
%   specified by the string  in UNITS.  If UNITS is 'degrees' or
%   'radians', then DIST itself will be a spherical distance.

angleUnits = {'degrees','radians'};
k = find(strncmpi(deblank(units), angleUnits, numel(deblank(units))));
if numel(k) == 1
    % In case units is 'degrees' or 'radians'
    dist = fromDegrees(angleUnits{k}, deg);
else
    % Assume that units specifies a length unit; convert using
    % kilometers as an intermediate unit.
    dist = unitsratio(units,'km') * deg2km(deg);
end

%--------------------------------------------------------------------------

function tagstr = uniqueTagString(ax)
% Construct a unique tag string for the children of the scaleruler baseline
i=0;
while 1
    i=i+1;
    tagstr = ['scaleruler' num2str(i)];
    hexists = findall(ax,'tag',tagstr);
    if isempty(hexists) 
        break; 
    end
end

%--------------------------------------------------------------------------

function normalruler(hScaleRuler)
% Determine scaling between geographic and surface units

s = hScaleRuler.UserData;
dDdS = geographicScaling(hScaleRuler);

% Allow for tics and text below the baseline
switch s.TickDir
    case 'down'
        ydir = -1;
        valign = 'Top'; % vertical alignment of text
        labelvalign = 'Bottom';
    otherwise
        ydir = 1;
        valign = 'Bottom';
        labelvalign = 'Top'; % vertical alignment of text
end

% Construct Major ticks
x = s.XLoc + dDdS*s.MajorTick; %  + dDdS*s.MinorTick(end)
y = s.YLoc*ones(size(x));
y2 = y + ydir*s.MajorTickLength*dDdS;

% Base line
line('Parent',hScaleRuler,'XData',x([1 end]),'YData',y([1 end]),'Color',s.Color,'LineWidth',s.LineWidth)

xMajor = [x;  x; nan(size(x))];
yMajor = [y; y2; nan(size(y))];
line('Parent',hScaleRuler,'XData',xMajor(:),'YData',yMajor(:),'Color',s.Color,'LineWidth',s.LineWidth);

% Legend label
text('Parent',hScaleRuler,'Position', [mean([x(1) x(end)]), y(1) - ydir*s.MajorTickLength*dDdS, 0], 'String',s.Label,...
    'HorizontalAlignment','center','VerticalAlignment',labelvalign,...
    'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
    'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName)

% Text labels
for i=1:length(s.MajorTickLabel)-1
    text('Parent',hScaleRuler,'Position',[x(i), y2(i), 0],'String',leadblnk(s.MajorTickLabel{i}),...
        'HorizontalAlignment','center','VerticalAlignment',valign,...
        'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
        'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName)
end

fill=char(32*ones(1,2+length(s.Units)));
text('Parent',hScaleRuler,'Position',[x(end), y2(end), 0],'String',[fill leadblnk(s.MajorTickLabel{end}) ' ' s.Units],...
    'HorizontalAlignment','center','VerticalAlignment',valign,...
    'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
    'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName)

% Minor ticks
x = s.XLoc - dDdS*s.MinorTick;
y = s.YLoc*ones(size(x));
y2 = y + ydir*s.MinorTickLength*dDdS;
xMinor = [x;  x; nan(size(x))];
yMinor = [y; y2; nan(size(y))];
line('Parent',hScaleRuler,'XData',xMinor(:),'YData',yMinor(:),'Color',s.Color,'LineWidth',s.LineWidth);

% Base line
line('Parent',hScaleRuler,'XData',x([1 end]),'YData',y([1 end]),'Color',s.Color,'LineWidth',s.LineWidth)

% Minor tick text label
y2 = y + ydir*s.MajorTickLength*dDdS;
text('Parent',hScaleRuler,'Position',[x(end), y2(end), 0], 'String', leadblnk(s.MinorTickLabel),...
    'HorizontalAlignment','center','VerticalAlignment',valign,...
    'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
    'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName)

%--------------------------------------------------------------------------
function lineruler(hScaleRuler)

s = hScaleRuler.UserData;
dDdS = geographicScaling(hScaleRuler);

% Allow for tics and text below the baseline
switch s.TickDir
    case 'down'
        ydir = -1;
        valign = 'Top'; % vertical alignment of text
        labelvalign = 'Bottom';
    otherwise
        ydir = 1;
        valign = 'Bottom';
        labelvalign = 'Top'; % vertical alignment of text
end

% Construct Major ticks
x = s.XLoc + dDdS*s.MajorTick; %  + dDdS*s.MinorTick(end)
y = s.YLoc*ones(size(x));
y2 = y + ydir*s.MajorTickLength*dDdS;

% Base line
line('Parent',hScaleRuler,'XData',x([1 end]),'YData',y([1 end]),'Color',s.Color,'LineWidth',s.LineWidth)
line('Parent',hScaleRuler,'XData',x([1 end]),'YData',y2([1 end]),'Color',s.Color,'LineWidth',s.LineWidth)

% Plot Major ticks
xMajor = [x;  x; nan(size(x))];
yMajor = [y; y2; nan(size(y))];
line('Parent',hScaleRuler,'XData',xMajor(:),'YData',yMajor(:),'Color',s.Color,'LineWidth',s.LineWidth);

% Center bars: indices of every other pair
ind =floor(2.5:.5:length(s.MajorTick));
ind = reshape(ind,2,length(ind)/2);
ind = ind(:,1:2:size(ind,2));
if size(ind,2) == 1
    ind = [ind ind];
end

if ~isempty(ind)
    xbars = x(ind);
    xbars = [xbars ; nan*ones(size(xbars(1,:)))];
    xbars = xbars(:);

    ymid = mean([y;y2]);
    ybars = ymid(ind);
    ybars = [ybars ; nan*ones(size(ybars(1,:)))];
    ybars = ybars(:);

    line('Parent',hScaleRuler,'XData',xbars,'YData',ybars,'Color',s.Color,'LineWidth',s.LineWidth)
end

% Legend label
text('Parent',hScaleRuler,'Position',[mean([x(1) x(end)]), y(1) - ydir*s.MajorTickLength*dDdS, 0], 'String', s.Label,...
    'HorizontalAlignment','center','VerticalAlignment',labelvalign,...
    'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
    'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName)

% Text labels
for i=1:length(s.MajorTickLabel)-1
    text('Parent',hScaleRuler,'Position',[x(i) y2(i) 0],'String',leadblnk(s.MajorTickLabel{i}),...
        'HorizontalAlignment','center','VerticalAlignment',valign,...
        'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
        'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName)
end

fill=char(32*ones(1,2+length(s.Units)));
text('Parent',hScaleRuler,'Position',[x(end) y2(end) 0],'String',[fill leadblnk(s.MajorTickLabel{end}) ' ' s.Units],...
    'HorizontalAlignment','center','VerticalAlignment',valign,...
    'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
    'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName)

% Minor tick center bars: indices of every other pair
x = s.XLoc - dDdS*s.MinorTick;
y = s.YLoc*ones(size(x));
y2 = y + ydir*s.MajorTickLength*dDdS;

ind =floor(1.5:.5:length(s.MinorTick));
ind = reshape(ind,2,length(ind)/2);
ind = ind(:,1:2:size(ind,2));

if size(ind,2) == 1
    ind = [ind ind];
end

if ~isempty(ind)
    xbars = x(ind);
    xbars = [xbars ; nan*ones(size(xbars(1,:)))];
    xbars = xbars(:);

    ymid = mean([y;y2]);
    ybars = ymid(ind);
    ybars = [ybars ; nan*ones(size(ybars(1,:)))];
    ybars = ybars(:);

    xMinor = [x;  x; nan(size(x))];
    yMinor = [y; y2; nan(size(y))];
    line('Parent',hScaleRuler,'XData',xMinor(:),'YData',yMinor(:),'Color',s.Color,'LineWidth',s.LineWidth);
    line('Parent',hScaleRuler,'XData',xbars,'YData',ybars,'Color',s.Color,'LineWidth',s.LineWidth)
    line('Parent',hScaleRuler,'XData',x(1:end),'YData',y(1:end),'Color',s.Color,'LineWidth',s.LineWidth)
    line('Parent',hScaleRuler,'XData',x(1:end),'YData',y2(1:end),'Color',s.Color,'LineWidth',s.LineWidth)
end

% Minor tick text label
text('Parent',hScaleRuler,'Position',[x(end), y2(end), 0], 'String', leadblnk(s.MinorTickLabel),...
    'HorizontalAlignment','center','VerticalAlignment',valign,...
    'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
    'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName);

%--------------------------------------------------------------------------
function patchruler(hScaleRuler)
% Determine scaling between geographic and surface units

s = hScaleRuler.UserData;
dDdS = geographicScaling(hScaleRuler);

% Allow for tics and text below the baseline
switch s.TickDir
    case 'down'
        ydir = -1;
        valign = 'Top'; % vertical alignment of text
        labelvalign = 'Bottom';
    otherwise
        ydir = 1;
        valign = 'Bottom';
        labelvalign = 'Top'; % vertical alignment of text
end

% Construct Major ticks
x = s.XLoc + dDdS*s.MajorTick; %  + dDdS*s.MinorTick(end)
y = s.YLoc*ones(size(x));
y2 = y + ydir*s.MajorTickLength*dDdS;

% Base line
line('Parent',hScaleRuler,'XData',x([1 end]),'YData',y([1 end]),'Color',s.Color,'LineWidth',s.LineWidth)
line('Parent',hScaleRuler,'XData',x([1 end]),'YData',y2([1 end]),'Color',s.Color,'LineWidth',s.LineWidth)

% Plot Major ticks
xMajor = [x;  x; nan(size(x))];
yMajor = [y; y2; nan(size(y))];
line('Parent',hScaleRuler,'XData',xMajor(:),'YData',yMajor(:),'Color',s.Color,'LineWidth',s.LineWidth);

% Center bars: indices of every other pair
ind =floor(2.5:.5:length(s.MajorTick));
ind = reshape(ind,2,length(ind)/2);
ind = ind(:,1:2:size(ind,2));

if size(ind,2) == 1
    ind = [ind ind];
end

xbars = [x(flipud(ind)); x(ind)];
ybars = [y(flipud(ind)); y2(ind)];

patch('Parent',hScaleRuler,'XData',xbars,'YData',ybars, ...
    'FaceColor',s.Color,'EdgeColor',s.Color)

% Legend label
text('Parent',hScaleRuler','Position',[mean([x(1) x(end)]), y(1) - ydir*s.MajorTickLength*dDdS, 0], 'String',s.Label,...
    'HorizontalAlignment','center','VerticalAlignment',labelvalign,...
    'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
    'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName);

% Text labels
for i=1:length(s.MajorTickLabel)-1
    text('Parent',hScaleRuler','Position',[x(i),y2(i),0],'String',leadblnk(s.MajorTickLabel{i}),...
        'HorizontalAlignment','center','VerticalAlignment',valign,...
        'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
        'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName);
end

fill=char(32*ones(1,2+length(s.Units)));
text('Parent',hScaleRuler','Position',[x(end),y2(end) 0],'String',[fill leadblnk(s.MajorTickLabel{end}) ' ' s.Units],...
    'HorizontalAlignment','center','VerticalAlignment',valign,...
    'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color, ...
    'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName);

% Minor tick center bars: indices of every other pair
x = s.XLoc - dDdS*s.MinorTick;
y = s.YLoc*ones(size(x));
y2 = y + ydir*s.MajorTickLength*dDdS;

ind =floor(1.5:.5:length(s.MinorTick));
ind = reshape(ind,2,length(ind)/2);
ind = ind(:,1:2:size(ind,2));

if size(ind,2) == 1
    ind = [ind ind];
end

xbars = [x(flipud(ind));  x(ind)];
ybars = [y(flipud(ind)); y2(ind)];

patch('Parent',hScaleRuler,'XData',xbars,'YData',ybars, ...
    'EdgeColor','k','FaceColor',s.Color)

% Base line
line('Parent',hScaleRuler,'XData',x([1 end]),'YData',y([1 end]),'Color',s.Color)
line('Parent',hScaleRuler,'XData',x([1 end]),'YData',y2([1 end]),'Color',s.Color)

% Minor ticks
xMinor = [x;  x; nan(size(x))];
yMinor = [y; y2; nan(size(y))];
line('Parent',hScaleRuler,'XData',xMinor(:),'YData',yMinor(:),'Color',s.Color,'LineWidth',s.LineWidth);

% Minor tick text label
text('Parent',hScaleRuler','Position',[x(end),y2(end),0],'String',leadblnk(s.MinorTickLabel),...
    'HorizontalAlignment','center','VerticalAlignment',valign,...
    'FontUnits',s.FontUnits,'FontSize',s.FontSize,'Color',s.Color,...
    'FontWeight',s.FontWeight,'FontAngle',s.FontAngle,'FontName',s.FontName);

%--------------------------------------------------------------------------

function dDdS = geographicScaling(hScaleRuler)
% Determine scaling between geographic and surface units

s = hScaleRuler.UserData;
mstruct = gcm(ancestor(hScaleRuler,'axes'));

% Cartesian coordinates of starting point
[xo,yo] = map.crs.internal.mfwdtran(mstruct, s.Lat, s.Long);

% Geographical and paper coordinates of a point downrange
sdistdeg = dist2deg(1,s.Units,s.Radius);

[nlat,nlon] = reckon(s.Lat,s.Long,sdistdeg,s.Azimuth);
[xn,yn] = map.crs.internal.mfwdtran(mstruct, nlat, nlon); % map coordinates

% Euclidean distance between two points in map coordinates
dDdS = hypot(xo-xn, yo-yn);

%--------------------------------------------------------------------------

function scaleRulerButtonDown(hSrc,~)
% ButtonDownFcn callback for scale rulers

hScaleRuler = ancestor(hSrc,'hggroup');
ax = ancestor(hScaleRuler,'axes');

% Ensure that the axes is in a 2D view.
if ~isequal(ax.View, [0 90])
    btn = questdlg({'Must be in 2D view for operation.',...
        'Change to 2D view?'},...
        'Incorrect View','Change','Cancel','Change');
    
    switch btn
        case 'Change'
            view(ax,2)
        case 'Cancel'
            return
    end
end

setappdata(hScaleRuler,'LastPoint',ax.CurrentPoint)

fig = ancestor(ax,'Figure');
fig.WindowButtonMotionFcn = @(~,~) buttonMotionCallback(ax, hScaleRuler);
fig.WindowButtonUpFcn = @(~,~) buttonUpCallback(fig, hScaleRuler);
fig.Pointer = 'fleur';

hScaleRuler.Selected = 'on';
hScaleRuler.Visible = 'on';

%--------------------------------------------------------------------------

function buttonMotionCallback(ax, hScaleRuler)
% Update the location of the scaleruler

pt = ax.CurrentPoint;
lastpt = getappdata(hScaleRuler,'LastPoint');
setappdata(hScaleRuler,'LastPoint',pt)

deltaX = pt(1,1) - lastpt(1,1);
deltaY = pt(1,2) - lastpt(1,2);

s = hScaleRuler.UserData;
s.XLoc = s.XLoc + deltaX;
s.YLoc = s.YLoc + deltaY;
hScaleRuler.UserData = s;

lines = findobj(hScaleRuler.Children,'Type','line');
shiftXYData(lines, deltaX, deltaY);

patches = findobj(hScaleRuler.Children,'Type','patch');
shiftXYData(patches, deltaX, deltaY);

textObjects = findobj(hScaleRuler.Children,'Type','text');
for k = 1:numel(textObjects)
    position = textObjects(k).Position;
    position = position + [deltaX, deltaY, 0.0];
    textObjects(k).Position = position;
end

%--------------------------------------------------------------------------

function shiftXYData(h, deltaX, deltaY)
% Shift XData and YData of patches or lines

for k = 1:numel(h)
    hk = h(k);
    hk.XData = hk.XData + deltaX;
    hk.YData = hk.YData + deltaY;
end

%--------------------------------------------------------------------------

function buttonUpCallback(fig, hScaleRuler)
% Restore settings after mouse button is released

fig.WindowButtonMotionFcn = '';
fig.WindowButtonUpFcn = '';
fig.Pointer = 'arrow';
hScaleRuler.Selected = 'off';
