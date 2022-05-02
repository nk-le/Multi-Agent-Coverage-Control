function hndl = mlabel(varargin)
%MLABEL Toggle and control display of meridian labels
%
%   MLABEL toggles the display of the meridian labels on the map axes.
%   These labels are drawn using the properties specified in the map axes.
%
%   MLABEL ON turns the meridian labels on. MLABEL OFF turns them off.
%
%   MLABEL RESET will redraw the meridian labels with the currently
%   specified properties.  This differs from the ON and OFF option which
%   simply sets the visible property of the current labels.
%
%   MLABEL(parallel) places the meridian labels at the specified parallel.
%   The input parallel is used to set the MLabelParallel property in the
%   map axes.
%
%   MLABEL('MapAxesPropertyName',PropertyValue,...) uses the specified Map
%   Axes properties to draw the meridian labels.
%
%   H = MLABEL(...) returns the handles of the labels drawn.
%
%   See also AXESM, MLABELZERO22PI, PLABEL, SETM

% Copyright 1996-2014 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

mstruct = gcm;

h = handlem('MLabel');
if nargout ~= 0
    hndl = h;
end

if nargin == 0
    if ~isempty(h)
        if strcmp('off',get(h,'Visible'))
            showm('MLabel');
            mstruct.meridianlabel = 'on';
            set(gca,'UserData',mstruct)
            return
        else
            hidem('MLabel');
            mstruct.meridianlabel = 'off';
            set(gca,'UserData',mstruct)
            return
        end
    end

elseif nargin == 1 && strcmpi(varargin{1},'on')
    if ~isempty(h)                      %  Show existing meridian labels.
 	      showm('MLabel');               %  Else, draw new one
		  mstruct.meridianlabel = 'on';
		  set(gca,'UserData',mstruct)
		  return
    end

elseif nargin == 1 && strcmpi(varargin{1},'off')
 	hidem('MLabel');
    mstruct.meridianlabel = 'off';
    set(gca,'UserData',mstruct)
    return

elseif nargin == 1 && ~strcmpi(varargin{1},'reset')
    % AXESM recursively calls MLABEL to display the labels
    axesm(mstruct,'MeridianLabel','reset','MLabelParallel',varargin{1});
	return        

elseif rem(nargin,2) == 0
    % AXESM recursively calls MLABEL to display the labels
    axesm(mstruct,'MeridianLabel','reset',varargin{:});
    return        

elseif (nargin == 1 && ~strcmpi(varargin{1},'reset') ) || ...
       (nargin > 1 && rem(nargin,2) ~= 0)
    error(message('map:validate:invalidArgCount'))
end


%  Default operation is to label the map.  Action string = 'reset'

%  Clear existing labels.
if ~isempty(h)
    delete(h)
end       

% Add new labels.
h = addMeridianLabels(mstruct);

%  Set the display flag to on
mstruct.meridianlabel = 'on';
set(gca,'UserData',mstruct)

% Return handle if requested.
if nargout ~= 0
    hndl = h;
end

%--------------------------------------------------------------------------

function h = addMeridianLabels(mstruct)
% Add a text object, containing meridian labels, to the current axes and
% return its handle.

%  Meridian label properties
mposit  = mstruct.mlabellocation;
mplace  = mstruct.mlabelparallel;
mround  = mstruct.mlabelround;

%  Skip labeling if position value contains Inf or NaN.
if any(isinf(mposit)) || any(isnan(mposit))
    h = gobjects(0);
    return
end

%  Get the font definition properties

fontangle  = mstruct.fontangle;
fontname   = mstruct.fontname;
fontsize   = mstruct.fontsize;
fontunits  = mstruct.fontunits;
fontweight = mstruct.fontweight;
fontcolor  = mstruct.fontcolor;
labelunits = mstruct.labelunits;

%  Convert the format into a string recognized by angl2str

switch mstruct.labelformat
    case 'compass',   format = 'ew';
	case 'signed',    format = 'pm';
	otherwise,        format = 'none';
end


%  Get the necessary current map data

maplon  = mstruct.maplonlimit;
units   = mstruct.angleunits;
frmlat  = mstruct.flatlimit;
alt     = mstruct.galtitude;

if isinf(alt)
    alt = 0;
end

%  Convert the input data into degrees.
%  DMS presents problems with arithmetic below

