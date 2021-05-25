function [Z, indxPointOutsideGrid]  = imbedm(lat, lon, value, Z, R, units)
%IMBEDM  Encode data points into regular data grid
%
%   Z = IMBEDM(LAT, LON, VALUE, Z, R) resets certain entries of a
%   regular data grid, Z.  R can be a geographic raster reference object, a
%   referencing vector, or a referencing matrix.
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
%   along a meridian and each row falls along a parallel. The entries to
%   be reset correspond to the locations defined by the latitude and
%   longitude position vectors LAT and LON. The entries are reset to the
%   same number if VALUE is a scalar, or to individually specified
%   numbers if VALUE is a vector the same size as LAT and LON. If any
%   points lie outside the input grid, a warning is issued.  All input
%   angles are in degrees.
%
%   Z = IMBEDM(LAT, LON, VALUE, Z, R, UNITS) specifies the units of the
%   vectors LAT and LON, where UNITS is any valid angle unit ('degrees' by
%   default).
%
%   [Z, indxPointOutsideGrid] = IMBEDM(...) returns the indices of
%   LAT and LON corresponding to points outside the grid in the variable
%   indxPointOutsideGrid.

% Copyright 1996-2020 The MathWorks, Inc.

% Validate inputs
narginchk(5, 6)

if nargin == 6
    [lat, lon] = toDegrees(units, lat, lon);
end

if isscalar(value)
    value = value + zeros(size(lat));
end

lat = ignoreComplex(lat, 'imbedm', 'LAT');
lon = ignoreComplex(lon, 'imbedm', 'LON');

assert(isequal(size(lat),size(lon),size(value)), ...
    'map:validate:inconsistentSizes3', ...
    'Function %s expected its %s, %s, and %s inputs to have the same size.', ...
    'imbedm', 'LAT', 'LON', 'VALUE')

%  If R is already spatial referencing object, validate it. Otherwise
%  convert the input referencing vector or matrix.
R = internal.map.convertToGeoRasterRef(R, size(Z), 'degrees', 'IMBEDM', 'R', 5);

%  Eliminate NaNs from the input data
qNaN = isnan(lat) | isnan(lon);
lat(qNaN) = [];
lon(qNaN) = [];
value(qNaN) = [];

%  Identify the rows and columns for cells (or samples) corresponding to
%  the input latitude-longitude locations.
[r, c, indxPointOutsideGrid] = geographicToDiscreteOmitOutside(R, lat, lon);

%  Embed the values into the grid
value(indxPointOutsideGrid) = [];
indx = (c-1)*size(Z,1) + r;
Z(indx) = value;
