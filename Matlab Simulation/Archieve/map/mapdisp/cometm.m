function cometm(lat,lon,p)
%COMETM Project 2-D comet plot on map axes
%
% COMETM will be removed in a future release. Instead, use the following:
%
%       [x,y] = mfwdtran(lat,lon); 
%       comet(x,y,p) 
%
%  COMETM(lat,lon) projects a comet plot in two dimensions
%  (z = 0) on the current map axes.  A comet plot is an animated
%  graph in which a circle (the comet head) traces the data points on the
%  screen.  The comet body is a trailing segment that follows the head.
%  The tail is a solid line that traces the entire function.  The
%  lat and lon vectors must be in the same units as specified in
%  the map structure.
%
%  COMETM(lat,lon,p) uses the input p to specify a comet body size of
%  p*length(lat)
%
%  See also COMET3M, COMET

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

warning(message('map:removing:cometm','COMETM'))

validateattributes(lat, {'double'}, {'vector','2d'}, 'COMETM', 'LAT', 1)
validateattributes(lon, {'double'}, {'vector','2d'}, 'COMETM', 'LON', 2)

if nargin == 2
    p = [];
else
    validateattributes(p, {'double'}, {'scalar'}, 'COMETM', 'P', 4)
end


%  Test for a map axes and get the map structure
mstruct = gcm;

%  Project the line data
[x,y,~,~] = map.crs.internal.mfwdtran(mstruct,lat,lon,[],'line');

%  Display the comet plot
nextmap;
if isempty(p) 
    comet(x,y)
else
    comet(x,y,p)
end
