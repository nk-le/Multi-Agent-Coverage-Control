function val = ltln2val(Z, R, lat, lon, method)
%LTLN2VAL  Extract data grid values for specified locations
%
%   LTLN2VAL will be removed in a future release. Use GEOINTERP instead.
%
%   VAL = LTLN2VAL(Z, R, LAT, LON) interpolates a regular data grid Z at
%   the points specified by vectors of latitude and longitude, LAT and LON.
%   R can be a geographic raster reference object, a referencing vector, or
%   a referencing matrix.
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
%   Nearest-neighbor interpolation is used by default.  NaN is returned
%   for points outside the grid limits or for which LAT or LON contain
%   NaN.  All angles are in units of degrees.
%
%   VAL = LTLN2VAL(Z, R, LAT, LON, METHOD) accepts a METHOD
%   to specify the type of interpolation: 'bilinear' for linear
%   interpolation, 'bicubic' for cubic interpolation, or 'nearest' for
%   nearest neighbor interpolation.
%
%   See also GEOINTERP

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(4, 5)
if nargin == 4
    method = 'nearest';
else
    method = convertStringsToChars(method);
    method = validatestring(method, ...
        {'nearest', 'linear', 'cubic', 'bilinear', 'bicubic'}, ...
        'ltln2val', 'METHOD', 5);
    if strcmp(method(1:2), 'bi')
        % Convert 'binear' to 'linear' and 'bicubic' to 'cubic'.
        method(1:2) = [];
    end
end

lat = ignoreComplex(lat, mfilename, 'LAT');
lon = ignoreComplex(lon, mfilename, 'LON');
checklatlon(lat, lon, mfilename, 'LAT', 'LON', 3, 4)
validateattributes(Z,{'numeric','logical'},{'2d','real'},mfilename,'Z',1)

%  If R is already spatial referencing object, validate it. Otherwise
%  convert the input referencing vector or matrix.
R = internal.map.convertToGeoRasterRef( ...
    R, size(Z), 'degrees', 'LTLN2VAL', 'R', 2);

%  Remove NaNs from lat/lon arrays, but keep track of where they were.
nanLatOrLon = isnan(lat) | isnan(lon);
lat(nanLatOrLon) = [];
lon(nanLatOrLon) = [];

% Initialize output to an array of NaN matching the original size of lat
% and lon, then fill in values only for elements corresponding to
% non-NaN lat and lon.
val = NaN(size(nanLatOrLon));
if method(1) == 'n' && strcmp(R.RasterInterpretation,'cells')
    val(~nanLatOrLon) = interpNearest(Z, R, lat, lon);
else
    % Use INTERP2.
    val(~nanLatOrLon) = interpGeoRaster(Z, R, lat, lon, method);
end

%-----------------------------------------------------------------------

function val = interpNearest(Z, R, lat, lon)
% Nearest-neighbor interpolation; return a value of NaN for points
% outside the grid limits.  VAL will be the same size as LAT and LON.

[row, col, indxPointOutsideGrid] = geographicToDiscreteOmitOutside(R, lat, lon);

% Construct logical array matching LAT and LON in size to indicate which
% points are inside or outside the grid limits.
insideLimits = true(size(lat));
insideLimits(indxPointOutsideGrid) = false;

% Output array matches LAT and LON in size and contains values copied
% from Z for points inside the map limits and NaN elsewhere.
indx = row + size(Z,1)*(col - 1);
val = NaN(size(lat));
val(insideLimits) = Z(indx);
