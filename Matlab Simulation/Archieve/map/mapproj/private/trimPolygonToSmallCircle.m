function [latTrimmed, lonTrimmed] = ...
    trimPolygonToSmallCircle(lat, lon, latCenter, lonCenter, radius, inc)
%TRIMPOLYGONTOSMALLCIRCLE Trim lat-lon polygon to small circle
%
%   [latTrimmed, lonTrimmed] = ...
%       trimPolygonToSmallCircle(lat, lon, latCenter, lonCenter, radius, inc)
%   trims the polygon defined by vectors LAT and LON to the small circle
%   defined by (latCenter, lonCenter) and RADIUS.  LAT and LON may contain
%   multiple rings separated by NaNs.  Outer rings should be clockwise,
%   inner rings counterclockwise.  INC is the distance increment to be used
%   to define the edges of trimmed polygons that intersect edge of the
%   small circle itself.  All inputs and outputs are assumed to be in units
%   of radians.

% Copyright 2005-2018 The MathWorks, Inc.

% Keep track of the shape of the input vectors, because polyjoin will
% automatically convert everything to column vectors.
rowVectorInput = (size(lat,2) > 1);
lat = lat(:);
lon = lon(:);

% Clamp latitudes
lat(lat < -pi/2) = -pi/2;
lat(lat >  pi/2) =  pi/2;
latCenter(lat < -pi/2) = -pi/2;
latCenter(lat >  pi/2) =  pi/2;

% Make sure lat and lon arrays are NaN-terminated.
nanTerminatedInput = isnan(lon(end));
if ~nanTerminatedInput
    lon(end+1,1) = NaN;
    lat(end+1,1) = NaN;
end

% Set the tolerance for closing nearly-closed rings to 5 degrees.
tolClose = 5 * pi/180;

% Pre-process lat-lon polygons.
[lat, lon] = preprocessLatLonPolygons(lat, lon, tolSnap, tolClose);

% Make sure that radius is slightly less than pi.  This buffer allows us
% to construct a ring around the antipode, if necessary. Set the buffer
% width to 0.5 degrees.
bufferWidth = 0.5 * (pi/180);
if radius > (pi - bufferWidth)
    radius = radius - bufferWidth;
end

% Transform latitude-longitude to range-azimuth.
[rng, az] = latlon2rngaz(lat, lon, latCenter, lonCenter);

% Save a copy of the input polygon.
rngIn = rng;
azIn = az;

% Trim range-azimuth vectors such that rng <= radius, leaving "dangling
% ends" along the circumference of the circle.
[az, rng] = truncateCurveOnCircle(rad2deg(az), rng, radius);
az = deg2rad(az);
if all(isnan(rng))
    rng = [];
    az = [];
end

