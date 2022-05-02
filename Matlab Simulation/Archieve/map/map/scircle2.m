function [latout,lonout] = scircle2(str,lat1,lon1,lat2,lon2,in5,in6,in7)
%SCIRCLE2  Small circles from center and perimeter
% 
%   [LAT,LON] = SCIRCLE2(LAT1,LON1,LAT2,LON2) computes small circles (on a
%   sphere) with centers at the point LAT1, LON1 and points on the circles
%   at LAT2, LON2.  The input and output latitudes and longitudes are in
%   units of degrees.  The inputs can be scalar or column vectors.
% 
%   [LAT,LON] = SCIRCLE2(LAT1,LON1,LAT2,LON2,ELLIPSOID) computes the small
%   circle on the ellipsoid defined by the input ELLIPSOID, rather than
%   assuming a sphere.  ELLIPSOID is a reference ellipsoid (oblate
%   spheroid) object, a reference sphere object, or a vector of the form
%   [semimajor_axis, eccentricity].  If ELLIPSOID is [], a sphere is
%   assumed.
% 
%   [LAT,LON] = SCIRCLE2(LAT1,LON1,LAT2,LON2,ANGLEUNITS) and
%   [LAT,LON] = SCIRCLE2(LAT1,LON1,LAT2,LON2,ELLIPSOID,ANGLEUNITS) use
%   ANGLEUNITS to determine the units of the angle-valued inputs and
%   outputs. ANGLEUNITS can be 'degrees' or 'radians'.
% 
%   [LAT,LON] = SCIRCLE2(LAT1,LON1,LAT2,LON2,ELLIPSOID,ANGLEUNITS,NPTS)
%   uses the scalar input NPTS to determine the number of points per track
%   computed.  The default value of NPTS is 100.
% 
%   [LAT,LON] = SCIRCLE2(TRACKSTR,...) uses TRACKSTR to define
%   either a great circle or rhumb line radius.  If TRACKSTR is 'gc',
%   then small circles are computed.  If TRACKSTR is 'rh', then
%   the circles with radii of constant rhumb line distance are computed.
%   If omitted, 'gc' is assumed.
% 
%   MAT = SCIRCLE2(...) returns a single output argument where
%   MAT = [LAT LON].  This is useful if only a single circle is computed.
% 
%   Multiple circles can be defined from a single center point by
%   providing scalar LAT1, LON1 inputs and column vectors for the points
%   on the circumference, LAT2, lon2.
% 
%   See also SCIRCLE1, SCIRCLEG, TRACK2.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

if nargin > 0
    str = convertStringsToChars(str);
end

if nargin > 4
    lon2 = convertStringsToChars(lon2);
end

if nargin > 5
    in5 = convertStringsToChars(in5);
end

if nargin > 6
    in6 = convertStringsToChars(in6);
end

if nargin == 0
    error(message('map:validate:invalidArgCount'))
    
elseif (nargin < 4  && ~ischar(str)) || (nargin == 4 && ischar(str))
	 error(message('map:validate:invalidArgCount'))
     
elseif (nargin == 4 && ~ischar(str)) || (nargin == 5 && ischar(str))

    if ~ischar(str)       %  Shift inputs since str omitted by user
		lon2 = lat2;
        lat2 = lon1;
		lon1 = lat1;
        lat1 = str;
		str  = [];
    end

	ellipsoid = [];
    units = [];
    npts  = [];

elseif (nargin == 5 && ~ischar(str)) || (nargin == 6 && ischar(str))

    if ~ischar(str)
        %  Shift inputs since str omitted by user
	    in5  = lon2;
        lon2 = lat2;
		lat2 = lon1;
        lon1 = lat1;
		lat1 = str;
        str  = [];
    end

    if ischar(in5)
	    ellipsoid = [];
        units = in5;
        npts  = [];
    else
	    ellipsoid = in5;
        units = [];
        npts  = [];
    end


elseif (nargin == 6 && ~ischar(str)) || (nargin == 7 && ischar(str))

    if ~ischar(str)
        %  Shift inputs since str omitted by user
	    in6  = in5;
        in5  = lon2;
		lon2 = lat2;
        lat2 = lon1;
		lon1 = lat1;
        lat1 = str;
		str  = [];
    end

    ellipsoid = in5;
    units = in6;
    npts  = [];


elseif (nargin == 7 && ~ischar(str)) || (nargin == 8 && ischar(str))

    if ~ischar(str)
        %  Shift inputs since str omitted by user
	    in7  = in6;
        in6  = in5;
	    in5  = lon2;
        lon2 = lat2;
		lat2 = lon1;
        lon1 = lat1;
		lat1 = str;
        str  = [];
    end

    ellipsoid = in5;
    units = in6;
    npts  = in7;

end


%  Test the track string

if isempty(str)
    str = 'gc';
else
    str = validatestring(str, {'gc','rh'}, 'SCIRCLE2', 'TRACKSTR', 1);
end

%  Allow for scalar starting point, but vectorized azimuths.  Multiple
%  circles starting from the same point

if length(lat1) == 1 && length(lon1) == 1 && ~isempty(lat2)
    lat1 = lat1(ones(size(lat2)));   lon1 = lon1(ones(size(lat2)));
end

%  Empty argument tests.  Set defaults

if isempty(ellipsoid)
    ellipsoid = [1 0];
else
    ellipsoid = checkellipsoid(ellipsoid,'SCIRCLE2','ELLIPSOID');
end

if isempty(units)
    units = 'degrees';
else
    units = checkangleunits(units);
end

if isempty(npts)
    npts  = 100;
end

%  Dimension tests

if ~isequal(size(lat1),size(lon1),size(lat2),size(lon2))
      error(['map:' mfilename ':mapError'], ...
          'Inconsistent dimensions on latitude and longitude inputs')
end

validateattributes(npts, {'double'}, {'scalar'}, 'SCIRCLE2','NPTS')

% Ensure that inputs are column vectors

lat1 = lat1(:);
lon1 = lon1(:);
lat2 = lat2(:);
lon2 = lon2(:);

%  Angle unit conversion

[lat1, lon1, lat2, lon2] ...
    = toRadians(units, lat1, lon1, lat2, lon2);

%  Compute azimuth and range

rng = distance(str,lat1,lon1,lat2,lon2,ellipsoid,'radians');
az  = 2*pi;
az = az(ones([size(lat1,1) 1]));

%  Compute circles

[latc,lonc] = scircle1(str,lat1,lon1,rng,az,ellipsoid,'radians',npts);

%  Convert the results to the desired units

[latc, lonc] = fromRadians(units, latc, lonc);

%  Set the output arguments

if nargout <= 1
     latout = [latc lonc];
elseif nargout == 2
     latout = latc;
     lonout = lonc;
end
