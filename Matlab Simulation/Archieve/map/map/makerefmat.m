function R = makerefmat(varargin)
%MAKEREFMAT Construct affine spatial-referencing matrix
%
%      MAKEREFMAT will be removed in a future release. Construct a raster
%      reference object using GEOREFCELLS, GEOREFPOSTINGS, GEORASTERREF,
%      MAPREFCELLS, MAPREFPOSTINGS, or MAPRASTERREF instead.
%
%   A spatial referencing matrix R ties the row and column subscripts of an
%   image or regular data grid to 2-D map coordinates or to geographic
%   coordinates (longitude and geodetic latitude).  R is a 3-by-2 affine
%   transformation matrix.  R either transforms pixel subscripts (row,
%   column) to/from map coordinates (x,y) according to
%
%                      [x y] = [row col 1] * R
%
%   or transforms pixel subscripts to/from geographic coordinates according
%   to
%
%                    [lon lat] = [row col 1] * R.
%
%   To construct a referencing matrix for use with geographic coordinates,
%   use longitude in place of X and latitude in place of Y, as shown in the
%   third syntax below.  This is one of the few places where longitude
%   precedes latitude in a function call.
%
%   R = MAKEREFMAT(X11, Y11, DX, DY) with scalar DX and DY constructs a
%   referencing matrix that aligns image/data grid rows to map X and
%   columns to map Y.  X11 and Y11 are scalars that specify the map
%   location of the center of the first (1,1) pixel in the image or first
%   element of the data grid, so that
%
%                   [X11 Y11] = pix2map(R,1,1).
%
%   DX is the difference in X (or longitude) between pixels in successive
%   columns and DY is the difference in Y (or latitude) between pixels in
%   successive rows.  More abstractly, R is defined such that
%
%      [X11 + (col-1) * DX, Y11 + (row-1) * DY] = pix2map(R, row, col).
%
%   Pixels cover squares on the map when abs(DX) = abs(DY).  To achieve the
%   most typical kind of alignment, where X increases from column to column
%   and Y decreases from row to row, make DX positive and DY negative.  In
%   order to specify such an alignment along with square pixels, make DX
%   positive and make DY equal to -DX:
%
%                 R = MAKEREFMAT(X11, Y11, DX, -DX).
%
%   R = MAKEREFMAT(PARAM1, VAL1, PARAM2, VAL2, ...) uses parameter
%   name-value pairs to construct a referencing matrix for an image or
%   raster grid that is referenced to and aligned with a geographic
%   coordinate system. There can be no rotation or skew: each column
%   must fall along a meridian and each row must fall along a parallel.
%   The following parameters may be supplied. Each parameter name must
%   be specified exactly as shown here, including case.
%
%   RasterSize
%   
%      RasterSize is a two-element size vector [M N] specifying the
%      number of rows (M) and columns (N) of the raster or image to be
%      used with the referencing matrix. Default value: [1 1].
%  
%      You may also provide a size vector having more than two elements.
%      This enables usage such as:
%
%           R = makerefmat('RasterSize', size(RGB), ...)
%
%      where RGB is M-by-N-by-3. However in cases like this only the
%      first two elements of the size vector will actually be used. The
%      higher (non-spatial) dimensions will be ignored.
%
%   LatitudeLimits
%  
%      LatitudeLimits (or Latlim) specifies the limits in latitude of the
%      geographic quadrangle bounding the georeferenced raster. It is a
%      two-element vector of the form:
%  
%               [southern_limit northern_limit]
%
%      and is in units of degrees. Default value: [0 1].
%
%   LongitudeLimits
%
%      LongitudeLimits(or Lonlim) specifies the limits in longitude of the
%      geographic quadrangle bounding the georeferenced raster. It is a
%      two-element vector of the form:
%  
%               [western_limit eastern_limit]
%               
%      and is in units of degrees. Default value: [0 1]. The elements of
%      the Lonlim vector must be ascending in value. In other words,
%      the limits must be unwrapped.
%
%   ColumnsStartFrom 
%
%      ColumnsStartFrom indicates the column direction of the raster
%      (south-to-north vs. north-to-south) in terms of the edge from which
%      row indexing starts. It can have the value 'south' or 'north'. The
%      default value is 'south', suiting the typical terrain grid in which
%      row indexing starts at the southern edge. In images, on the other
%      hand, row indexing starts typically at the northern edge. The input
%      can be shortened and is case-insensitive.
%
%   RowsStartFrom
%
%      RowsStartFrom indicates the row direction of the raster
%      (west-to-east vs. east-to-west) in terms of the edge from which
%      column indexing starts. It can have the value: 'west' or 'east'. The
%      default value is 'west', indicating rows that run from west to east,
%      which almost always the case. The input can be shortened and is
%      case-insensitive.
%
%   R = MAKEREFMAT(X11, Y11, DX, DY) with two-element vectors DX and DY
%   constructs the most general possible kind of referencing matrix, for
%   which
%
%     [X11 + ([row col]-1) * DX(:), Y11 + ([row col]-1) * DY(:)]
%                                                = pix2map(R, row, col).
%
%   In this general case, each pixel may become a parallelogram on the map,
%   with neither edge necessarily aligned to map X or Y.  The vector
%   [DX(1) DY(1)] is the difference in map location between a pixel in one
%   row and its neighbor in the preceding row.  Likewise, [DX(2) DY(2)] is
%   the difference in map location between a pixel in one column and its
%   neighbor in the preceding column.
%
%   To specify pixels that are rectangular or square (but possibly
%   rotated), choose DX and DY such that prod(DX) + prod(DY) = 0.  To
%   specify square (but possibly rotated) pixels, choose DX and DY such
%   that the 2-by-2 matrix [DX(:) DY(:)] is a scalar multiple of an
%   orthogonal matrix (i.e., its two eigenvalues are real, non-zero and
%   equal in absolute value).  This amounts to either rotation, a mirror
%   image, or a combination of both. Note that for scalar DX and DY
%
%               R = makerefmat(X11, Y11, [0 DX], [DY 0])
%
%   is equivalent to
%
%                  R = makerefmat(X11, Y11, DX, DY).
%
%   R = MAKEREFMAT(LON11, LAT11, DLON, DLAT), with longitude preceding
%   latitude, constructs a referencing matrix for use with geographic
%   coordinates. In this case
%
%                 [LAT11, LON11] = pix2latlon(R,1,1),
%
%   [LAT11 + (row-1) * DLAT, LON11 + (col-1) * DLON]
%                                               = pix2latlon(R, row, col)
%
%   for scalar DLAT and DLON, and 
%
%   [LAT11 + ([row col]-1) * DLAT(:), LON11 + ([row col]-1) * DLON(:)]
%                                               = pix2latlon(R, row, col)
%
%   for vector DLAT and DLON.
%
%   Example 1
%   ---------
%   Create a referencing matrix for an image with square, four-meter pixels
%   and with its upper left corner (in a map coordinate system) at
%   x = 207000 meters, y = 913000 meters. The image follows the typical
%   orientation:  x increasing from column to column and y decreasing from
%   row to row.
%
%      x11 = 207002;  % Two meters east of the upper left corner
%      y11 = 912998;  % Two meters south of the upper left corner
%      dx =  4;
%      dy = -4;
%      refmat = makerefmat(x11, y11, dx, dy)
%
%   Example 2
%   ---------
%   Create a referencing matrix for a global grid of
%   one-degree-by-one-degree cells.
%   
%      rasterSize = [180 360];
%      refmat = makerefmat('RasterSize', rasterSize, ...
%          'LatitudeLimits', [-90 90], 'LongitudeLimits', [0 360])
%
%   See also GEOREFCELLS, GEOREFPOSTINGS, GEORASTERREF,
%            MAPREFCELLS, MAPREFPOSTINGS, MAPRASTERREF

