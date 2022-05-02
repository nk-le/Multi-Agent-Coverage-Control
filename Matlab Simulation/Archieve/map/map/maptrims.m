function [Ztrimmed,Rtrimmed] = maptrims(Z,R,latlim,lonlim,cellDensity)
%MAPTRIMS  Trim regular data grid to latitude-longitude quadrangle
%
%     MAPTRIMS will be removed in a future release. Use GEOCROP instead.
%
%   Z_TRIMMED = MAPTRIMS(Z,R,LATLIM,LONLIM) trims a regular data grid Z
%   to the region specified by LATLIM and LONLIM. By default, the output
%   grid Z_TRIMMED has the same sample size as the input. R can be a
%   geographic raster reference object, a referencing vector, or a
%   referencing matrix.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z) and its RasterInterpretation must be
%   'cells'.
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
%   along a meridian and each row falls along a parallel. LATLIM and LONLIM
%   are two-element vectors, defining the latitude and longitude limits,
%   respectively. The LATLIM vector has the form:
%
%                   [southern_limit northern_limit] 
%   
%   and the LONLIM vector has the form:
% 
%                   [western_limit eastern_limit].
%
%   When an individual value in LATLIM or LONLIM corresponds to a
%   parallel or meridian that runs precisely along cell boundaries, the
%   output grid will extend all the way to that limit. But if a limiting
%   parallel or meridian cuts through a column or row of input cells,
%   then the limit will be adjusted inward. In other words, the
%   requested limits will be truncated as necessary to avoid partial
%   cells.
%
%   Z_TRIMMED = MAPTRIMS(Z, R, LATLIM, LONLIM, cellDensity) uses the
%   scalar cellDensity to reduce the size of the output. If R is a
%   referencing vector, then R(1) must be evenly divisible by
%   cellDensity. If R is a referencing matrix, then the inverse of each
%   element in the first two rows (containing "deltaLat" and "deltaLon")
%   must be evenly divisible by cellDensity.
%
%   [Z_TRIMMED, R_TRIMMED] = MAPTRIMS(...) returns a referencing vector,
%   matrix, or object for the trimmed data grid. If R is a referencing
%   vector, then R_TRIMMED is a referencing vector. If R is a
%   referencing matrix, then R_TRIMMED is a referencing matrix. If R is a
%   geographic raster reference object, then R_TRIMMED is either a
%   geographic raster reference object (when Z_TRIMMED is non-empty) or []
%   (when Z_TRIMMED is empty).
%
%   See also GEOCROP, MAPTRIML, MAPTRIMP

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(4,5)
Z = ignoreComplex(Z, mfilename, 'Z');
validateattributes(Z, {'numeric'}, {'2d','real'}, 'maptrims', 'Z', 1)
latlim = sort(ignoreComplex(latlim, mfilename, 'latlim'));
lonlim = ignoreComplex(lonlim, mfilename, 'lonlim');
checkgeoquad(latlim, lonlim, 'maptrims', 'LATLIM', 'LONLIM', 3, 4)

% If R is already spatial referencing object, validate it. Otherwise
% convert the input referencing vector or matrix.
S = internal.map.convertToGeoRasterRef( ...
    R, size(Z), 'degrees', 'MAPTRIMS', 'R', 2);

assert(strcmp(S.RasterInterpretation,'cells'), ...
    'map:validate:unexpectedPropertyValueString', ...
    'Function %s expected the %s property of input %s to have the value: ''%s''.', ...
    'maptrims', 'RasterInterpretation', 'R', 'cells')

if (nargin == 4)
    % cellDensity input was omitted; keep what we have.
    rowSampleFactor = 1;
    colSampleFactor = 1;
else
    % Validate cellDensity input and compute sample factors.
    [rowDensity, colDensity] = sampleDensity(S);
    [rowSampleFactor, colSampleFactor] ...
        = computeSampleFactors(cellDensity, rowDensity, colDensity);
end

decreasingDensity = (rowSampleFactor > 1) || (colSampleFactor > 1);
%  If reduction is requested, ensure that sparse input map is binary
if decreasingDensity && issparse(Z) && any(nonzeros(Z) ~= 1)
    error('map:maptrims:expectedBinaryGrid', ...
        'Cell density reduction requires a binary grid as input.')
