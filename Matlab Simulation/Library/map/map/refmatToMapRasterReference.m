function R = refmatToMapRasterReference(refmat, rasterSize, varargin)
%refmatToMapRasterReference Referencing matrix to map raster reference object
%
%   R = refmatToMapRasterReference(REFMAT, rasterSize) constructs a
%   map raster reference object, R, from a referencing matrix, REFMAT, and
%   size vector, rasterSize.
%
%   rasterSize is a size vector [M N ...] specifying the number of rows
%   (M) and columns (N) in the raster or image to be associated with the
%   map raster reference object, R. For convenience, rasterSize may be a
%   row vector with more than two elements. This flexibility enables you
%   to specify the size in the following way:
%
%       R = refmatToMapRasterReference(refmat, size(RGB))
%
%   where RGB is M-by-N-by-3. However, in such cases, only the first
%   two elements of the size vector are actually used. The higher
%   (non-spatial) dimensions are ignored.
%
%   R = refmatToMapRasterReference(REFMAT, rasterSize, rasterInterpretation)
%   uses the rasterInterpretation input to determine which type of map
%   raster reference object to construct.
%
%   The rasterInterpretation input indicates basic geometric nature of the
%   raster, and can equal either 'cells' or 'postings'.
%
%   R = refmatToMapRasterReference(___, FUNC_NAME, VAR_NAME, ARG_POS)
%   uses up to three optional arguments to provide additional
%   information. This information is used to construct error messages if
%   either the REFMAT or rasterSize inputs turn out to be invalid. Thus,
%   you can use refmatToMapRasterReference for both validating and
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
%      refmatToMapRasterReference includes this information in the
%      formatted error message.
%
%   R = refmatToMapRasterReference(Rin, rasterSize, ...), where Rin is
%   a map raster reference object, verifies that Rin.RasterSize
%   is consistent with rasterSize, then copies Rin to R.
%
%   Example
%   -------
%   % Import a 2000-by-2000 TIFF orthoimage referenced to the
%   % Massachusetts State Plane Mainland coordinate system.
%   [X, cmap] = imread('concord_ortho_e.tif');
%
%   % Its limits in this coordinate system are:
%   xlimits = [209000 211000];
%   ylimits = [911000 913000];
%
%   % Because diff(xlimits) and diff(ylimits) both equal 2000, each pixel
%   % covers one square meter. As is typical for orthoimages, the image
%   % columns run from north to south. This enough information to write
%   % out a referencing matrix:
%   dx =  1;
%   dy = -1;
%   refmat = [0  dy;  dx  0;  xlimits(1) - dx/2   ylimits(2) + -dy/2]
%
%   % We can convert refmat to a raster reference object.
%   R = refmatToMapRasterReference(refmat, size(X))
%
%   % In this case, an easier alternative is simply to obtain the raster
%   % reference by using information in the accompanying world file, which
%   % has the same name but with a ".tfw" extension
%   worldfileread('concord_ortho_e.tfw','planar',size(X))
%
%   See also MAPREFCELLS, MAPREFPOSTINGS, refmatToGeoRasterReference

% Copyright 2010-2020 The MathWorks, Inc.

if nargin >= 3
    [varargin{:}] = convertStringsToChars(varargin{:});
    try
        rasterInterpretation = validatestring(varargin{1},{'cells','postings'});
        varargin(1) = [];
    catch me
        % Throw error only for non-character input. Otherwise assume that
        % varargin{1} is func_name.
        if ~ischar(varargin{1})
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
    func_name = 'refmatToMapRasterReference';
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
% finite doubles, or a map raster reference object.
map.rasterref.internal.validateRasterReference( ...
    refmat, 'planar', func_name, var_name, arg_pos)

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
        'A %s object was provided to function %s, but its %s value is not consistent with the raster size vector.', ...
        class(R), func_name, 'RasterSize')
else
    isRectilinear = (refmat(1,1) == 0 && refmat(2,2) == 0);
    if isRectilinear
        % Obtain defining parameters from referencing matrix.
        deltaX = refmat(2,1);
        deltaY = refmat(1,2);
        
        if strcmp(rasterInterpretation,'cells')
            firstCornerX = firstCorner(refmat(3,1), deltaX);
            firstCornerY = firstCorner(refmat(3,2), deltaY);
        else
            firstCornerX = firstCorner(refmat(3,1), 2*deltaX);
            firstCornerY = firstCorner(refmat(3,2), 2*deltaY);
        end
        
        J = [deltaX 0; 0 deltaY];
    else
        % Permute the first two rows of refmat to obtain the Jacobian matrix.
        J = refmat([2 1; 5 4]);
        
        if strcmp(rasterInterpretation,'cells')
            % The bottom row of refmat establishes a reference point at (0, 0)
            % in intrinsic coordinates, so take a step of 0.5 in both X and Y to
            % reach the outer corner at (0.5, 0.5).
            firstCornerX = refmat(3,1) + (J(1,1) + J(1,2)) / 2;
            firstCornerY = refmat(3,2) + (J(2,1) + J(2,2)) / 2;
        else
            firstCornerX = refmat(3,1) + (J(1,1) + J(1,2));
            firstCornerY = refmat(3,2) + (J(2,1) + J(2,2));
        end
    end
    
    % Construct referencing object.
    R = map.rasterref.internal.constructMapRasterReference(rasterSize, ...
        rasterInterpretation ,firstCornerX, firstCornerY, J, [1 1; 1 1]);
end
