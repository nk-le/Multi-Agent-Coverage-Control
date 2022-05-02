function [latmean,lonmean] = meanm(lat,lon,ellipsoid,units)
%MEANM  Mean location of geographic points
%
%   [LATBAR,LONBAR] = MEANM(LAT,LON) computes means for geographic data.
%   This corresponds to the geographic centroid of a data set, assuming
%   that the data are distributed on a sphere.  In contrast, MEAN assumes
%   that the data are distributed on a Cartesian plane. When LAT and LON
%   are vectors, a single mean location is returned.  When LAT and LON are
%   matrices, LATBAR and LONBAR are row vectors providing the mean
%   locations for each column of LAT and LON.  Higher dimensional arrays
%   are not allowed.  All inputs and outputs are in degrees.
%
%   [LATBAR,LONBAR] = MEANM(LAT,LON,ELLIPSOID) computes the geographic mean
%   on the ellipsoid defined by the input ELLIPSOID, which is a reference
%   ellipsoid (oblate spheroid) object, a reference sphere object, or a
%   vector of the form [semimajor_axis, eccentricity].  If omitted, the
%   unit sphere, ELLIPSOID = [1 0], is assumed.
%
%   [LATBAR,LONBAR] = MEANM(...,ANGLEUNITS) uses ANGLEUNITS to specify the
%   angle units of the inputs and outputs.  ANGLEUNITS can be 'degrees' or
%   'radians'.
%
%   MAT = MEANM(...) returns a single output, where MAT = [LATBAR,LONBAR].
%   This is particularly useful if the lat and lon inputs are vectors.
%
%  See also MEAN, STDM, STDIST.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown, W. Stumpf

narginchk(2, 4)

if nargin == 2
    ellipsoid = [];
    units = [];
elseif nargin == 3
    if ischar(ellipsoid) || isStringScalar(ellipsoid)
        units = ellipsoid;
        ellipsoid = [];
    else
        units = [];
    end
end

%  Empty argument tests

if isempty(units) || (isStringScalar(units) && strlength(units) == 0)
    units = 'degrees';
end

if isempty(ellipsoid)
    ellipsoid = [1 0];
else
    ellipsoid = checkellipsoid(ellipsoid,'MEANM','ELLIPSOID',3);
end

%  Input dimension tests

if ndims(lat)>2
	error(['map:' mfilename ':mapError'], ...
        'Latitude and longitude inputs limited to two dimensions.')
end

if ~isequal(size(lat),size(lon))
    error(message('map:validate:inconsistentSizes2','MEANM','LAT','LON'))
end

%  Convert inputs to radians.  Use an authalic sphere for
%  calculations.  Thus, the mean calculation is area-based,
%  since the authalic sphere has the same surface area as
%  the ellipsoid.

[lat, lon] = toRadians(units, lat, lon);
lat = convertlat(ellipsoid, lat, 'geodetic', 'authalic', 'nocheck');

%  Convert the input data to Cartesian coordinates.
%  Compute the centroid point by vector summing all Cartesian data.

[x,y,z]=sph2cart(lon,lat,ones(size(lat)));
[lonbar,latbar,radius]=cart2sph(sum(x),sum(y),sum(z));

%  Transform outputs to proper units.  Set longitude in -pi to pi range

latbar = convertlat(ellipsoid, latbar, 'authalic', 'geodetic', 'nocheck');
lonbar = wrapToPi(lonbar);

[latbar, lonbar] = fromRadians(units, latbar, lonbar);

%  Eliminate any points whose vector sum produces a point
%  which is near the center of the sphere or ellipsoid.  This
%  occurs when the data consists of only points and their
%  antipodes, and in this case, the centroid does not have any meaning.

indx = find(radius <= epsm('radians'));
if ~isempty(indx)
    warning('map:meanm:allPointsCancel', ...
'Data in at least one column consists of only points and their antipodes.')
	latbar(indx) = NaN;
    lonbar(indx) = NaN;
end

%  Set the output arguments

if nargout < 2
    latmean = [latbar lonbar];
elseif nargout == 2
    latmean = latbar;
    lonmean = lonbar;
end