% Copyright 1996-2020 The MathWorks, Inc.

% Worldfile Matrix to Referencing Matrix
% --------------------------------------
% R = MAKEREFMAT(W) constructs a referencing matrix from a worldfile
% matrix, 
%                   W = [A B C;
%                        D E F]
%
% MAKEREFMAT accepts the 6-element vector [A D B E C F] or its transpose,
% or equivalently, W(:) or W(:)', in addition to a 2-by-3 matrix.
%
% Both W and the general syntax with vector DX and DY provide six
% independent scalar parameters.  They are simply related:
%
%                   W = [DX(2)    DX(1)    X11 
%                        DY(2)    DY(1)    Y11].
%
% and conversely R = makerefmat(W) is equivalent to
%
%         R = makerefmat(W(5), W(6), [W(3) W(1)], [W(4) W(2)]).
%
% See map.internal.referencingMatrix for more information.
%--------------------------------------------------------------------

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if nargin == 0 || ischar(varargin{1})
    % Assume parameter name-value syntax
    R = makeRefmatFromParameters(varargin);
else
    switch(nargin)
        case 1
            W = validateWorldFileMatrix(varargin{1},'makerefmat','W',1);
            R = map.internal.referencingMatrix(W);
        case 4
            R = map.internal.referencingMatrix(constructW(varargin{:}));
        otherwise
            error('map:makerefmat:invalidArgCount', ...
                'Function %s expected either one or four input arguments.', ...
                mfilename)
    end
