function [Z, R] = vec2mtx(lat, lon, varargin)
%VEC2MTX Convert latitude-longitude vectors to regular data grid
%
%   Starting in R2021a, most VEC2MTX function syntaxes return a raster
%   reference object instead of a referencing vector. Most Mapping Toolbox
%   functions that accept referencing vectors as input also accept raster
%   reference objects, so this change is unlikely to affect your existing
%   code. (The syntax [Z,R] = VEC2MTX(LAT,LON,Z1,R1,...) is an exception:
%   if R1 is a referencing vector or matrix, then R is also a referencing
%   vector or matrix.)
%
%   [Z, R] = VEC2MTX(LAT, LON, DENSITY) creates a regular data grid Z
%   from vector data, placing ones in grid cells intersected by a vector
%   and zeroes elsewhere. R is the raster reference object for the computed
%   grid.  LAT and LON are vectors of equal length containing geographic
%   locations in units of degrees.  DENSITY indicates the number of grid
%   cells per unit of latitude and longitude (a value of 10 indicates 10
%   cells per degree, for example), and must be scalar-valued.  Whenever
%   there is space, a buffer of two grid cells is included on each of
%   the four sides of the grid.  The buffer is reduced as needed to keep
%   the latitude limits within [-90 90] and to keep the difference in
%   longitude limits from exceeding 360 degrees.
%
%   [Z, R] = VEC2MTX(LAT, LON, DENSITY, LATLIM, LONLIM) uses the
%   two-element vectors LATLIM and LONLIM to define the latitude and
%   longitude limits of the grid.
%
%   [Z, R] = VEC2MTX(LAT, LON, Z1, R1) uses a pre-existing data grid
%   Z1, georeferenced by R1, to define the limits and density of the output
%   grid.  R1 can be a referencing vector, a referencing matrix, or a
%   geographic raster reference object. R is the same type is R1.
%
%   If R1 is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z1) and its RasterInterpretation must be
%   'cells'.
%
%   If R1 is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R1 is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                      [lon lat] = [row col 1] * R1.
%
%   If R1 is a referencing matrix, it must define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel. With this
%   syntax, output R is equal to R1, and may be a referencing object,
%   vector, or matrix.
%
%   [Z, R] = VEC2MTX(...,'filled'), where LAT and LON form one or
%   more closed polygons (with NaN-separators), fills the area outside the
%   polygons with the value two instead of the value zero.
%
%   Notes
%   -----
%   Empty LAT, LON vertex arrays will result in an error unless the grid
%   limits are explicitly provided (via LATLIM, LONLIM or Z1, R1).
%   In the case of explicit limits, Z will be filled entirely with 0s if
%   the 'filled' parameter is omitted, and 2s if it is included.
%
%   It's possible to apply VEC2MTX to sets of polygons that tile without
%   overlap to cover an area, as in Example 1 below, but using 'filled'
%   with polygons that actually overlap may lead to confusion as to which
%   areas are inside and which are outside.
%   
%   Example 1
%   ---------
%   states = shaperead('usastatelo', 'UseGeoCoords', true);
%   lat = [states.Lat];
%   lon = [states.Lon];
%   [Z, R] = vec2mtx(lat, lon, 5, 'filled');
%   figure
%   worldmap(Z, R)
%   meshm(Z,R)
%   colormap(flag(3))
%
%   Example 2
%   ---------
%   % Combine two separate calls to VEC2MTX to create a 4-color raster map
%   % showing interior land areas, coastlines, oceans, and world rivers.
%   load coastlines
%   [Z, R] = vec2mtx(coastlat, coastlon, ...
%       1, [-90 90], [-90 270], 'filled');
%   rivers = shaperead('worldrivers.shp','UseGeoCoords',true);
%   A = vec2mtx([rivers.Lat], [rivers.Lon], Z, R);
%   Z(A == 1) = 3;
%   figure
%   worldmap(Z, R)
%   geoshow(Z, R, 'DisplayType', 'texturemap')
%   colormap([.45 .60 .30; 0 0 0; 0 0.5 1; 0 0 1])
%
%   See also IMBEDM

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(3, 6)

% Parse inputs/determine the location and size of the output grid.
[fill, rasterSize, R] = referenceOutput(lat, lon, varargin{:});

% If R is already a raster reference object, validate it. Otherwise
% convert the input referencing vector or matrix.
R1 = internal.map.convertToGeoRasterRef( ...
    R, rasterSize, 'degrees', 'VEC2MTX', 'R', 2);

assert(strcmp(R1.RasterInterpretation,'cells'), ...
    'map:validate:unexpectedPropertyValueString', ...
    'Function %s expected the %s property of input %s to have the value: ''%s''.', ...
    'vectmtx', 'RasterInterpretation', 'R', 'cells')

% Initialize all output cells to 0.
Z = zeros(rasterSize);

if fill
    % Interpret (lat, lon) as polygon vertices and assign 2 to all cells
    % having centers outside all the polygons.
    Z(~cellCentersInPolygon(lat, lon, rasterSize, R1)) = 2;
end

% Set the value of each cell crossed by a line or edge to 1.
Z = imbedLines(lat, lon, Z, R1);

%-----------------------------------------------------------------------

function in = cellCentersInPolygon(lat, lon, sizeZ, R)
% Interpret lat and lon as the edges of closed polygons and return a
% logical array IN such that size(IN) equals sizeZ containing true for
% all grid cell centers that are inside a polygon and false for cell
% center that are outside all polygons. R is a geographic raster reference
% object.

% Construct a regular quadrangular mesh connecting all the cell centers
% in the regular data grid defined by Z and R.
[glon, glat] = meshgrid(...
    R.intrinsicXToLongitude(1:R.RasterSize(2)), ...
    R.intrinsicYToLatitude( 1:R.RasterSize(1)));

