function varargout = map2pix(R,varargin)
%MAP2PIX Convert map coordinates to pixel coordinates
%
%   [ROW,COL] = MAP2PIX(R,X,Y) calculates pixel coordinates ROW, COL from
%   map coordinates X, Y.  R is either a 3-by-2 referencing matrix
%   defining a 2-dimensional affine transformation from intrinsic pixel
%   coordinates to map coordinates, or a map raster reference object.  X
%   and Y are vectors or arrays of matching size.  The outputs ROW and COL
%   have the same size as X and Y.
%
%   P = MAP2PIX(R,X,Y) combines ROW and COL into a single array P.  If X
%   and Y are column vectors of length N, then P is an N-by-2 matrix and
%   each (P(k,:)) specifies the pixel coordinates of a single point.
%   Otherwise, P has size [size(ROW) 2], and P(k1,k2,...,kn,:) contains the
%   pixel coordinates of a single point.
%
%   [...] = MAP2PIX(R,S) combines X and Y into a single array S.  If X and
%   Y are column vectors of length N, the S should be an N-by-2 matrix such
%   that each row (S(k,:)) specifies the map coordinates of a single point.
%   Otherwise, S should have size [size(X) 2], and S(k1,k2,...,kn,:) should
%   contain the map coordinates of a single point.
%
%   Example 
%   -------
%   % Find the pixel coordinates for the spatial coordinates 
%   % (207050, 912900)
%   [X,cmap] = imread('concord_ortho_w.tif');
%   R = worldfileread('concord_ortho_w.tfw','planar',size(X));
%   [row,col] = map2pix(R,207050,912900)
%
% See also MAPREFCELLS, WORLDFILEREAD

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(2,3)
nargoutchk(0,2)

% Validate referencing matrix or map raster reference object.
map.rasterref.internal.validateRasterReference(R,'planar','map2pix','R',1)

% Check inputs, package coordinates into column vectors (x,y).
[x, y, coordArraySize] = parseCoordinateInputs(varargin);

if isobject(R)
    [col, row] = R.worldToIntrinsic(x, y);
else
    [row, col] = map2pix_refmat(R, x, y);
end

% Reshape output pixel coordinates (P) and package into a one-
% or two-element cell array.
varargout = packageOutputs(nargout, coordArraySize, row, col);

%--------------------------------------------------------------------------
function [row, col] = map2pix_refmat(R, x, y)
% Invert the transformation
%
%     [x y] = [row col 1] * R
%
% in a way that is robust with respect to large offsets from the origin.

P = [x - R(3,1), y - R(3,2)]/R(1:2,:);

row = P(:,1);
col = P(:,2);

%--------------------------------------------------------------------------
function [x, y, coordArraySize] = parseCoordinateInputs(coordinates)

switch(length(coordinates))
    
    case 1   % MAP2PIX(R,S)
        s = coordinates{1};
        sizes = size(s);
        if sizes(end) ~= 2
             error('map:validate:lastDimNotSize2', ...
                 'The highest dimension of %s must have size 2.', 'S');
        end
        if length(sizes) > 2
             coordArraySize = sizes(1:end-1);
        else
             coordArraySize = [sizes(1) 1];
        end
        s = reshape(s,prod(coordArraySize),2);
        x = s(:,1);  % Column vector
        y = s(:,2);  % Column vector
        
    case 2   % MAP2PIX(R,X,Y)
        x = coordinates{1};
        y = coordinates{2};
        if any(size(x) ~= size(y))
            error('map:validate:inconsistentSizes', ...
                '%s and %s must have the same size.', 'X', 'Y');
        end
        coordArraySize = size(x);
        x = x(:);  % Column vector
        y = y(:);  % Column vector
      
    otherwise
        error('map:misc:internalError', ...
            '%s: Internal error.', 'map2pix');
end

%--------------------------------------------------------------------------
function outputs = packageOutputs(nOutputArgs, coordArraySize, row, col)

switch(nOutputArgs)
    case {0,1}
        if length(coordArraySize) == 2 && coordArraySize(2) == 1
            outputSize = [coordArraySize(1) 2];
        else
            outputSize = [coordArraySize 2];
        end
        outputs = {reshape(cat(2,row,col),outputSize)};

    case 2
        outputs = {reshape(row,coordArraySize),...
                   reshape(col,coordArraySize)};
    otherwise
        error('map:misc:internalError', ...
            '%s: Internal error.', 'map2pix');
end
