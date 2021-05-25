function d = departure(lon1,lon2,lat,in4,in5)
%DEPARTURE  Departure of longitudes at specific latitudes
%
%   D = DEPARTURE(LON1,LON2,LAT) computes the departure distance from LON1
%   to LON2 at the input latitude LAT.  Departure is the distance along a
%   specific parallel between two meridians.  The inputs are in units of
%   degrees, and D is in degrees of arc on a sphere.
%
%   D = DEPARTURE(LON1,LON2,LAT,ELLIPSOID) computes the departure for
%   points on the ellipsoid defined by the input ELLIPSOID.  ELLIPSOID is a
%   reference ellipsoid (oblate spheroid) object, a reference sphere
%   object, or a vector of the form [semimajor_axis, eccentricity]. D has
%   the same units as the semimajor axis of the ellipsoid.
%
%   D = DEPARTURE(LON1,LON2,LAT,ANGLEUNITS) and
%   D = DEPARTURE(LON1,LON2,LAT,ELLIPSOID,ANGLEUNITS) use the input
%   ANGLEUNITS to determine the units of the angle-valued inputs and
%   outputs.  ANGLEUNITS is either a string scalar or a character vector.
%
%   See also DISTANCE.

% Copyright 1996-2019 The MathWorks, Inc.

narginchk(3,5)

if ~isequal(size(lon1),size(lon2),size(lat))
    error(message('map:validate:inconsistentSizes3',...
        'DEPARTURE','LON1','LON2','LAT'))
end

if nargin == 3
    ellipsoid = [1 0];
    useSphericalDistance = true;
    units = 'degrees';
elseif nargin == 4
    if ischar(in4)
        ellipsoid = [1 0];
        units = checkangleunits(in4);
        useSphericalDistance = true;
    else
        ellipsoid = map.geodesy.internal.validateEllipsoid(in4,'DEPARTURE','ELLIPSOID',4);
        units = 'degrees';
        useSphericalDistance = false;
    end
else
    ellipsoid = map.geodesy.internal.validateEllipsoid(in4,'DEPARTURE','ELLIPSOID',5);
    units = checkangleunits(in5);
    useSphericalDistance = false;
end

if strcmp(units,'degrees')
    divisor = 360;
else
    divisor = 2*pi;
end

dlon = lon2 - lon1;
dlon = min(mod(dlon,divisor), mod(-dlon,divisor));

if ~useSphericalDistance && strcmp(units,'degrees')
    dlon = deg2rad(dlon);
end

d = dlon .* rcurve('parallel', ellipsoid, lat, units);
