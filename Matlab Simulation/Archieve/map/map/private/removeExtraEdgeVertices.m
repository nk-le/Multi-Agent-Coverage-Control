function [x, y] = removeExtraEdgeVertices(x, y, xBound)
% Remove extra vertices from the edge x == xBound. A vertex is "extra"
% if both the preceding and following vertices are on the same edge.

% Copyright 2010 The MathWorks, Inc.

edgeIndex = find((x == xBound));
extra = (diff(edgeIndex) == 1);
if ~isempty(extra)
    extra = [false; extra] & [extra; false];
end
x(edgeIndex(extra)) = [];
y(edgeIndex(extra)) = [];
