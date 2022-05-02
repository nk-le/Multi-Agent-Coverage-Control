function [x, y] = filterEdgeSegments(x, y, xLimit, yLimit)
%filterEdgeSegments Remove line segments on edge of bounding rectangle
%
%   [x, y] = filterEdgeSegments(x, y, xLimit, yLimit)
%
%   Given a multipart line defined by the vertices in vectors x and y, with
%   the breaks between parts defined by NaN values in x and y, remove from
%   any open parts in (x,y) all segments that follow the edge of the
%   bounding rectangle defined by the 1-by-2 vectors xLimit and yLimit. In
%   some cases this may involve breaking a single part into multiple parts.
%   Assume that all elements of x are bounded by xLimit(1) and xLimit(2),
%   and likewise with y and yLimit. (Note: only open parts are affected;
%   closed parts with edge segments are unchanged.)

% Copyright 2012 The MathWorks, Inc.

% Note that it's possible all vertices in a segment to fall on the edge,
% but for part of the segment to cut across a corner of the rectangle.
% Here's a simple example: x = [0 1]; y = [1, 0]. These vectors define a
% diagonal line connecting the vertex(0,1) to the vertex (1,0). It does not
% lie on the edge. This example makes it clear that x and y must be
% examined segment by segment, not just vertex by vertex.

% Identify vertices that belong to open parts.
[first, last] = internal.map.findFirstLastNonNan(x);
closed = (x(first) == x(last)) & (y(first) == y(last));
closed = closed(last >= first + 2);
first(closed) = [];
last(closed)  = [];
inOpenPart = false(size(x));
for k = 1:numel(first)
    inOpenPart(first(k):last(k)) = true;
end

% Identify segments to be removed. The segment must belong to an open part
% and its start and end points must both fall on the _same_ edge of the
% bounding rectangle. Note that length(removeSegment) = length(x) - 1.
removeSegment = inOpenPart(1:end-1) & inOpenPart(2:end) & ( ...
      (x(1:end-1) == xLimit(1) & x(2:end) == xLimit(1)) ...
    | (x(1:end-1) == xLimit(2) & x(2:end) == xLimit(2)) ...
    | (y(1:end-1) == yLimit(1) & y(2:end) == yLimit(1)) ...
    | (y(1:end-1) == yLimit(2) & y(2:end) == yLimit(2)));

% Ensure that removeSegment is a row vector.
removeSegment = removeSegment(:)';

if any(removeSegment)
    % Remove each vertex that starts or ends a part, if it's part of a
    % segment that needs to be removed.
    
    % Locate the NaNs; work with row vectors throughout.
    n = isnan(x(:)');
    
    % Set isFirstInPart to true for the first vertex and for each vertex
    % that immediately follows a NaN-separator.
    isFirstInPart = [true n(1:end-1)];
    
    % Set isLastInPart to true for the last vertex and for each vertex that
    % immediately precedes a NaN-separator.
    isLastInPart = [n(2:end) true];
    
    % Identify vertices that start or end segments to be removed.
    startsSegmentToBeRemoved = [removeSegment false];
    endsSegmentToBeRemoved   = [false removeSegment];
    
    % Very provisional list of verticies to be removed.
    removeVertex = (isFirstInPart & startsSegmentToBeRemoved) ...
        | (isLastInPart & endsSegmentToBeRemoved);
    
    % If a vertex does not start or end a part, then it's the start point
    % of one segment and the end point of the next.  Such a vertex should
    % be removed if and only if both segments in which it participates need
    % to be removed. Identify a provisional list of segments to be removed.
    % Only vertices for which removeVertex (as computed in the following
    % statement) is true should be removed -- but the list is provisional;
    % some of them might not need to be removed after all.
    removeVertex(endsSegmentToBeRemoved & startsSegmentToBeRemoved) = true;
    
    % The part containing any segment to be removed, in which neither
    % vertex is to be removed, needs to be broken apart at the location of
    % that segment.
    [x, y, removeVertex] = breakSegments(x, y, removeVertex, removeSegment);
    
    if any(removeVertex)
        % Remove vertices and replace with NaN-separators where required to
        % break a single part into multiple parts.
        
        % Replace the vertices to be removed with NaN.
        x(removeVertex) = NaN;
        y(removeVertex) = NaN;
        
        % Remove extraneous NaNs (including a leading NaN, if any).
        [x, y] = removeExtraNanSeparators(x,y);
    end
end

%--------------------------------------------------------------------------

function [x, y, removeVertex] ...
    = breakSegments(x, y, removeVertex, removeSegment)
% Check to see if there are any segments to be removed, in which neither
% vertex is to be removed.  Insert part-separating NaNs in x and y to at
% such locations, and update the removeVertex array as well.

% If we're removing a segment, but not removing either of the vertices that
% form the segment, then we need to insert a break.
breaks = find(removeSegment ...
    & ~(removeVertex(1:end-1) | removeVertex(2:end)));

for k = 1:numel(breaks)
    % Insert NaN to break segment; insert false at the same location in
    % removeVertex. Note that numel(x) changes with each iteration,
    % so it needs to be determined within the loop.
    
    % Add k to advance the break location, taking into account the
    % resizing.
    b = k + breaks(k);
    
    % Construct an index that duplicates the b-th element of a vector
    % the size of x.
    ind = [1:b b (b+1):numel(x)];
    
    % Duplicate the b-th element of x, y, and the removeVertex vector.
    x = x(ind);
    y = y(ind);
    removeVertex = removeVertex(ind);
    
    % Replace the duplicates with NaN, in the case of x and y, and false,
    % in the case of removeVertex.
    x(b) = NaN;
    y(b) = NaN;
    removeVertex(b) = false;
end
