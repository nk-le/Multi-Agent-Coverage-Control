function h = BoundingBox(varargin)
%BOUNDINGBOX Bounding Box coordinates
%
%   BOUNDINGBOX(B) Creates a bounding box object from B. B may be in one of
%   two forms: 
%
%   1. A position vector [X,Y,WIDTH,HEIGHT] 
%
%   2. The lower-left and upper-right corners [lower-left-x,y; upper-right-x,y],
%   
%      or equivalently,  [left      bottom;
%                         right        top]
%
%   BOUNDINGBOX(R,rasterSize) Creates a bounding box object from a
%   referencing matrix or map raster reference object, R, and a rasterSize
%   vector.

% Copyright 1996-2020 The MathWorks, Inc.

    if nargin < 2
        h = boundingBoxFromPositionOrCorners(varargin{:});
    else
        h = boundingBoxFromRaster(varargin{:});
    end
end


function h = boundingBoxFromPositionOrCorners(b)
    h = MapModel.BoundingBox;
    if all(size(b) == [1 4]) % Position Vector
        h.PositionVector = b;
        corners = [ ...
            b(1)          b(2);
            b(1) + b(3)   b(2) + b(4)];
        h.Corners = [ ...
            min(corners(:,1)), min(corners(:,2));
            max(corners(:,1)), max(corners(:,2))];
    elseif all(size(b) == [2 2]) % Box corners
        h.Corners = b;
        corner = b(1,:);
        h.PositionVector = [corner diff(b)];
    else
        error('map:MapGraphics:invalidBox', ...
            ['%s must be a position vector %s,', ...
            ' or the lower-left and upper-right corners %s\n'], ...
            'B', '[X,Y,WIDTH,HEIGHT]', '[lower-left-x,y; upper-right-x,y]')
    end
end


function h = boundingBoxFromRaster(R, rasterSize)
    if isobject(R)
        % Compute bounding box from raster reference object.
        b = [sort(R.XWorldLimits)' sort(R.YWorldLimits)'];
    else
        % Compute bounding box from referencing matrix.
        h = rasterSize(1);
        w = rasterSize(2);
        outline = [(0.5 + [0  0;...
                           0  w;...
                           h  w;...
                           h  0]), ones(4,1)] * R;
        b = [min(outline); max(outline)];
    end
    h = boundingBoxFromPositionOrCorners(b);
end
