function hout = northarrow(varargin)
%NORTHARROW Add graphic element pointing to geographic North Pole
%
%   NORTHARROW creates a north arrow symbol at the map origin on the
%   displayed map.  The north arrow symbol can be repositioned by clicking
%   and dragging its icon.  Alternate clicking on the icon creates an input
%   dialog box that can be also to change the location of the north arrow.
%
%   NORTHARROW('property',value,...) creates a north arrow using the
%   specified property-value pairs.  Valid entries for properties are
%   'latitude', 'longitude', 'facecolor', 'edgecolor', 'linewidth', and
%   'scaleratio'.  The 'latitude' and 'longitude' properties specify the
%   location of the north arrow.  The 'facecolor', 'edgecolor', and
%   'linewidth' properties control the appearance of the north arrow.  The
%   'scaleratio' property represents the size of the north arrow as a
%   fraction of the size of the axes.  A 'scaleratio' value of 0.10 will
%   create a north arrow one-tenth (1/10) the size of the axes.  The
%   appearance ('facecolor', 'edgecolor', and 'linewidth') of the north
%   arrow can be changed using the SET command.
%
%   Modifying some of the properties of the north arrow will result in
%   replacement of the original object.  Use HANDLEM('NorthArrow') to get
%   the handles associated with the north arrow.
%
%   LIMITATIONS:  Multiple north arrows may be drawn on the map.  However,
%   the callbacks will only work with the most recently created north
%   arrow. In addition, since it can be displayed outside the map frame
%   limits, the north arrow is not converted into a 'mapped' object. Hence,
%   the location and orientation of the north arrow has to be updated
%   manually if the map origin or projection is changed.

% Copyright 1996-2020 The MathWorks, Inc.
% Written by: L. Job

% check if a valid map axes is open
hndl = get(get(0,'CurrentFigure'),'CurrentAxes');
if isempty(hndl)
    error(['map:' mfilename ':mapdispError'], 'No axes in current figure')
end

gcm(hndl);

% check to make sure that the map projection and axes view are 2-D
mapproj = getm(gca,'mapprojection');
switch mapproj
    case 'globe'
        error(['map:' mfilename ':mapdispError'], ...
            'NORTH ARROW only works on 2-D map projections.')
    otherwise
        % change view
        vw = get(gca,'view');
        if any(vw ~= [0 90])
            btn = questdlg(...
                {'Must be in 2D view for operation.','Change to 2D view?',...
                'Incorrect View','Change','Cancel','Change'});
            switch btn
                case 'Change',      view(2);
                case 'Cancel',      return
            end
        end
end

switch nargin
    case 0
        
        % 1st time through with no inputs
        x = mean(xlim);
        y = mean(ylim);
        [s.lat,s.lon ] = map.crs.internal.minvtran(x,y);
        s.action = 'initialize';
        s.facecolor = [0 0 0];
        s.edgecolor = [0 0 0];
        s.linewidth = 1;
        s.scaleratio = 0.1;
        s = scalefactor(s);
        setApplicationData(s)
        constructSymbol(s)
        
    case 1
        
        % execute callbacks
        action = convertStringsToChars(varargin{1});
        appdata = getappdata(gcf,'appdata');
        s = appdata.s;
        s.action = action;
        setappdata(gcf,'appdata',appdata);
        
    otherwise
        
        % 1st time through with inputs
        % default values
        x = mean(xlim);
        y = mean(ylim);
        [s.lat,s.lon ] = map.crs.internal.minvtran(x,y);
        s.action = 'initialize';
        s.facecolor = [0 0 0];
        s.edgecolor = [0 0 0];
        s.linewidth = 1;
        s.scaleratio = 0.1;
        
        % fill in values
        if mod(nargin,2) ~= 0
            error(['map:' mfilename ':mapdispError'], ...
                'Property-Value Pairs Required')
        end
        [varargin{:}] = convertStringsToChars(varargin{:});
        parameters = {'latitude', 'longitude', 'facecolor', ...
            'edgecolor','linewidth','scaleratio'};
        for i = 1:2:nargin
            prop = validatestring( ...
                varargin{i} ,parameters, 'northarrow', 'property name');
            val = varargin{i+1};
            switch prop
                case 'latitude',    s.lat = val;
                case 'longitude',   s.lon = val;
                case 'facecolor',   s.facecolor = val;
                case 'edgecolor',   s.edgecolor = val;
                case 'linewidth',   s.linewidth = val;
                case 'scaleratio',  s.scaleratio = val;
            end
        end
        
        s = scalefactor(s);
        setApplicationData(s)
        constructSymbol(s)
        
