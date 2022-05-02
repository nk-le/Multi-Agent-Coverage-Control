function [x, y] = trimPolygonToVerticalLine(x, y, xBound, boundType, tol)
%   Trims a multi-part polygon defined by vectors X and Y to the halfspace
%   bounded by xBound, interpolating a new point at each place where a line
%   segment crosses the line x = xBound.
%
%   If boundType is 'upper', the polygon is trimmed such that x <= xBound.
%   If boundType is 'lower', the polygon is trimmed such that x >= xBound.
%
%   Polygons that nearly close are closed fully if their endpoints are
%   within distance TOL of each other.

% Copyright 2005-2016 The MathWorks, Inc.

if isempty(x)
    return
end

% Do all internal operations using column vectors.
usingRowVectors = (size(x,2) > 1);
if usingRowVectors
    x = x(:);
    y = y(:);
end

% Make sure to close rings that are supposed to be closed.
[x, y] = closeNearlyClosedRings(x, y, tol, @checkEndPoints);

% Use a sign flip to reflect across x == 0 so that we can treat lower
% bounds the same way as upper bounds. Then reflect across y == 0 so to
% preserved right-handedness.
usingLowerBound = strncmpi(boundType, 'lower', numel(boundType));
if usingLowerBound
    x = -x;
    y = -y;
    xBound = -xBound;
end

% Perform basic truncation on the curves ("lines") that make up the
% polygons, interpolating an extra point each time a curve crosses the
% vertical line x == xBound, and eliminating bounds where x > xBound.
[x, y] = truncateAtBoundary(x, y, xBound);

% Break into organized parts with end points on the boundary.  Clear out
% null parts and isolated singleton points left over from truncation.
[xcells, ycells] = partitionAndClear(x, y, xBound);

% Separate out the parts that don't touch the boundary.
[xcells, ycells, xNonBounding, yNonBounding] ...
    = separateNonBoundingParts(xcells, ycells, xBound);

% Combine parts that were part of the same closed ring and were separated
% only because the x-position of the start/stop point is less than xBound.
[xcells, ycells] = reconnectBrokenRings(xcells, ycells, xBound);

% Organize the parts that touch the boundary into three types.  If the
% endpoints of a part of type 'outer' are joined by adding a segment along
% the boundary, then it forms a closed, clockwise ring.  In the case of an
% 'inner' part, such a closed ring would be counter-clockwise.  Only one
% end of 'loose-end' part touches the boundary.
[xOuter, yOuter, xInner, yInner, xLoose, yLoose] ...
    = identifyPartTypes(xcells, ycells, xBound);
clear('xcells', 'ycells')

% Combine each inner part with the outer part, if any, that most tightly
% encloses it.  Remove enclosed inner parts from the inner parts arrays.
[xOuter, yOuter, xInner, yInner] ...
    = mergeEnclosedInnerParts(xOuter, yOuter, xInner, yInner);

% Where possible, combine/concatenate un-enclosed inner parts and loose ends.
[xInner, yInner] ...
    = mergeInnerPartsAndLooseEnds(xInner, yInner, xLoose, yLoose, xBound);
clear('xLoose', 'yLoose')

% Put all the parts together and return to NaN-separated form.
[x, y] = polyjoin([xOuter; xInner; xNonBounding], ...
                  [yOuter; yInner; yNonBounding]);

% Reverse any sign flips.
if usingLowerBound
    x = -x;
    y = -y;
end

% Make output shape consistent with input.
if usingRowVectors
    x = x';
    y = y';
end

%-----------------------------------------------------------------------

function [x, y] = truncateAtBoundary(x, y, xBound)

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
    
    % Insert the new point via a simple concatenation and resize operation.
    x = [x(1:k); xNew; x((k+1):end)];
    y = [y(1:k); yNew; y((k+1):end)];
end    

% Eliminate all points for which x > xBound.
discard = (x > xBound);
x(discard) = [];
y(discard) = [];

%-----------------------------------------------------------------------

function [xcells, ycells] = partitionAndClear(x, y, xBound)

% Break into parts wherever there is a run of two or more consecutive
% points with x = xBound.
onBoundary = (x == xBound);
onBoundary(1) = false;
onBoundary(end) = false;

