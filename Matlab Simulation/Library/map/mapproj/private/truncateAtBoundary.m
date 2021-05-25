function [x, y] = truncateAtBoundary(x, y, xBound, curveIsPolygon)

% Truncate the curve defined by the coordinate arrays x and y,
% eliminating vertices for which x > xBound and interpolating new
% vertices along the boundary as needed.  For polygons, allow sections
% of curves that were connected by loops to the right of the boundary to
% remain connected.  For lines, break such sections where they meet the
% boundary.

% Copyright 2007-2009 The MathWorks, Inc.  

if curveIsPolygon
    truncate = @truncateForPolygon;
    insert = @insertForPolygon;
else
    truncate = @truncateForLine;
    insert = @insertForLine;
end

% Find places where the curve has crossed the bounding line without having
% an intersection point on the line itself.
signDiff = diff(sign(x - xBound)); 
kCrossing = find(abs(signDiff) == 2);

% Flip kCrossing to facilitate inserting values into x and y. (Insert
% additional points starting toward the end of the arrays so as not to
% invalidate the index values in kCrossing itself.)
kCrossing = flipud(kCrossing);

% For each k in kCrossing, interpolate linearly between (x(k),y(k)) and
% (x(k+1),y(k+1)) to a new point where x == xBound.
for j = 1:numel(kCrossing)
    k = kCrossing(j);
    dx = x(k + 1) - x(k);
    weightK  = (x(k + 1) - xBound) / dx;
    weightK1 = (xBound - x(k)) / dx;
    xNew = xBound;
    yNew  = weightK * y(k) + weightK1 * y(k + 1);
    [x, y] = insert(k, xNew, yNew, x, y, dx);
end    

% Remove points beyond the boundary.
[x, y] = truncate(x, y, xBound);

%-----------------------------------------------------------------------

function [x, y] = insertForPolygon(k, xNew, yNew, x, y, dx) %#ok<INUSD>

% Insert the new point via a simple contenation and resize operation.

x = [x(1:k); xNew; x((k+1):end)];
y = [y(1:k); yNew; y((k+1):end)];

%-----------------------------------------------------------------------

function [x, y] = insertForLine(k, xNew, yNew, x, y, dx)

% Insert the new point via a simple contenation and resize operation,
% placing NaNs to separate the new point from the next vertex beyond the
% boundary.

crossingLeftToRight = (dx > 0);
if crossingLeftToRight
    xInsert = [xNew; NaN];
    yInsert = [yNew; NaN];
else
    xInsert = [NaN; xNew];
    yInsert = [NaN; yNew];
end
x = [x(1:k); xInsert; x((k+1):end)];
y = [y(1:k); yInsert; y((k+1):end)];

%-----------------------------------------------------------------------

function [x, y] = truncateForPolygon(x, y, xBound)

% Eliminate all points for which x > xBound, allowing truncated
% sections to remain connected along the bounding line.

q = (x > xBound);
x(q) = [];
y(q) = [];

%-----------------------------------------------------------------------

function [x, y] = truncateForLine(x, y, xBound)

% Eliminate all points for which x > xBound, breaking truncated sections
% along the bounding line.

% Replace the coordinate values for all such points with NaN
q = (x > xBound);
x(q) = NaN;
y(q) = NaN;

% Remove any excess NaN-separators
q = isnan(x);
q = q & [q(2:end); false];
x(q) = [];
y(q) = [];
