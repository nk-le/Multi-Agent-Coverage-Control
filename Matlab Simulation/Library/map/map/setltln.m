function [lat,lon,indxPointOutsideGrid] = setltln(Z,R,row,col)
%SETLTLN  Convert data grid rows and columns to latitude-longitude
%
%      SETLTLN will be removed in a future release.
%      Use intrinsicToGeographic instead.
%
%   [LAT, LON] = setltln(Z, R, ROW, COL) returns the latitude and
%   longitudes associated with the input row and column coordinates of
%   the regular data grid Z.  R can be a geographic raster reference
%   object, a referencing vector, or a referencing matrix.
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
%   along a meridian and each row falls along a parallel. All input and
%   output angles are in units of degrees.
%
%   [LAT, LON, indxPointOutsideGrid] = setltln(Z, R, ROW, COL)
%   returns the indices of the elements of the ROW and COL vectors that
%   lie outside the input grid.  The outputs LAT and LON always ignore
%   these points; the third output accounts for them.
%
%   LATLON = setltln(Z, R, ROW, COL) returns the coordinates in a
%   single two-column matrix of the form [latitude longitude]. 
%
%   See also map.rasterref.GeographicRasterReference/intrinsicToGeographic

% Copyright 1996-2020 The MathWorks, Inc.

assert(isequal(size(row),size(col)), ...
    'map:setltln:rowcolSizeMismatch', ...
    'Inconsistent dimensions on row and col inputs.')

row = ignoreComplex(row, mfilename, 'ROW');
col = ignoreComplex(col, mfilename, 'COL');

%  Ensure integer row and column inputs.
row = round(row);
col = round(col);

%  Construct a geographic raster reference object
R = internal.map.convertToGeoRasterRef( ...
    R, size(Z), 'degrees', mfilename, 'R', 2);

%  Use a method of R to map (col,row) to (lat,lon)
[lat, lon] = R.intrinsicToGeographic(col,row);

% Identify and remove points that fall outside the grid
indxPointOutsideGrid = ~R.contains(lat, lon);
lat(indxPointOutsideGrid) = [];
lon(indxPointOutsideGrid) = [];

% Convert to linear indexing
indxPointOutsideGrid = find(indxPointOutsideGrid);

%  Set the output arguments if necessary.
if nargout < 2
    lat = [lat(:) lon(:)];
end
