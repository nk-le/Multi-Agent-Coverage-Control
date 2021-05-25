function a = areaint(lat,lon,in3,in4)
%AREAINT Surface area of polygon on sphere or ellipsoid
%
%   A = AREAINT(LAT,LON) calculates the spherical surface area of the
%   polygon specified by the input vectors LAT, LON.  LAT and LON are in
%   degrees.  The calculation uses a line integral approach.  The output,
%   A, is the surface area fraction covered by the polygon on a unit
%   sphere.  Multiple polygons can be supplied provided that each polygon
%   is separated by a NaN in the input vectors. Accuracy of the integration
%   method is inversely proportional to the distance between polygon
%   vertices.
%
%   A = AREAINT(LAT,LON,ELLIPSOID) uses the input ELLIPSOID to describe the
%   sphere or ellipsoid.  ELLIPSOID is a reference ellipsoid (oblate
%   spheroid) object, a reference sphere object, or a vector of the form
%   [semimajor_axis, eccentricity].  The output, A, is in square units
%   corresponding to the length units of the semimajor axis.
%
%   A = AREAINT(...,ANGLEUNITS) uses the units specified by ANGLEUNITS.
%   ANGLEUNITS can be 'degrees' or 'radians'.
%
%   See also AREAMAT, AREAQUAD.

% Copyright 1996-2017 The MathWorks, Inc.

narginchk(2,4)
switch(nargin)
    case 2
	    units = [];
        ellipsoid = [];
    case 3
	    if ischar(in3) || isStringScalar(in3)
		    units = in3;
            ellipsoid = [];
	    else
		    units = [];
            ellipsoid = in3;
	    end
    case 4
		ellipsoid = in3;
        units = in4;
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
    ellipsoid = checkellipsoid(ellipsoid,mfilename,'ELLIPSOID',3);
    absolute_units = true;
end

% Validate LAT and LON
checklatlon(lat,lon,mfilename,'LAT','LON',1,2);

% Ensure that lat and lon are column vectors
lat = lat(:);
lon = lon(:);

%  Convert coordinates to radians, if necessary
%  Transform to the authalic sphere

[lat, lon] = toRadians(units, lat, lon);
lat = convertlat(ellipsoid, lat, 'geodetic', 'authalic', 'nocheck');
radius = rsphere('authalic',ellipsoid);

%  Ensure at a terminating NaN in the vectors

if ~isnan(lat(end))
    lat(end+1) = NaN;
end

if ~isnan(lon(end))
    lon(end+1) = NaN;
end

%  Ensure vectors don't begin with NaNs

if isnan(lat(1)) || isnan(lon(1))
	lat(1) = [];
	lon(1) = [];
end

%  Find segment demarcations

indx=find(isnan(lat));

%  Initialize area output vector

a(length(indx),1) = 0;

%  Perform area calculation for each segment

for k = 1:length(indx)
    if k == 1
        subs = 1:indx(k)-1;
    else
        subs = indx(k-1)+1:indx(k)-1;
    end
    a(k) = singleint(lat(subs),lon(subs));
end

%  Convert to absolute terms if the default radius was not used

if absolute_units
    a = a * 4*pi*radius^2;
end

%----------------------------------------------------------------------

function area = singleint(lat,lon)

% Compute the area of a single polygon.

% Ensure the path segment closes upon itself by
% repeating beginning point at the end.

lat(end+1) = lat(1);
lon(end+1) = lon(1);

% Set origin for integration.  Any point will do, so (0,0) used

lat0 = 0;
lon0 = 0;

% Get colatitude (a measure of surface distance as an angle)
% and azimuth of each point in segment from the arbitrary origin

[colat, az] = distance('gc',lat0,lon0,lat,lon,'radians');

% Calculate step sizes

daz=diff(az);
daz=wrapToPi(daz);

% Determine average surface distance for each step

deltas=diff(colat)/2;
colat=colat(1:length(colat)-1)+deltas;

% Integral over azimuth is 1-cos(colatitudes)

integrands=(1-cos(colat)).*daz;

% Integrate and save the answer as a fraction of the unit sphere.
% Note that the sum of the integrands will include a factor of 4pi.

area = abs(sum(integrands))/(4*pi); % Could be area of inside or outside

% Define the inside to be the side with less area.

area = min(area,1-area);
