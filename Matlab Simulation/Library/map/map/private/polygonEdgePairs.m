function [edgePairIndex, x, y] = polygonEdgePairs(x, y, xBound)
% Given column vectors x and y forming a closed, multi-part polygon,
% return a 2-by-N array with the indices of adjacent pairs of vertices
% on that edge. Assume that extra edge vertices have already been
% removed.

% Copyright 2010 The MathWorks, Inc.

% Update the edge index to account for vertex removal.
edgeIndex = find(x == xBound);

% Narrow down to pairs of adjacent edge vertices.
if numel(edgeIndex) > 1
    pairs = (diff(edgeIndex) == 1);
    if ~isempty(pairs)
        pairs = [false; pairs] | [pairs; false];
    end
    edgeIndex(~pairs) = [];
else
    edgeIndex = [];
end

% At this point, numel(edgeIndex) should be even. Reshape it so that
% there is one column for each pair of adjacent edge vertices.
edgePairIndex = reshape(edgeIndex,  [2, numel(edgeIndex)/2]);