% When trimming a topologically-consistent, multi-part polygon to a
% small circle centered on the projection origin (the "trimming
% circle"), we need to determine when, in order to properly enclose all
% interior areas in the projected map plane, it's necessary to add a
% ring that traces the trimming circle and encloses the origin. There
% are four such cases.
if ~isempty(rng)
    % Trace curves that have been disconnected by the truncation process,
    % interpolating additional vertices along the circumference.
    [rng, az, curvesTouchCircle] = closePolygonInCircle(rng, az, radius, inc);
    if ~curvesTouchCircle
        % Check to see if there's a ring (after the trimming step above)
        % that encloses the trimming circle itself. This check is necessary
        % only if function closePolygonInCircle has not already closed a
        % ring that touches the trimming circle.
        if (map.internal.signedPolygonArea(rng.*cos(-az), rng.*sin(-az)) < 0)
            % All the "outermost" rings are counter-clockwise and thus
            % enclose the trimming circle itself; enclose them within a
            % clockwise ring tracing the circumference of the circle.
            [rngCircle, azCircle] = smallCircle(radius, inc);
            rng = [rng; NaN; rngCircle];
            az  = [ az; NaN; azCircle];
        end
    end
else
    % All the inputs have been trimmed away, but check the full set of data
    % to see if the origin (along with the entire interior of the trimming
    % circle) falls on the inside of the input polygon.
    % if originFallsInside(rngIn, azIn)
    if (map.internal.signedPolygonArea((pi-rngIn).*cos(azIn), (pi-rngIn).*sin(azIn)) < 0)
        % Return a clockwise ring tracing the circumference of the circle.
        [rng, az] = smallCircle(radius, inc);
    end
end

% Make sure terminating NaNs haven't been lost.
if ~isempty(rng) && ~isnan(rng(end))
    rng(end+1,1) = NaN;
    az(end+1,1) = NaN;
end

% Transform range-azimuth back to latitude-longitude.
[latTrimmed, lonTrimmed] = rngaz2latlon(rng, az, latCenter, lonCenter);

% Restore shape if necessary.
if rowVectorInput
    latTrimmed = latTrimmed';
    lonTrimmed = lonTrimmed';
end

%-----------------------------------------------------------------------

% Tolerance for snapping to limits.
function tol = tolSnap()
tol = 10*eps(pi);

%-----------------------------------------------------------------------

function [rng, az] = smallCircle(radius, inc)
% Return a ring enclosing a small circle with the specified radius.

n = ceil(2*pi/inc);
az = 2*pi*(0:n)'/n;
rng = radius + zeros(size(az));

%--------------------------------------------------------------------------

function [rng, az, closureNeeded] = closePolygonInCircle(rng, az, radius, inc)
% Trace and re-connect open curves which start and/or end at the
% trimming radius. Be sure to work in azimuth modulo 2*pi.

[first,last] = internal.map.findFirstLastNonNan(az);

% Identify open curves that start and/or end at rng == radius, allowing
% for round off of azimuth values during a previous unwrapping step.
isOpen = (rng(first) == radius | rng(last) == radius) ...
    & ~(rng(first) == rng(last)  ...
        & abs(wrapToPi(az(first) - az(last))) < 100*eps(pi));

closureNeeded = any(isOpen);
if closureNeeded
    % Number of vertices needed to interpolate a full circle and then some.
    nCircumference = ceil(4*pi/inc);
    
    % Allocate output arrays, allowing for additional vertices.
    rngTraced = NaN(numel(rng) + nCircumference,1);
    azTraced = rngTraced;
    
    % Indices for open curves
    firstOpen = first(isOpen);
    lastOpen  = last(isOpen);

    % Construct a lookup table which, given an open curve index k
    % returns the index of the open curve next(k) whose start point
    % coincides with or follows (in terms of increasing azimuth, modulo
    % 2*pi) curve k's end point.
    next = nextCurveLookup(rng, az, radius, firstOpen, lastOpen);
    
    % Trace the open curves, copying vertices into rngTraced and
    % azTraced.  n, a positive, scalar integer indicates where to start
    % when copying addition vertices (from closed curves) into rngTraced
    % and azTraced.
    [rngTraced, azTraced, n] = traceOpenCurves(rng, az, ...
        firstOpen, lastOpen, next, rngTraced, azTraced, radius, inc);
    
    % Append curves that were closed already.
    [rngTraced, azTraced] = appendClosedCurves(rng, az, ...
        first(~isOpen), last(~isOpen), rngTraced, azTraced, n + 1);  
    
    % Correct for any excess allocation.
    [rng, az] = removeExtraNanSeparators(rngTraced, azTraced);
    
    % Wrap the azimuths.
    az = mod(az, 2*pi);

    % Remove duplicate vertices.
    duplicate = [diff(az)==0 & diff(rng)==0; false];
    az(duplicate) = [];
    rng(duplicate) = [];
end

%--------------------------------------------------------------------------

function next = nextCurveLookup(rng, az, radius, firstOpen, lastOpen)
% Construct a lookup table which, given an open curve index k
% returns the index of the open curve next(k) whose start point
% coincides with or follows (in terms of increasing azimuth, modulo
% 2*pi) curve k's end point.

tolAzimuth = 100*eps(pi);
tolRange = eps(10);

% Start points as column vectors
rs = rng(firstOpen);
as = az(firstOpen);

% End points as row vectors
re = rng(lastOpen)';
ae = az(lastOpen)';

endsOnCircle   = (re == radius);
startsOnCircle = (rs == radius);

aeCircle = ae(endsOnCircle);
asCircle = as(startsOnCircle);

% Expand into n-by-n arrays.
n = numel(firstOpen);
nOnes = ones(1,n);

rs = rs(:,nOnes);
as = as(:,nOnes);

re = re(nOnes,:);
ae = ae(nOnes,:);

% n-by-n logical connects is true when an end point coincides
% (or nearly coincides) with a start point.
connects = (abs(wrapToPi(as - ae)) < tolAzimuth) ...
    & ((re == rs) | (re < radius & rs < radius & abs(re-rs) < tolRange));

% Account also for the case in which the start and end points are
% distinct, but a start point on the circle immediately follows an end
% point when the circle is traversed in a clockwise direction.
n = numel(aeCircle);
nOnes = ones(1,n);
asCircle = asCircle(:,nOnes);
aeCircle = aeCircle(nOnes,:);
[~,nextOnCircle] = min(mod(asCircle - aeCircle, 2*pi));
connectsOnCircle = false(n,n);
for k = 1:numel(nextOnCircle)
    connectsOnCircle(nextOnCircle(k),k) = true;
end

% Combine results for both types of connectivity.
connects(startsOnCircle, endsOnCircle) = connectsOnCircle;
[next, ~] = find(connects);

%--------------------------------------------------------------------------

function [rLinked, aLinked, n] = traceOpenCurves(rng, az, ...
    firstOpen, lastOpen, next, rLinked, aLinked, radius, inc)
% Trace to link up open curves and add vertices on circumference of circle.

traced = false(size(firstOpen));
nOpen = numel(traced);
nTraced = 0;
k = 1; % Index to current open curve
n = 1; % Index to current position in output vertex arrays
f = 1; % Index to start of current curve in set of linked curves
while any(~traced)
    nTraced = nTraced + 1;
    map.internal.assert(nTraced <= nOpen, 'map:topology:tracingFailedToConverge')
    
    if traced(k)
        k = find(~traced);
        k = k(1);
        n = n + 1; % Allow for NaN-separator
    end
    s = firstOpen(k);
    e = lastOpen(k);
    m = n + e - s;
    rLinked(n:m) = rng(s:e);
    aLinked(n:m) = az(s:e);
    traced(k) = true;
    k1 = k;
    k = next(k);
    if (rng(lastOpen(k1)) == radius) && (rng(firstOpen(k)) == radius)
        % Curves end and start on circle:
        %   Insert extra vertices along the circumference.
        azNew = interpolateAzimuths(k1, k, firstOpen, lastOpen, rng, az, radius, inc);
        n = m + 1;
        m = n + numel(azNew) - 1;
        rLinked(n:m) = radius;
        aLinked(n:m) = azNew;
    end
    if traced(k)
        % Close up curve and replicate first vertex if needed.
        m = m + 1;
        rLinked(m) = rLinked(f);
        aLinked(m) = aLinked(f);
        rLinked(m+1) = NaN;
        aLinked(m+1) = NaN;
        f = m + 2;
    end
    n = m + 1;
end

%--------------------------------------------------------------------------

function azNew = interpolateAzimuths(k1, k, firstOpen, lastOpen, rng, az, radius, inc)
% Adaptively choose an increment in azimuth at which to insert extra
% vertices based on the mean separation of vertices in the last part of the
% previous segment (including up to 10 vertices) and first part of the next
% segment (again, including up to 10 vertices). In any case, keep the
% vertex density at least a dense as indicated by the nominal increment,
% inc. Then construct a vector of azimuths to insert between the vertices
% lastOpen(k1) and firstOpen(k).

eprev = lastOpen(k1);
snext = firstOpen(k);

az1 = mod(az(eprev),2*pi);
az2 = mod(az(snext),2*pi);

nmax = 10;

nprev = eprev - firstOpen(k1);
sprev = eprev - min(nprev, nmax);

nnext = lastOpen(k) - snext;
enext = snext + min(nnext, nmax);

[yprev, xprev] = pol2cart(az(sprev:eprev), rng(sprev:eprev));
[ynext, xnext] = pol2cart(az(snext:enext), rng(snext:enext));

xdiff = [diff(xprev); diff(xnext)];
ydiff = [diff(yprev); diff(ynext)];

delta = mean(hypot(xdiff, ydiff));
if ~isempty(delta) && delta > 0
    inc = min(inc, delta/radius);
end

dAzimuth = mod(az2 - az1, 2*pi);
numVertices = floor(dAzimuth / inc);
if numVertices > 0
    inc = dAzimuth / (numVertices + 1);
    azNew = wrapTo2Pi(az1 + (1:numVertices)' * inc);
else
    azNew = reshape([], [0 1]);
end

%--------------------------------------------------------------------------

function [u, v, n] = appendClosedCurves( ...
    x, y, firstClosed, lastClosed, u, v, n)
% Copy closed curves from NaN-separated vertex arrays (x,y) to
% NaN-separated vertex arrays (u,v). The positive integer n is the index
% of a starting vertex in (u,v), n.

% Adapted from toolbox/map/map/private/gluePolygonsOnVerticalEdges.m

for k = 1:numel(firstClosed)
    % First and last indices of k-th closed curve in (x,y).
    s = firstClosed(k);
    e = lastClosed(k);
    
    % Compute index m for (u,v) such that n:m is the same size as s:e
    m = n + e - s;
    
    % Copy vertices from k-th closed curve.
    u(n:m) = x(s:e);
    v(n:m) = y(s:e);
    
    % Advance by 2 instead of 1, leaving a NaN-separator in u and v to
    % separate this curve from the next one.
    u(m+1) = NaN;
    v(m+1) = NaN;
    n = m + 2;
end

%--------------------------------------------------------------------------

function [rng, az] = latlon2rngaz(lat, lon, latCenter, lonCenter)
% Transform latitude-longitude to range-azimuth and unwrap the azimuths.
% Note simple optimization for polar projections.

if latCenter >= pi/2
    % Centered on north pole
    rng = pi/2 - lat;
    az = -lon;
elseif latCenter <= -pi/2
    % Centered on south pole
    rng = lat + pi/2;
    az  = lon;
else
    [rng, az] = greatCircleInverse(latCenter, lat, lon - lonCenter);
end
az = unwrapMultipart(az);

% For rings in which azimuths don't wrap, restore exact match between
% first and last elements.
[first,last] = internal.map.findFirstLastNonNan(az);
nonWrapping = abs(az(last) - az(first)) < pi;
az(last(nonWrapping)) = az(first(nonWrapping));
rng(last(nonWrapping)) = rng(first(nonWrapping));

%--------------------------------------------------------------------------

function [lat, lon] = rngaz2latlon(rng, az, latCenter, lonCenter)
% Transform range-azimuth to latitude-longitude.

if latCenter >= pi/2
    lat = pi/2 - rng;
    lon = -az;
elseif latCenter <= -pi/2
    lat = rng - pi/2;
    lon = az;
else
    [lat, dlon] = greatCircleForward(latCenter, rng, az);
    lon = lonCenter + dlon;
end
lon = wrapToPi(lon);

%--------------------------------------------------------------------------

function [phi, dlambda] = greatCircleForward(phi0, delta, az)
% Great circle forward computation in radians. Local function copied from
% scircle1 and ellipse1.

cosdelta = cos(delta);
sindelta = sin(delta);

cosphi0 = cos(phi0);
sinphi0 = sin(phi0);

cosAz = cos(az);
sinAz = sin(az);

phi = asin(sinphi0.*cosdelta + cosphi0.*sindelta.*cosAz);
dlambda = atan2(sindelta.*sinAz, cosphi0.*cosdelta - sinphi0.*sindelta.*cosAz);

%--------------------------------------------------------------------------

function [rho, az] = greatCircleInverse(phi1, phi2, deltaLambda)

cosPhi1 = cos(phi1);
cosPhi2 = cos(phi2);

sinPhi1 = sin(phi1);
sinPhi2 = sin(phi2);

deltaPhi = phi2 - phi1;

h = sin(deltaPhi/2).^2 + cosPhi1 .* cosPhi2 .* sin(deltaLambda/2).^2;

rho = 2 * asin(sqrt(h));

az = greatCircleAzimuth(cosPhi1, sinPhi1, cosPhi2, sinPhi2, deltaLambda);

%--------------------------------------------------------------------------

function az = greatCircleAzimuth(cosPhi1, sinPhi1, cosPhi2, sinPhi2, deltaLambda)
% Input deltaLambda and output AZ are in radians. This is a elementwise function.
% Adapted from local function in scxsc.

az = atan2(cosPhi2 .* sin(deltaLambda),...
    cosPhi1 .* sinPhi2 - sinPhi1 .* cosPhi2 .* cos(deltaLambda));
