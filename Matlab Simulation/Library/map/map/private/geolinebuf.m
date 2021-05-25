function p = geolinebuf(lat, lon, bufwidth, n)
% Buffer zone for latitude-longitude polyline
% 
%   [LATB, LONB] = GEOLINEBUF(LAT, LON, BUFWIDTH, N) computes the buffer
%   zone around a polyline on a sphere. The buffer zone is the locus of
%   points at within a certain of the polyline itself. LAT and LON are
%   column vectors containing the latitudes and longitudes of the polyline
%   vertices, which may be broken into multiple parts separated by isolated
%   values of NaN in LAT and LON. LAT and LON are known not to have any
%   repeated vertices. The width of the buffer zone is given by
%   the scalar BUFWIDTH, expressed as a spherical distance in degrees of
%   arc. The buffer zone is approximated as a multi-part polygon that
%   encloses the polyline. The latitudes and longitudes of its vertices are
%   returned in LATB and LONB, which are NaN-separated column vectors in
%   units of degrees. N controls the spacing of vertices used to
%   approximate circles about the vertices of the polygon. An isolated
%   point would be enclosed by a polygon with N + 1 vertices (with the last
%   vertex being a replica of the first) and N sides. The output is in
%   latitude-longitude, but with a planar topology and longitudes
%   restricted to [-180 180].

% Copyright 2010-2018 The MathWorks, Inc.

latlim = [ -90  90];
lonlim = [-180 180];

[cx, cy, cz, cxEast, cyEast, czEast, cxWest, cyWest, czWest] ...
    = geocirclebuf(bufwidth, n);

[lat, lon] = removeExtraNanSeparators(lat, lon);

lat = deg2rad(lat);
lon = deg2rad(lon);

% Place a full circle around each isolated vertex.
[first, last] = internal.map.findFirstLastNonNan(lat);
isolated = first((first == last));
if isempty(isolated)
    pa = polyshape.empty;
else
    % Pre-allocate row vector of default polyshape objects, then iterate.
    numIsolatedVertices = numel(isolated);
    pa(1, numIsolatedVertices) = polyshape;
    for k = 1:numIsolatedVertices
        [phib, lambdab] = geopointbuf(lat(isolated(k)), lon(isolated(k)), cx, cy, cz);
        [lata, lona] = maptrimp( ...
            rad2deg(phib), rad2deg(lambdab), latlim, lonlim);
        pa(1,k) = polyshape(lona, lata, 'Simplify', false, 'KeepCollinearPoints', true);
    end
end

% Remove the isolated vertices from the lists of start and end points.
multivertex = (first < last);
first = first(multivertex);
last  = last(multivertex);

% Process each part and each arc within that part.
if isempty(first)
    pb = polyshape.empty;
else
    % Pre-allocate row vector of default polyshape objects, then iterate.
    numArcs = sum(last - first);
    pb(1, numArcs) = polyshape;
    m = 1;
    for j = 1:numel(first)
        for k = first(j):(last(j)-1)
            [phib, lambdab] = geoarcbuf(lat(k), lon(k), lat(k+1), lon(k+1), ...
                deg2rad(bufwidth), cxEast, cyEast, czEast, cxWest, cyWest, czWest);
            [latb, lonb] = maptrimp( ...
                rad2deg(phib), rad2deg(lambdab), latlim, lonlim);
            pb(1,m) = polyshape(lonb, latb, 'Simplify', false, 'KeepCollinearPoints', true);
            m = m + 1;
        end
    end
end

p = union([pa pb], 'KeepCollinearPoints', true);

%---------------------------------------------------------------------------

function [cx, cy, cz, cxEast, cyEast, czEast, cxWest, cyWest, czWest] ...
    = geocirclebuf(bufwidth, n)
% Construct a small circle with radius bufwidth and center at lat = 0, lon
% = 0, approximated by a regular n-sided polygon. The polygon has n + 1
% vertices starting and ending at the same vertex: lat = bufwidth, lon = 0.
% Extract symmetric eastern western parts, omitting the first, last, and
% middle vertices (with abs(lat) == bufwidth). Return the results as unit
% ("direction cosine") vectors rather than latitudes and longitudes.

% Start with a counter-clockwise circle centered on the North Pole and
% rotate about the Y-axis by 90 degrees. Mapping -cx to cz would keep
% the circle counter-clockwise, but we want a clockwise circle, so we
% actually map cx to cz instead (simply omitting the minus sign).
lonc = -180 + ((0:n)/n)*360;
cr = sind(bufwidth);
cx = cosd(bufwidth) + zeros(1,n+1);    % Rotation:  cz
cy = cr * sind(lonc);                  % Rotation:  cy
cz = cr * cosd(lonc);                  % Rotation: -cx

% Relying on the knowledge that n is even, extract symmetric western and
% eastern parts, omitting the points at lon == 0.
ne = n / 2;
nw = ne + 2;

% Take the western half, dropping the southern-most and northern-most
% vertices; repeat for the eastern half.
cxWest = cx(2:ne);
cyWest = cy(2:ne);
czWest = cz(2:ne);

cxEast = cx(nw:end-1);
cyEast = cy(nw:end-1);
czEast = cz(nw:end-1);

%--------------------------------------------------------------------------

