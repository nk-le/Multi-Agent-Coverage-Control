function [lat,lon] = interpm(lat, lon, maxsep, method, angleunit)
%INTERPM  Densify latitude-longitude sampling in lines or polygons
%
%   [DENSELAT,DENSELON] = INTERPM(LAT,LON,MAXSEP) inserts additional points
%   into vectors latitude (LAT) and longitude (LON) if adjacent points are
%   separated by more than the tolerance MAXSEP. New points are spaced
%   linearly, in both latitude and longitude, between existing points.
%   LAT, LON, and MAXSEP are specified in degrees.
%
%   [DENSELAT,DENSELON] = INTERPM(__,METHOD), where METHOD is 'gc', inserts
%   new points along great circles. Where METHOD is 'rh', INTERPM inserts
%   new points along rhumb lines. The default method, linear spacing in
%   latitude and longitude, can be specified as 'lin'.
%
%   [DENSELAT,DENSELON] = INTERPM(__,METHOD,ANGLEUNIT), where ANGLEUNIT is
%   'radians', specifies LAT, LON, and MAXSEP in radians.
%
%  See also GEOINTERP, INTRPLAT, INTRPLON, LINSPACE

% Copyright 1996-2019 The MathWorks, Inc.

narginchk(3,5)

if ~isequal(size(lat),size(lon))
    error(message('map:validate:inconsistentSizes2','INTERPM','LAT','LON'))
end

validateattributes(maxsep, {'double'}, {'scalar'}, 'INTERPM', 'MAXSEP', 3)

lat = ignoreComplex(lat, 'interpm', 'lat');
lon = ignoreComplex(lon, 'interpm', 'lon');
maxsep = ignoreComplex(maxsep, 'interpm', 'maxdiff');

if nargin < 4
    method = 'lin';
else
    method = validatestring(method, {'gc','rh','lin'}, 'INTERPM', 'METHOD', 4);
end

if nargin < 5
    angleunit = 'degrees';
else
    angleunit = checkangleunits(angleunit);
end

switch method
    case 'gc'
        [lat, lon] = densifyGreatCircle(lat, lon, maxsep, angleunit);
    case 'rh'
        [lat, lon] = densifyRhumbline(lat, lon, maxsep, angleunit);
    otherwise
        [lat, lon] = densifyLinear(lat, lon, maxsep);
end
