function h = scatterm(varargin)
%SCATTERM Project point markers with variable color and area
%
%   SCATTERM(LAT,LON,S,C) displays colored circles at the locations
%   specified by the vectors LAT and LON (which must be the same size).
%
%   S determines the area of each marker (in points^2). S can be a
%   vector the same length as LAT and LON or a scalar. If S is a scalar, 
%   MATLAB draws all the markers the same size. If S is empty, the
%   default size is used.
%
%   C determines the colors of the markers. When C is a vector the same
%   length as LAT and LON, the values in C are linearly mapped to the
%   colors in the current colormap. When C is a length(X)-by-3 matrix,
%   it directly specifies the colors of the markers as RGB values. C can
%   also be a color string. See ColorSpec.
%
%   SCATTERM(LAT,LON) draws the markers in the default size and color.
%   SCATTERM(LAT,LON,S) draws the markers at the specified sizes (S)
%   with a single color.
%   SCATTERM(...,M) uses the marker M instead of 'o'.
%   SCATTERM(...,'filled') fills the markers.
%
%   SCATTERM(AX,...) plots into axes AX instead of GCA. AX is a handle
%   to a map axes.
%
%   H = SCATTERM(...) returns a handle to an hggroup.
%
%   Example
%   -------
%   seamount = load('seamount.mat');
%   lat = seamount.y;
%   lon = seamount.x;
%   worldmap([-49 -47.5],[-150 -147.5])
%   scatterm(lat, lon, 5, seamount.z);
%   scaleruler

% Copyright 1996-2015 The MathWorks, Inc.

% Identify and validate map axes.
[ax, args] = axescheck(varargin{:});
if isempty(ax)
    latPosition = 1;
    ax = gca;
else
    latPosition = 2;
end
gcm(ax);

% Parse latitude-longitude inputs.
if numel(args) < 2
    error(message('MATLAB:narginchk:notEnoughInputs'));
end 
lat = args{1};
lon = args{2};
args(1:2) = [];

% Validate lat-lon vectors.
checklatlon(lat, lon, mfilename, 'LAT', 'LON', latPosition, latPosition + 1)

% Construct linked GeoScatterGroup and hggroup objects.
mapgraph = internal.mapgraph.GeoScatterGroup(ax, lat, lon, args{:});

if nargout > 0
    % Return handle to hggroup object.
    h = mapgraph.HGGroup;
end
