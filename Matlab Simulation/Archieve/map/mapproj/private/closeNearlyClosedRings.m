function [x, y] = closeNearlyClosedRings(x, y, tol, checkEndPoints)
% Patch up rings that don't quite close. X and Y are NaN-separated
% arrays of polygon vertex coordinates. TOL is the distance tolerance
% for closing rings. checkEndPoints is a function handle that returns
% two logical arrays.

% Copyright 2008-2009 The MathWorks, Inc.

nanTerminated = (~isempty(x) && isnan(x(end)));

[first, last] = internal.map.findFirstLastNonNan(x);

[endPointsCoincide, endPointsWithinTolerance] ...
    = checkEndPoints(x(first), y(first), x(last), y(last), tol);

replicateFirst = ~endPointsCoincide & endPointsWithinTolerance;

if any(replicateFirst)
    s = cumsum(replicateFirst);
    newlast = last + s;
    newfirst = [1; 2 + newlast(1:end-1)];
    newx = NaN + zeros(newlast(end),1);
    newy = NaN + zeros(newlast(end),1);
    for k = 1:numel(first)
        if replicateFirst(k)
            newx(newfirst(k):(newlast(k)-1)) = x(first(k):last(k));
            newy(newfirst(k):(newlast(k)-1)) = y(first(k):last(k));
            newx(newlast(k)) = x(first(k));
            newy(newlast(k)) = y(first(k));
        else
            newx(newfirst(k):newlast(k)) = x(first(k):last(k));
            newy(newfirst(k):newlast(k)) = y(first(k):last(k));
        end
    end
    x = newx;
    y = newy;
end

% Restore NaN-terminators, in case they were removed.
if nanTerminated && ~isempty(x) && ~isnan(x(end))
    x(end+1,1) = NaN;
    y(end+1,1) = NaN;
end
