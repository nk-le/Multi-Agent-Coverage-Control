function [x, y, xp, yp] = adjustContourTopology(x, y, xlimit, ylimit, xmax, ymax)
%adjustContourTopology Reorder contour vertices for consistent topology
%
%   [X, Y, XP, YP] = adjustContourTopology(X, Y, XLIMIT, YLIMIT, XMAX, YMAX)
%   reorders the vertices of the NaN-separated contour lines specified
%   in the vectors X and Y to ensure a consistent topology.  The contours
%   in X and Y should correspond to a single contour level only.  The
%   contours must be bounded by a rectangle that is aligned with the
%   coordinate axes, with extent and location as defined by the
%   2-vectors XLIMIT and YLIMIT.  XMAX and YMAX are scalars that specify
%   the location of a point (which may be one of many) at which the data
%   that was contoured reaches its global maximum.
%
%   The topology is adjusted as required such that in the output the
%   higher values fall to the right-hand side every curve, assuming that
%   X and Y are plotted in a right-handed Cartesian system.
%
%   If XP and YP are requested, they contain the vertices of a polygon
%   constructed by adding line segments as needed along the edges of the
%   bounding rectangle. Points inside the polygon (on the right hand
%   side of the curve) have values greater than or equal to the contour
%   level, and those outside have values less than or equal to the
%   contour level.
%
%   REMARKS
%
%   * In typical usage, one would call this function while iterating
%     through the full set of contour levels.
%
%   * A single contour is often closed, but may be open if it originates
%     at a point on the rectangular boundary and ends at another
%     boundary point.  The directions of such open contours are adjusted
%     as required, as in the case of the closed loops.
%
%   * No curve, closed or open, may intersect any other.

% Copyright 2010-2012 The MathWorks, Inc.

% We're working with three high-level chunks of data:
%
%     closed curves (C)
%     open curves (B)
%     sectors (S)
%
% By "sectors" we mean the polygonal areas bounded by the open curves in
% combination with the rectangular boundary.  We'll manage information
% about closed curves, open curves, and sectors using structure arrays
% named "C", "B", and "S", respectively.  (Because they help _bound_
% the sectors, we use the variable name "B" to denote the open curves,
% avoiding use of the awkward name "O".)
%
% The number of sectors is always equal to  n + 1, where n is the
% number of open curves.  This is easy to see, using induction:
%
% If there are no open curves (n == 0), then the entire bounding
% rectangle constitutes 1 == 0 + 1 == n + 1 sector. If there's one open
% curve (n == 1), it must divide the rectangle into exactly 2 == 1 + 1
% == n + 1 sectors. sectors. If there's more than one open curve, add each
% additional curve one at a time. The n-th open curve must fall entirely
% within only one of the n sectors defined by the rectangle and the
% preceding n - 1 open curves, because it may not intersect any other open
% curves. So adding the n-th open curve divides one of n sectors into 2,
% resulting a total of n + 1 sectors.

% At this level we care about these fields:
% 
% closed curves (C):
%   First
%   Last
%   Sector
%   SameDirAsSector
%   
% open curves (B):
%   First
%   Last
%   LeftSector
%   
% sectors (S):
%   NeedsToBeClockwise

% Turn off any warning about the size of the polygon is approaching the
% lower limit.
w = warning('off', 'MATLAB:inpolygon:ModelingWorldLower');
obj = onCleanup(@() warning(w));

[C, B, S] = analyzeTopology(x, y, xlimit, ylimit, xmax, ymax);

% Adjust vertex directions in open curves, flipping the order as needed,
% and reset the PosFirst and PosLast fields to retain consistency.
% (There is no need to update the other fields: First, Last, LeftSector,
% or RightSector; they are not used again once this loop is finished.)
for k = 1:numel(B)
    needToReverse = S(B(k).LeftSector).NeedsToBeClockwise;
    if needToReverse
        first = B(k).First;
        last  = B(k).Last;
        x(first:last) = x(last:-1:first);
        y(first:last) = y(last:-1:first);
        p = B(k).PosFirst;
        B(k).PosFirst = B(k).PosLast;
        B(k).PosLast = p;
    end
end

