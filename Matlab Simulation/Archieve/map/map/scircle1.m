function [latout,lonout] = scircle1(str,lat,lon,rng,in4,in5,in6,in7)
%SCIRCLE1  Small circles from center, range and azimuth
% 
%   [LAT,LON] = SCIRCLE1(LAT0,LON0,RADIUS) computes small circles (on a
%   sphere) with a center at the point LAT0, LON0 and radius RADIUS.  The
%   inputs can be scalar or column vectors.  The input and output latitudes
%   and longitudes are in units of degrees, and RADIUS is in degrees of arc
%   length on a sphere. Multiple circles can be defined from a single
%   starting point by providing scalar LAT0, LON0 inputs a column for
%   RADIUS.
% 
%   [LAT,LON] = SCIRCLE1(LAT0,LON0,RADIUS,AZ) uses the input AZ to define
%   the small circle arcs computed.  The arc azimuths are measured
%   clockwise from due north.  If AZ is a column vector, then the
%   arc length is computed from due north.  If AZ is a two-column
%   matrix, then the small circle arcs are computed starting at the
%   azimuth in the first column and ending at the azimuth in the
%   second column.  If AZ = [], then a complete small circle is computed.
%   Multiple circles can be defined from a single starting point by
%   providing scalar LAT0, LON0 inputs and column vectors for RADIUS and AZ.
% 
%   [LAT,LON] = SCIRCLE1(LAT0,LON0,RADIUS,AZ,ELLIPSOID) computes small
%   circles on the ellipsoid defined by the input ELLIPSOID, rather than
%   assuming a sphere. ELLIPSOID is a reference ellipsoid (oblate spheroid)
%   object, a reference sphere object, or a vector of the form
%   [semimajor_axis, eccentricity].  RADIUS must be in units of length that
%   match the units of the semimajor axis, unless ELLIPSOID is empty.  If
%   ELLIPSOID is [], then RADIUS is interpreted as an angle and the small
%   circles are computed on a sphere, as in the preceding syntax.
% 
%   [LAT,LON] = SCIRCLE1(LAT0,LON0,RADIUS,ANGLEUNITS),
%   [LAT,LON] = SCIRCLE1(LAT0,LON0,RADIUS,AZ,ANGLEUNITS), and
%   [LAT,LON] = SCIRCLE1(LAT0,LON0,RADIUS,AZ,ELLIPSOID,ANGLEUNITS) use
%   ANGLEUNITS to determine the units of the angle-values inputs
%   and outputs.  ANGLEUNITS can be 'degrees' or 'radians'.
% 
%   [LAT,LON] = SCIRCLE1(LAT0,LON0,RADIUS,AZ,ELLIPSOID,ANGLEUNITS,NPTS)
%   uses the scalar input NPTS to determine the number of points per small
%   circle computed.  The default value of NPTS is 100.
% 
%   [LAT,LON] = SCIRCLE1(TRACKSTR,...) uses TRACKSTR to define
%   either a great circle (geodesic) or rhumb line radius.  If TRACKSTR is
%   'gc', then small circles are computed.  If TRACKSTR is 'rh', then the
%   circles with radii of constant rhumb line distance are computed. If
%   omitted, 'gc' is assumed.
% 
%   MAT = SCIRCLE1(...) returns a single output argument where
%   MAT = [LAT LON].  This is useful if only a single circle is computed.
% 
%   See also SCIRCLE2, SCIRCLEG, TRACK1.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

if nargin > 0
    str = convertStringsToChars(str);
end

if nargin > 3
    rng = convertStringsToChars(rng);
end

if nargin > 4
    in4 = convertStringsToChars(in4);
end

if nargin > 5
    in5 = convertStringsToChars(in5);
end

if nargin > 6
    in6 = convertStringsToChars(in6);
end

if nargin == 0
    error(message('map:validate:invalidArgCount'))
    
elseif (nargin < 3  && ~ischar(str)) ||  (nargin == 3 && ischar(str))
    error(message('map:validate:invalidArgCount'))

elseif (nargin == 3 && ~ischar(str)) || (nargin == 4 && ischar(str))

    if ~ischar(str)
        %  Shift inputs since str omitted by user
		rng = lon;
        lon = lat;
		lat = str;
        str = [];
    end

	npts  = [];
    az    = [];
	ellipsoid = [];
    units = [];

elseif (nargin == 4 && ~ischar(str)) || (nargin == 5 && ischar(str))

    if ~ischar(str)
        %  Shift inputs since str omitted by user
		in4 = rng;
        rng = lon;
		lon = lat;
        lat = str;
		str = [];
    end

    if ischar(in4)
         az    = [];
         ellipsoid = [];
         units = in4;
         npts  = [];
    else
		 az    = in4;
         ellipsoid = [];
         units = [];
         npts  = [];
    end

elseif (nargin == 5 && ~ischar(str)) || (nargin == 6 && ischar(str))

    if ~ischar(str)
        %  Shift inputs since str omitted by user
		in5 = in4;
        in4 = rng;
		rng = lon;
        lon = lat;
		lat = str;
        str = [];
    end

    if ischar(in5)
		az    = in4;
        units = in5;
        ellipsoid = [];
        npts  = [];
    else
        az    = in4;
        units = [];
        ellipsoid = in5;
        npts  = [];
    end