end

switch s.action
    case 'initialize'
        
        appdata = getappdata(gcf,'appdata');
        a = appdata.a;
        p = appdata.p;
        ns = appdata.ns;
        s = appdata.s;
        
        % convert the data to Cartesian coordinates so that we can plot
        % them outside the frame also and add a color patch to the arrow
        
        x = [a.x nan ns.x nan];
        y = [a.y nan ns.y nan];
        
        % color properties
        h1 = patch(x, y, 'c', 'linewidth', s.linewidth, ...
            'edgecolor', s.edgecolor, 'facecolor', s.facecolor,...
            'tag', 'NorthArrow', 'Clipping', 'off');
        
        % fill in arrow body with specified fill color
        nanindx = find(isnan(x));
        ax = x(1:nanindx(1)-1);
        ay = y(1:nanindx(1)-1);
        h2 = patch(ax, ay, 'c', 'linewidth', s.linewidth, ...
            'edgecolor', s.edgecolor, 'facecolor', s.facecolor,...
            'tag', 'NorthArrow', 'Clipping', 'off');
        
        s.action = 'mousedown';
        
        % save application data in object
        appdata.a = a;
        appdata.p = p;
        appdata.ns = ns;
        appdata.s = s;
        appdata.h = [h1 h2];
        h = findobj(gcf,'Tag','NorthArrow');
        set(h,'buttondownfcn','northarrow(''mousedown'')')
        for i = 1:length(h)
            setappdata(h(i),'appdata',appdata);
        end
        
        %  Restack to ensure standard child order in the map axes.
        map.graphics.internal.restackMapAxes(h)
        
        if nargout > 0
            hout = h;
        end
        
    case 'mousedown'
        
        appdata = getappdata(gco,'appdata');
        
        stype  = get(gcf,'SelectionType');
        switch stype
            case 'alt'
                
                s = appdata.s;
                dlgTitle = 'Inputs for North Arrow';
                prompt = {'Latitude and Longitude', 'FaceColor', ...
                    'EdgeColor', 'LineWidth', 'ScaleRatio'};
                def = { ...
                    sprintf('%10.4f     ',[s.lat s.lon]),...
                    sprintf('%10.4f     ',s.facecolor),...
                    sprintf('%10.4f     ',s.edgecolor),...
                    sprintf('%10.4f     ',s.linewidth),...
                    sprintf('%10.4f     ',s.scaleratio)};
                lineNo = 1;
                answer = inputdlg(prompt,dlgTitle,lineNo,def);
                if ~isempty(answer)
                    latlon = str2num(answer{1}); %#ok<ST2NM>
                    % input errors for latitude and longitude
                    if isempty(latlon)
                        warndlg('Latitude and Longitude Unspecified', ....
                            'Input Error','modal')
                        return
                    end
                    if length(latlon) ~= 2
                        warndlg('Latitude or Longitude Unspecified', ...
                            'Input Error','modal')
                        return
                    end
                    if latlon(1)<-90 || latlon(1)> 90
                        warndlg('Latitude value must fall between 90 and -90 degrees', ...
                            'Input Error','modal')
                        return
                    end
                    if latlon(2)<-180 || latlon(1)> 180
                        warndlg('Longitude value must fall between 180 and -180 degrees', ...
                            'Input Error','modal')
                        return
                    end
                    fcolor = str2num(answer{2}); %#ok<ST2NM>
                    % facecolor elements
                    if length(fcolor) ~= 3
                        warndlg('FaceColor must be a three element vector', ...
                            'Input Error','modal')
                        return
                    end
                    aboveIndx = fcolor>1;
                    belowIndx = fcolor<0;
                    if any(aboveIndx) || any(belowIndx)
                        warndlg('Each element of vector must fall between 0 and 1', ...
                            'Input Error','modal')
                        return
                    end
                    ecolor = str2num(answer{3}); %#ok<ST2NM>
                    % edgecolor elements
                    if length(ecolor) ~= 3
                        warndlg('EaceColor must be a three element vector', ...
                            'Input Error','modal')
                        return
                    end
                    aboveIndx = ecolor>1;
                    belowIndx = ecolor<0;
                    if any(aboveIndx) || any(belowIndx)
                        warndlg('Each element of vector must fall between 0 and 1', ...
                            'Input Error','modal')
                        return
                    end
                    lwidth = str2num(answer{4}); %#ok<ST2NM>
                    % linewidth element
                    if length(lwidth) ~= 1 || lwidth < 0
                        warndlg('LineWidth must be a non-negative value', ...
                            'Input Error','modal')
                        return
                    end
                    sratio = str2num(answer{5}); %#ok<ST2NM>
                    % scaleratio element
                    if length(sratio) ~= 1 || lwidth < 0
                        warndlg('ScaleRatio must be a non-negative value', ...
                            'Input Error','modal')
                        return
                    end
                end
                
                if ~isempty(answer)
                    
                    s.lat = latlon(1);
                    s.lon = latlon(2);
                    s.facecolor = fcolor;
                    s.edgecolor = ecolor;
                    s.linewidth = lwidth;
                    s.scaleratio = sratio;
                    
                    if ishghandle(appdata.h)
                        delete(appdata.h);
                    end
                    appdata.h = [];
                    appdata.s = s;
                    setappdata(gcf,'appdata',appdata);
                    
                    s = scalefactor(s);
                    constructSymbol(s);
                    northarrow('initialize');
                    
                end
                
            case 'normal'
                
                if ishghandle(appdata.h)
                    h1 = appdata.h(1);
                    
                    % Save the HG properties of the NorthArrow.
                    edgeColor = get(h1,'EdgeColor');
                    faceColor = get(h1,'FaceColor');
                    lineWidth = get(h1,'LineWidth');
                    if isfield(appdata,'s')
                        appdata.s.edgecolor = edgeColor;
                        appdata.s.facecolor = faceColor;
                        appdata.s.linewdith = lineWidth;
                    end
                    
                    delete(appdata.h);
                end
                cpoint = get(gca,'CurrentPoint');
                x = cpoint(1,1);
                y = cpoint(1,2);
                appdata.s.XLoc = x;
                appdata.s.YLoc = y;
                h = plot(x, y, 'r.', 'MarkerSize', 20, ...
                    'Tag', 'northArrowControl', ...
                    'Clipping', 'off');
                appdata.h = h;
                setappdata(gcf,'appdata',appdata);
                set(gcf, 'WindowButtonMotionFcn', 'northarrow(''move'');')
                set(gcf, 'WindowButtonUpFcn', 'northarrow(''mouseup'');')
                
        end
        
    case 'move'
        
        h = findobj(gcf,'Tag','northArrowControl');
        cpoint = get(gca,'CurrentPoint');
        x = cpoint(1,1);
        y = cpoint(1,2);
        set(h,'XData',x,'YData',y);
        
        
    case 'mouseup'
        
        delete(findobj(gcf,'Tag','northArrowControl'))
        cpoint = get(gca,'CurrentPoint');
        x = cpoint(1,1);
        y = cpoint(1,2);
        
        set(gcf,'WindowButtonMotionFcn','')
        set(gcf,'WindowButtonUpFcn','')
        
        % redraw north arrow from new location
        appdata = getappdata(gcf,'appdata');
        delx = x - appdata.s.XLoc;
        dely = y - appdata.s.YLoc;
        xOrigin = appdata.s.origin(1) + delx;
        yOrigin = appdata.s.origin(2) + dely;
        [lat,lon] = map.crs.internal.minvtran(xOrigin,yOrigin);
        
        s = appdata.s;
        s.origin = [xOrigin, yOrigin];
        s.lat = lat;
        s.lon = lon;
        appdata.s = s;
        setappdata(gcf,'appdata',appdata);
        s = scalefactor(s);
        constructSymbol(s);
        northarrow('initialize');
        
