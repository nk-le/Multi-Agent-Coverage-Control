function [a, cellarea] = areamat(BW, R, ellipsoid)
%AREAMAT Surface area covered by non-zero values in binary data grid
%
%   A = AREAMAT(BW, R) returns the surface area covered by the
%   elements of the binary regular data grid BW which contain the value 1
%   (true).  BW might be the result of a logical expression such as BW =
%   (topo > 0).  R can be a geographic raster reference object, a
%   referencing vector, or a referencing matrix.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(BW) and its RasterInterpretation must be
%   'cells'.
%
%   If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R,
%
%   where lat and lon are in units of degrees. If R is a referencing
%   matrix, it must define a (non-rotational, non-skewed) relationship in
%   which each column of the data grid falls along a meridian and each row
%   falls along a parallel. The output A expresses surface area as a
%   fraction of the surface area of the unit sphere (4*pi), so the result
%   ranges from 0 to 1.
%
%   A = AREAMAT(BW, R, ELLIPSOID) uses the input ELLIPSOID vector to
%   describe the sphere or reference ellipsoid.  ELLIPSOID is a reference
%   ellipsoid (oblate spheroid) object, a reference sphere object, or a
%   vector of the form [semimajor_axis, eccentricity].  The units of the
%   output, A, are the square of the length units in which the semimajor
%   axis is provided.  For example, if ELLIPSOID is replaced with
%   wgs84Ellipsoid('kilometers'), then A is in square kilometers.
%
%   [A, CELLAREA] = AREAMAT(...) returns a vector, CELLAREA, describing
%   the area covered by the data cells in BW.  Because all the cells in
%   a given row are exactly the same size, only one value is needed per
%   row.  Therefore CELLAREA has size M-by-1, where M = size(BW,1) is
%   the number of rows in BW.
%
%   See also AREAINT, AREAQUAD

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(2,3)

if nargin == 2
    % Let AREAQUAD use the default ellipsoid.
    ellipsoid = [];
    if isa(R, 'map.rasterref.GeographicRasterReference') && isscalar(R) ...
            && ~isempty(R.GeographicCRS) && ~isempty(R.GeographicCRS.Spheroid)
        ellipsoid = R.GeographicCRS.Spheroid;
    end
else
    ellipsoid = checkellipsoid(ellipsoid,mfilename,'ELLIPSOID',3);
end

%  Ensure that BW is binary.
assert(all((BW(:) == 0) | (BW(:) == 1)), ...
    'map:validate:nonBinaryInput', ...
    'Function %s expected input %s to be binary (containing only 0s and 1s).', ...
    'areamat', 'BW')

%  If R is already spatial referencing object, validate it. Otherwise
%  convert the input referencing vector or matrix.
R = internal.map.convertToGeoRasterRef( ...
    R, size(BW), 'degrees', mfilename, 'R', 2);

assert(strcmp(R.RasterInterpretation,'cells'), ...
    'map:validate:unexpectedPropertyValueString', ...
    'Function %s expected the %s property of input %s to have the value: ''%s''.', ...
    'areamat', 'RasterInterpretation', 'R', 'cells')

% Each cell of BW is, in spherical geometry, the intersection
% of a lune with a zone.  Every cell in a given 1-cell-wide zone
% has equal area; areas of cells in a given 1-cell-wide lune
% decrease as the poles are approached.

% Define vector with one element for each row (zone) of BW
% and assign it the area for a cell at that latitude.  The resulting
% vector is a sort of 'reference lune'.

% Start with reference cells running from south to north.
edgelats = sort(intrinsicYToLatitude(R, 0.5 + (0:(R.RasterSize(1)))))';
lat1 = edgelats(1:end-1);
lat2 = edgelats(2:end);
lon1 = zeros(size(lat1));
lon2 = lon1 + R.RasterExtentInLongitude/R.RasterSize(2);
cellarea = areaquad(lat1, lon1, lat2, lon2, ellipsoid, 'degrees' );

% If necessary, flip the vector of "reference lune" cell areas.
if ~columnsRunSouthToNorth(R)
    cellarea = cellarea(numel(cellarea):-1:1);
end

%  Total area for elements of BW with value true.
%  Avoid matrix multiplication (cellarea' * BW)  because this
%  can be extremely time consuming for large sparse BW.

[i,~] = find(BW);
a = sum(cellarea(i));