elseif (nargin == 6 && ~ischar(str)) || (nargin == 7 && ischar(str))

   if ~ischar(str)
       %  Shift inputs since str omitted by user
		in6 = in5;
        in5 = in4;
		in4 = rng;
        rng = lon;
		lon = lat;
        lat = str;
		str = [];
    end

    az    = in4;
    ellipsoid = in5;
    units = in6;
    npts = [];

elseif (nargin == 7 && ~ischar(str)) || (nargin == 8 && ischar(str))

    if ~ischar(str)
        %  Shift inputs since str omitted by user
		in7 = in6;
        in6 = in5;
		in5 = in4;
        in4 = rng;
		rng = lon;
        lon = lat;
		lat = str;
        str = [];
    end

    az    = in4;
    ellipsoid = in5;
    units = in6;
    npts = in7;

end

%  Test the track string

if isempty(str)
    str = 'gc';
else
    str = validatestring(str, {'gc','rh'}, 'SCIRCLE1', 'TRACKSTR', 1);
end


%  Allow for scalar starting point, but vectorized azimuths.  Multiple
%  circles starting from the same point

if isscalar(lat) && isscalar(lon) && ~isempty(rng)
    lat = lat(ones(size(rng)));
    lon = lon(ones(size(rng)));
end

useSphericalDistance = isempty(ellipsoid);
if useSphericalDistance
    useSphericalDistance = true;
    ellipsoid = [1 0];
else
    ellipsoid = checkellipsoid(ellipsoid,'SCIRCLE1','ELLIPSOID');
end

if isempty(units)
    units = 'degrees';
else
    units = checkangleunits(units);
end

if isempty(npts)
    npts  = 100;
end

if isempty(az)
     az = fromDegrees(units, [0 360]);
     az = az(ones([size(lat,1) 1]), :);
end

%  Dimension tests

if ~isequal(size(lat),size(lon),size(rng))
    error(message('map:validate:inconsistentSizes3', ...
        'SCIRCLE1','LAT0','LON0','RADIUS'))

elseif ndims(lat) > 2 || size(lat,2) ~= 1
    error(['map:' mfilename ':mapError'], ...
        'LAT0, LON0, and RADIUS inputs must be column vectors.')

elseif size(lat,1) ~= size(az,1)
    error(['map:' mfilename ':mapError'], ...
        'Inconsistent dimensions for starting points and azimuths.')

elseif ndims(az) > 2 || size(az,2) > 2
    error(['map:' mfilename ':mapError'], ...
        'Azimuth input must have two columns or less.')
end

%  Angle unit conversion

[lat, lon, az] = toRadians(units, lat, lon, az);

%  Convert the range to radians if no radius or semimajor axis provided
%  Otherwise, reckon will take care of the conversion of the range inputs

if useSphericalDistance
    rng = toRadians(units, rng);
end

%  Expand the azimuth inputs

if size(az,2) == 1
    %  Single column azimuth inputs
    negaz = zeros(size(az));
    posaz = az;

else
    %  Two column azimuth inputs
    negaz = az(:,1);
    posaz = az(:,2);
end

%  Use real(npts) to avoid a cumbersome warning for complex n in linspace

az = zeros([size(negaz,1) npts]);
for i = 1:size(az,1)
	
%  Handle case where limits give more than half of the circle.
%  Go clockwise from start to end. 	
	
	if negaz(i) > posaz(i)  
		posaz(i) = posaz(i)+2*pi;
	end
		
	az(i,:) = linspace(negaz(i),posaz(i),real(npts));	
end

%  Compute the circles.
%  Each circle occupies a row of the output matrices.

biglat = lat(:,ones([1,size(az,2)]) );
biglon = lon(:,ones([1,size(az,2)]) );
bigrng = rng(:,ones([1,size(az,2)]) );

if strcmp(str,'gc')
    if ellipsoid(2) ~= 0
        [latc,lonc] = geodesicfwd(biglat, biglon, az, bigrng, ellipsoid);
    else
        [latc, dlon] = greatCircleForward(biglat, bigrng/ellipsoid(1), az);
        lonc = biglon + dlon;
    end    
else
    [latc,lonc] = rhumblinefwd(biglat, biglon, az, bigrng, ellipsoid);
end
lonc = wrapToPi(lonc);

%  Convert the results to the desired units

[latc, lonc] = fromRadians(units, latc', lonc');

%  Set the output arguments

if nargout <= 1
     latout = [latc lonc];
elseif nargout == 2
     latout = latc;
     lonout = lonc;
end

%--------------------------------------------------------------------------

function [phi, dlambda] = greatCircleForward(phi0, delta, az)
% Great circle forward computation in radians

cosdelta = cos(delta);
sindelta = sin(delta);

cosphi0 = cos(phi0);
sinphi0 = sin(phi0);

cosAz = cos(az);
sinAz = sin(az);

phi = asin(sinphi0.*cosdelta + cosphi0.*sindelta.*cosAz);
dlambda = atan2(sindelta.*sinAz, cosphi0.*cosdelta - sinphi0.*sindelta.*cosAz);
