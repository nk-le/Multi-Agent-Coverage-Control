function R = georasterref(varargin)
%georasterref Construct geographic raster reference object
%
%   A geographic raster reference object encapsulates the relationship
%   between a geographic coordinate reference system and a system of
%   "intrinsic coordinates" anchored to the columns and rows of a 2-D
%   spatially referenced raster grid or image. The raster must be sampled
%   regularly in latitude and longitude and its columns and rows must be
%   aligned with meridians and parallels, respectively.
%
%   Use of the georefcells function or the georefpostings function is
%   recommended, instead of georasterref, except when constructing a raster
%   reference object from world file input.
%
%   R = georasterref() constructs a geographic raster reference object with
%   default property values.
%
%   R = georasterref(Name,Value) accepts a list of name-value pairs
%   that are used to assign selected properties when initializing a
%   geographic raster reference object. You can include any of the
%   following properties, overriding their default values as needed:
%
%       LatitudeLimits  (default value: [0.5 2.5])
%       LongitudeLimits (default value: [0.5 2.5])
%       RasterSize (default value: [2 2])
%       RasterInterpretation (default value: 'cells')
%       ColumnsStartFrom (default value: 'south')
%       RowsStartFrom (default value: 'west')
%
%   Alternatively, you can omit any or all properties when constructing a
%   geographic raster reference object, then customize the result by
%   resetting properties from this list one at a time. The exception is the
%   RasterInterpretation property. To have a raster interpretation of
%   'postings' (rather than the default, 'cells'), the name-value pair
%   'RasterInterpretation','postings' must be specified in your call to
%   georasterref.
%
%   R = georasterref(W, rasterSize, rasterInterpretation) constructs a
%   geographic raster reference object with the specified raster size
%   and interpretation properties, and with remaining properties defined
%   by a 2-by-3 world file matrix, W. The rasterInterpretation input is
%   optional, can equal either 'cells' or 'postings', and has a default
%   value of 'cells'.
%
%   Example 1
%   ---------
%   % Construct a referencing object for a global raster comprising
%   % a grid of 180-by-360 one-degree cells, with rows that start at
%   % longitude -180, with the first cell located in the northwest corner.
%   R = georasterref('RasterSize', [180 360], ...
%         'RasterInterpretation', 'cells', 'ColumnsStartFrom', 'north', ...
%         'LatitudeLimits', [-90 90], 'LongitudeLimits', [-180 180])
%
%   Example 2
%   ---------
%   % Construct a referencing object for the DTED Level 0 file that
%   % includes Sagarmatha (Mount Everest). The DTED columns run
%   % from south to north and the first column runs along the
%   % western edge of the (one-degree-by-one-degree) quadrangle,
%   % consistent with the default values for 'ColumnsStartFrom' and
%   % 'RowsStartFrom'.
%   R = georasterref('LatitudeLimits', [27 28], 'LongitudeLimits', [86 87], ...
%        'RasterSize', [121 121], 'RasterInterpretation', 'postings')
%
%   Example 3
%   ---------
%   % Repeat Example 2 with a different strategy: Create an object by
%   % specifying only the RasterInterpretation value, then modify
%   % the object by resetting additional properties. (As noted above,
%   % the RasterInterpretation of an existing raster reference object
%   % cannot be changed.)
%   R = georasterref('RasterInterpretation','postings');
%   R.RasterSize = [121 121];
%   R.LatitudeLimits  = [27 28];
%   R.LongitudeLimits = [86 87];
%
%   Example 4
%   ---------
%   % Repeat Example 1 using a world file matrix as input.
%   W = [1    0   -179.5; ...
%        0   -1     89.5];
%   rasterSize = [180 360];
%   rasterInterpretation = 'cells';
%   R = georasterref(W, rasterSize, rasterInterpretation);
%
%   See also georefcells, georefpostings, maprasterref, map.rasterref.GeographicCellsReference, map.rasterref.GeographicPostingsReference

% Copyright 2010-2017 The MathWorks, Inc.

if nargin == 0
    % Construct a default object.
    R = map.rasterref.GeographicCellsReference();
elseif ischar(varargin{1}) || isstring(varargin{1})
    % Determine the raster interpretation and initialize a geographic
    % raster reference object of the appropriate class.
    [rasterInterpretation, pairs] = map.internal.findNameValuePair( ...
        'RasterInterpretation', 'cells', varargin{:});
    rasterInterpretation = validatestring(rasterInterpretation, ...
        {'cells','postings'}, 'georasterref', 'rasterInterpretation');
    if strcmp(rasterInterpretation,'cells')
        R = map.rasterref.GeographicCellsReference();
    else
        R = map.rasterref.GeographicPostingsReference();
    end
    
    % Set each property found in the list of remaining pairs.
    validPropertyNames = {'RasterSize', 'RasterInterpretation', ...
        'ColumnsStartFrom', 'RowsStartFrom', ...
        'LatitudeLimits', 'Latlim', ...
        'LongitudeLimits', 'Lonlim'};
    R = setSpatialReferencingProperties(R, ...
        pairs, validPropertyNames, 'georasterref');
else
    W = varargin{1};  % We know there's at least one input.
    W = validateWorldFileMatrix(W, 'georasterref', 'worldFileMatrix', 1);
    
    assert(W(1,2) == 0 && W(2,1) == 0, ...
        'map:validate:expectedRectilinearWorldFileMatrix', ...
        'Function %s expected input number %d, %s, to define a rectilinear transformation between intrinsic and geographic coordinates.', ...
        'georasterref', 1, 'worldFileMatrix')
    
    [rasterSize, rasterInterpretation] ...
        = parseRasterSizeAndInterpretation(varargin(2:end), 'georasterref');
    
    deltaLon = W(1,1);
    deltaLat = W(2,2);
    
    if strcmp(rasterInterpretation, 'cells')
        firstCornerLon = firstCorner(W(1,3), -deltaLon);
        firstCornerLat = firstCorner(W(2,3), -deltaLat);
    else
        firstCornerLon = W(1,3);
        firstCornerLat = W(2,3);
    end
    
    R = map.rasterref.internal.constructGeographicRasterReference( ...
        rasterSize, rasterInterpretation, ...
        firstCornerLat, firstCornerLon, deltaLat, 1, deltaLon, 1);
end
