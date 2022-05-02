function [x, y] = interpolateAlongVerticalEdge(x, y, xEdge, yInc)

% Interpolate and insert new points in the polygon defined by X and Y, as
% determined by the scalar yInc, along the edge of the rectangle (where x
% == xEdge).  With suitable changes to its inputs, this function can be
% applied in sequence to all four edges of a rectangle.

% Copyright 2005-2006 The MathWorks, Inc.

% Make x diff array that's the same size as x.  The pad value
% doesn't matter, except that it must not be zero.
xDiff = [diff(x); 1];

% Find adjacent points on the edge of the rectangle where x == xEdge.
kEdge = find((xDiff == 0) & (x == xEdge));

% Flip kEdge to facilitate insertions of values into x and y. (Insert
% additional sequences of points starting toward the end of the arrays so
% as not to invalidate the index values in kEdge itself.)
kEdge = flipud(kEdge);

% Loop over all detected pairs on the left edge, inserting new points
% when the current spacing is larger than yInc
for j = 1:numel(kEdge)
    k = kEdge(j);
    n = 2 + floor(abs(y(k+1) - y(k)) / yInc);
    if n > 2
        % Construct coordinates of new points to insert.  (Discard the
        % start and end values of the array from linspace to avoid
        % duplicates.)
        yNew = linspace(y(k), y(k+1), n)';
        yNew([1; n]) = [];
        xNew = xEdge + zeros(size(yNew));
        
        % Insert new points via a simple contenation and resize operation.
        x = [x(1:k); xNew; x((k+1):end)];
        y = [y(1:k); yNew; y((k+1):end)];
    end
end
