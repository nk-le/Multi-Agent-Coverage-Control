function [latout,lonout] = track1(str,lat,lon,az,in4,in5,in6,in7)
%TRACK1  Geographic tracks from starting point, azimuth and range
% 
%   [LAT,LON] = TRACK1(LAT0,LON0,AZ) computes complete great circle
%   tracks on a sphere starting at the point LAT0, LON0 and proceeding
%   along the input azimuth, AZ.  The inputs can be scalar or column
%   vectors.  All inputs and outputs are in degrees.
%
%   [LAT,LON] = TRACK1(LAT0,LON0,AZ,ARCLEN) uses the input ARCLEN to
%   specify the arc length of the great circle track. ARCLEN is specified
%   in units of degrees of arc.  If ARCLEN is a column vector, then the
%   track is computed from the starting point, with positive distance
%   measured easterly.  If ARCLEN is a two column matrix, then the track is
%   computed starting at the range in the first column and ending at the
%   range in the second column.  If ARCLEN = [], then the complete track
%   is computed. Multiple tracks can be defined from a single starting
%   point by providing scalar LAT0 and LON0 and column vectors for AZ and
%   ARCLEN.
%
%   [LAT,LON] = TRACK1(LAT0,LON0,AZ,ARCLEN,ELLIPSOID) computes geodesic
%   tracks on the ellipsoid defined by ELLIPSOID.  ELLIPSOID is a reference
%   ellipsoid (oblate spheroid) object, a reference sphere object, or a
%   vector of the form [semimajor_axis, eccentricity]. ARCLEN must be
%   expressed in length units that match the units of the semimajor axis of
%   the ellipsoid, unless ELLIPSOID is [].  If ELLIPSOID is [], ARCLEN is
%   assumed to be in degrees of arc and the tracks are computed on a
%   sphere, as in the preceding syntax.
%
%   [LAT,LON] = TRACK1(LAT0,LON0,AZ,ANGLEUNITS),
%   [LAT,LON] = TRACK1(LAT0,LON0,AZ,ARCLEN,ANGLEUNITS), and
%   [LAT,LON] = TRACK1(LAT0,LON0,AZ,ARCLEN,ELLIPSOID,ANGLEUNITS) use
%   ANGLEUNITS to specify the angle units of the inputs and outputs.
%   ANGLEUNITS can be 'degrees' or 'radians'.
%
%   [LAT,LON] = TRACK1(LAT0,LON0,AZ,ARCLEN,ELLIPSOID,ANGLEUNITS,NPTS) uses
%   the scalar input NPTS to specify the number of points per track.  The 
%   default value of NPTS is 100.
%
%   [LAT,LON] = TRACK1(TRACKSTR,...) uses TRACKSTR to specify
%   great circle (geodesic) or rhumb line tracks.  If TRACKSTR is 'gc',
%   then great circle (geodesic) tracks are computed.  If TRACKSTR is 'rh',
%   then rhumb line tracks are computed.
%
%   MAT = TRACK1(...) returns a single output argument MAT such that
%   MAT = [LAT LON].  This is useful if only a single track is computed.
%
%   See also TRACK2, TRACKG, SCIRCLE1.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

if nargin > 0
    str = convertStringsToChars(str);
end

if nargin > 3
    az = convertStringsToChars(az);
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
elseif (nargin < 3  && ~ischar(str)) || (nargin == 3 && ischar(str))
    error(message('map:validate:invalidArgCount'))
elseif (nargin == 3 && ~ischar(str)) || (nargin == 4 && ischar(str))

    if ~ischar(str)       %  Shift inputs since str omitted by user
        az  = lon;
        lon = lat;
        lat = str;
        str = [];
    end

    rng = [];
    npts  = [];
    ellipsoid = [];
    units = [];

elseif (nargin == 4 && ~ischar(str)) || (nargin == 5 && ischar(str))

    if ~ischar(str)       %  Shift inputs since str omitted by user
        in4 = az;
        az  = lon;
        lon = lat;
        lat = str;
        str = [];
    end

    if ischar(in4)
        units = in4;
        ellipsoid = [];
        rng = [];
        npts = [];
    else
        units = [];
        ellipsoid = [];
        rng = in4;
        npts = [];
    end

elseif (nargin == 5 && ~ischar(str)) || (nargin == 6 && ischar(str))

    if ~ischar(str)       %  Shift inputs since str omitted by user
        in5 = in4;
        in4 = az;
        az  = lon;
        lon = lat;
        lat = str;
        str = [];
    end

    if ischar(in5)
        rng   = in4;
        units = in5;
        ellipsoid = [];
        npts = [];
    else
        rng   = in4;
        units = [];
        ellipsoid = in5;
        npts = [];
    end

elseif (nargin == 6 && ~ischar(str)) || (nargin == 7 && ischar(str))

    if ~ischar(str)       %  Shift inputs since str omitted by user
        in6 = in5;
        in5 = in4;
        in4 = az;
        az  = lon;
        lon = lat;
        lat = str;
        str = [];
    end

    rng   = in4;
    ellipsoid = in5;
    units = in6;
    npts = [];