end

% Validate consistency of input and output limits
[latlim, lonlim] = checkLimits(S, latlim, lonlim);

% Trim the input raster, snapping the limits in far enough to ensure
% that the output raster sizes are exact multiples of rowSampleFactor
% and colSampleFactor, and returning updated size and limits.
[Ztrimmed, latlim, lonlim] = trimRaster( ...
    Z, S, latlim, lonlim, rowSampleFactor, colSampleFactor);

rasterSize = size(Ztrimmed);
if all(rasterSize > 0)
    % At least one row and one column remain after trimming. Update the
    % spatial referencing object S, then convert to a referencing matrix.
    S.RasterSize = rasterSize;
    S.LatitudeLimits = latlim;
    S.LongitudeLimits = lonlim;
    if isobject(R)
        Rtrimmed = S;
    else
        Rtrimmed = map.internal.referencingMatrix(worldFileMatrix(S));
    end
else
    % Empty output raster.
    if isobject(R)
        % A referencing object cannot represent an empty raster, so
        % return empty for both Ztrimmed and Rtrimmed.
        Rtrimmed = [];
    else
        % Construct a referencing matrix directly, ignoring truncation.
        sn = double(columnsRunSouthToNorth(S));
        we = double(rowsRunWestToEast(S));
        [densityInLatitude, densityInLongitude] = sampleDensity(S);
        dlat = rowSampleFactor * (2*sn - 1) / densityInLatitude;
        dlon = colSampleFactor * (2*we - 1) / densityInLongitude;
        lat11 = latlim(1 + ~sn) + dlat/2;
        lon11 = lonlim(1 + ~we) + dlon/2;
        W = [dlon   0    lon11;
               0   dlat  lat11];
        Rtrimmed = map.internal.referencingMatrix(W);
    end
end

% Return a referencing vector instead if needed to match input.
refvecInput = isequal(size(R), [1 3]);
if refvecInput
    Rtrimmed = [R(1)/rowSampleFactor latlim(2) lonlim(1)];
end

%-----------------------------------------------------------------------

function [Ztrimmed, latlim, lonlim] = trimRaster( ...
    Z, S, latlim, lonlim, rowSampleFactor, colSampleFactor)
% Trim the input raster, snapping the limits in far enough to ensure
% that the output raster sizes are exact multiples of rowSampleFactor
% and colSampleFactor, then resize if required. Return updated size and
% limits.

% Ensure that trimmed map is completely within the requested limits
xiLim = sort(S.longitudeToIntrinsicX(lonlim));
yiLim = sort(S.latitudeToIntrinsicY(latlim));
clim = [ceil(xiLim(1) + 0.5), floor(xiLim(2) - 0.5)];
rlim = [ceil(yiLim(1) + 0.5), floor(yiLim(2) - 0.5)];

% Snap in further as needed to ensure sizes that are multiples of
% rowSampleFactor and colSampleFactor.
decreasingDensity = (rowSampleFactor > 1) || (colSampleFactor > 1);
if decreasingDensity
    [rlim, clim] ...
        = snapInLimits(rlim, clim, rowSampleFactor, colSampleFactor);
end

% Translated new limits back to latitude-longitude.
latlim = snapLatitudeLimits(S, rlim, yiLim);
lonlim = snapLongitudeLimits(S, clim, xiLim);

% Compute the new raster size.
rasterSize = [ ...
    max(0, rlim(2) - rlim(1) + 1), ...
    max(0, clim(2) - clim(1) + 1)];

rasterSize = rasterSize ./ [rowSampleFactor colSampleFactor];

% Subset the input raster Z at full resolution.
Ztrimmed = Z(rlim(1):rlim(2),clim(1):clim(2));

% Adjust Ztrimmed as needed.
if all(rasterSize > 0)
    % At least one row and one column remain after trimming.
    if decreasingDensity
        Ztrimmed = double(imresize(Ztrimmed, rasterSize, 'nearest'));
    end
else
    % Empty output raster
    Ztrimmed = reshape([], rasterSize);
end

%-----------------------------------------------------------------------

function [rlim, clim] ...
    = snapInLimits(rlim, clim, rowSampleFactor, colSampleFactor)
