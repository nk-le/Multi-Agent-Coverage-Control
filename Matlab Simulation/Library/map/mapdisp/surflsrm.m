function [hout, msg] = surflsrm(lat,lon,map,s,rgbs,clim)
%SURFLSRM 3-D lighted shaded relief of geolocated data grid
%
%  SURFLSRM(lat,lon,map) displays the general matrix map colored according
%  to elevation and surface slopes.  By default, shading is based on a light
%  to the east (90 deg.)  at an elevation of 45 degrees.  Also by default,
%  the colormap is constructed from 16 colors and 16 grays.  Lighting is
%  applied before the data is projected.  The current axes must have a valid
%  map projection definition.
%
%  SURFLSRM(lat,lon,map,[azim elev]) displays the general matrix map with
%  the light coming from the specified azimuth and elevation.  Angles are
%  specified in degrees, with the azimuth measured clockwise from North,
%  and elevation up from the zero plane of the surface.
%
%  SURFLSRM(lat,lon,map,[azim elev],cmap) displays the general matrix map
%  using the provided colormap.  The number of grayscales is chosen to keep
%  the size of the shaded colormap below 256. If the vector of azimuth and
%  elevation is empty, the default locations are used. Color axis limits are
%  computed from the data.
%
%  SURFLSRM(lat,lon,map,[azim elev],cmap,clim) uses the provided caxis limits.
%
%  h = SURFLSRM(...) returns the handle to the surface drawn.
%
%  See also MESHLSRM, SHADEREL, MESHM, SURFLM, SURFM, SURFACEM, PCOLORM.

% Copyright 1996-2016 The MathWorks, Inc.
% Written by:  A. Kim, W. Stumpf

% Obsolete syntax
% ---------------
% [h,msg] = SURFLSRM(...) returns a string indicating any error encountered
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

%  Initialize outputs
if nargout ~= 0
    hout = [];
end

validateattributes(lat, {'double'}, {'2d'}, 'SURFLSRM', 'LAT', 1)
validateattributes(lon, {'double'}, {'2d'}, 'SURFLSRM', 'LON', 2)
validateattributes(map, {'double'}, {'2d'}, 'SURFLSRM', 'MAP', 3)

if nargin==3
    rgbs = [];
    clim = [];
    s = [];
elseif nargin==4
    rgbs = [];
    clim = [];
elseif nargin==5
    clim = [];
end

if ~isequal(size(lat),size(lon),size(map))
    error(message('map:validate:inconsistentSizes3', ...
        'SURFLSRM', 'LAT', 'LON', 'MAP'))
end

%  Set the light source azimuth and elevation
if ~isempty(s) && length(s) ~= 2
    error('map:surflsrm:mapdispError', ...
        'Light source vector must consist of azimuth and elevation.');
end

%  Set the color axis limits
if isempty(clim)
    clim = [min(map(:)) max(map(:))];
else
    validateattributes(clim,{'double'},{'size',[1 2]}, 'SURFLSRM', 'CLIM', 6)
end

%  Build shaded relief colormap
if isempty(rgbs)
    [rgbs,clim] = demcmap(map);
end

[rgbindx,rgbmap,clim] = shaderel(lon,lat,map,rgbs,s,[],clim);

%  Display shaded relief map
h = surfacem(lat,lon,rgbindx,map); colormap(rgbmap)
caxis(clim)

%  Set handle return argument if necessary
if nargout ~= 0
    hout = h;
end