end

%-----------------------------------------------------------
function constructSymbol(s)

appdata = getappdata(gcf,'appdata');
a = appdata.a;
p = appdata.p;
ns = appdata.ns;

% origin
[ox,oy] = map.crs.internal.mfwdtran(s.lat,s.lon);
vertVect = s.u*s.scalefactor;
horzVect = s.uPrime*s.scalefactor;

% arrow points
x{1} = ox + [0 a.Dist(1)*vertVect(1)];
y{1} = oy + [0 a.Dist(1)*vertVect(2)];

x{2} = ox + (a.Dist(2)*horzVect(1));
y{2} = oy + (a.Dist(2)*horzVect(2));

x{3} = ox + (a.Dist(3)*vertVect(1));
y{3} = oy + (a.Dist(3)*vertVect(2));

x{4} = ox - (a.Dist(4)*horzVect(1));
y{4} = oy - (a.Dist(4)*horzVect(2));

a.x = [x{:} fliplr(x{1})];
a.y = [y{:} fliplr(y{1})];

% pivot points
clear x y
x{1} = ox + (p.Dist(1)*vertVect(1));
y{1} = oy + (p.Dist(1)*vertVect(2));

x{2} = ox + (p.Dist(2)*vertVect(1));
y{2} = oy + (p.Dist(2)*vertVect(2));

