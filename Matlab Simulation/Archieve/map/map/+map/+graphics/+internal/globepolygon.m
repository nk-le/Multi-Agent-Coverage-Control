function h = globepolygon(spheroid, lat, lon, height, varargin)
%GLOBEPOLYGON Display polygon in 3-D globe system
%
%   map.graphics.internal.GLOBEPOLYGON(SPHEROID, LAT, LON, HEIGHT, Name,
%   Value) uses a patch plus an "edge line" to display a polygon in a 3-D
%   "globe" system.
%
%   H = map.graphics.internal.GLOBEPOLYGON(___) returns a handle to a patch
%   object, that may be used to reset various properties (or [], if LAT and
%   LON are empty).
%
%   Inputs
%   ------
%   SPHEROID is a spheroid object: an oblateSpheroid, referenceEllipsoid,
%   or referenceSphere.
%
%   LAT and LON are vectors containing the polygon vertices, and use NaN
%   delimiters to designate multiple parts, including inner rings.  LAT and
%   LON must be the same size and have NaNs in matching locations.  LAT and
%   LON are in degrees.
%
%   HEIGHT is a scalar indicating the ellipsoidal height of the polygon.
%
%   Name, Value indicates optional name-value pairs corresponding to
%   graphics properties of patch.  An optional 'EdgeLine' parameter may
%   also be specified, with a scalar logical value.  If true (the default),
%   an "edge line" object is created and used to display the polygon edges.
%   If false, the edge line is omitted and the polygon edges are not
%   shown.
%
%   If the EdgeAlpha, EdgeColor, LineWidth, or LineStyle properties (or
%   any marker properties) are set during construction, or via set(h,...),
%   their values are applied to the edge line object, not the patch itself.
%
%   Example
%   -------
%   coast = load('coast.mat');
%   figure('Color','white')
%   h = map.graphics.internal.globepolygon(wgs84Ellipsoid, ...
%         coast.lat, coast.long, 0, 'FaceColor', [0.7 0.7 0.4]);
%   axis equal; axis off
%   set(h,'FaceAlpha',0.5)
%   get(h)
%
%   See also map.graphics.internal.MAPPOLYGON

% Copyright 2012-2019 The MathWorks, Inc.

internal.map.checkNameValuePairs(varargin{:})

% Separate out any 'Parent' properties from varargin.
qParent = strncmpi(varargin,'pa',2);
qParent = qParent | circshift(qParent,[0 1]);
parents = varargin(qParent);
varargin(qParent) = [];

% Check the 'EdgeLine' flag, which is true by default.
[edgeLine, varargin] = map.internal.findNameValuePair('EdgeLine',true,varargin{:});

if ~isempty(lat) || ~isempty(lon)
    if any(~isnan(lat(:))) || any(~isnan(lon(:)))
        [f, vLat, vLon] = geoPolygonToFaceVertex(lat, lon);
        [vX, vY, vZ] = geodetic2ecef(spheroid, vLat, vLon, height);
        geodata = {'Faces', f, 'Vertices', [vX vY vZ]};
    else
        % xdata and ydata both contain nothing but NaN.
        geodata = {'XData', NaN, 'YData', NaN, 'ZData', NaN};
    end
    % Construct a pale-yellow patch with edges turned off;
    % keep it invisible for now.
    defaultFaceColor = [1 1 0.5];   % Pale yellow
    hPatch = patch(geodata{:}, parents{:}, ...
        'FaceColor',defaultFaceColor, ...
        'EdgeColor','none', ...
        'Visible','off');
    
    if edgeLine
        % Construct an "edge line" object.
        [x, y, z] = geodetic2ecef(spheroid, lat, lon, height);
        map.graphics.internal.constructEdgeLine(hPatch,x,y,z);
    end
    
    % After setting up listeners and initializing the "update" state, we're
    % ready to set the rest of the input properties and make both patch and
    % line visible. Also add a delete function to clean up the edge line.
    set(hPatch,'Visible','on',varargin{:})
else
    % Return empty when LAT and LON are both empty.
    hPatch = reshape([],[0 1]);
end

% Suppress output if called with no return value and no semicolon.
if nargout > 0
    h = hPatch;
end

end

%-----------------------------------------------------------------------

function [f, vLat, vLon] = geoPolygonToFaceVertex(lat, lon)
% Convert a latitude-longitude polygon to face vertex form. F is the
% face array, vLat is a column vector containing the vertex latitudes,
% and vLon is a column vector, the same size as vLat, containing the
% vertex longitudes.

[lat, lon] = maptrimp(lat(:), lon(:), [-90 90], [-180 180]);
[f, v] = map.internal.polygonToFaceVertex(lon, lat);
vLat = v(:,2);
vLon = v(:,1);

end
