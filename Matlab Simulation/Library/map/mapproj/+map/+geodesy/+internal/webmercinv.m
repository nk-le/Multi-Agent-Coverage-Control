function [lat,lon] = webmercinv(x,y)
%WEBMERCINV WGS 84 Web Mercator Inverse Projection
%
%   [LAT,LON] = map.geodesy.internal.webmapinv(X,Y) unprojects points from
%   a WGS 84 "Web Mercator" projected coordinate reference system (EPSG
%   3857) to a WGS 84 geographic coordinate reference system (EPSG 4326).
%
%   Input Arguments
%   ---------------
%   X -- Projected x-coordinates (eastings) of one or more points in the
%     EPSG 3857 system, specified as a scalar value, vector, matrix, or N-D
%     array, in units of meters. Data Type: double
%
%   Y -- Projected y-coordinates (northings) of one or more points in the
%     EPSG 3857 system, specified as a scalar value, vector, matrix, or N-D
%     array, in units of meters. Data Type: double
%
%   Output Arguments
%   ----------------
%   LAT -- WGS 84 Geodetic latitude of the input points, returned as a
%     scalar value, vector, matrix, or N-D array, and expressed in degrees.
%
%   LON -- WGS 84 Longitude of the input points, returned as a scalar value
%     vector, matrix, or N-D array, and expressed in degrees.
%
%   Technical Definition
%   --------------------
%   See the help for map.geodesy.internal.webmercfwd.
%
%   See also map.geodesy.internal.webmercfwd, wgs84Ellipsoid

% Copyright 2015 The MathWorks, Inc.

spheroid = wgs84Ellipsoid;
R = spheroid.SemimajorAxis;
lat = asind(tanh(y/R));
lon = rad2deg(x/R);
