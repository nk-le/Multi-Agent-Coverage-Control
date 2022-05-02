function A = signedPolygonArea(x,y)
%signedPolygonArea Polygon area with sign dependent on vertex order
%
%   A = signedPolygonArea(x,y) returns the area of the polygon bounded by
%   curves with vertices specified by vectors x and y. In the case of a
%   simple closed curve, the result is:
%
%      Positive for clockwise vertex order
%      Negative for counter-clockwise vertex order
%      Zero if there are fewer than 3 vertices
%
%   The polygon boundary may consist of muliple (simple closed) curves,
%   separated by NaN values at matching indices in x and y (comprising
%   several disjoint and or "holes" within a region). In this case, A is
%   the sum of the signed areas of the individual curves.
%
%   Equivalent to polyarea(x,y) or area(polyshape(x,y)), when all vertices
%   run clockwise.
%
%   See also ISPOLYCW, POLYAREA, POLYSHAPE

% Copyright 2018 The MathWorks, Inc.

[first, last] = internal.map.findFirstLastNonNan(x);
A = 0;
for k = 1:numel(first)
    s = first(k);
    e = last(k);
    A = A + map.internal.simplePolygonArea(x(s:e), y(s:e));
end