% Find adjacent groups of boundary points.
kBoundary = find(onBoundary);
kAdjacent = kBoundary(find(diff(kBoundary) == 1));  %#ok<FNDSB>
kAdjacent = flipud(kAdjacent);
for j = 1:numel(kAdjacent)
    % Insert NaN via a simple concatenation and resize operation.
    k = kAdjacent(j);
    x = [x(1:k); NaN; x((k+1):end)];
    y = [y(1:k); NaN; y((k+1):end)];
end

% Use the NaNs to split into parts.
[xcells, ycells] = polysplit(x,y);

% Clear out null parts and isolated singleton points or segments that
% fall entirely on the bounding line.
cellsToClear = false(size(xcells));
for k = 1:numel(xcells)
    cellsToClear(k) = (numel(xcells{k}) < 2) || all(xcells{k} == xBound);
end
[xcells, ycells] = ...
    discardFromColumnCellVectors(xcells, ycells, cellsToClear);

%-----------------------------------------------------------------------

function [xcells, ycells, xNonBounding, yNonBounding] ...
    = separateNonBoundingParts(xcells, ycells, xBound)

nonBounding = false(size(ycells));
for k = 1:numel(xcells)
    nonBounding(k) = isNonBoundingRing(xcells{k}, ycells{k}, xBound);
end
xNonBounding = xcells(nonBounding);
yNonBounding = ycells(nonBounding);
[xcells, ycells] = ...
    discardFromColumnCellVectors(xcells, ycells, nonBounding);

%-----------------------------------------------------------------------

function tf = isNonBoundingRing(x, y, xBound)

% We consider a ring to be "non-bounding" if it is completely to the left
% of the boundary.  In addition, a _closed_ ring can touch the boundary
% and still be non-bounding.

isClosed = ((x(1) + 1i*y(1)) == (x(end) + 1i*y(end)));
tf = (max(x) < xBound) || (isClosed && max(x) == xBound);

%-----------------------------------------------------------------------

function [xcells, ycells] = reconnectBrokenRings(xcells, ycells, xBound)

% Exploit MATLAB support for complex variables to intersect coordinate pairs.
startLoose = NaN + zeros(size(ycells));
endLoose   = NaN + zeros(size(ycells));
for k = 1:numel(xcells)
    if (xcells{k}(1) ~= xBound)
        startLoose(k) = xcells{k}(1) + 1i * ycells{k}(1);
    end
    if (xcells{k}(end) ~= xBound)
        endLoose(k) = xcells{k}(end) + 1i * ycells{k}(end);
    end
end
intersectPoint = intersect(startLoose, endLoose);
discard = false(size(ycells));
for j = 1:numel(intersectPoint)
    kStart = find(intersectPoint(j) == startLoose);
    kEnd   = find(intersectPoint(j) == endLoose);
    xcells{kStart} = [xcells{kEnd}(1:(end-1)); xcells{kStart}];
    ycells{kStart} = [ycells{kEnd}(1:(end-1)); ycells{kStart}];
    discard(kEnd) = true;
end
[xcells, ycells] = ...
    discardFromColumnCellVectors(xcells, ycells, discard);

%-----------------------------------------------------------------------

function [xOuter, yOuter, xInner, yInner, xLoose, yLoose] ...
    = identifyPartTypes(xcells, ycells, xBound)

% There are three types of parts that touch the boundary: outer, inner, and loose-end.
isOuter = false(size(ycells));
isInner = false(size(ycells));
isLoose = false(size(ycells));

for k = 1:numel(xcells)
    if (xcells{k}(1) ~= xBound) || (xcells{k}(end) ~= xBound)
        isLoose(k) = true;
    else
        partGoesUp = (ycells{k}(end) > ycells{k}(1));
        if partGoesUp
            isOuter(k) = true;
        else
            isInner(k) = true;
        end
    end
end

xOuter = xcells(isOuter);
yOuter = ycells(isOuter);

xInner = xcells(isInner);
yInner = ycells(isInner);

xLoose = xcells(isLoose);
yLoose = ycells(isLoose);

%-----------------------------------------------------------------------

function [xOuter, yOuter, xInner, yInner] ...
    = mergeEnclosedInnerParts(xOuter, yOuter, xInner, yInner)

