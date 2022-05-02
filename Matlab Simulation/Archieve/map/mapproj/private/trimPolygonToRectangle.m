function [x, y] = trimPolygonToRectangle(x, y, xLimits, yLimits, xInc, yInc)
% Intersect a polygon with a rectangle and interpolate edge points.
%
%   Intersect the polygon defined by vectors X and Y with the rectangle
%   defined by the 2-vectors xLimits and yLimits.  X and Y may contain
%   multiple rings separated by NaNs.  Outer rings should be clockwise,
%   inner rings counterclockwise.  If the intersection of a ring with an
%   edge of the polygon results in adjacent vertices separated by more than
%   the threshold values specified in xInc or yInc, then additional
%   vertices are interpolated to decrease the spacing.  xInc and yInc are
%   2-vectors and control vertex spacing along the four edges as follows:
%
%       xInc(1) - bottom edge
%       xInc(2) - top edge
%       yInc(1) - left edge
%       yInc(2) - right edge

% Copyright 2005-2016 The MathWorks, Inc.

if isempty(x)
    return
end

% Use column vectors throughout.
rowVectorInput = (size(x,2) > 1);
if rowVectorInput
    x = x(:);
    y = y(:);
end

% Construct a closed, rectangular, clockwise polygon.
xRect = xLimits([1 1 2 2 1])';
yRect = yLimits([1 2 2 1 1])';

% Set the tolerance for closing nearly-closed rings to 5 degrees.
tol = 5 * pi/180;

% Trim to a vertical line once for each x-limit and each y-limit.  Do the
% y-limits in a system that's been rotated 90-degrees clockwise.  These
% rotations require changing the sign of x.  Make sure to restore the
% original signs after each call.
[x, y] = trimPolygonToVerticalLine(x,  y, xLimits(2), 'upper', tol);
[y, x] = trimPolygonToVerticalLine(y, -x, yLimits(2), 'upper', tol); x = -x;
[x, y] = trimPolygonToVerticalLine(x,  y, xLimits(1), 'lower', tol);
[y, x] = trimPolygonToVerticalLine(y, -x, yLimits(1), 'lower', tol); x = -x;

% Close any open ring that touches the edges of the rectangle on both ends.
% Interpolation increments do double-duty as tolerances for snapping to the
% boundary points that are already close to the boundary.
xTol = xInc;
yTol = yInc;
[x, y] = closeAlongBoundary(x, y, xLimits, yLimits, xTol, yTol);

% Interpolate points along the edges where the original polygon has been
% truncated to fit within the x,y-limits.
[x, y] = interpolateAlongVerticalEdge( x, y, xLimits(1), yInc(1));  % Left edge
[x, y] = interpolateAlongVerticalEdge( x, y, xLimits(2), yInc(2));  % Right edge
[y, x] = interpolateAlongVerticalEdge( y, x, yLimits(1), xInc(1));  % Bottom edge
[y, x] = interpolateAlongVerticalEdge( y, x, yLimits(2), xInc(2));  % Top edge

% Make sure terminating NaNs haven't been lost.
if ~isempty(x) && ~isnan(x(end))
    x(end+1,1) = NaN;
    y(end+1,1) = NaN;
end

% Restore shape, if necessary.
if rowVectorInput
    x = x';
    y = y';
end

%--------------------------------------------------------------------------

function [x, y] = closeAlongBoundary(x, y, xLimits, yLimits, xTol, yTol)