[maplon,frmlat,mposit,mplace] ...
    = toDegrees(units,maplon,frmlat,mposit,mplace);

%  Longitude locations for the whole world and then some
%  Will be truncated later.  Use more than the whole world
%  to ensure capturing the data range of the current map.

lonlim = [-360 360];

%  Compute the longitudes at which to place labels

if length(mposit) == 1
	lonline = [fliplr(-mposit:-mposit:min(lonlim)), 0:mposit:max(lonlim) ];
else
	lonline = mposit;            %  Vector of points supplied
end

lonline = lonline(lonline >= min(maplon)  &  lonline <= max(maplon));

%  Compute the latitude placement points and set vertical justification

latline = mplace(ones(size(lonline)));
if mplace == min(frmlat)
     justify = 'top';
elseif mplace == max(frmlat)
     justify = 'bottom';
else
     justify = 'middle';
end

%  Transform the location data back into the map units

latline = fromDegrees(units,latline);
lonline = fromDegrees(units,lonline);

%  Display the latitude labels on the map

if ~isempty(latline) && ~isempty(lonline)

    azimuthal = mprojIsAzimuthal(mstruct.mapprojection);

    if azimuthal
        % Remove the 180W label so that it won't be overwritten by the 180E
        % label.
        remove = (lonline == -180);
        latline(remove) = [];
        lonline(remove) = [];
    end
    
    % Expand limits slightly to avoid roundoff when trimming.
    if azimuthal
        mstruct.flatlimit(2) = max( ...
            mstruct.flatlimit(2) + eps(180), mstruct.trimlat(2));
    else
        [flatlim, flonlim] = bufgeoquad( ...
            mstruct.flatlimit, mstruct.flonlimit, eps(180), eps(180));
        mstruct.flatlimit = flatlim;
        mstruct.flonlimit = flonlim;
    end
        
    if strcmp(mstruct.mapprojection,'globe')
        [x,y,alt] = globe(mstruct, ...
            latline,lonline,zeros(size(latline)),'text','forward');
    else
        [x,y,latline,lonline] = projectLabelPoints(mstruct,latline,lonline);
        alt = alt(ones(size(x)));
    end
    
    if ~isempty(x)
        if azimuthal
            % Push labels outward, to keep text at the limit from landing
            % on the end of the map frame.
            justify = 'middle';
            x = 1.04 * (x - mstruct.falseeasting)  + mstruct.falseeasting;
            y = 1.04 * (y - mstruct.falsenorthing) + mstruct.falsenorthing;
        end
        
        %  Compute the label strings.
        if strncmpi(labelunits, 'dms', numel(labelunits))
            % Replace 'dms' with 'degrees2dms'
            % and     'dm'  with 'degrees2dm'
            labelunits = ['degrees2' labelunits];
        else
            % labelunits should be 'degrees' or 'radians'
            lonline = fromDegrees(labelunits,lonline);
        end
        labelstr = cellstr(angl2str(lonline,format,labelunits,mround));
        if strcmp(justify,'top')
            labelstr = cellfun(@(s) sprintf('\n%s',s),labelstr,'UniformOutput',false);
        elseif strcmp(justify,'bottom')
            labelstr = cellfun(@(s) sprintf('%s\n',s),labelstr,'UniformOutput',false);
        end
        
        h = text(x,y,alt,labelstr,...
            'Color',fontcolor,...
            'FontAngle',fontangle,...
            'FontName',fontname,...
            'FontSize',fontsize,...
            'FontUnits',fontunits,...
            'FontWeight',fontweight,...
            'HorizontalAlignment','center',...
            'Interpreter','tex',...
            'VerticalAlignment',justify,...
            'Tag','MLabel',...
            'Clipping','off');
        
        %  Restack to ensure standard child order in the map axes.
        map.graphics.internal.restackMapAxes(h)
        
        %  Align text to graticule
        if strcmp(mstruct.labelrotation,'on') ...
                && ~strcmp(mstruct.mapprojection,'globe')
            for k = 1:length(h)
                if ishghandle(h(k),'text')
                    set(h(k),'Rotation', ...
                        labelRotationAngle(mstruct, latline(k), lonline(k)))
                end
            end
        end
    else
        h = gobjects(0);
    end
else
	h = gobjects(0);
end
