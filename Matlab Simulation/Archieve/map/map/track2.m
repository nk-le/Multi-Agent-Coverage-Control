function [latout,lonout] = track2(str,lat1,lon1,lat2,lon2,in5,in6,in7)
%TRACK2  Geographic tracks from starting and ending points
% 
%   [LAT,LON] = TRACK2(LAT1,LON1,LAT2,LON2) computes great circle tracks on
%   a sphere starting at the point LAT1, LON1 and ending at LAT2, LON2. The
%   inputs can be scalar or column vectors.  Multiple tracks can be defined
%   from a single starting point by providing scalar LAT1, LON1 inputs and
%   column vectors for LAT2, LON2.  All inputs and outputs are in degrees.
% 
%   [LAT,LON] = TRACK2(LAT1,LON1,LAT2,LON2,ELLIPSOID) computes geodesic
%   tracks on the ellipsoid defined by ELLIPSOID.  ELLIPSOID is a reference
%   ellipsoid (oblate spheroid) object, a reference sphere object, or a
%   vector of the form [semimajor_axis, eccentricity].  If ELLIPSOID is [],
%   a sphere is assumed.
% 
%   [LAT,LON] = TRACK2(LAT1,LON1,LAT2,LON2,ANGLEUNITS) and
%   [LAT,LON] = TRACK2(LAT1,LON1,LAT2,LON2,ELLIPSOID,ANGLEUNITS) use 
%   ANGLEUNITS to determine the units of the angle-valued inputs
%   and outputs.
% 
%   [LAT,LON] = TRACK2(LAT1,LON1,LAT2,LON2,ELLIPSOID,ANGLEUNITS,NPTS) uses
%   the scalar input NPTS to determine the number of points per track
%   computed.  The default value of NPTS is 100.
% 
%   [LAT,LON] = TRACK2(TRACKSTR,...) uses TRACKSTR to specify
%   great circle (geodesic) or rhumb line tracks.  If TRACKSTR = 'gc', then
%   great circle (geodesic) tracks are computed.  If TRACKSTR = 'rh', then
%   rhumb line tracks are computed.
% 
%   MAT = TRACK2(...) returns a single output argument MAT such that
%   MAT = [LAT LON].  This is useful if only a single track is computed.
% 
%   See also TRACK1, TRACKG, SCIRCLE2.

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

    if ~ischar(str)       %  Shift inputs since str omitted by user
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

    if ~ischar(str)       %  Shift inputs since str omitted by user
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

    if ~ischar(str)       %  Shift inputs since str omitted by user
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
    str = validatestring(str, {'gc','rh'}, 'TRACK2', 'TRACKSTR', 1);
end

%  Allow for scalar starting point, but vectorized azimuths.  Multiple
%  tracks starting from the same point

if (numel(lat1) == 1) && (numel(lon1)) == 1 && ~isempty(lat2)
    lat1 = lat1(ones(size(lat2)));
    lon1 = lon1(ones(size(lat2)));
end

%  Empty argument tests.  Set defaults

if isempty(ellipsoid)
    ellipsoid = [1 0];
else
    ellipsoid = checkellipsoid(ellipsoid,'TRACK2','ELLIPSOID');
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
elseif max(size(npts)) ~= 1
    error(['map:' mfilename ':mapError'], ...
        'Scalar npts required')
end

%  Angle unit conversion
[lat1, lon1, lat2, lon2] = toRadians(units, lat1, lon1, lat2, lon2);

[lattrk, lontrk] = doTrack2(str, lat1, lon1, lat2, lon2, ellipsoid, npts);

%  Convert the results to the desired units
[lattrk, lontrk] = fromRadians(units, lattrk, lontrk);

%  Set the output arguments
if nargout <= 1
     latout = [lattrk lontrk];
elseif nargout == 2
     latout = lattrk;
     lonout = lontrk;
end