% Construct the array ownsInner to associate each inner part with the outer
% part, if any, that most closely encloses it.  For each element of xInner
% and yInner, the value of ownsInner will be either an index into xOuter
% and yOuter or zero.
ownsInner = zeros(size(yInner));
yFirstOuter = zeros(size(yOuter));
yLastOuter  = zeros(size(yOuter));
for k = 1:numel(yOuter)
    yFirstOuter(k) = yOuter{k}(1);
    yLastOuter(k)  = yOuter{k}(end);
end
for k = 1:numel(yInner)
    % Find all the outer parts that enclose the k-th inner
    enclosedBy = find(...
        (yFirstOuter < yInner{k}(end)) & (yInner{k}(1) < yLastOuter));
    
    % Among the enclosing outer parts, find the one that's closest.  Can
    % check for closeness above or below, the results should be equivalent.
    if ~isempty(enclosedBy)
        owner = find(yFirstOuter == max(yFirstOuter(enclosedBy)));
        ownsInner(k) = owner;
    end
end

% For each outer part, concatenate any inner parts that it owns, ordered in
% terms of decreasing first-Y values.  Then form it into a closed ring.
for k = 1:numel(yOuter)
    xInnerK = xInner(ownsInner == k);
    yInnerK = yInner(ownsInner == k);
    [~, yFirstIndexInnerK] = sortByFirstY(yInnerK);
    yFirstIndexInnerK = flipud(yFirstIndexInnerK);
    xOuter{k} = vertcat(xOuter{k}, xInnerK{yFirstIndexInnerK});
    yOuter{k} = vertcat(yOuter{k}, yInnerK{yFirstIndexInnerK});
    xOuter{k}(end+1,1) = xOuter{k}(1);
    yOuter{k}(end+1,1) = yOuter{k}(1);
end

% Remove inner parts that are owned by outer parts from the inner parts
% arrays.
[xInner, yInner] = ...
    discardFromColumnCellVectors(xInner, yInner, (ownsInner ~= 0));

%-----------------------------------------------------------------------

function [yFirst, yFirstIndex] = sortByFirstY(ycells)

yFirst = zeros(size(ycells));
for k = 1:numel(ycells)
    yFirst(k) = ycells{k}(1);
end
[yFirst, yFirstIndex] = sort(yFirst);

%-----------------------------------------------------------------------

function [xInner, yInner] ...
    = mergeInnerPartsAndLooseEnds(xInner, yInner, xLoose, yLoose, xBound)

% Combine loose ends and remaining inner parts.
xInner = [xLoose; xInner];
yInner = [yLoose; yInner];
clear('xLoose','yLoose')

% Assign arrays containing the y-values of their start and end points,
% using special rules to put the non-boundary end of each loose-end part at
% +/- infinity.
[yFirst, yLast] = firstAndLastY(xInner, yInner, xBound);

% Put two parts in sequence whenever the last point in one part falls
% directly above the first point in another part.
sequences = identifyPartSequences(yFirst, yLast);

% Concatenate the sequences of elements in xInner, yInner
[xInner, yInner] = concatenatePartSequences(xInner, yInner, sequences);

%-----------------------------------------------------------------------

function [yFirst, yLast] = firstAndLastY(xInner, yInner, xBound)

yFirst = zeros(size(yInner));
yLast  = zeros(size(yInner));
for k = 1:numel(yInner)
    if (xInner{k}(1) ~= xBound)
        yFirst(k) = Inf;  % First point is a loose end
    else
        yFirst(k) = yInner{k}(1);
    end
    if (xInner{k}(end) ~= xBound)
        yLast(k) = -Inf;  % Last point is a loose end
    else
        yLast(k) = yInner{k}(end);
    end
end

%-----------------------------------------------------------------------

function sequences = identifyPartSequences(yFirst, yLast)

% Sort the vector of first y-values.
[yFirstSorted, yFirstIndex] = sort(yFirst);

% Initialize a cell array in which each cell will hold indices for a
% sequence of parts that need to be concatenated.
sequences = cell(0,1);

% Initialize a counter for cell array of sequences.
j = 1;

