function [xLinked, yLinked] ...
    = linkOpenCurvesAlongBoundary(x, y, xLimit, yLimit, C, B)
% Convert open curves into a set of closed polygons by combining
% topologically adjacent curves along with corner points as needed. Or,
% if there are no open curves but there are unenclosed counter-clockwise
% loops, add an enclosing rectangle. This function should be used only
% B is non-empty.

% Copyright 2010 The MathWorks, Inc.

assert(~isempty(B), 'map:linkOpenCurvesAlongBoundary:noOpenCurves', ...
    'Expected structure array B to have at least one element.')

% Sort B in terms of the "position" at which each curve starts.
posFirst = [B.PosFirst];
[posFirst,I] = sort(posFirst);
B = B(I);

% Link each open curve to one that follows (which could be itself), in the
% following sense: Starting from the last vertex in a given curve, find
% the curve whose first vertex has the next highest "position."
for k = 1:numel(B)
    next = find(B(k).PosLast <= posFirst);
    if isempty(next)
        % Wrap around
        B(k).Next = 1;
    else
        B(k).Next = next(1);
    end
end

xEdge = xLimit([1 1 2 2 1]);
yEdge = yLimit([1 2 2 1 1]);    

% edgePositions = computePositionOnBoundary( ...
%     xEdge(1:end-1), yEdge(1:end-1), xLimit, yLimit);
edgePositions = (0:3);

% Trace to count vertices in closed curves, including NaN-separators.
numVertices = 0;
for k = 1:numel(C)
    numVertices = numVertices + C(k).Last - C(k).First + 2;
end

% Keep track of the number of curves traced in relation to the total
% number, to ensure that the while loop terminates (see assert below).
nOpen = numel(B);
nTraced = 0;

% Trace to count vertices for linked curves.
traced = false(size(B));
k = 1;
while any(~traced)
    % Ensure that the loop cannot run forever. The following
    % assertion should never be triggered.
    nTraced = nTraced + 1;
    assert(nTraced <= nOpen, ...
        'map:linkOpenCurvesAlongBoundary:tracingFailed1', ...
        'Failed to converge when tracing open curves.')
            
    if traced(k)
        k = find(~traced);
        k = k(1);
        numVertices = numVertices + 1; % Allow for NaN-separator
    end
    numVertices = numVertices + B(k).Last - B(k).First + 1;
    traced(k) = true;
    position1 = B(k).PosLast;
    k = B(k).Next;
    position2 = B(k).PosFirst;
    edgeIndx = positionsTraversed(position1, position2, edgePositions);
    numVertices = numVertices + numel(edgeIndx);
    if traced(k)
        % Allocate additional vertex to close curve.
        numVertices = numVertices + 1;
    end
end
numVertices = numVertices + 1; % Allow for NaN-separator

% Allocate output arrays.
xLinked = NaN(1,numVertices);
yLinked = NaN(1,numVertices);

% Trace to link up open curves and add corner vertices.
traced = false(size(B));
nTraced = 0;
k = 1; % Index to current open curve
n = 1; % Index to current position in output vertex arrays
f = 1; % Index to start of current curve in set of linked curves
while any(~traced)
    nTraced = nTraced + 1;
    assert(nTraced <= nOpen, ...
        'map:linkOpenCurvesAlongBoundary:tracingFailed2', ...
        'Failed to converge when tracing open curves.')
            
    if traced(k)
        k = find(~traced);
        k = k(1);
        n = n + 1; % Allow for NaN-separator
    end
    first = B(k).First;
    last  = B(k).Last;
    m = n + last - first;
    xLinked(n:m) = x(first:last);
    yLinked(n:m) = y(first:last);
    traced(k) = true;
    k1 = k;
    k = B(k).Next;
    edgeIndx = positionsTraversed(B(k1).PosLast, B(k).PosFirst, edgePositions);
    n = m + 1;
    m = n + numel(edgeIndx) - 1;
    xLinked(n:m) = xEdge(edgeIndx);
    yLinked(n:m) = yEdge(edgeIndx);
    if traced(k)
        % Time to close up curve and replicate first vertex if needed.
        m = m + 1;
        xLinked(m) = xLinked(f);
        yLinked(m) = yLinked(f);
        f = m + 2;
    end
    n = m + 1;
end

% Append the closed curves.
n = n + 1;
for k = 1:numel(C)
    first = C(k).First;
    last  = C(k).Last;
    m = n + last - first;
    xLinked(n:m) = x(first:last);
    yLinked(n:m) = y(first:last);
    n = m + 2;
end

%-----------------------------------------------------------------------

function indx = positionsTraversed(position1, position2, positions)
% Given a sorted vector of "positions" in the interval [0 4), return, in
% sequence, the linear indices of the elements of this position vector that
% are traversed when moving from position 1 to position 2 in order of
% increasing position.

if position1 <= position2
    indx = find(position1 < positions & positions < position2);
else
    indx = [find(position1 < positions) find(positions < position2)];
end