% Adjust vertex directions in closed curves. (As above, update only
% what's needed; IsClockwise in this case.)
for k = 1:numel(C)
    first = C(k).First;
    last  = C(k).Last;
    needsToBeClockwise = ~xor( ...
        C(k).SameDirAsSector, S(C(k).Sector).NeedsToBeClockwise);
    isClockwise = ispolycw(x(first:last), y(first:last));
    needToReverse = xor(isClockwise, needsToBeClockwise);
    if needToReverse
        x(first:last) = x(last:-1:first);
        y(first:last) = y(last:-1:first);
        C(k).IsClockwise = ~isClockwise;
    else
        C(k).IsClockwise = isClockwise;
    end
end

% At this point, the topology of x and y has been fully corrected. All
% that remains is the (optional) step of copying these curves and
% supplementing them with strips along the boundary as needed to ensure
% valid polygon topology.
computePolygons = (nargout > 2);
if computePolygons
    % Compute bounding rectangle.
    if ~isempty(B)
        % If the current contour has open segments that intersect the
        % bounding rectangle, close it up by tracing the boundary.
        [xp, yp] = linkOpenCurvesAlongBoundary(x, y, xlimit, ylimit, C, B);
    else
        % If the bounding box falls on the right hand side of the
        % current contour, combine them, ensuring valid planar topology.
        [xp, yp] = boundClosedCurves(x, y, xlimit, ylimit, C);
    end
end

%--------------------------------------------------------------------------

function [C, B, S] = analyzeTopology(x, y, xlimit, ylimit, xmax, ymax)

x = x(:);
y = y(:);

[S, B] = traceAllSectors(x, y, xlimit, ylimit, xmax, ymax);

C = relateClosedCurvesToSectors(x, y, xmax, ymax, S);

% Each open curve separates exactly two sectors, so it must form part of
% two sector polygons. The sectors form a graph. Each pair of adjacent
% sectors is separated by one of the sector boundary curves.

% If the sector falls right hand side of an open curve, then that curve
% runs in the same direction as the sector.

assert(sum([S.ContainsMax]) <= 1, ...
    'map:adjustContourTopology:analyzeTopology1', ...
    'Failed internal check: ContainsMax should be true for at most one sector.')

curveWrappingMax = find([C.WrapsMax]);
if isempty(curveWrappingMax)
    needsToBeClockwise = true;
elseif isscalar(curveWrappingMax)
   needsToBeClockwise = C(curveWrappingMax).SameDirAsSector;
   assert(C(curveWrappingMax).Sector == find([S.ContainsMax]), ...
       'map:adjustContourTopology:analyzeTopology2', ...
       'Failed internal check: Inconsistency between curves and sectors.')
else
   error('map:adjustContourTopology:analyzeTopology3', ...
       'Failed internal check: WrapsMax should be true at most one curve.')
end

% Now we have one sector figured out, so we can do the others:
sameDirAsFirstSector = relativeSectorDirections(B);
needsToBeClockwise = ~xor(sameDirAsFirstSector, ...
    sameDirAsFirstSector([S.ContainsMax]) == needsToBeClockwise);
    
% Now save this information in S
for k = 1:numel(S)
    S(k).NeedsToBeClockwise = needsToBeClockwise(k);
end

%--------------------------------------------------------------------------

function C = relateClosedCurvesToSectors(x, y, xmax, ymax, S)

% Find the first and last vertices for each part.  These will help us
% reference and manipulate the coordinates using only "in-place"
% operations.
last = find(isnan(x)) - 1;
first = [1; 2 + last(1:end-1)];
closed = (x(first) == x(last)) & (y(first) == y(last));

closedCurves = find(closed);
template = struct( ...
    'First', [], ...
    'Last', [], ...
    'FirstX', [], ...
    'FirstY', [], ...
    'Sector', [], ...
    'SameDirAsSector', [], ...
    'WrapsMax', [], ...
    'IsClockwise', []);
C(1:numel(closedCurves),1) = template;

for k = 1:numel(closedCurves)
    j = closedCurves(k);
    C(k).First = first(j);
    C(k).Last  = last(j);
    C(k).FirstX = x(first(j));
    C(k).FirstY = y(first(j));
end

% Identify the enclosing sector for each of the closed curves.
xFirst = [C.FirstX];
yFirst = [C.FirstY];
for k = 1:numel(S)
    in = inpolygon(xFirst, yFirst, S(k).X, S(k).Y);
    [C(in).Sector] = deal(k);
end

% Process the closed curves sector-by-sector in order to determine the
% direction that each one should have relative to the enclosing sector.
enclosingSector = [C.Sector];
for k = 1:numel(S)
    index = (enclosingSector == k);
    C(index) = relativeClosedCurveDirections(x, y, xmax, ymax, C(index));
end

%--------------------------------------------------------------------------

function C = relativeClosedCurveDirections(x, y, xmax, ymax, C)

% C is a subset of the closed curves array containing only the closed
% curves in one given sector.

% Construct a square matrix, in, such that in(k,j) is true if and only if
% C(k) contains (or equals) C(j).
in = false(numel(C), numel(C));
containsMax = false(numel(C),1);
xFirst = [C.FirstX];
yFirst = [C.FirstY];
for k = 1:numel(C)
    first = C(k).First;
    last  = C(k).Last;
    % Because the curves are not allowed to intersect, it's sufficient to
    % check only one point (which we arbitrarily choose to be the first)
    % from each curve.
    in(k,:) = inpolygon(xFirst, yFirst, x(first:last), y(first:last));
    containsMax(k) = inpolygon(xmax, ymax, x(first:last), y(first:last));
end

% The results from inpolygon will indicate that each curve contains itself
% (the diagonal of in is full of 1s), but we need to exclude self-enclosure.
in(diag(true(numel(C),1))) = false;

numberOfEnclosingCurves = sum(in,1);
sameDirAsSector = (mod(numberOfEnclosingCurves,2) == 1);
for k = 1:numel(C)
    C(k).SameDirAsSector = sameDirAsSector(k);
end

% There is at most one curve that contains the point of global maximum
% (xmax, ymax) and does not contain any other curve that also contains the
% global maximum.  In other words, it's the curve that most tightly wraps
% around the global maximum.  Assuming a right-handed system, the vertices
% in this curve should be order in a clockwise direction.
for k = 1:numel(C)
    C(k).WrapsMax = containsMax(k) && ~any(containsMax(in(k,:)));
end

%--------------------------------------------------------------------------

function sameDirAs1 = relativeSectorDirections(B)
% Determine the direction of each sector relative to the first. When an
% element is TRUE in the output, that means that the corresponding sector
% runs clockwise if the first sector runs clockwise, and runs
% counterclockwise otherwise. When an element is FALSE, the direction of
% the corresponding sector runs opposite to that of sector 1.

numberOfSectors = 1 + numel(B);
sz = [numberOfSectors 1];

sameDirAs1     = true(sz);
directionKnown = false(sz);
used           = false(sz);

directionKnown(1) = true;
while any(~directionKnown)
    k = find(directionKnown & ~used);
    k = k(1);
    indxL = [B([B.RightSector] == k).LeftSector];
    indxR = [B([B.LeftSector] == k).RightSector];
    sameDirAs1(indxL) = ~sameDirAs1(k);
    sameDirAs1(indxR) = ~sameDirAs1(k);
    directionKnown(indxL) = true;
    directionKnown(indxR) = true;
    used(k) = true;
end

%--------------------------------------------------------------------------

function [S, B] = traceAllSectors(x, y, xlimit, ylimit, xmax, ymax)

[B,E] = organizeOpenCurves(x, y, xlimit, ylimit);

% Loop over each sector boundary (open curve) and trace the outline of
% sector to its left (if not yet traced), and then trace the outline of the
% sector to its right (if not yet traced). Keep track of these sectors
% adding 'LeftSector' and 'RightSector' fields to structure B.

tracedForward  = false(size(B));
tracedBackward = false(size(B));

% Pre-allocate sector containers. For now we'll rely on the following
% conjecture (for which we do not yet have proof): The number of sectors
% always equals the number of sector boundaries plus one.
S(1 + numel(B),1) = struct( ...
    'X', [], 'Y', [], 'ContainsMax', [], 'NeedsToBeClockwise', []);

% Corner coordinates, indexed in order of increasing position
xc = xlimit([1 1 2 2])';
yc = ylimit([1 2 2 1])';

% Trace all the sectors, ensuring that each open curve is traced exactly
% once in each direction.
numSectors = 0;
for k = 1:numel(B)
    if ~tracedForward(k)
        
        % Trace starting with the right side (clockwise)
        forward = true;
        numSectors = numSectors + 1;
        [xs, ys, B, tracedForward, tracedBackward] = traceSector(numSectors, ...
            k, forward, tracedForward, tracedBackward, x, y, B, E, xc, yc); 
        S(numSectors).X = xs;
        S(numSectors).Y = ys;
    end
    if ~tracedBackward(k)
        % Trace starting with the left side (counter-clockwise)
        forward = false;
        numSectors = numSectors + 1;
        [xs, ys, B, tracedForward, tracedBackward] = traceSector(numSectors, ...
            k, forward, tracedForward, tracedBackward, x, y, B, E, xc, yc); 
        S(numSectors).X = xs;
        S(numSectors).Y = ys;
    end
end

if isempty(B)
    % If there no open curves, then there's just one big sector.
    S(1).X = xlimit([1 1 2 2 1]);
    S(1).Y = ylimit([1 2 2 1 1]);
end

% Determine the sector containing the global maximum (xmax, ymax).
for k = 1:numel(S)
    S(k).ContainsMax = inpolygon(xmax, ymax, S(k).X, S(k).Y);
end

%--------------------------------------------------------------------------

function [xs, ys, B, tracedForward, tracedBackward] = traceSector(sectorNumber, ...
    k, forward, tracedForward, tracedBackward, x, y, B, E, xcorners, ycorners)
% If FORWARD is TRUE, trace the sector that falls on the right-hand side of
% the k-th open contour. Otherwise, trace the sector that falls on its
% left-hand side. Return the vertices of the closed curve that results in
% coordinate vectors XS and YS. And update arrays tracedForward and
% tracedBackward to keep track of which open contours have been traversed
% and in which direction. Keep track of the sectors on either side of each
% open curve by adding two new fields to B: 'LeftSector' and 'RightSector'.

initialValueOfForward = forward;
position = [E.Position];

% Trace once to count the vertices.
numVertices = 0;
j = k;
done = false;
while ~done
    numVertices = numVertices + (B(j).Last - B(j).First + 1);
    if forward
        endPosition = B(j).PosLast;
        B(j).RightSector = sectorNumber;
    else
        endPosition = B(j).PosFirst;
        B(j).LeftSector = sectorNumber;
    end
    
    % Proceed clockwise around the perimeter to the next end point,
    % accounting for the possibility that the current end point might not
    % be unique (because 2 distinct curves can share a common end point).
    posmatch = find(position == endPosition);
    m = [E(posmatch).Index];
    p = 1 + mod(posmatch(m == j), numel(E));
    
    j = E(p).Index;
    corners = cornersTraversed(endPosition, E(p).Position);
    numVertices = numVertices + numel(corners);
    forward = E(p).IsFirst;
    done = (j == k);
end
numVertices = numVertices + 1;

% Trace again to assign the vertices.
xs = zeros(numVertices,1);
ys = zeros(numVertices,1);
j = k;
i1 = 1;
done = false;
forward = initialValueOfForward;
while ~done
    if forward
        endPosition = B(j).PosLast;        
        subs = (B(j).First):(B(j).Last);
        tracedForward(j) = true;
    else
        endPosition = B(j).PosFirst;
        subs = (B(j).Last):-1:(B(j).First);
        tracedBackward(j) = true;
    end
    i2 = i1 + B(j).Last - B(j).First;
    xs(i1:i2) = x(subs);
    ys(i1:i2) = y(subs);
    
    % Proceed clockwise around the perimeter to the next end point,
    % accounting for the possibility that the current end point might not
    % be unique (because 2 distinct curves can share a common end point).
    posmatch = find(position == endPosition);
    m = [E(posmatch).Index];
    p = 1 + mod(posmatch(m == j), numel(E));
    
    j = E(p).Index;
    corners = cornersTraversed(endPosition, E(p).Position);
    i1 = i2 + 1;
    i2 = i2 + numel(corners);
    xs(i1:i2) = xcorners(corners);
    ys(i1:i2) = ycorners(corners);
    i1 = i1 + numel(corners);
    forward = E(p).IsFirst;
    done = (j == k);
end
xs(end) = xs(1);
ys(end) = ys(1);

%-----------------------------------------------------------------------

function corners = cornersTraversed(position1, position2)
% Return, in sequence, the indices of the corners that are traversed when
% moving from position 1 to position 2 in clockwise order (order of
% increasing position).

% All possible corners in increasing order
corners = (0:7);  
    
% Unwrap positions into the half-open interval [0 8).
if position2 < position1
    position2 = position2 + 4;
end

% Eliminate the corners that are not traversed.
corners(corners <= position1) = [];
corners(corners >= position2) = [];

% Wrap back to into the interval [0 3], and add one to convert from
% position to index.  The final result is a section of the array [1 2 3 4].
corners = 1 + mod(corners,4);

%-----------------------------------------------------------------------

function [x, y] = boundClosedCurves(x, y, xlimit, ylimit, C)
% If the bounding box falls on the right hand side of the current
% contour, combine them, ensuring valid planar topology.

cw = [C.IsClockwise];
if ~all(cw)
    if all(~cw)
        % All curves are CCW ... they need to be enclosed by the
        % bounding rectangle.
        combineWithBoundary = true;
    else
        % Some points are CW and some are CCW ...
        
        % Use the first vertex of each CCW curve as a test point.
        firstCCW = [C(~cw).First];
        xt = x(firstCCW);
        yt = y(firstCCW);
        
        % See if all the test points are already enclosed by CW polygons.
        enclosed = false(size(xt));
        for k = find(cw)
            s = C(k).First;
            e = C(k).Last;
            enclosed = enclosed | inpolygon(xt, yt, x(s:e), y(s:e));           
        end        
        combineWithBoundary = any(~enclosed);
    end
    
    if combineWithBoundary
        x = [xlimit([1 1 2 2 1]) NaN x];
        y = [ylimit([1 2 2 1 1]) NaN y];
    end
end
