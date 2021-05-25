function R = refmatToGeoRasterReference(refmat, rasterSize, varargin)
%refmatToGeoRasterReference Referencing matrix to geographic raster reference object
%
%   R = refmatToGeoRasterReference(REFMAT, rasterSize) constructs a
%   cell-oriented geographic raster reference object, R, from a referencing
%   matrix, REFMAT, and size vector, rasterSize. REFMAT may be any valid
%   referencing matrix subject to the two following constraints. First, the
%   matrix must lead to valid latitude and longitude limits when combined
%   with rasterSize. Second, the matrix columns and rows must be aligned
%   with meridians and parallels, respectively.
%
%   rasterSize is a size vector [M N ...] specifying the number of rows (M)
%   and columns (N) in the raster or image to be associated with R. For
%   convenience, rasterSize may be a row vector with more than two
%   elements. This flexibility enables you to specify the size in the
%   following way:
%
%       R = refmatToGeoRasterReference(refmat, size(RGB))
%
%   where RGB is M-by-N-by-3. However, in such cases, only the first
%   two elements of the size vector are actually used. The higher
%   (non-spatial) dimensions are ignored.
%
%   R = refmatToGeoRasterReference(REFMAT, rasterSize, rasterInterpretation)
%   uses the rasterInterpretation input to determine which type of
%   geographic raster reference object to construct.
%
%   The rasterInterpretation input indicates basic geometric nature of the
%   raster, and can equal either 'cells' or 'postings'.
%
%   R = refmatToGeoRasterReference(___, FUNC_NAME, VAR_NAME, ARG_POS)
%   uses up to three optional arguments to provide additional
%   information. This information is used to construct error messages if
%   either the REFMAT or rasterSize inputs turn out to be invalid. Thus,
%   you can use refmatToGeoRasterReference for both validating and
%   converting a referencing matrix. The optional inputs work just like
%   their counterparts in the MATLAB function VALIDATEATTRIBUTES:
%
%      FUNC_NAME specifies the name used in the formatted error message to
%      identify the function checking the input.
%
%      VAR_NAME specifies the name used in the formatted error message to
%      identify the referencing matrix.
%
%      ARG_POS is a positive integer that indicates the position of the
%      referencing matrix checked in the function argument list.
%      refmatToGeoRasterReference includes this information in the
%      formatted error message.
%
%   R = refmatToGeoRasterReference(Rin, rasterSize, ...), where Rin is
%   a geographic raster reference object, verifies that Rin.RasterSize
%   is consistent with rasterSize, then copies Rin to R.
%
%   Example
%   -------
%   % Construct a referencing matrix for a regular grid that covers the
%   % entire globe with 2x3-degree cells, with columns starting at the
%   % South Pole.
%   latlim = [-90  90];
%   lonlim = [  0 360];
%   rasterSize = [90 120];
%   dlat = diff(latlim) / rasterSize(1)
%   dlon = diff(lonlim) / rasterSize(2)
%
%   refmat = [        0                 dlat
%                   dlon                  0
%            lonlim(1) - dlon/2   latlim(1) - dlat/2]
%
%
%   % Convert to a geographic raster reference object
%   R = refmatToGeoRasterReference(refmat, rasterSize)
%
%   % Alternatively, construct the reference object directly.
%   georefcells(latlim, lonlim, rasterSize)
%
%   See also GEOREFCELLS, GEOREFPOSTINGS, refmatToMapRasterReference

% Copyright 2010-2020 The MathWorks, Inc.

if nargin >= 3
    [varargin{:}] = convertStringsToChars(varargin{:});
    try
        rasterInterpretation = validatestring(varargin{1},{'cells','postings'});
        varargin(1) = [];
    catch me
        % Throw error only for non-character input. Otherwise assume that
        % varargin{1} is func_name.
        if ~(ischar(varargin{1}) || isstring(varargin{1}))
            rethrow(me)
        else
            rasterInterpretation = 'cells';
        end
    end
else
    rasterInterpretation = 'cells';
end

if ~isempty(varargin)
    func_name = varargin{1};
    varargin(1) = [];
else
    func_name = 'refmatToGeoRasterReference';
end

if ~isempty(varargin)
    var_name = varargin{1};
    varargin(1) = [];
else
    var_name = 'REFMAT';
end

if ~isempty(varargin)
    arg_pos = varargin{1};
else
    arg_pos = 1;
end

% Validate first input (refmat). It must be a 3-by-2 matrix of real-valued
% finite doubles, or a geographic raster reference object.
map.rasterref.internal.validateRasterReference(refmat, ...
    'geographic', func_name, var_name, arg_pos)

%Validate raster size.
validateattributes(rasterSize, ...
    {'double'}, {'row','positive','integer'}, func_name)

assert(numel(rasterSize) >= 2, ...
    'map:convertspatialref:invalidRasterSize', ...
    'The raster size vector provided to function %s must have at least two elements.', ...
    func_name)

if isobject(refmat)
    R = refmat;
    
    assert(isequal(R.RasterSize, rasterSize(1,1:2)), ...
        'map:convertspatialref:inconsistentRasterSize', ...
        'A %s object was provided to function %s., but its % value is not consistent with the raster size vector.', ...
        class(R), func_name, 'RasterSize')
    
    assert(strcmp(R.RasterInterpretation, rasterInterpretation), ...
        'map:convertspatialref:inconsistentRasterInterpretation', ...
        'A %s object was provided to function %s., but its % value is not consistent with the rasterInterpretation string.', ...
        class(R), func_name, 'RasterInterpretation')
else
    assert(refmat(1,1) == 0 && refmat(2,2) == 0, ...
        'map:convertspatialref:skewOrRotation', ...
        ['The referencing matrix supplied to function %s specifies', ...
        ' that the associated raster is rotated or skewed with', ...
        ' respect to the latitude/longitude system.  Function %s', ...
        ' does not support this geometry.'], func_name, func_name)
    
    % Compute other defining parameters from referencing matrix.
    deltaLat = refmat(1,2);
    deltaLon = refmat(2,1);
    
    if strcmp(rasterInterpretation,'cells')
        firstCornerLat = firstCorner(refmat(3,2), deltaLat);
        firstCornerLon = firstCorner(refmat(3,1), deltaLon);
    else
        firstCornerLat = firstCorner(refmat(3,2), 2*deltaLat);
        firstCornerLon = firstCorner(refmat(3,1), 2*deltaLon);
    end
    
    % Invoke constructor and interpret errors in the case of inconsistent
    % combinations of property values.
    R = constructGeoRasterReference(rasterSize, rasterInterpretation, ...
        firstCornerLat, firstCornerLon, deltaLat, 1, deltaLon, 1);
end
