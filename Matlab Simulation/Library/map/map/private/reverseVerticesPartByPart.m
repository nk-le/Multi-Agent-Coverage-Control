function [x, y] = reverseVerticesPartByPart(x, y)
% Reverse the coordinate vertices in vectors X and Y, operating
% separately on each NaN-separated part.

% Copyright 2010-2015 The MathWorks, Inc.

    [first, last] = internal.map.findFirstLastNonNan(x);
    for k = 1:numel(first)
        s = first(k);
        e = last(k);
        x(s:e) = x(e:-1:s);
        y(s:e) = y(e:-1:s);
    end
end
