function R = maprasterref(varargin)
%maprasterref Construct map raster reference object
%
%   A map raster reference object encapsulates the relationship between a
%   planar map coordinate system and a system of "intrinsic coordinates"
%   anchored to the columns and rows of a 2-D spatially referenced raster
%   grid or image. Typically the raster is sampled regularly in the planar
%   "world X" and "world Y" coordinates of the map system such that the
%   "intrinsic X" and "world X" axes are parallel, and likewise with the
%   "intrinsic Y" and "world Y" axes (although they may point in opposite
%   directions). When this is true the TransformationType is 'rectilinear'.
%   See the remark below for information on the more general affine case.
%
%   Use of the maprefcells function or the maprefpostings function is
%   recommended, instead of maprasterref, except when constructing a raster
%   reference object from world file input.
%
%   R = maprasterref() constructs a map raster reference object with
%   default property values.
%
%   R = maprasterref(Name,Value) accepts a list of name-value pairs that
%   are used to assign selected properties when initializing a map raster
%   reference object. You can include any of the following, overriding
%   their default values as needed:
%
%       XWorldLimits (default value: [0.5 2.5])
%       YWorldLimits (default value: [0.5 2.5])
%       RasterSize (default value: [2 2])
%       RasterInterpretation (default value: 'cells')
%       ColumnsStartFrom (default value: 'south')
%       RowsStartFrom (default value: 'west')
%
%   Alternatively, you can omit any or all properties when constructing a
%   map raster reference object, then customize the result by resetting
%   properties from this list one at a time. The exception is the
%   RasterInterpretation property. To have a raster interpretation of
%   'postings' (rather than the default, 'cells'), the name-value pair
%   'RasterInterpretation','postings' must be specified in your call to
%   maprasterref.
%
%   This name-value syntax always results in an object with a 'rectilinear'
%   TransformationType. If your image is rotated with respect to the world
%   coordinate axes, you need an object with a TransformationType of
%   'affine'. To obtain such an object, provide an appropriate world file
%   matrix as input, as shown in the following syntax. You cannot do it by
%   resetting properties of an existing rectilinear map raster reference
%   object.
%
%   R = maprasterref(W, rasterSize, rasterInterpretation) constructs a
%   map raster reference object with the specified raster size and raster
%   interpretation properties, and with remaining properties defined by a
%   2-by-3 world file matrix, W. The rasterInterpretation input is
%   optional, can equal either 'cells' or 'postings', and has a default
%   value of 'cells'.
%
%   Example 1
%   ---------
%   Construct a referencing object for an 1000-by-2000 image with
%   square, 1/2 meter pixels referenced to a planar map coordinate
%   system (the "world" system). The X-limits in the world system are
%   207000 and 208000. The Y-limits are 912500 and 913000. The image
%   follows the popular convention in which world X increases from
%   column to column and world Y decreases from row to row.
%   R = maprasterref('RasterSize', [1000 2000], ...
%         'YWorldLimits', [912500 913000], 'ColumnsStartFrom','north', ...
%         'XWorldLimits', [207000 208000])
%
%   Example 2
%   ---------
%   % Repeat Example 1 with a different strategy: Create a default
%   % object and then modify that object's property settings as needed.
%   R = maprasterref;
%   R.XWorldLimits = [207000 208000];
%   R.YWorldLimits = [912500 913000];
%   R.ColumnsStartFrom = 'north';
%   R.RasterSize = [1000 2000]
%
%   Example 3
%   ---------
%   % Repeat Example 1 again, this time using a world file matrix.
%   W = [0.5   0.0   207000.25; ...
%        0.0  -0.5   912999.75];
%   rasterSize = [1000 2000];
%   R = maprasterref(W, rasterSize)
%
%   Cell Shapes and Affine Transformation Type
%   ------------------------------------------
%   More generally (and much more rarely), the intrinsic and world systems
%   may have a general affine relationship, which allows for the
%   possibility of rotation (and skew). In this case the TransformationType
%   has the value 'affine' instead of 'rectilinear'. In either case, the
%   sample spacing from row to row need not equal the sample spacing from
%   column to column. If the raster data set is interpreted as comprising a
%   grid of cells or pixels, the cells or pixels need not be square. In the
%   most general case, they could even be parallelograms, but in practice
%   they are always rectangular.
%
%   See also maprefcells, maprefpostings, georasterref, map.rasterref.MapCellsReference, map.rasterref.MapPostingsReference

% Copyright 2010-2017 The MathWorks, Inc.

if nargin == 0
    % Construct a default object.
    R = map.rasterref.MapCellsReference();
elseif ischar(varargin{1}) || isstring(varargin{1})
    % Determine the raster interpretation and initialize a map raster
    % reference object of the appropriate class.
    [rasterInterpretation, pairs] = map.internal.findNameValuePair( ...
        'RasterInterpretation', 'cells', varargin{:});
    rasterInterpretation = validatestring(rasterInterpretation, ...
        {'cells','postings'}, 'maprasterref', 'rasterInterpretation');
    if strcmp(rasterInterpretation,'cells')
        R = map.rasterref.MapCellsReference();
    else
        R = map.rasterref.MapPostingsReference();
    end
    
    % Set each property found in the list of remaining pairs.
    validPropertyNames = {'RasterSize', 'RasterInterpretation', ...
        'ColumnsStartFrom', 'RowsStartFrom', ...
        'XWorldLimits', 'XLimWorld', ...
        'YWorldLimits', 'YLimWorld'};
    R = setSpatialReferencingProperties(R, ...
        pairs, validPropertyNames, 'maprasterref');
else
    W = varargin{1};  % We know there's at least one input.
    W = validateWorldFileMatrix(W, 'maprasterref', 'worldFileMatrix', 1);
    
    [rasterSize, rasterInterpretation] ...
        = parseRasterSizeAndInterpretation(varargin(2:end), 'maprasterref');
    
    J = W(:,1:2);
    
    if strcmp(rasterInterpretation, 'cells')
        firstCornerX = firstCorner(W(1,3), -(J(1,1) + J(1,2)));
        firstCornerY = firstCorner(W(2,3), -(J(2,1) + J(2,2)));
    else
        firstCornerX = W(1,3);
        firstCornerY = W(2,3);
    end
    
    R = map.rasterref.internal.constructMapRasterReference(rasterSize, ...
        rasterInterpretation, firstCornerX, firstCornerY, J, [1 1; 1 1]);
end