end

%--------------------------------------------------------------------------

function W = constructW(x11, y11, dx, dy)
% Construct W from inputs X11, Y11, DX, and DY.

validateattributes(x11, {'double'}, {'real','scalar','finite'}, mfilename, 'X11', 1);
validateattributes(y11, {'double'}, {'real','scalar','finite'}, mfilename, 'Y11', 2);

validateattributes(dx, {'double'}, {'real','finite'}, mfilename, 'DX', 1);
validateattributes(dy, {'double'}, {'real','finite'}, mfilename, 'DY', 1);

switch numel(dx)
  case 1,  dx = [0 dx];
  case 2  % dx is already a 2-element vector
  otherwise
    error('map:makerefmat:wrongSizeDX', ...
        'Function %s expected its %s argument, %s, to have one or two elements.', ...
        mfilename, num2ordinal(3), 'DX')
end

switch numel(dy)
  case 1,  dy = [dy 0];
  case 2  % dy is already a 2-element vector
  otherwise
    error('map:makerefmat:wrongSizeDY', ...
        'Function %s expected its %s argument, %s, to have one or two elements.', ...
        mfilename, num2ordinal(3), 'DY')
end

W = [dx(2) dx(1) x11;...
     dy(2) dy(1) y11];
 
%--------------------------------------------------------------------------

function refmat = makeRefmatFromParameters(pvPairs)

%Verify that there are an even number of inputs.
evenNumberOfInputs = (mod(numel(pvPairs),2) == 0);
assert(evenNumberOfInputs, ...
    'map:makerefmat:expectedEvenNumberOfArgs', ...
    ['Function %s expected an even number of input arguments', ...
    ' (parameter name-value pairs).'], mfilename)

% Verify that inputs are name-value pairs.
names = pvPairs(1:2:end);
nonchar = find(~cellfun(@ischar,names));
if ~isempty(nonchar)
    position = 2*nonchar(1) - 1;
    error('map:makerefmat:parameterNameNotString', ...
        ['Function %s expected argument %d to be a parameter name' ...
        ' string instead of class %s.'], mfilename, position, ...
        class(names{nonchar(1)}))
end

% Construct a default geographic raster reference object.
R = georasterref('RasterSize',[1 1], 'LatitudeLimits', [0 1], 'LongitudeLimits', [0 1]);

% Table of parameter names and set functions (implemented as structure).
% If provided, the set function allows use of a makerefmat parameter
% to set the value of the corresponding geographic raster reference
% property.
validParameters = {'RasterSize','LatitudeLimits','Latlim', ...
    'LongitudeLimits','Lonlim','ColumnsStartFrom','RowsStartFrom'};

% Process each input parameter and set the corresponding property of R.
for k = 1:2:numel(pvPairs)
    name  = pvPairs{k};
    value = pvPairs{k + 1};
    
    assert(any(strcmp(name,validParameters)), ...
        'map:makerefmat:invalidParameterName', ...
        ['The string %s is not a valid parameter name', ...
        ' for use with function %s.'], name, 'makerefmat')
    
    switch(name)
        case 'Latlim'
            R.LatitudeLimits = value;
        case 'Lonlim'
            R.LongitudeLimits = value;
        otherwise
            R.(name) = value;
    end
end

refmat = map.internal.referencingMatrix(worldFileMatrix(R));
