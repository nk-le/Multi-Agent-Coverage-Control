function hndl = plabel(varargin)
%PLABEL Toggle and control display of parallel labels
%
%   PLABEL toggles the display of the parallel labels on the map axes.
%   These labels are drawn using the properties specified in the map axes.
%
%   PLABEL ON turns the parallel labels on. PLABEL OFF turns them off.
%
%   PLABEL RESET will redraw the parallel labels with the currently
%   specified properties.  This differs from the ON and OFF which simply
%   sets the visible property of the current labels.
%
%   PLABEL(meridian) places the parallel labels at the specified meridian.
%   The input meridian is used to set the PLabelMeridian property in the
%   map axes.
%
%   PLABEL('MapAxesPropertyName',PropertyValue,...) uses the specified Map
%   Axes properties to draw the parallel labels.
%
%   H = PLABEL(...) returns the handles of the labels drawn.
%
%   See also AXESM, MLABEL, SETM

% Copyright 1996-2014 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

mstruct = gcm;

h = handlem('PLabel');
if nargout ~= 0
    hndl = h;
end

if nargin == 0
    if ~isempty(h)
	    if strcmp('off',get(h,'Visible'))
	          showm('PLabel');
			  mstruct.parallellabel = 'on';
              set(gca,'UserData',mstruct)
			  return
	    else
	          hidem('PLabel');
			  mstruct.parallellabel = 'off';
              set(gca,'UserData',mstruct)
			  return
	    end
    end

elseif nargin == 1 && strcmpi(varargin{1},'on')
    if ~isempty(h)                      %  Show existing parallel labels.
 	      showm('PLabel');               %  Else, draw new one
		  mstruct.parallellabel = 'on';
		  set(gca,'UserData',mstruct)
		  return
    end

elseif nargin == 1 && strcmpi(varargin{1},'off')
 	hidem('PLabel');
    mstruct.parallellabel = 'off';
    set(gca,'UserData',mstruct)
    return

elseif nargin == 1 && ~strcmpi(varargin{1},'reset')
    % AXESM recursively calls PLABEL to display the labels
    axesm(mstruct,'ParallelLabel','reset','PLabelMeridian',varargin{1});
    return

elseif rem(nargin,2) == 0
    % AXESM recursively calls PLABEL to display the labels
    axesm(mstruct,'ParallelLabel','reset',varargin{:});
    return

elseif (nargin == 1 && ~strcmpi(varargin{1},'reset') ) || ...
       (nargin > 1 && rem(nargin,2) ~= 0)
    error(message('map:validate:invalidArgCount'))
end


%  Default operation is to label the map.  Action string = 'reset'

%  Clear existing labels
if ~isempty(h)
    delete(h)
end       

% Add new labels.
h = addParallelLabels(mstruct);

%  Set the display flag to on
mstruct.parallellabel = 'on';
set(gca,'UserData',mstruct)

% Return handle if requested.
if nargout ~= 0
    hndl = h;
end

%--------------------------------------------------------------------------

function h = addParallelLabels(mstruct)
% Add a text object, containing parallel labels, to the current axes and
% return its handle.

%  Parallel label properties
pposit  = mstruct.plabellocation;
pplace  = mstruct.plabelmeridian;
pround  = mstruct.plabelround;

%  Skip labeling if position value contains Inf or NaN.
if any(isinf(pposit)) || any(isnan(pposit))
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
    case 'compass',   format = 'ns';
	case 'signed',    format = 'pm';
	otherwise,        format = 'none';
end

%  Get the necessary current map data

maplat  = mstruct.maplatlimit;
origin  = mstruct.origin;
units   = mstruct.angleunits;
frmlon  = mstruct.flonlimit;
alt     = mstruct.galtitude;

if isinf(alt)
    alt = 0;
end

%  Convert the input data into degrees.
%  DMS presents problems with arithmetic below

[maplat,origin,frmlon,pposit,pplace] ...
    = toDegrees(units,maplat,origin,frmlon,pposit,pplace);

%  Latitude locations for the whole world

latlim = [-90 90];

%  Compute the latitudes at which to place labels

if length(pposit) == 1
    latline = [fliplr(-pposit:-pposit:min(latlim)), 0:pposit:max(latlim) ];
else
	latline = pposit;            %  Vector of points supplied
end

latline = latline(latline >= min(maplat) & latline <= max(maplat));

%  Compute the latitude placement points

lonline = pplace(ones(size(latline)));

%  Set appropriate horizontal justification

if pplace == min(frmlon) + origin(2)
     justify = 'right';
elseif pplace == max(frmlon) + origin(2)
     justify = 'left';
else
     justify = 'center';
end

%  Transform the location data back into the map units

[latline,lonline] = fromDegrees(units,latline,lonline);

%  Display the latitude labels on the map

if ~isempty(latline) && ~isempty(lonline)

    % Expand limits slightly to avoid roundoff when trimming.
    if mprojIsAzimuthal(mstruct.mapprojection)
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
        [x, y, latline, lonline] = projectLabelPoints(mstruct, latline, lonline);
        alt = alt(ones(size(x)));
    end
    
    if ~isempty(x)
        %  Compute the label strings.
        if strncmpi(labelunits, 'dms', numel(labelunits))
            % Replace 'dms' with 'degrees2dms'
            % and     'dm'  with 'degrees2dm'
            labelunits = ['degrees2' labelunits];
        else
            % labelunits should be 'degrees' or 'radians'
            latline = fromDegrees(labelunits,latline);
        end
        labelstr = cellstr(angl2str(latline,format,labelunits,pround));
        if strcmp(justify,'right')
            labelstr = cellfun(@(s) sprintf('%s  ',s),labelstr,'UniformOutput',false);
        elseif strcmp('justify','left')
            labelstr = cellfun(@(s) sprintf('  %s',s),labelstr,'UniformOutput',false);
        end
        
        h = text(x,y,alt,labelstr,...
            'Color',fontcolor,...
            'FontAngle',fontangle,...
            'FontName',fontname,...
            'FontSize',fontsize,...
            'FontUnits',fontunits,...
            'FontWeight',fontweight,...
            'HorizontalAlignment',justify,...
            'Interpreter','tex',...
            'VerticalAlignment','middle',...
            'Tag','PLabel',...
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
