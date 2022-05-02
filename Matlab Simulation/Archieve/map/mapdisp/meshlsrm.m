function hout = meshlsrm(Z,R,s,rgbs,clim)
%MESHLSRM 3-D lighted shaded relief of regular data grid
%
%   MESHLSRM(Z, R) displays the regular data grid Z colored according
%   to elevation and surface slopes.  R can be a referencing vector, a
%   referencing matrix, or a geographic raster reference object.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z).
%
%   If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R.
%
%   If R is a referencing matrix, it must define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel.
%
%   By default, shading is based on a light to the east (90 deg.) at an
%   elevation of 45 degrees.  Also by default, the colormap is
%   constructed from 16 colors and 16 grays.  Lighting is applied before
%   the data is projected.  The current axes must have a valid map
%   projection definition.
%
%   MESHLSRM(Z, R, [AZIM ELEV]) displays the regular data grid Z with
%   the light coming from the specified azimuth and elevation.  Angles
%   are specified in degrees, with the azimuth measured clockwise from
%   North, and elevation up from the zero plane of the surface.
%
%   MESHLSRM(Z, R, [AZIM ELEV], CMAP) displays the regular data grid Z
%   using the specified colormap.  The number of grayscales is chosen to
%   keep the size of the shaded colormap below 256.  If the vector of
%   azimuth and elevation is empty, the default locations are used.
%   Color axis limits are computed from the data.
%
%   MESHLSRM(Z, R, [AZIM ELEV], CMAP, CLIM) uses the provided caxis limits.
%
%   H = MESHLSRM(...) returns the handle to the surface drawn.
%
%   Example
%   -------
%   load korea5c
%   worldmap(korea5c,korea5cR)
%   meshlsrm(korea5c,korea5cR,[45, 65])
%
%   See also MESHM, PCOLORM, SURFACEM, SURFLM, SURFLSRM

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  A. Kim, W. Stumpf, E. Byrns

narginchk(2, 5)

if nargin == 2
    rgbs = [];
    clim = [];
    s = [];
elseif nargin == 3
    rgbs = [];
    clim = [];
elseif nargin == 4
    clim = [];
end

R = internal.map.convertToGeoRasterRef( ...
    R, size(Z), 'degrees', mfilename, 'R', 2);
[lat,lon] = map.internal.graticuleFromRasterReference(R, size(Z));

%  Display the shaded relief map
h = surflsrm(lat,lon,Z,s,rgbs,clim);

%  Set the output argument if necessary
if nargout==1
    hout = h;
end
