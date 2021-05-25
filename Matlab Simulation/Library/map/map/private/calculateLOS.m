function [vis0, dist, h, lattrk, lontrk, x1, z1, x2, z2] ...
    = calculateLOS(F, R, lat1, lon1, lat2, lon2, oalt, talt, ...
        observerAltitudeIsAGL, targetAltitudeIsAGL, actualradius, apparentradius)
% Perform the line-of-sight computations needed by LOS2 and VIEWSHED.

% Copyright 2014-2015 The MathWorks, Inc.

% Sample at slightly less than the elevation grid spacing.
spacingInDegrees = 0.9 / sampleDensity(R);

% Intermediate points along the great circle arc between start and end.
[lattrk, lontrk, arclenInRadians] ...
    = sampleGreatCircle(lat1, lon1, lat2, lon2, spacingInDegrees);

dist = actualradius(1) * arclenInRadians;

% Elevation profile between the start and end points.
h = interpolate(F, R, lattrk, lontrk);

% Visibility of points along the profile between the start and end points.
[vis0, x1, z1, x2, z2] = losprofile(dist, h, oalt, talt, ...
    observerAltitudeIsAGL, targetAltitudeIsAGL, apparentradius);

%--------------------------------------------------------------------------

function [lat, lon, arclenInRadians] ...
    = sampleGreatCircle(lat1, lon1, lat2, lon2, spacingInDegrees)

%  Compute sort of maximum angular distance between the end points.
maxdist = max(abs(lat2 - lat1), abs(lon2 - lon1));

if maxdist > spacingInDegrees
    %  Insert points using linear interpolation.
    npts = 1 + ceil(maxdist/spacingInDegrees);
    
    [lat, lon, arclenInRadians] = doTrack2(deg2rad(lat1), deg2rad(lon1), ...
        deg2rad(lat2), deg2rad(lon2), npts);
    
    lat = rad2deg(lat);
    lon = rad2deg(lon);
    
    %  Use exact endpoint.
    lat(end) = lat2;
    lon(end) = lon2;
else
    lat = [lat1; lat2];
    lon = [lon1; lon2];
    arclenInRadians = greatcircleinv(deg2rad(lat1), deg2rad(lon1), ...
        deg2rad(lat2), deg2rad(lon2));
end

%--------------------------------------------------------------------------

function [phiTrack, lambdaTrack, arclenInRadians] ...
    = doTrack2(phi1, lambda1, phi2, lambda2, npts)
% Interpolate regularly spaced points along a great circle.

[fullArcLength, az] = greatcircleinv(phi1, lambda1, phi2, lambda2);

arclenInRadians = linspace(0, fullArcLength, npts)';

[phiTrack, lambdaTrack] = greatcirclefwd(...
    phi1, lambda1, az, arclenInRadians);

lambdaTrack = wrapToPi(lambdaTrack);

%--------------------------------------------------------------------------

function [arclen, az] = greatcircleinv(phi1, lambda1, phi2, lambda2)
% Great circle distance and azimuth between points on a sphere, using the
% Haversine Formula for distance.  All angles are in radians.

cosphi1 = cos(phi1);
cosphi2 = cos(phi2);

h = sin((phi2-phi1)/2).^2 ...
    + cosphi1 .* cosphi2 .* sin((lambda2-lambda1)/2).^2;

arclen = 2 * asin(sqrt(h));

if nargout > 1
    az = atan2(cosphi2 .* sin(lambda2-lambda1),...
        cosphi1 .* sin(phi2) - sin(phi1) .* cosphi2 .* cos(lambda2-lambda1));
end

%--------------------------------------------------------------------------

function [phi, lambda] = greatcirclefwd(phi0, lambda0, az, arclen)
% Points on a great circles given specified start point, azimuths and
% spherical distances.  All angles are in radians.

% Reference
% ---------
% J. P. Snyder, "Map Projections - A Working Manual,"  US Geological Survey
% Professional Paper 1395, US Government Printing Office, Washington, DC,
% 1987, pp. 29-32.

