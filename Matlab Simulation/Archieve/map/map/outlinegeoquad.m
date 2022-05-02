function [lat, lon] = outlinegeoquad(latlim, lonlim, dlat, dlon)
% OUTLINEGEOQUAD Polygon outlining geographic quadrangle
%
%   [LAT, LON] = OUTLINEGEOQUAD(LATLIM, LONLIM, DLAT, DLON) constructs a
%   polygon that traces the outline of the geographic quadrangle defined
%   by LATLIM and LONLIM.  Such a polygon can be useful for displaying
%   the quadrangle graphically, especially on a projection where the
%   meridians and/or parallels do not project to straight lines.
%   LATLIM is a two-element vector of the form:
%
%                [southern-limit northern-limit]
%
%   and LONLIM is a two-element vector of the form:
%
%                 [western-limit eastern-limit]
%
%   DLAT is a positive scalar that specifies a minimum vertex spacing in
%   degrees to be applied along the meridians that bound the eastern and
%   western edges of the quadrangle.  Choose a reasonably small value (a
%   few degrees, perhaps) when using a projection with curved meridians.
%   Likewise, DLON is a positive scalar that specifies a minimum vertex
%   spacing in degrees of longitude to be applied along the parallels
%   that bound the northern and southern edges of the quadrangle. Choose
%   a reasonable small value when using a projection with curved
%   parallels.  To avoid interpolating extra vertices along meridians or
%   parallels, set DLAT or DLON to a value of Inf.  The outputs LAT and
%   LON contain the vertices of a simple closed polygon with clockwise
%   vertex ordering.  All input and output angles are in units of
%   degrees.
%
%   Special Cases
%   -------------
%   The insertion of additional vertices is suppressed at the poles
%   (that is, if LATLIM(1) == -90 or LATLIM(2) == 90). 
%
%   If LONLIM corresponds to a quadrangle width of exactly 360 degrees
%   (LONLIM == [-180 180], for example), then it covers a full
%   latitudinal zone and includes two, separate, NaN-separated parts,
%   unless:
%
%   * Either LATLIM(1) == -90 or LATLIM(2) == 90, so that only one part
%     is needed -- a polygon that follows a parallel clockwise around
%     one of the poles
%
%   * LATLIM(1) == -90 and LATLIM(2) == 90, so that the quadrangle
%     encompasses the entire planet.  In this case the quadrangle cannot
%     be represented by a latitude-longitude polygon and an error
%     results.
%
%   Example
%   -------
%   % Display the outlines of three geographic quadrangles having
%   % very different qualities on top of a simple base map
%   figure('Color','white')
%   axesm('ortho','Origin',[-45 110],'frame','on','grid','on')
%   axis off
%   coast = load('coast');
%   geoshow(coast.lat, coast.long)
% 
%   % Quadrangle covering Australia and vicinity
%   [lat, lon] = outlinegeoquad([-45 5],[110 175],5,5);
%   geoshow(lat,lon,'DisplayType','polygon','FaceAlpha',0.5);
% 
%   % Quadrangle covering Antarctic region
%   antarcticCircleLat = dms2degrees([-66 33 39]);
%   [lat, lon] = outlinegeoquad([-90 antarcticCircleLat],[-180 180],5,5);
%   geoshow(lat,lon,'DisplayType','polygon', ...
%       'FaceColor','cyan','FaceAlpha',0.5);
% 
%   % Quadrangle covering nominal time zone 9 hours ahead of UTC
%   [lat, lon] = outlinegeoquad([-90 90], 135 + [-7.5 7.5], 5, 5);
%   geoshow(lat,lon,'DisplayType','polygon', ...
%       'FaceColor','green','FaceAlpha',0.5);
%
%   See also INGEOQUAD, INTERSECTGEOQUAD.

% Copyright 2007-2010 The MathWorks, Inc.

checkgeoquad(latlim, lonlim, mfilename, 'LATLIM', 'LONLIM', 1, 2)

assert(dlat > 0, ...
    ['map:' mfilename ':nonPositiveDLat'], ...
    'DLAT must be a positive number.')

assert(dlon > 0, ...
    ['map:' mfilename ':nonPositiveDLon'], ...
    'DLON must be a positive number.')

s = latlim(1);
n = latlim(2);
w = lonlim(1);
e = lonlim(2);

% Compute "height" in latitude, "width" in longitude, and take care of
% longitude wrapping in LONLIM.
height = n - s;
width = wrapTo360(e - w);
e = w + width;

% Compute the number of vertices to insert along the meridians (not
% counting corners) and adjust dlat slightly to achieve an even spacing,
% allowing for the possibility that the input value of dlat was Inf.
m = ceil(height/dlat - 1);
if m >= 0
    dlat = height / (m + 1);
else
    m = 0;
    dlat = 0;
end

% Compute number of vertices to insert along the parallels (not counting
% corners) and adjust dlon slightly to achieve an even spacing, allowing
% for the possibility that the input value of dlon was Inf.
p = ceil(width/dlon - 1);
if p >= 0
    dlon = width / (p + 1);
else
    p = 0;
    dlon = 0;
end

% Specify separate values of p and dlon along the northern and southern
% edges, in order to suppress insertion of additional vertices at the
% poles.
if s > -90
    ps = p;
    dlons = dlon;
else
    ps = 0;
    dlons = 0;
end

if n < 90
    pn = p;
    dlonn = dlon;
else
    pn = 0;
    dlonn = 0;
end

if width < 360
    % Construct the closed polygon beginning in the southwest corner and
    % traversing the four edges, using the exact values of s, n, e, and w
    % at the four corners and along the western, northern, eastern, and
    % southern edges:
    %
    %     SW + W edge      NW + N edge      NE + E edge     SE + S edge + SW
    lat = [s+(0:m)*dlat    n(ones(1,1+pn))  n-(0:m)*dlat    s(ones(1,2+ps))];
    lon = [w(ones(1,1+m))  w+(0:pn)*dlonn   e(ones(1,1+m))  e-(0:ps)*dlons w];
elseif (-90 < s && n < 90)
    % The quadrangle covers 360 degrees in longitude, so it is actually
    % a full latitudinal zone; split the output into an east-going small
    % circle and a west-going small circle separated by NaNs that bound
    % the northern and southern edges of the zone, respectively.
    lat = [n(ones(1,2+pn))   NaN  s(ones(1,2+ps)) ];
    lon = [w+(0:pn)*dlonn e  NaN  e-(0:ps)*dlons w];
elseif s == -90 && n < 90
    % The quadrangle is zone that includes the South Pole so the
    % polygon traces a single parallel from west to east.
    lat = n(ones(1,2+pn));
    lon = [w+(0:pn)*dlonn e];   
elseif -90 < s && n == 90
    % The quadrangle is a zone that includes the North Pole so the
    % polygon traces a single parallel from east to west.
    lat = s(ones(1,2+ps));
    lon = [e-(0:ps)*dlons w];
else
    % The quadrangle covers the entire planet, but we don't have a way
    % to specify a polygon that covers the entire planet.
    error(['map:' mfilename ':coversEntirePlanet'], ...
        ['The geographic quadrangle with LATLIM = [%f %f] and\n', ...
        'LONLOM = [%f %f] covers the entire planet and\n', ...
        'cannot be represented as a polygon.'], s, n, w, e)
end