function [phib, lambdab] = geopointbuf(phi, lambda, cx, cy, cz)
% Buffer zone around isolated point

% Transform a set of unit vectors centered on (0,0) to a small circle in
% latitude and longitude centered on (phi, lambda).

% Rotate about Y by omegaY = phi.
[cz, cx] = rotateInPlane(cz, cx, phi);

% Convert unit vectors to latitudes and longitudes.
[lambdab, phib] = cart2sph(cx, cy, cz);

% Rotate about Z by omegaZ = lambda.
lambdab = lambdab + lambda;

%--------------------------------------------------------------------------

function [phib, lambdab] = geoarcbuf(phi1, lambda1, phi2, lambda2, ...
    bufwidth, cxEast, cyEast, czEast, cxWest, cyWest, czWest)
% Buffer zone around great circle arc
%
%   Compute a polygon enclosing the area within a specified distance of
%   the minor great circle arc connecting a pair of points on the
%   sphere. The arc is defined by the end points (phi1, lambda1) and
%   (phi2, lambda2), where phi1 and phi2 are latitudes in radians and
%   lambda1 and lambda2 are longitudes in radians. bufwidth is the
%   buffer zone extent expressed as a spherical distance in radians. The
%   outputs phib and lambdab are column vectors comprising the latitudes
%   and longitudes of the vertices of the simple closed polygon that
%   encloses the arc at distance bufwidth. The vertices are ordered such
%   that the arc lies on the right hand side of the curve defined by
%   phib and lambdab. The buffer polygon in the vicinity of each end
%   point includes a semicircle -- half of a small circle of radius
%   bufwidth centered on the point itself -- approximated by n segments.
%   The two semicircles are connected by portions of two small circles
%   centered on the pole of the arc, running along each side of the
%   arc. These connecting small circle arcs have a much lower curvature
%   than the semicircles, and therefore are sampled at approximately
%   1/4 the density of the sampling along the semicircles. (Or maybe we
%   should use a sampling interval equal to some fixed fraction of
%   bufwidth?)

% Rotate about the Z-axis by -omegaZ, bringing Point 1 to the Prime
% Meridian.
omegaZ = lambda1;

lambda1 = lambda1 - omegaZ;
lambda2 = lambda2 - omegaZ;

% Rotate about the Y-axis by -omegaY, bringing Point 1 to the Equator.
omegaY = phi1;

phi1 = 0;  % (phi1 = phi1 - omegaY)
[vx, vy, vz] = sph2cart(lambda2, phi2, 1);
[vz, vx] = rotateInPlane(vz, vx, -omegaY);
[lambda2, phi2] = cart2sph(vx, vy, vz);

% Compute the distance and azimuth from Point 1 to Point 2. This could be
% done before the rotations about X and Y, but if we wait until Point 1 has
% been brought to the Equator, we can be sure of getting a useful azimuth
% value.
[rng, az] = greatcircleinv(phi1, lambda1, phi2, lambda2, 1);

% Rotate about the X-axis by -omegaX, bringing Point 2 to the Equator
% (and leaving Point 1 fixed at phi1 = 0, lambda1 = 0).
omegaX = az - pi/2;

% At this point it should be possible to validate that the following
% computation gives lambda2 equal to rng and phi2 equal to 0.
%
%     [vy, vz] = rotateInPlane(vy, vz, -omegaX);
%     [lambda2, phi2] = cart2sph(vx, vy, vz)

% Compute a west-to-east small circle arc, centered on the poles, at
% latitude phi = bufwidth.
m = max(2,ceil(rng/(4*bufwidth)));
lambda = linspace(0, rng, m);
dx = cos(lambda);
dy = sin(lambda);
dz = sin(bufwidth) + zeros(size(dx));

% Reposition the eastern semicircular arc, centering it on
% lat = 0, lon = rng (== lambda2).
[cxEast, cyEast] = rotateInPlane(cxEast, cyEast, -rng);

% Trace the buffer polygon, keeping the Equatorial arc to its right:
%  * West-to-east small circle arc, centered on poles, lat = bufwidth
%  * Semicircular arc centered on eastern endpoint
%  * East-to-west small circle arc, centered on poles, lat = -bufwidth
%  * Semicircular arc centered on western endpoint
%  * Exact repetition of starting point
bx = [dx  cxEast  dx(end:-1:1)  cxWest  dx(1)];
by = [dy  cyEast  dy(end:-1:1)  cyWest  dy(1)];
bz = [dz  czEast  -dz           czWest  dz(1)];

% Rotate about X by omegaX.
[by, bz] = rotateInPlane(by, bz, omegaX);

% Rotate about Y by omegaY.
[bz, bx] = rotateInPlane(bz, bx, omegaY);

% Convert unit vectors to latitudes and longitudes.
[lambdab, phib] = cart2sph(bx, by, bz);

% Rotate about Z by omegaZ.
lambdab = lambdab + omegaZ;

%--------------------------------------------------------------------------

function [vx, vy] = rotateInPlane(vx, vy, omega)
% Transform the vector [vx, vy] under a clockwise coordinate system
% rotation through angle omega.

c = cos(omega);
s = sin(omega);

t = vx;

vx =  c .* t + s .* vy;
vy = -s .* t + c .* vy;
