function hndl = framem(varargin)
%FRAMEM Toggle and control display of map frame
%
%   FRAMEM toggles the display of the map frame.  The map frame
%   is drawn at the longitude and latitude limits specified
%   by the frame properties in the map axes.
%
%   FRAMEM ON turns the map frame on.  FRAMEM OFF turns it off.
%
%   FRAMEM RESET will redraw the frame with the currently
%   specified properties.  This differs from the ON and OFF
%   which simply sets the visible property of the current frame.
%
%   FRAMEM('LineSpec') uses any valid LineSpec to define the frame edge.
%
%   FRAMEM('MapAxesPropertyName',PropertyValue,...) uses the
%   specified Map Axes properties to draw the frame.
%
%   h = FRAMEM(...) returns the handle of the frame drawn.
%
%   See also AXESM, SETM

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Make sure there's a map axes
mstruct = gcm;

h = handlem('Frame');
if nargout ~= 0 
    hndl = h;
end 
if nargin == 0
    if ~isempty(h)
        if strcmp(get(h,'Visible'),'off')
            showm('Frame');
            mstruct.frame = 'on';
        else
            hidem('Frame');
            mstruct.frame = 'off';
        end
        set(gca,'UserData',mstruct)
        return
    end
elseif nargin == 1 && strcmpi(varargin{1},'on')
    if ~isempty(h)                     %  Show existing frame.
        showm('Frame');                %  Else, draw new one
        mstruct.frame = 'on';
        set(gca,'UserData',mstruct)
        return
    end
elseif nargin == 1 && strcmpi(varargin{1},'off')
    hidem('Frame');
    mstruct.frame = 'off';
    set(gca,'UserData',mstruct)
    return
elseif nargin == 1 && ~strcmpi(varargin{1},'reset')
    [~, lcolor] = internal.map.parseLineSpec(varargin{1});

    %  Build up a new property string vector for input to AXESM
    varargin(1) = [];
    if ~isempty(lcolor)
        varargin{length(varargin)+1} = 'FEdgeColor';
        varargin{length(varargin)+1} = lcolor;
    end

    %  If a valid line style is found, then display the new grid, via AXESM
    if ~isempty(varargin)
        axesm(mstruct,'Frame','reset',varargin{:});
        return        %  AXESM  recursively calls FRAMEM to display the frame
    end

elseif rem(nargin,2) == 0
    axesm(mstruct,'Frame','reset',varargin{:});
    return
    %  AXESM recursively calls FRAMEM to display the grid
elseif (nargin == 1 && ~strcmpi(varargin{1},'reset') ) || ...
        (nargin > 1 && rem(nargin,2) ~= 0)
    error(message('map:validate:invalidArgCount'))
end

%  Remove existing frame
if ~isempty(h)
    delete(h)
end

%  Default operation is to draw the frame.  Action string = 'reset'
h0 = constructFramePatch(gca);

%  Set the output argument if necessary, otherwise suppress command-line output
if nargout == 1
    hndl = h0;
end

%-----------------------------------------------------------------------

function h = constructFramePatch(ax)
% Construct a frame patch in the specified map axes and return its handle.

mstruct = gcm(ax);

% Construct a map-frame polygon
[xFrame, yFrame] = mapframe(mstruct);

zFrame = zeros(size(xFrame));

% Construct patch
h = patch('XData', xFrame, 'YData', yFrame, 'ZData', zFrame, ...
    'ButtonDownFcn', @uimaptbx,...
    'Tag','Frame',...
    'FaceColor', mstruct.ffacecolor,...
    'EdgeColor', mstruct.fedgecolor,...
    'LineWidth', mstruct.flinewidth, ...
    'Clipping', 'off', ...
    'Parent', ax);
    
% Restack the frame to the bottom to avoid blocking access to
% other object's buttondownfcns
uistack(h,'bottom');
           
%  Set the display flag to on
mstruct.frame = 'on';
set(ax,'UserData',mstruct)

%-----------------------------------------------------------------------

function [xFrame, yFrame] = mapframe(mstruct)
%MAPFRAME Frame polygon in map coordinates

if strcmp(mstruct.mapprojection, 'globe')
    % 'globe' is not a true projection and should not have a frame
    xFrame = [];
    yFrame = [];
else
    %  Reset the origin so that the frame is displayed relative to the
    %  base projection (not a potentially skewed rotation)
    projImplementedViaRotation = ...
        ~any(strcmp(mstruct.mapprojection, {'tranmerc', 'cassinistd', ...
        'eqaconicstd', 'eqdconicstd', 'lambertstd', 'polyconstd'}));
    if projImplementedViaRotation
        mstruct.origin = [0 0 0];
    else
        % Don't modify the origin latitude -- this projection does not
        % simply rotate an auxiliary sphere.
        mstruct.origin = [mstruct.origin(1) 0 0];
    end
    
    [latfrm, lonfrm] = constructFramePoly(mstruct);
    
    [xFrame, yFrame] = feval(mstruct.mapprojection, ...
        mstruct, latfrm, lonfrm, 'notrim', 'forward');
end

%-----------------------------------------------------------------------

function [latfrm, lonfrm] = constructFramePoly(mstruct)

if ~mprojIsAzimuthal(mstruct.mapprojection) % Quadrangular frame
    
    framelat = sort(toDegrees(mstruct.angleunits, mstruct.flatlimit));
    framelon = sort(toDegrees(mstruct.angleunits, mstruct.flonlimit));

    lats = linspace(framelat(1), framelat(2), mstruct.ffill)';
    lons = linspace(framelon(1), framelon(2), mstruct.ffill)';

    n = numel(lats);
    m = numel(lons);
    
    % Concatenate western, northern, eastern, and southern edges
    latfrm = lats([   1:(n-1)    n+zeros(1,m)   (n-1):-1:2    ones(1,m) ]);
    lonfrm = lons([ ones(1,n-1)     1:m       m+zeros(1,n-2)   m:-1:1   ]);

else  % Circular frame

    if strcmp(mstruct.mapprojection,'vperspec')
        radius = vperspecFrameRadius(mstruct);
    else
        radius = toDegrees(mstruct.angleunits, max(mstruct.flatlimit));
    end

    [latfrm,lonfrm] = scircle1('gc', ...
        0, 0, radius, [0 360], [], 'degrees', mstruct.ffill);
end

% Work in degrees, but return output in the angleunits of the map axes
[latfrm, lonfrm] = fromDegrees(mstruct.angleunits, latfrm, lonfrm);

%-----------------------------------------------------------------------

function radius = vperspecFrameRadius(mstruct)
% Vertical perspective requires special treatment

ellipsoid = mstruct.geoid;
if isobject(ellipsoid)
    semimajorAxis = ellipsoid.SemimajorAxis;
else
    semimajorAxis = ellipsoid(1);
end
P = 1 + mstruct.mapparallels / semimajorAxis;

maxRadius = 1.5533; % 89 degrees in radians
radius = min([acos(1/P)-5*epsm('radians') max(mstruct.flatlimit) maxRadius]); 
radius = rad2deg(radius);