while ~isempty(yFirstSorted)    
    % Initialize a sequence.
    sequences{j} = [];
    subordinateY = true(size(yFirstSorted));

    while any(subordinateY)
        % Find the position of the last non-zero element in the subordinate
        % Y logical array.  Initially it will simply correspond to the
        % final (largest) element of yFirstSorted.
        idx = find(subordinateY);
        p = idx(end);
        
        % Find the index, relative to yFirst, yLast, xInner, and yInner, of
        % the part with the greatest first y-value.
        k = yFirstIndex(p);
        
        % Add to the sequence of part indices, making sure it's a column
        % vector.
        sequences{j}(end+1,1) = k;
        
        % Now that it's added to the sequence, remove the part from the
        % sort arrays.
        yFirstSorted(p) = [];
        yFirstIndex(p)  = [];
 
        % Logical array indicating which parts have last y-values less than
        % the last y-value in the current part.
        subordinateY = (yFirstSorted < yLast(k));
    end
    j = j + 1;
end

%-----------------------------------------------------------------------

function [xCat, yCat] = concatenatePartSequences(xInner, yInner, sequences)

% Concatenate the sequences of elements in xInner, yInner and insert the
% results into xCat and yCat.
xCat = cell(numel(sequences),1);
yCat = cell(numel(sequences),1);
for k = 1:numel(sequences)
    xInnerK = xInner(sequences{k});
    yInnerK = yInner(sequences{k});
    xCat{k} = vertcat(xInnerK{:});
    yCat{k} = vertcat(yInnerK{:});
end

%-----------------------------------------------------------------------

function [x, y] = discardFromColumnCellVectors(x, y, toBeRemoved)

% Remove all elements from column cell vectors X and Y for which logical
% column vector toBeRemoved contains true.  X, Y, and toBeRemoved must
% all have the same length.  Force X and Y to remain column vectors even
% if they end up empty.  (By default MATLAB will turn them into empty
% row vectors with size 1-by-0.)  This allows them to be concatenated
% vertically with other column cell vectors without triggering MATLAB
% warnings.
x(toBeRemoved) = [];
y(toBeRemoved) = [];
if isempty(x)
    x = reshape(x, [0 1]);
    y = reshape(y, [0 1]);
end

%-----------------------------------------------------------------------

function [latcells,loncells] = polysplit(lat,lon)

% Private copy of polysplit that skips argument checking plus the call
% to removeExtraNanSeparators.

% [lat, lon] = removeExtraNanSeparators(lat, lon);

% Find NaN locations.
indx = find(isnan(lat(:)));

% Simulate the trailing NaN if it's missing.
if ~isempty(lat) && ~isnan(lat(end))
    indx(end+1,1) = numel(lat) + 1;
end

%  Extract each segment into pre-allocated N-by-1 cell arrays, where N is
%  the number of polygon segments.  (Add a leading zero to the indx array
%  to make indexing work for the first segment.)
N = numel(indx);
latcells = cell(N,1);
loncells = cell(N,1);
indx = [0; indx];
for k = 1:N
    iStart = indx(k)   + 1;
    iEnd   = indx(k+1) - 1;
    latcells{k} = lat(iStart:iEnd);
    loncells{k} = lon(iStart:iEnd);
end

%-----------------------------------------------------------------------

function [lat,lon] = polyjoin(latcells,loncells)

% Private copy of polyjoin that skips argument checking.

M = numel(latcells);
N = 0;
for k = 1:M
    N = N + numel(latcells{k});
end

lat = zeros(N + M - 1, 1);
lon = zeros(N + M - 1, 1);
p = 1;
for k = 1:(M-1)
    q = p + numel(latcells{k});
    lat(p:(q-1)) = latcells{k};
    lon(p:(q-1)) = loncells{k};
    lat(q) = NaN;
    lon(q) = NaN;
    p = q + 1;
end
if M > 0
    lat(p:end) = latcells{M};
    lon(p:end) = loncells{M};
end

%-----------------------------------------------------------------------

function [endPointsCoincide, endPointsWithinTolerance] ...
    = checkEndPoints(xFirst, yFirst, xLast, yLast, tol)

endPointsCoincide = (xFirst == xLast) & (yFirst == yLast);

endPointsWithinTolerance ...
    = (abs(xFirst - xLast)) < tol & (abs(yFirst - yLast) < tol);