cosPhi0 = cos(phi0);
sinPhi0 = sin(phi0);
cosAz = cos(az);
cosDelta = cos(arclen);
sinDelta = sin(arclen);

phi = asin( sinPhi0.*cosDelta + cosPhi0.*sinDelta.*cosAz );

lambda = lambda0 + atan2( sinDelta.*sin(az),...
                      cosPhi0.*cosDelta - sinPhi0.*sin(arclen).*cosAz );

%--------------------------------------------------------------------------

function v =  interpolate(F, R, lat, lon)
% Use the griddentInterpolant object F which is defined in the intrinsic
% coordinate system referred to by raster reference object R.

% Interpolate bilinearly in intrinsic coordinates.
xi = longitudeToIntrinsicX(R, lon);
yi = latitudeToIntrinsicY(R, lat);

% Snap in all points that fall within distance 0.5 of an edge, so that
% we get a non-NaN value for them from interp2.
xi(0.5 <= xi & xi < 1) = 1;
yi(0.5 <= yi & yi < 1) = 1;

sz = R.RasterSize;
M = sz(1);
N = sz(2);

xi(N < xi & xi <= N + 0.5) = N;
yi(M < yi & yi <= M + 0.5) = M;

v = F(yi,xi);

%--------------------------------------------------------------------------

function [vis, x, z, x2, z2] = losprofile(arclen, zin, oalt, talt, ...
    observerAltitudeIsAGL, targetAltitudeIsAGL, apparentradius)

arclen = arclen(:)';
zin = zin(:)';

if ~isinf(apparentradius)
    [x, z] = adjustterrain(arclen, zin, apparentradius);
else
    x = arclen;
    z = zin;
end

% Convert AGL observer altitude to MSL 
if observerAltitudeIsAGL
    %  Observer is at first location
    oalt =  z(1) + oalt;
end

% Shift terrain so observer is at altitude 0, and terrain altitudes are relative
% to the observer

z = z - oalt;  % Observer is at first location

% Compute the angles of sight from the observer to each point on the profile.
% measured positive up from the center of the sphere

ang = pi + atan2(z,x);
if x(1) == 0 && z(1) == 0
    ang(1) = pi/2;  % Look straight down at observer's location
end

% Find the cumulative maximum:  maxtohere(k) equals max(ang(1:k))
maxangtohere = cummax(ang);

% Adjust the angles for the altitude of the target height above ground level 
% or sea level and redo calculation of angles. This makes the obscuring factor
% the terrain only, and not any target height. To model stuff above the terrain 
% like a forest canopy, pass in a z vector that has the added heights.

if targetAltitudeIsAGL
    if ~isinf(apparentradius)
        [x2, z2] = adjustterrain(arclen, zin + talt, apparentradius);
        z2 = z2 - oalt;
    else
        z2 = z + talt;
        x2 = x;
    end
else
    if ~isinf(apparentradius)
        [x2, z2] = adjustterrain(arclen, talt + zeros(size(zin)), apparentradius);
        z2 = z2 - oalt;
    else
        z2 = (talt)*ones(size(zin)) - oalt;
        x2 = x;
    end
end

% Compute line of sight angles again.

ang2 = pi + atan2(z2,x2);
if x2(1) == 0 && z2(1) == 0
    ang2(1) = pi/2;  % Look straight down at observer's location
end

% Visible are points that rise above the maximum angle of LOS of intervening 
% terrain.

vis = (ang2 >= maxangtohere);

% Visibility of first point below terrain needs a special test, since
% it always passes the "angles of terrain up to here" test.

if (z2(1) < z(1)) && (z(1) < 0)
    vis(1) = false;
end

vis = vis(:);

%-----------------------------------------------------------------------

function [x, z] = adjustterrain(arclen, zin, apparentradius)

% Adjust the terrain slice for the curvature of the sphere. The radius
% may potentially be different from the actual body, for example to
% model refraction of radio waves.

r = apparentradius + zin;
phi = arclen/apparentradius;
x = r .* sin(phi);
z = r .* cos(phi) - apparentradius;
