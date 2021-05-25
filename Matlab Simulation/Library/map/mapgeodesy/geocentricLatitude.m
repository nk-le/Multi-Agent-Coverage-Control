function psi = geocentricLatitude(phi, f, angleUnit)
%geocentricLatitude Convert geodetic to geocentric latitude
%
%   PSI = geocentricLatitude(PHI, F) returns the geocentric latitude
%   corresponding to geodetic latitude PHI on an ellipsoid with
%   flattening F.
%
%   PSI = geocentricLatitude(PHI, F, angleUnit) specifies the units of
%   input PHI and output PSI.
%
%   Examples
%   --------
%   % Compute the geocentric latitude corresponding to a geodetic latitude
%   % of 45 degrees on the WGS 84 ellipsoid
%   s = wgs84Ellipsoid;
%   geocentricLatitude(45, s.Flattening)
%
%   % Compute the geocentric latitude corresponding to a geodetic latitude
%   % of pi/3 radians on the WGS 84 ellipsoid
%   s = wgs84Ellipsoid;
%   geocentricLatitude(pi/3, s.Flattening, 'radians')
%
%   Input Arguments
%   ---------------
%   PHI -- Geodetic latitude of one or more points, specified as a scalar
%     value, vector, matrix, or N-D array. Values must be in units that
%     match the input argument angleUnit, if supplied, and in degrees,
%     otherwise. Data Types: single | double
%
%   F -- Flattening of reference spheroid, specified as a scalar value.
%     Data Type: single | double
%
%   angleUnit -- Unit of angle, specified as 'degrees' (default), or
%      'radians'. Data Type: char
%
%   Output Argument
%   ---------------
%   PSI -- Geocentric latitudes of one or more points, returned as a
%     scalar value, vector, matrix, or N-D array. Values are in units that
%     match the input argument angleUnit, if supplied, and in degrees,
%     otherwise.
%
%   See also geodeticLatitudeFromGeocentric,
%      parametricLatitude,
%      map.geodesy.AuthalicLatitudeConverter,
%      map.geodesy.ConformalLatitudeConverter,
%      map.geodesy.IsometricLatitudeConverter,
%      map.geodesy.RectifyingLatitudeConverter

% Copyright 2012-2019 The MathWorks, Inc.

% Reference
% ---------
% John P. Snyder, "Map Projections - A Working Manual,"  US Geological
% Survey Professional Paper 1395, US Government Printing Office,
% Washington, DC, 1987, page 17.

if f == 0
    % Perfect sphere:
    % Avoid round off in the trig round-trip and ensure an exact identity.
    psi = phi;
else
    t = (1 - f)^2;
    inDegrees = (nargin < 3 || map.geodesy.isDegree(angleUnit));
    if inDegrees
        psi = atan2d(t*sind(phi), cosd(phi));
    else
        psi = atan2(t*sin(phi), cos(phi));
    end
end