% Snap row and column limits inward to ensure to specify a subset of the
% grid in which the number of rows is an exact multiple of
% rowSampleFactor and the number of columns is an exact multiple of
% columnSampleFactor.

% Use max(0,...) to avoid negative sizes
numrows = max(0, rlim(2) - rlim(1) + 1);
numcols = max(0, clim(2) - clim(1) + 1);

% Round to even multiples of the sample factors
numrowsSub = rowSampleFactor * floor(numrows / rowSampleFactor);
numcolsSub = colSampleFactor * floor(numcols / colSampleFactor);

% Choose offsets to center selected range within available range
offsetRows = floor((numrows - numrowsSub)/2);
offsetCols = floor((numcols - numcolsSub)/2);

% Apply offsets to reset lower limits
rlim(1) = rlim(1) + offsetRows;
clim(1) = clim(1) + offsetCols;

% Reset upper limits (bounded by original limits)
rlim(2) = min(rlim(2), rlim(1) + numrowsSub - 1);
clim(2) = min(clim(2), clim(1) + numcolsSub - 1);

%-----------------------------------------------------------------------

function latlim = snapLatitudeLimits(S, rlim, yiLim)

if rlim(1) <= rlim(2)
    % Output has at least one row
    latlim = sort(S.intrinsicYToLatitude(rlim + [-0.5 0.5]));
else
    % Output has no rows; size(Ztrimmed,1) == 0
    yiLimSnap = floor(yiLim + 0.5) - 0.5;
    if diff(yiLimSnap) < 1
        yiMin = yiLimSnap(1);
    else
        yiMin = yiLimSnap(1) + 1;
    end
    latlim = S.intrinsicYToLatitude(yiMin(1, [1 1]));
end

%-----------------------------------------------------------------------

function lonlim = snapLongitudeLimits(S, clim, xiLim)

if clim(1) <= clim(2)
    % Output has at least one column
    lonlim = sort(S.intrinsicXToLongitude(clim + [-0.5 0.5]));
else
    % Output has no columns; size(Ztrimmed,2) == 0
    xiLimSnap = floor(xiLim + 0.5) - 0.5;
    if diff(xiLimSnap) < 1
        xiMin = xiLimSnap(1);
    else
        xiMin = xiLimSnap(1) + 1;
    end
    lonlim = S.intrinsicXToLongitude(xiMin(1, [1 1]));
end

%-----------------------------------------------------------------------

function [rowSampleFactor, colSampleFactor] ...
    = computeSampleFactors(cellDensity, rowDensity, colDensity)

cellDensity = ignoreComplex(cellDensity, mfilename, 'cellDensity');

if ~isscalar(cellDensity)
    error('map:maptrims:expectedScalarCellDensity', ...
        'cellDensity input must be a scalar')
end

tol = 1E-5; % allow for floating point round off
if rem(rowDensity,cellDensity) > tol || rem(colDensity,cellDensity) > tol
    error('map:maptrims:expectedIntegerSampleFactors', ...
        'Input cell density must be evenly divisible by cellDensity')
end

rowSampleFactor = round(rowDensity/cellDensity);
colSampleFactor = round(colDensity/cellDensity);

%-----------------------------------------------------------------------

function [latlim, lonlim] = checkLimits(S, latlim, lonlim)

%  Get the corners of the requested region

north = max(latlim);
south = min(latlim);
west  = lonlim(1);
east  = lonlim(2);

%  Ensure ascending latitude limits

latlim(1) = south;
latlim(2) = north;

%  Check the corners for consistency

if south >= north || west >= east
    error('map:maptrims:expectedUniqueCorners', 'Non-unique corner definition.')
end

%  Ensure that the corners of the requested region lie within the grid

if south < S.LatitudeLimits(1)
    error('map:maptrims:southernEdgeOutsideGrid', ...
        'Southern edge does not lie within the grid.')
end

if north > S.LatitudeLimits(2)
    error('map:maptrims:northernEdgeOutsideGrid', ...
        'Northern edge does not lie within the grid.')
end

if west < S.LongitudeLimits(1)
    error('map:maptrims:westernEdgeOutsideGrid', ...
        'Western edge does not lie within the grid.')
end

if east > S.LongitudeLimits(2)
    error('map:maptrims:easternEdgeOutsideGrid', ...
        'Eastern edge does not lie within the grid.')
end
