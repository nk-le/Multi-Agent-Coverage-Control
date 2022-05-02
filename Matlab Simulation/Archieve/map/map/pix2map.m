function varargout = pix2map(R, varargin)
%PIX2MAP Convert pixel coordinates to map coordinates
%
%   [X,Y] = PIX2MAP(R,ROW,COL) calculates map coordinates X, Y from
%   pixel coordinates ROW, COL.  R is either a 3-by-2 referencing matrix
%   defining a 2-dimensional affine transformation from intrinsic pixel
%   coordinates to map coordinates, or a map raster reference object.  ROW
%   and COL are vectors or arrays of matching size. The outputs X and Y
%   have the same size as ROW and COL.
%
%   S = PIX2MAP(R,ROW,COL) combines X and Y into a single array S.  If ROW
%   and COL are column vectors of length N, then S is an N-by-2 matrix and
%   each row (S(k,:)) specifies the map coordinates of a single point.
%   Otherwise, S has size [size(ROW) 2], and S(k1,k2,...,kn,:) contains the
%   map coordinates of single point.
%
%   [...] = PIX2MAP(R,P) combines ROW and COL into a single array P.  If
%   ROW and COL are column vectors of length N, then P should be an N-by-2
%   matrix such that each row (P(k,:)) specifies the pixel coordinates of a
%   single point.  Otherwise, P should have size [size(ROW) 2], and
%   P(k1,k2,...,kn,:) should contain the pixel coordinates of single point.
%
%   Example 
%   -------
%   % Find the map coordinates for the pixel at (100,50).
%   [X,cmap] = imread('concord_ortho_w.tif');
%   R = worldfileread('concord_ortho_w.tfw','planar',size(X));
%   [x,y] = pix2map(R,100,50)
%
%   See also MAPREFCELLS, WORLDFILEREAD

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(2,3)
nargoutchk(0,2)

% Validate referencing matrix or map raster reference object.
map.rasterref.internal.validateRasterReference(R,'planar','pix2map','R',1)

% Check inputs, package coordinates into column vectors (row, col).
[row, col, coordArraySize] = parseCoordinateInputs(varargin);

if isobject(R)
    [x, y] = R.intrinsicToWorld(col, row);
else
    [x, y] = pix2map_refmat(R, row, col);
end

% Reshape output coordinate arrays (x, y) and package them into a
% one- or two-element cell array.
varargout = packageOutputs(nargout, coordArraySize, x, y);

%--------------------------------------------------------------------------
function [x, y] = pix2map_refmat(R, row, col)
% Apply the transformation (using referencing matrix R)
%
%     [x y] = [row col 1] * R
%
% in a way that is robust with respect to large offsets from the origin.

t = [row col] * R(1:2,:);
x = t(:,1) + R(3,1);
y = t(:,2) + R(3,2);

%--------------------------------------------------------------------------
function [row, col, coordArraySize] = parseCoordinateInputs(coordinates)

switch(length(coordinates))
    
    case 1   % PIX2MAP(R,P)
        p = coordinates{1};
        sizep = size(p);
        if sizep(end) ~= 2
             error('map:validate:lastDimNotSize2', ...
                 'The highest dimension of %s must have size 2.', 'P');
        end
        if length(sizep) > 2
             coordArraySize = sizep(1:end-1);
        else
             coordArraySize = [sizep(1) 1];
        end
        p = reshape(p,prod(coordArraySize),2);
        row = p(:,1);  % Column vector
        col = p(:,2);  % Column vector
        
    case 2   % PIX2MAP(R,ROW,COL)
        row = coordinates{1};
        col = coordinates{2};
        if any(size(row) ~= size(col))
            error('map:validate:inconsistentSizes', ...
                '%s and %s must have the same size.', 'ROW', 'COL');
        end
        coordArraySize = size(row);
        row = row(:);  % Column vector
        col = col(:);  % Column vector
      
    otherwise
        error('map:misc:internalError', ...
            '%s: Internal error.', 'pix2map');
end

%--------------------------------------------------------------------------
function outputs = packageOutputs(nOutputArgs, coordArraySize, x, y)

switch(nOutputArgs)
     case {0,1}
        if length(coordArraySize) == 2 && coordArraySize(2) == 1
            outputSize = [coordArraySize(1) 2];
        else
            outputSize = [coordArraySize 2];
        end
        outputs = {reshape(cat(2,x,y),outputSize)};
    case 2
        outputs = {reshape(x,coordArraySize),...
                   reshape(y,coordArraySize)};
    otherwise
        error('map:misc:internalError', ...
            '%s: Internal error.', 'pix2map');
end