% Trim to grid limits.
latlim = R.LatitudeLimits;
lonlim = R.LongitudeLimits;
try
    % This should work if the input has a valid polygon topology.
    [lat, lon] = maptrimp(lat, lon, latlim, lonlim);
catch e
    mappingToolboxException = strncmp(e.identifier, 'map:', 4);
    if mappingToolboxException
        % It's likely that the input data fail to have a valid polygon
        % topology.  This can easily happen when multiple, adjacent
        % polygons are concatenated -- like the 48 conterminous U.S.
        % states, for example. In this case, try trimming each part and
        % combining the result.
        [lat, lon] = trimAndCombinePolygons(lat, lon, latlim, lonlim);
    else
        % Rethrow the exception; something unexpected might be wrong.
        rethrow(e)
    end
end

% Construct a logical array of size sizeZ containing true for cell centers
% inside the polygon and false for cell centers outside the polygon.
if isempty(lat)
    in = false(sizeZ);
else
    in = inpolyfast(glon, glat, lon, lat);
end

%-----------------------------------------------------------------------

function [lat, lon] = trimAndCombinePolygons(lat, lon, latlim, lonlim)
% Trim each part of a multipart polygon, then combine the results.

[latcells, loncells] = polysplit(lat,lon);
trimmedAway = false(size(latcells));
for k = 1:numel(latcells)
    [latcells{k},loncells{k}] ...
        = maptrimp(latcells{k}, loncells{k}, latlim, lonlim);
    trimmedAway(k) ...
        = (isempty(latcells{k}) || all(isnan(latcells{k})));
end
latcells(trimmedAway) = [];
loncells(trimmedAway) = [];

if isscalar(latcells)
    lat = latcells{1};
    lon = loncells{1};
else
    [lat, lon] = polyjoin(latcells, loncells);
end

%-----------------------------------------------------------------------

function Z = imbedLines(lat, lon, Z, R)
% Given a set of line or polygon vertices in LAT and LON, set the value of
% each cell in the grid Z to 1 if that that cell is intersected by a line
% or edge. R is a geographic raster reference object.

% Trim input as _lines_.
[lat, lon] = maptriml(lat, lon, R.LatitudeLimits, R.LongitudeLimits);

% Increase the vertex density to slightly exceed the cell width/height
% to ensure that we don't miss any cells along the edge.
maxsep = 0.9/sampleDensity(R);
[lat, lon] = densifyLinear(lat, lon, maxsep);

% Set the value of each cell that contains a vertex to 1.
Z = imbedm(lat, lon, 1, Z, R);

%-----------------------------------------------------------------------

function [fill, rasterSize, R] = referenceOutput(lat, lon, varargin)
% Parse inputs to check for the presence of the 'filled' parameter and
% to determine the size and position of the output grid. R is always a
% referencing vector, except the [Z, R] = VEC2MTX(lat, lon, Z1, R1, ...)
% syntax. In that case, R and R1 are equal and they may be either
% referencing vectors or referencing matrices.

% Validate input vertex arrays.
checklatlon(lat, lon, mfilename, 'LAT', 'LON', 1, 2)

% Check to see if the last argument has value 'filled'.
fill = false;
if nargin >= 4
    str = varargin{end};
    if ischar(str) || isstring(str)
        try
            validatestring(str,"filled");
        catch e
            throwAsCaller(e)
        end
        fill = true;
    end
end

% Look for each of the three basic syntaxes.
if (nargin == 3) || (nargin == 4 && fill)
    % [Z, R] = VEC2MTX(lat, lon, density)
    % [Z, R] = VEC2MTX(lat, lon, density, 'filled')
    validateattributes(lat, {'double'}, {'nonempty'}, mfilename, 'LAT')
    validateattributes(lon, {'double'}, {'nonempty'}, mfilename, 'LON')
    density = varargin{1};
    validateattributes(density, ...
        {'double'},{'scalar','positive','finite'},mfilename,'DENSITY')
    bufwidth = 2 / density;  % Expand minimum bounding quadrangle by 2 cells
    [latlim, lonlim] = geoquadline(lat, lon);
    [latlim, lonlim] = bufgeoquad(latlim, lonlim, bufwidth, bufwidth);
    lonlim = map.internal.unwrapLongitudeLimits(lonlim);
    R = georefcells(latlim, lonlim, 1/density, 1/density);
    rasterSize = R.RasterSize;
elseif (nargin == 4) || (nargin == 5 && fill)
    % [Z, R] = VEC2MTX(lat, lon, Z1, R1)
    % [Z, R] = VEC2MTX(lat, lon, Z1, R1, 'filled')
    Z = varargin{1};
    R = varargin{2};
    rasterSize = size(Z);
elseif (nargin == 5) || (nargin == 6 && fill)
    % [Z, R] = VEC2MTX(lat, lon, density, latlim, lonlim)
    % [Z, R] = VEC2MTX(lat, lon, density, latlim, lonlim, 'filled')
    density = varargin{1};
    latlim = varargin{2};
    lonlim = varargin{3};
    validateattributes(density, ...
        {'double'},{'scalar','positive','finite'},mfilename,'DENSITY')
    checkgeoquad(latlim, lonlim, mfilename, 'LATLIM', 'LONLIM', 4, 5)
    lonlim = map.internal.unwrapLongitudeLimits(lonlim);
    R = georefcells(latlim, lonlim, 1/density, 1/density);
    rasterSize = R.RasterSize;
else
    % Couldn't find a recognizable syntax.
    error('map:vec2mtx:invalidSyntax', ...
        'Function %s was called with an invalid syntax.', 'VEC2MTX')
end
