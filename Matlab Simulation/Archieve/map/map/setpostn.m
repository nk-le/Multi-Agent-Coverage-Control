function varargout = setpostn(Z, R, lat, lon)
%SETPOSTN  Convert latitude-longitude to data grid rows and columns
%
%      SETPOSTN will be removed in a future release.
%      Use geographicToDiscrete instead.
%
%   [ROW, COL] = SETPOSTN(Z, R, LAT, LON) returns the row and column
%   indices of the regular data grid Z for the points specified by the
%   vectors LAT and LON. R can be a geographic raster reference object, a
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
%   along a meridian and each row falls along a parallel. Points falling
%   outside the grid are ignored in ROW and COL.  All input angles are
%   in degrees.
%
%   INDX = SETPOSTN(...) returns the indices of Z corresponding to
%   the points in LAT and LON.  Points falling outside the grid are
%   ignored in INDX.
%
%   [ROW, COL, indxPointOutsideGrid] = SETPOSTN(...) returns the indices
%   of LAT and LON corresponding to points outside the grid.  These
%   points are ignored in ROW and COL.
%
%   See also map.rasterref.GeographicRasterReference/geographicToDiscrete
%            map.rasterref.GeographicRasterReference/geographicToIntrinsic

% Copyright 1996-2020 The MathWorks, Inc.

lat = ignoreComplex(lat, mfilename, 'LAT');
lon = ignoreComplex(lon, mfilename, 'LON');
checklatlon(lat, lon, mfilename, 'LAT', 'LON', 3, 4)

%  If R is already spatial referencing object, validate it. Otherwise
%  convert the input referencing vector or matrix.
R = internal.map.convertToGeoRasterRef( ...
    R, size(Z), 'degrees', 'SETPOSTN', 'R', 2);

[row, col, indxPointOutsideGrid] = geographicToDiscreteOmitOutside(R, lat, lon);

if ~isempty(indxPointOutsideGrid)
    warning('map:setpostn:pointOutsideLimits', ...
        'At least one point falls outside of the limits of the data grid.')
end

%  Assign outputs
switch(nargout)
    case {0,1}
        varargout = {(col-1)*size(Z,1) + row};
    case 2
        varargout = {row, col};
    case 3
        varargout = {row, col, indxPointOutsideGrid};
end
