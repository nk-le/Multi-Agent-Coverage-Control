function [lat, lon] = preprocessLatLonPolygons(lat, lon, tolSnap, tolClose)

% Copyright 2009 The MathWorks, Inc.

% Remove extraneous NaN separators, just in case.
[lat, lon] = removeExtraNanSeparators(lat, lon);

% Make sure the longitudes are unwrapped.
lon = unwrapMultipart(lon);

% Remove duplicate vertices.
duplicate = [diff(lat)==0 & diff(lon)==0; false];
lat(duplicate) = [];
lon(duplicate) = [];

% Preprocess any polygons that touch either pole (or both), inserting an
% extra polar vertex if needed.
northPoleLat =  pi/2;
southPoleLat = -pi/2;
[lat, lon] = adjustPolarVertices(lat, lon, northPoleLat, tolSnap);
[lat, lon] = adjustPolarVertices(lat, lon, southPoleLat, tolSnap);

% Close up nearly-closed rings. This also happens when trimLatitudes
% calls trimPolygonToVerticalLine, but we need it sooner than that.
[lat, lon] = closeNearlyClosedRings(lat, lon, tolClose, @checkEndPoints);

% Eliminate any longitude wrapping reintroduced by the closure process.
lon = unwrapMultipart(lon);

%----------------------------------------------------------------------

function [endPointsCoincide, endPointsWithinTolerance] ...
    = checkEndPoints(latFirst, lonFirst, latLast, lonLast, tol)

dist = greatcircledist(latFirst, lonFirst, latLast, lonLast, 1);
endPointsCoincide = (dist < eps(2*pi));
endPointsWithinTolerance = (dist < tol);

%----------------------------------------------------------------------

function rng = greatcircledist(lat1, lon1, lat2, lon2, r)

% Calculate great circle distance between points on a sphere using the
% Haversine Formula.  LAT1, LON1, LAT2, and LON2 are in radians.  RNG is a
% length and has the same units as the radius of the sphere, R.  (If R is
% 1, then RNG is effectively arc length in radians.)

a = sin((lat2-lat1)/2).^2 + cos(lat1) .* cos(lat2) .* sin((lon2-lon1)/2).^2;
rng = r * 2 * atan2(sqrt(a),sqrt(1 - a));
