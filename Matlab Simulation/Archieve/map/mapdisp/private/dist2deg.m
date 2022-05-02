function deg = dist2deg(dist, units, sphere)
%DIST2DEG  Convert to spherical distance in degrees
%
%   DEG = DIST2DEG(DIST, UNITS, RADIUS) converts distances to degrees as
%   measured along a great circle on a sphere having the specified
%   radius.  DIST and RADIUS have the units of length or angle specified
%   by the string UNITS.  If UNITS is 'degrees' or 'radians', then DIST
%   itself is a spherical distance.
%
%   DEG = DIST2DEG(DIST, UNITS, SPHERE) converts distances to degrees,
%   as measured along a great circle on a sphere approximating an object
%   in the Solar System.  UNITS indicates the units of length used for
%   DIST.  SPHERE may be one of the following strings: 'sun', 'moon',
%   'mercury', 'venus', 'earth', 'mars', 'jupiter', 'saturn', 'uranus',
%   'neptune', or 'pluto', and is case-insensitive.

% Copyright 2007-2017 The MathWorks, Inc.


angleUnits = {'degrees','radians'};
k = find(strncmpi(deblank(units), angleUnits, numel(deblank(units))));
if numel(k) == 1
    % In case units is 'degrees' or 'radians'
    deg = toDegrees(angleUnits{k}, dist);
else
    % Assume that units specifies a length unit
    if ischar(sphere) || isStringScalar(sphere)
        % Convert to kilometers, then let km2deg take care of the rest
        deg = km2deg(unitsratio('km',units)*dist, sphere);
    else
        % DIST and SPHERE must have the same units, so
        % there is no dependency on the value of UNITS
        deg = rad2deg(dist/sphere);
    end
end
