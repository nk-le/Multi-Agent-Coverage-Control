function [x, y] = trimPolylineToVerticalLine(x, y, xBound, boundType)
% Trim a multi-part line defined by column vectors X and Y to the halfspace
% bounded by xBound, interpolating a new point at each place where a line
% segment crosses the line x = xBound. X and Y contain NaN-separators to
% separate the individual parts of the polyline.
%
% If boundType is 'upper', the line is trimmed such that x <= xBound.
% If boundType is 'lower', the line is trimmed such that x >= xBound.

% Copyright 2008 The MathWorks, Inc.  

if isempty(x)
    return
end

% Use a sign flip to reflect across x == 0 so that we can treat lower
% bounds the same way as upper bounds. Then reflect across y == 0 so to
% preserved right-handedness.
usingLowerBound = strncmpi(boundType, 'lower', numel(boundType));
if usingLowerBound
    x = -x;
    y = -y;
    xBound = -xBound;
end

% Perform basic truncation, interpolating an extra point each time a
% curve crosses the vertical line x == xBound, and eliminating bounds
% where x > xBound.  The last argument (false) indicates that we want to
% trim lines instead of polygons.
[x, y] = truncateAtBoundary(x, y, xBound, false);

% Reverse any sign flips.
if usingLowerBound
    x = -x;
    y = -y;
end