elseif (nargin == 7 && ~ischar(str)) || (nargin == 8 && ischar(str))

    if ~ischar(str)       %  Shift inputs since str omitted by user
        in7 = in6;
        in6 = in5;
        in5 = in4;
        in4 = az;
        az  = lon;
        lon = lat;
        lat = str;
        str = [];
    end

    rng = in4;
    ellipsoid = in5;
    units = in6;
    npts = in7;
end

%  Test the track string

if isempty(str)
    str = 'gc';
else
    str = validatestring(str, {'gc','rh'}, 'TRACK1', 'TRACKSTR', 1);
end

%  Allow for scalar starting point, but vectorized azimuths.  Multiple
%  tracks starting from the same point

if length(lat) == 1 && length(lon) == 1 && ~isempty(az)
    lat = lat(ones(size(az)));
    lon = lon(ones(size(az)));
end

%  Empty argument tests

useSphericalDistance = isempty(ellipsoid);
if useSphericalDistance
    ellipsoid = [1 0];
else
    ellipsoid = checkellipsoid(ellipsoid,'TRACK1','ELLIPSOID');
end

if isempty(units)
    units = 'degrees';
else
    units = checkangleunits(units);
end

if isempty(npts)
    npts  = 100;
end

rhumbdefault = false;        %  Don't perform rhumb line range limit calcs
if isempty(rng)
    if useSphericalDistance
        rng = fromDegrees(units, [-180 180]);
    else
        rng = [0 2*pi]*ellipsoid(1);
    end

    rng = rng(ones([size(lat,1) 1]), :);
    if strcmp(str,'rh')
        rhumbdefault = true;  %  Perform rhumb line range limit calcs
    end
end

%  Dimension tests
if ~isequal(size(lat),size(lon),size(az))
    error(['map:' mfilename ':mapError'], ...
        'Inconsistent dimensions for lat, lon, and azimuth inputs.')
elseif ndims(lat) > 2 || size(lat,2) ~= 1
    error(['map:' mfilename ':mapError'], ...
        'Lat, lon, and azimuth inputs must be column vectors.')
elseif size(lat,1) ~= size(rng,1)
    error(['map:' mfilename ':mapError'], ...
        'Inconsistent dimensions for starting points and ranges.')
elseif ndims(rng) > 2 || size(rng,2) > 2
    error(['map:' mfilename ':mapError'], ...
        'Range input must have two columns or less')
end

%  Angle unit conversion

[lat, lon, az] = toRadians(units, lat, lon, az);

%  Convert the range to radians if working with spherical distances.
%  Otherwise, reckon will perform the conversion itself.

if useSphericalDistance   
    rng = toRadians(units, rng);
end

%  Expand the range vector
if rhumbdefault  %  Default limits for rhumb line calculation.
    %  Simple +/-180 does not guarantee a pole to pole rhumb line.
    indx1 = find( abs(cos(az))<eps ) ;    %  Tracks directly along parallels
    indx = 1:numel(az);
    indx(indx1) = [];  %  All other tracks
    negrng   = zeros(size(az));
    posrng   = zeros(size(az));

    if useSphericalDistance
        rec = lat;
    else
        rec = convertlat(ellipsoid, lat, 'geodetic', 'rectifying', 'nocheck');
    end
    negcolat = pi/2+rec;
    poscolat = pi/2-rec;

    negrng(indx) = -abs(negcolat(indx)./cos(az(indx)));
    posrng(indx) =  abs(poscolat(indx)./cos(az(indx)));

    posrng(indx1) = pi*cos(rec(indx1));  %  Directly along
    negrng(indx1) = -posrng(indx1);      %  parallels

    if ~useSphericalDistance    %  Convert from radians if necessary
        radius = rsphere('rectifying',ellipsoid);
        negrng = negrng*radius;
        posrng = posrng*radius;
    end
elseif size(rng,2) == 1
    % Single column range inputs
    negrng = zeros(size(rng));
    posrng = rng;
else
    % Two column range inputs (not rhumb default)
    negrng = rng(:,1);
    posrng = rng(:,2);
end

%  Use real(npts) to avoid a cumbersome warning for complex n in linspace
rng = zeros([size(negrng,1) npts]);
for i = 1:size(rng,1)
	rng(i,:) = linspace(negrng(i),posrng(i),real(npts));
end

%  Compute the tracks
%  Each track occupies a row of the output matrices.

biglat = lat(:,ones([1,size(rng,2)]) );
biglon = lon(:,ones([1,size(rng,2)]) );
bigaz  = az(:,ones([1,size(rng,2)]) );

[lattrk,lontrk] = reckon(str,biglat,biglon,rng,bigaz,ellipsoid,'radians');

%  Convert the results to the desired units
%  Transpose the reckon results so that each track occupies
%  one column of the output matrices.

[lattrk, lontrk] = fromRadians(units, lattrk', lontrk');

%  Set the output arguments
if nargout <= 1
    latout = [lattrk lontrk];
elseif nargout == 2
    latout = lattrk;
    lonout = lontrk;
end
