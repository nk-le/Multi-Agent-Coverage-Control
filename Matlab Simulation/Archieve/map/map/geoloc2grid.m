function [B, R] = geoloc2grid(lat, lon, A, cellsize)
%GEOLOC2GRID Convert geolocated data array to regular data grid
%
%   Starting in R2021a, the GEOLOC2GRID function returns a raster reference
%   object instead of a referencing vector. Most Mapping Toolbox functions
%   that accept referencing vectors as input also accept raster reference
%   objects, so this change is unlikely to affect your existing code.
%
%   [B,R] = GEOLOC2GRID(LAT,LON,A,CELLSIZE) converts the geolocated data
%   array, A, given geolocation points in LAT and LON, to produce a regular
%   data grid, B, and the corresponding raster reference object R.
%   CELLSIZE is a scalar that specifies the width and height of data cells
%   in the regular data grid, using the same angular units as LAT and LON.
%   Data cells in B falling outside the area covered by A are set to NaN.
%
%   Note
%   ----
%   GEOLOC2GRID provides an easy-to-use alternative to gridding geolocated 
%   data arrays with IMBEDM.  There is no need to pre-allocate the output
%   map, there are no data gaps in the output (even if CELLSIZE is chosen
%   to be very small), and the output map is smoother.
%
%   Example
%   -------
%   % Load the geolocated data array 'map1' and grid it to 1/2-degree cells.
%   load mapmtx
%   cellsize = 0.5;
%   [Z, R] = geoloc2grid(lt1, lg1, map1, cellsize);
%
%   % Create a figure
%   f = figure;
%   [cmap,clim] = demcmap(map1);
%   set(f,'Colormap',cmap,'Color','w')
%
%   % Define map limits
%   latlim = [-35 70];
%   lonlim = [0 100];
%
%   % Display 'map1' as a geolocated data array in subplot 1
%   subplot(1,2,1)
%   ax = axesm('mercator','MapLatLimit',latlim,'MapLonLimit',lonlim,...
%              'Grid','on','MeridianLabel','on','ParallelLabel','on');
%   set(ax,'Visible','off')
%   geoshow(lt1, lg1, map1, 'DisplayType', 'texturemap');
%
%   % Display 'Z' as a regular data grid in subplot 2
%   subplot(1,2,2)
%   ax = axesm('mercator','MapLatLimit',latlim,'MapLonLimit',lonlim,...
%              'Grid','on','MeridianLabel','on','ParallelLabel','on');
%   set(ax,'Visible','off')
%   geoshow(Z, R, 'DisplayType', 'texturemap');

% Copyright 1996-2020 The MathWorks, Inc.

checklatlon(lat, lon, mfilename, 'LAT', 'LON', 1, 2);
validateattributes(A,{'numeric'},{'real','2d','nonempty'}, mfilename,'A', 3);

if any(size(lat) ~= size(A))
    error('map:geoloc2grid:invalidLatLonSize', ...
        '%s and %s must have the same size as %s.', 'LAT', 'LON', 'A')
end

if numel(cellsize) ~= 1
    error('map:geoloc2grid:cellsizeNotScalar', ...
        '%s must be a scalar.', 'CELLSIZE')
end

if cellsize <= 0
    error('map:geoloc2grid:cellsizeNotPositive', ...
        '%s  must be positive.', 'CELLSIZE')
end

ab1 = abs(diff(lon,1,1));
ab2 = abs(diff(lon,1,2));
lonCheck1 = max(ab1(:));
lonCheck2 = max(ab2(:));
if isempty(lonCheck1) || isempty(lonCheck2) || ...
   (lonCheck1 > 10*cellsize) || (lonCheck2 > 10*cellsize)
    warning('map:geoloc2grid:possibleLongitudeWrap', ...
        'Longitude values may wrap.')
end

% Extend limits to even degrees in lat and lon
latlim = [floor(min(lat(:))),ceil(max(lat(:)))];
lonlim = [floor(min(lon(:))),ceil(max(lon(:)))];

halfcell = cellsize/2;

% Apply linear interpolation on a triangular lon-lat mesh.
F = TriScatteredInterp(lon(:), lat(:), A(:));
[lonmesh, latmesh] = meshgrid( ...
    ((lonlim(1)+halfcell):cellsize:(lonlim(2)-halfcell)),...
    ((latlim(1)+halfcell):cellsize:(latlim(2)-halfcell))');
B = F(lonmesh, latmesh);
R = georefcells(latlim, lonlim, cellsize, cellsize);