x{3} = x{1};
y{3} = y{1};

x{4} = x{2};
y{4} = y{2};

p.x = [x{:}];
p.y = [y{:}];

% north symbol points
clear x y
x{1} = p.x(1) - (ns.Dist(1)*horzVect(1));
y{1} = p.y(1) - (ns.Dist(1)*horzVect(2));

x{2} = p.x(2) - ns.Dist(2)*horzVect(1);
y{2} = p.y(2) - ns.Dist(2)*horzVect(2);

x{3} = p.x(3) + ns.Dist(3)*horzVect(1);
y{3} = p.y(3) + ns.Dist(3)*horzVect(2);

x{4} = p.x(4) + ns.Dist(4)*horzVect(1);
y{4} = p.y(4) + ns.Dist(4)*horzVect(2);

% ensure that the 'N' letter is drawn correctly
if sign(s.u(1)) == -1 && sign(s.u(2)) == 1
    ns.x = [x{3} x{4} x{1} x{2}];
    ns.y = [y{3} y{4} y{1} y{2}];
else
    ns.x = [x{:}];
    ns.y = [y{:}];
end

% set application data
appdata.a = a;
appdata.p = p;
appdata.ns = ns;
setappdata(gcf,'appdata',appdata);

%-----------------------------------------------------------
function setApplicationData(s)

% set application data

% arrow
a.Dist = [0.25 0.25 0.75 0.25 0.25];
a.Az =  [0 90 0 270 0];
a.lat = []; a.lon = [];
a.x = []; a.y = [];

% pivot
p.Dist = [0.75 1.00 0.75 1.00];
p.Az = [0 0 0 0];
p.x = []; p.y = [];

% north symbol
ns.Dist = [0.125 0.125 0.125 0.125];
ns.Az = [270 270 90 90];
ns.lat = []; ns.lon = [];
ns.x = []; ns.y = [];

appdata.a = a;
appdata.p = p;
appdata.ns = ns;
appdata.s = s;
setappdata(gcf,'appdata',appdata)

%-----------------------------------------------------------
function s = scalefactor(s)

% compute the mean distance covered by the map axes
dist = mean([abs(diff(xlim)) abs(diff(ylim))]);
s.scalefactor = dist*s.scaleratio;

% compute scalefactor in degrees
[x,y] = map.crs.internal.mfwdtran(s.lat,s.lon);
s.origin = [x,y];
x2 = x; y2 = y+s.scalefactor;
[lat2,lon2] = map.crs.internal.minvtran(x2,y2);
s.scalefactordeg = distance(s.lat,s.lon,lat2,lon2);
% s.scalefactor = scalefactor;

% unit vector pointing north
[lat2,lon2] = reckon(s.lat,s.lon,s.scalefactordeg,0);
[x2,y2] = map.crs.internal.mfwdtran(lat2,lon2);
nV = [x2-x y2-y];

% unit vector pointing north
u = nV./norm(nV);
uSign = sign(u);
if diff(uSign) == 0
    uPrimeSign = [1 -1];
else
    uPrimeSign = -1*uSign;
end

% special case if unit vector aligned along principal direction
if all(u) ~= 1
    uPrime = u;
    uPrime(u ~= 0) = 0;
    uPrime(u == 0) = u(u  ~= 0);
else
    % unit vector perpendicular to one pointing north
    uPrime = 1./u;
    uPrime = uPrime./norm(uPrime).*uPrimeSign;
end

s.u = u;
s.uPrime = uPrime;
