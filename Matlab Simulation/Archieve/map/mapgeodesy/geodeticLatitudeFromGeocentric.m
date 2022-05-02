function phi = geodeticLatitudeFromGeocentric(psi, f, angleUnit)
%geodeticLatitudeFromGeocentric Convert geocentric to geodetic latitude
%
%   PHI = geodeticLatitudeFromGeocentric(PSI, F) returns the geodetic
%   latitude corresponding to geocentric latitude PSI on an ellipsoid with
%   flattening F.
%
%   PHI = geodeticLatitudeFromGeocentric(PSI, F, angleUnit) specifies the
%   units of input PSI and output PHI.
%
%   Example
%   -------
%   % Compute the geodetic latitude corresponding to a geocentric latitude
%   % of 45 degrees on the WGS 84 ellipsoid
%   s = wgs84Ellipsoid;
%   geodeticLatitudeFromGeocentric(45, s.Flattening)
%
%   % Compute the geodetic latitude corresponding to a geocentric latitude
%   % of pi/3 radians on the WGS 84 ellipsoid
%   s = wgs84Ellipsoid;
%   geodeticLatitudeFromGeocentric(pi/3, s.Flattening, 'radians')
%
%   Input Arguments
%   ---------------
%   PSI -- Geocentric latitude of one or more points, specified as a scalar
%     value, vector, matrix, or N-D array. Values must be in units that
%     match the input argument angleUnit, if supplied, and in degrees,
%     otherwise. Data Types: single | double
%
%   F -- Flattening of reference spheroid, specified as a scalar value.
%     Data Type: double
%
%   angleUnit -- Unit of angle, specified as 'degrees' (default), or
%      'radians'. Data Type: char
%
%   Output Argument
%   ---------------
%   PHI -- Geodetic latitudes of one or more points, returned as a
%     scalar value, vector, matrix, or N-D array. Values are in units that
%     match the input argument angleUnit, if supplied, and in degrees,
%     otherwise.
%
%   See also geocentricLatitude,
%      geodeticLatitudeFromParametric,
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
    phi = psi;
else
    t = (1 - f)^2;
    inDegrees = (nargin < 3 || map.geodesy.isDegree(angleUnit));
    if inDegrees
        phi = atan2d(sind(psi), t*cosd(psi));
    else
        phi = atan2(sin(psi), t*cos(psi));
    end
end
