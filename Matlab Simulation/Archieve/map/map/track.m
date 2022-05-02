function [outlat,outlon]=track(str,lat,lon,in3,in4,in5)
%TRACK  Track segments to connect navigational waypoints
%
%   [LAT,LON] = TRACK(LAT0,LON0) connects waypoints given in navigation
%   track format with track segments.  The track segments are rhumb lines,
%   which is the navigationally common method.  All inputs and outputs are
%   in degrees.
%
%   [LAT,LON] = TRACK(LAT0,LON0,ELLIPSOID) computes the rhumb line tracks
%   on the ellipsoid defined by the input ELLIPSOID. ELLIPSOID is a
%   reference ellipsoid (oblate spheroid) object, a reference sphere
%   object, or a vector of the form [semimajor_axis, eccentricity].
%
%   [LAT,LON] = TRACK(LAT0,LON0,ANGLEUNITS) and
%   [LAT,LON] = TRACK(LAT0,LON0,ELLIPSOID,ANGLEUNITS) use
%   ANGLEUNITS to specify the angle units of the inputs and outputs.
%   ANGLEUNITS can be 'degrees' or 'radians'.
%
%   [LAT,LON] = TRACK(LAT0,LON0,ELLIPSOID,ANGLEUNITS,NPTS) uses the
%   scalar input NPTS to determine the number of points per track computed.
%   The default value of NPTS is 100.
%
%   [LAT,LON] = TRACK(TRACKSTR,...) uses TRACKSTR to define
%   either a great circle or rhumb line tracks.  If TRACKSTR is 'gc', then
%   the great circle tracks are computed.  If TRACKSTR is 'rh', then the
%   rhumb line tracks are computed.  If omitted, 'rh' is assumed.
%
%   [LAT,LON] = TRACK(MAT) and [LAT,LON] = TRACK(MAT,ANGLEUNITS), where
%   MAT = [LAT0 LON0], are equivalent to [LAT,LON] = TRACK(LAT0,LON0) and
%   [LAT,LON] = TRACK(LAT0,LON0,ANGLEUNITS).
%
%   MAT = TRACK(...) returns a single output argument MAT such that MAT =
%   [LAT LON].
%
%   See also GCWAYPTS, TRACK1, TRACK2, TRACKG.

% Copyright 1996-2019 The MathWorks, Inc.
% Written by:  E. Brown, E. Byrns

if nargin > 0
    str = convertStringsToChars(str);
end

if nargin > 1
    lat = convertStringsToChars(lat);
end

if nargin > 2
    lon = convertStringsToChars(lon);
end

if nargin > 3
    in3 = convertStringsToChars(in3);
end

if nargin > 4
    in4 = convertStringsToChars(in4);
end

if nargin == 0 || (nargin == 1 && ischar(str))
    
    error(message('map:validate:invalidArgCount'))

elseif (nargin == 1 && ~ischar(str)) || (nargin == 2 && ischar(str))

    if ~ischar(str)       %  Shift inputs since str omitted by user
        lat = str;
        str = [];
    end

    if size(lat,2) ~= 2 || ~ismatrix(lat)
        error(['map:' mfilename ':mapError'], ...
            'Input matrix must have two columns [lat lon]')
    else
        lon = lat(:,2);
        lat = lat(:,1);
    end

    ellipsoid = [];
    units = [];
    npts  = [];

elseif (nargin == 2 && ~ischar(str)) || (nargin == 3 && ischar(str))

    %  Shift inputs since str omitted by user
    if ~ischar(str)
        lon = lat;
        lat = str;
        str = [];
    end

    if ischar(lon)
        %  track(str,mat,ANGLEUNITS)  usage
        if size(lat,2) ~= 2 || ~ismatrix(lat)
            error(['map:' mfilename ':mapError'], ...
                'Input matrix must have two columns [lat lon]')
        else
            units = lon;
            lon = lat(:,2);
            lat = lat(:,1);
            ellipsoid = [];
            npts  = [];
        end

    else
        %  track(str,lat,lon)  usage
        ellipsoid = [];
        units = [];
        npts  = [];
    end

elseif (nargin == 3 && ~ischar(str)) || (nargin == 4 && ischar(str))

    %  Shift inputs since str omitted by user
    if ~ischar(str)
        in3  = lon;
        lon = lat;
        lat  = str;
        str  = [];
    end

    if ischar(in3)
        ellipsoid = [];
        units = in3;
        npts  = [];
    else
        ellipsoid = in3;
        units = [];
        npts  = [];
    end

elseif (nargin == 4 && ~ischar(str)) || (nargin == 5 && ischar(str))

    %  Shift inputs since str omitted by user
    if ~ischar(str)
        in4  = in3;
        in3  = lon;
        lon  = lat;
        lat  = str;
        str  = [];
    end

    ellipsoid = in3;
    units = in4;
    npts  = [];


elseif (nargin == 5 && ~ischar(str)) || (nargin == 6 && ischar(str))

    %  Shift inputs since str omitted by user
    if ~ischar(str)
        in5  = in4;
        in4  = in3;
        in3  = lon;
        lon  = lat;
        lat  = str;
        str  = [];
    end

    ellipsoid = in3;
    units = in4;
    npts  = in5;

end

if isempty(str)
    %  Default is rhumb line tracks
    str = 'rh';
else
    str = validatestring(str, {'gc','rh'}, 'TRACK', 'TRACKSTR', 1);
end

if isempty(ellipsoid)
    ellipsoid = [1 0];
else
    ellipsoid = checkellipsoid(ellipsoid,'TRACK','ELLIPSOID');
end

if isempty(units)
    units = 'degrees';
end

if isempty(npts)
    npts  = 30;
end

if ~isequal(size(lat),size(lon))
    error(message('map:validate:inconsistentSizes2','TRACK','LAT','LON'))
elseif any([min(size(lat)) min(size(lon))] ~= 1) || ...
       any([ndims(lat) ndims(lon)] > 2)
    error(['map:' mfilename ':mapError'], ...
        'Latitude and longitude inputs must vectors')
elseif max(size(lat)) == 1
    error(['map:' mfilename ':mapError'], ...
        'At least 2 lats and 2 longs are required')
end

validateattributes(npts,{'double'}, ...
    {'positive','scalar','integer'},'TRACK','NPTS')

[lat, lon] = toRadians(units, lat, lon);
[outlat, outlon] = doTrack(str, lat, lon, ellipsoid, npts);
[outlat, outlon] = fromRadians(units, outlat, outlon);

%  Set the output argument if necessary
if nargout < 2
    outlat = [outlat outlon];
end


function [outPhi, outLambda] = doTrack(trackstr, phi, lambda ,ellipsoid, npts)
% Core computations performed by TRACK.  All angles are in units of
% radians.  TRACKSTR can be 'gc' or 'rh'.

%  Ensure that phi and lambda are column vectors
phi = phi(:);
lambda = lambda(:);

%  Compute vectors of start and end points
startlats = phi(1:length(phi)-1);
endlats   = phi(2:length(phi));
startlons = lambda(1:length(lambda)-1);
endlons   = lambda(2:length(lambda));

[outPhi,outLambda] = doTrack2(...
    trackstr, startlats, startlons, endlats, endlons, ellipsoid, npts);

%  Link all tracks into a single NaN clipped vector
r = size(outPhi,1); 
outPhi(r+1,:) = NaN;
outLambda(r+1,:) = NaN;
outPhi = outPhi(:);
outLambda = outLambda(:);
