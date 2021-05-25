function comet3m(lat,lon,z,p)
%COMET3M Project 3-D comet plot on map axes
%
% COMETM will be removed in a future release. Instead, use the following:
%
%       [x,y,z] = mfwdtran(lat,lon,z); 
%       comet3(x,y,z,p) 
%
%  COMET3M(lat,lon,z) projects a comet plot in three dimensions
%  on the current map axes.  A comet plot is an animated graph
%  in which a circle (the comet head) traces the data points on the
%  screen.  The comet body is a trailing segment that follows the head.
%  The tail is a solid line that traces the entire function.  The
%  lat and lon vectors must be in the same units as specified in
%  the map structure.
%
%  COMET3M(lat,lon,z,p) uses the input p to specify a comet body
%  size of p*length(lat)
%
%  See also COMETM, COMET3

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

warning(message('map:removing:comet3m','COMET3M'))

validateattributes(lat, {'double'}, {'vector','2d'}, 'COMET3M', 'LAT', 1)
validateattributes(lon, {'double'}, {'vector','2d'}, 'COMET3M', 'LON', 2)
validateattributes(z,   {'double'}, {'vector','2d'}, 'COMET3M', 'Z', 3)

if nargin == 3
    p = [];
else
    validateattributes(p, {'double'}, {'scalar'}, 'COMET3M', 'P', 4)
end

%  Test for scalar z data
%  Comet3 won't accept all data in single z plane, so use z(1) as a work-around
if length(z) == 1
    z = z(ones(size(lat)));
    z(1) = z(1)-1E-6;
end

%  Test for a map axes and get the map structure
mstruct = gcm;

%  Project the line data
[x,y,z,~] = map.crs.internal.mfwdtran(mstruct,lat,lon,z,'line');

%  Display the comet plot
nextmap;
if isempty(p)
    comet3(x,y,z)
else
    comet3(x,y,z,p)
end