% Close any open ring that touches the edges of the rectangle on both ends.
[xcells, ycells] = polysplit(x, y);
for k = 1:numel(xcells)
    xK = xcells{k};
    yK = ycells{k};
    xK = snapEndsToLimits(xK, xLimits, xTol);
    yK = snapEndsToLimits(yK, yLimits, yTol);
    endPointsDistinct = ((xK(1) + 1i*yK(1)) ~= (xK(end) + 1i*yK(end)));
    if endPointsDistinct && ...
            all(onBoundary(xK([1 end]), yK([1 end]), xLimits, yLimits))
        % Walk around the boundary clockwise starting from the end point,
        % inserting corner points along the way.  Going from the end point
        % to the start point gives a set of new points that will close the
        % ring and which move in a consistent direction.
        [xWalk, yWalk] = ...
            walkBoundary(xK(end), yK(end), xK(1), yK(1), xLimits, yLimits);
        % Start xWalk, yWalk subscript at 2 because (xK(end), yK(end)),
        % which is the same as (xWalk(1), yWalk(1)).
        xcells{k} = [xK; xWalk(2:end)];
        ycells{k} = [yK; yWalk(2:end)];
    end
end
[x, y] = polyjoin(xcells, ycells);

%--------------------------------------------------------------------------

function x = snapEndsToLimits(x, xLimits, xTol)

% Reset the first or last value in x to xLimits(1) if it's within xTol(1)
% of the xLimits(1) or within xTol(2) of xLimits(2).

if abs(x(1) - xLimits(1)) < xTol(1)
    x(1) = xLimits(1);
end

if abs(x(end) - xLimits(1)) < xTol(1)
    x(end) = xLimits(1);
end

if abs(x(1) - xLimits(2)) < xTol(2)
    x(1) = xLimits(2);
end

if abs(x(end) - xLimits(2)) < xTol(2)
    x(end) = xLimits(2);
end

%--------------------------------------------------------------------------

function answer = onBoundary(x, y, xLimits, yLimits)

answer = (x == xLimits(1)) | (x == xLimits(2)) ...
       | (y == yLimits(1)) | (y == yLimits(2));

%--------------------------------------------------------------------------

function [x, y] = walkBoundary(x1, y1, x2, y2, xLimits, yLimits)

% Start at the starting point.
x(1) = x1;
y(1) = y1;

% Trace clockwise around the edges until the end point is reached.
[xn, yn] = nextCorner(x(end), y(end), xLimits, yLimits);
while ~between(x(end), y(end), xn, yn, x2, y2)
    x(end+1,1) = xn;
    y(end+1,1) = yn;
    [xn, yn] = nextCorner(x(end), y(end), xLimits, yLimits);
end

% Finish at the end point.
x(end+1,1) = x2;
y(end+1,1) = y2;

% Convert to column vectors.
x = x(:);
y = y(:);

%--------------------------------------------------------------------------

function [x, y] = nextCorner(x, y, xLimits, yLimits)

% Given a point on the edge of the rectangle defined by xLimits and
% yLimits, find the nearest corner while proceeding in a clockwise
% direction.

if (x == xLimits(1)) && (y < yLimits(2))
    x = xLimits(1);
    y = yLimits(2);
elseif (x > xLimits(1)) && (y == yLimits(1))
    x = xLimits(1);
    y = yLimits(1);
elseif (x == xLimits(2)) && (y > yLimits(1))
    x = xLimits(2);
    y = yLimits(1);
elseif (x < xLimits(2)) && (y == yLimits(2))
    x = xLimits(2);
    y = yLimits(2);
else
    error(message('map:internalProblem:invalidInputs'))
end

%--------------------------------------------------------------------------

function tf = between(x1, y1, x2, y2, xt, yt)

% Return true iff (x1,y1) and (x2,y2) are the endpoints of a perfectly
% vertical or horizontal segment and point (xt,yt) coincides with one of
% them or falls between them on that segment.

vertical   = (x1 == x2) && (y1 ~= y2);
horizontal = (y1 == y2) && (x1 ~= x2);

if vertical
    tf = (xt == x1) && (min(y1,y2) <= yt) && (yt <= max(y1,y2));
elseif horizontal
    tf = (yt == y1) && (min(x1,x2) <= xt) && (xt <= max(x1,x2));
else
    tf = false;
end
