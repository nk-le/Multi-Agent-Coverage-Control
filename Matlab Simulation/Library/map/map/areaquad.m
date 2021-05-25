function a = areaquad(lat1,lon1,lat2,lon2,in5,in6)
%AREAQUAD Surface area of latitude-longitude quadrangle
%
%   A = AREAQUAD(LAT1,LON1,LAT2,LON2) returns the surface area of the
%   geographic quadrangle bounded by the parallels LAT1 and LAT2 and the
%   meridians LON1 and LON2. The output area is a fraction of the unit
%   sphere's area of 4*pi, so the result ranges from 0 to 1. The latitude
%   and longitude inputs are in degrees.
%
%   A = AREAQUAD(LAT1,LON1,LAT2,LON2,ELLIPSOID) uses the input ELLIPSOID to
%   describe the sphere or ellipsoid.  ELLIPSOID is a reference ellipsoid
%   (oblate spheroid) object, a reference sphere object, or a vector of the
%   form [semimajor_axis, eccentricity]. When ELLIPSOID is input, the
%   resulting area is given in terms of the square of the unit of length
%   used to define the ellipsoid. For example, if the ellipsoid
%   referenceEllipsoid('grs80','kilometers') is used, the resulting area
%   is in square kilometers. The default ellipsoid is the unit sphere.
%
%   A = AREAQUAD(...,ANGLEUNITS) uses the units specified by ANGLEUNITS for
%   the latitudes and longitudes.  ANGLEUNITS can be 'degrees' or
%   'radians'.
%
%  See also AREAINT, AREAMAT.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Brown, E. Byrns

narginchk(4,6)
if nargin==4
	units = [];
    ellipsoid = [];
elseif nargin==5
	if ischar(in5) || isStringScalar(in5)
		units = in5;
        ellipsoid = [];
	else
		units = [];
        ellipsoid = in5;
	end
elseif nargin==6
	ellipsoid=in5;
    units=in6;
end

%  Empty argument tests

if isempty(units) || (isStringScalar(units) && strlength(units) == 0)
    units  = 'degrees';
end

% Return a result in absolute units when an ellipsoid has been supplied.
% Otherwise the result is normalized to the surface area of a sphere.
if isempty(ellipsoid)
    ellipsoid = [1 0];
    absolute_units = false;
else
    ellipsoid = checkellipsoid(ellipsoid,mfilename,'ELLIPSOID',5);
    absolute_units = true;
end

%  Input dimension tests
validateattributes(lat1,{'double'},{'real'},mfilename,'LAT1',1);
validateattributes(lon1,{'double'},{'real'},mfilename,'LON1',2);
validateattributes(lat2,{'double'},{'real'},mfilename,'LAT2',3);
validateattributes(lon2,{'double'},{'real'},mfilename,'LON2',4);

if ~isequal(size(lat1),size(lon1),size(lat2),size(lon2))
    error('map:areaquad:latlonSizeMismatch', ...
        'Latitude and longitude inputs must all match in size.');
end

%  Convert angles to radians and transform to the authalic sphere

[lat1,lon1,lat2,lon2] = toRadians(units,lat1,lon1,lat2,lon2);
lat1 = convertlat(ellipsoid, lat1, 'geodetic', 'authalic', 'nocheck');
lat2 = convertlat(ellipsoid, lat2, 'geodetic', 'authalic', 'nocheck');
radius = rsphere('authalic',ellipsoid);

%  Compute the surface area as a fraction of a sphere

a = abs(lon1-lon2) .* abs(sin(lat1)-sin(lat2)) / (4*pi);

%  Convert to absolute terms if the default radius was not used

if absolute_units
    a = a * 4*pi*radius^2;
end
