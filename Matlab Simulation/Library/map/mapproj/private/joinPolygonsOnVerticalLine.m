function [xOut, yOut] ...
    = joinPolygonsOnVerticalLine(xLeft, yLeft, xRight, yRight, xBound, tol)

% Assume that xLeft and yLeft define a set of polygons bounded on the right
% by xBound, and that xRight and yRight define a set of polygons bounded on
% the left by xBound.  Combine polygons that share a common edge segment on
% x = xBound, starting and ending at the same values of y, but running in
% opposite directions.  If TOL is nonzero, snap points to the boundary for
% which abs(x - xBound) < tol.

% Copyright 2005-2011 The MathWorks, Inc.  

nonNanLeftInput  = ~isempty(xLeft)  && ~all(isnan(xLeft));
nonNanRightInput = ~isempty(xRight) && ~all(isnan(xRight));

if nonNanLeftInput && nonNanRightInput
    % Do all internal operations using column vectors.
    usingRowVectors = (size(xLeft,2) > 1) || (size(xRight,2) > 1);
    if usingRowVectors
        xLeft = xLeft(:);
        yLeft = yLeft(:);
        xRight = xRight(:);
        yRight = yRight(:);
    end

    % Use fields 'LEFT' and 'RIGHT' in structures xIn and yIn to hold vertices
    % on the two sides of the boundary.  The structure splitParts, which
    % contains arrays of start/end indices and next/previous part numbers will
    % have these same top-level fields.
    xIn.LEFT  = xLeft;
    xIn.RIGHT = xRight;
    yIn.LEFT  = yLeft;
    yIn.RIGHT = yRight;

    % (1) Determine start- and end-indices that split the inputs wherever
    % parts from either side touch the boundary line (x == xBound) or
    % come within distance TOL of the boundary, (2) snap x to xBound for
    % such points, and (3) determine the corresponding y-values (yBound)
    % and sort them in ascending order.
    [splitParts, xIn, yBound] = splitPartsOnBoundary(xIn, yIn, xBound, tol);

    % For each split part, find the numbers of the split parts (if any) that
    % immediately precede and follow it, and add them to the split part
    % structures.  Also add a field to indicate which side the next part is on.
    % Usually, but not always, these next and previous parts come from the
    % opposite side of the boundary.
    splitParts = addLinksToNextAndPrevious(xIn, yIn, splitParts, yBound);

    % Connect the parts where they touch along the boundary, copying from the
    % two sets of input vertices into the one set of output vertices.
    [xOut, yOut] = traceAcrossBoundary(xIn, yIn, splitParts);

    % Make output shape consistent with input.
    if usingRowVectors
        xOut = xOut';
        yOut = yOut';
    end
elseif nonNanLeftInput
    xOut = xLeft;
    yOut = yLeft;
else
    xOut = xRight;
    yOut = yRight;
end

%--------------------------------------------------------------------------

function [splitParts, xIn, yBound] ...
    = splitPartsOnBoundary(xIn, yIn, xBound, tol)

% Determine start- and end-indices that split the inputs wherever parts
% from either side touch the boundary line (x == xBound).  Return the
% results in a structure with the following form:
%
%          splitParts
%              |
%              |-------- LEFT
%              |           |
%              |           |------ iStart
%              |           |
%              |           |------ iEnd
%              |           |
%              |           |------ startsOnBoundary
%              |           |
%              |           |------ endsOnBoundary
%              |
%              |-------- RIGHT
%                          |
%                          |------ iStart
%                          |
%                          |------ iEnd
%                          |
%                          |------ startsOnBoundary
%                          |
%                          |------ endsOnBoundary
%
%
% where splitParts.LEFT.iStart and splitParts.LEFT.iEnd index into the
% vertex arrays xIn.LEFT and yIn.LEFT.  Likewise splitParts.RIGHT.iStart
% and splitParts.LEFT.iEnd index into the vertex arrays xIn.RIGHT and
% yIn.RIGHT.  Snap x to xBound for points within distance TOL of the
% boundary.  And compute yBound, an ordered list of the y-values at
% which curves from either side the boundary x == xBound.

% Find the boundary point indices and sort in order of increasing y.
leftBndIndx  = findOrderedBoundaryPoints(xIn.LEFT,  yIn.LEFT,  xBound, tol);
rightBndIndx = findOrderedBoundaryPoints(xIn.RIGHT, yIn.RIGHT, xBound, tol);

% Split the two sides separately.
splitParts.LEFT  = splitOneSide(leftBndIndx,  xIn.LEFT);
splitParts.RIGHT = splitOneSide(rightBndIndx, xIn.RIGHT);

% Snap x to xBound.
xIn.LEFT(leftBndIndx)   = xBound;
xIn.RIGHT(rightBndIndx) = xBound;

% Unique (ascending) y-values of boundary points.
yBound = union(yIn.LEFT(leftBndIndx), yIn.RIGHT(rightBndIndx));

%--------------------------------------------------------------------------

function indx = findOrderedBoundaryPoints(x, y, xBound, tol)

% Return an array with the indices of the points in (x,y) where x ==
% xBound, sorted in terms of ascending values of y.

indx = find(abs(x - xBound) < tol);
[~, sortIndx] = sort(y(indx));
indx = indx(sortIndx);

%--------------------------------------------------------------------------

function splitParts = splitOneSide(indx, x)

% On either side of the boundary, determine the start and end indices
% needed to split up the vertex arrays at points where the curves on this
% side touch the boundary and which coincide with vertices from the
% opposite side.  Input indx contains all the indices of elements in vertex
% coordinate array x which correspond to such points.

% For each element of indx, determine the number of the part to which the
% point x(indx(k)), y(indx(k)) belongs.  (The parts are delineated by the
% locations of NaN-separators in x.)

if isempty(x)
    splitParts.iStart = [];
    splitParts.iEnd = [];
    splitParts.startsOnBoundary = [];
    splitParts.endsOnBoundary = [];
    return
end

lookup = 1 + cumsum(isnan(x));
partNumbers = lookup(indx);

% Find the start and end indices for each NaN-separated part, assuming that
% x is a column vector.

nanIndx = find(isnan(x));
if ~isnan(x(end))
    nanIndx(end+1,1) = 1 + numel(x);
end
startIndx = [1; 1 + nanIndx(1:(end-1))];
endIndx = nanIndx - 1;

% Concatenate these start and end indices with the original indx array, and
% store the result back into indx.

indx = [indx; startIndx; endIndx];

% Upate the partNumbers array so that it once again indicates which part
% each of the index values in indx corresponds to.

numParts = numberOfParts(x);
partNumbers = [partNumbers; (1:numParts)'; (1:numParts)'];

% Create a third array having the same size as indx, in which each
% element indicates whether or not the corresponding point falls on the
% boundary.

isBound = false(size(indx));
isBound(1:(numel(partNumbers) - 2*numParts)) = true;

% Now indx, partNumbers, and isBound are all the same size and have and
% element-by-element correspondence.  Sort indx by ascending value and
% permute partNumbers and isBound to maintain the correspondence.
[indx, sortIndx] = sort(indx);
partNumbers = partNumbers(sortIndx);
isBound = isBound(sortIndx);

% After the sort, everything should be grouped by parts, but some indices
% are duplicated because some points are both boundary points and end
% points.  The next step is to merge these duplicates by applying a Boolean
% OR to the corresponding elements of isBound (and simply deleting the
% extraneous elements in partNumbers).

dups = find(diff(indx) == 0);
isBound(dups+1) = isBound(dups) | isBound(dups+1);
isBound(dups) = [];
partNumbers(dups) = [];
indx(dups) = [];

% Wherever two adjacent boundary points are found in the same part, it's
% necessary to split the part in two.  To see how to do this, first note
% that partNumbers starts at one and increases monotically in unit steps.
% The steps occur, naturally, at the transition from one part to the next.
% So we compute a second array having the same size as partNumbers that
% also increases monotonically in unit steps, but start this array at zero
% and locate transitions at breaks where the part reaches the boundary at a
% given vertex then departs the boundary at the following vertex.  In each
% such pair, naturally, the index of the second vertex exceeds the index of
% the first vertex by one, so the expression
%
%                          diff([1; indx]) == 1
%
% provides a set of candidate step points.  However, we have to avoid
% confusing these points with loose ends that are only one vertex away from
% a boundary point (a relatively rare case, but it must be covered
% properly).  Therefore we use the following expression to make sure that
% the vertices on both sides of the transition are on the boundary (vs.
% having one loose end and one boundary point),
%
%                          diff([0; isBound]) == 0
%
% Thus, by a applying a Boolean AND to corresponding elements of these
% expressions, we narrow things down to true boundary transitions. Finally,
% we take the cumulative sum of the output of OR to produce a
% 'partBreaksOnBoundary' array.  

partBreaksOnBoundary ...
    = cumsum((diff([1; indx]) == 1) & (diff([0; isBound]) == 0));

% As described above, partBreaksOnBoundary starts at zero and increases by
% one for each sequential pair of vertices where a part touches and then
% departs from the boundary.

% Finally, the sum of the input part numbers array and the
% partBreaksOnBoundary array results in a array of new part numbers.  Like
% the original it starts at one and increases monotically by one, but the
% steps occur where there is either (1) a transition to a different
% (original) part or (2) two adjacent boundary points from the same
% (original) part.

newPartNumbers = partNumbers + partBreaksOnBoundary; 

% Last steps:  Find the elements of indx which correspond to the start and
% end points of the new parts.

pNewStart = find(diff(newPartNumbers) == 0);
pNewEndPt = pNewStart + 1;

% And build the return structure.

splitParts.iStart = indx(pNewStart);
splitParts.iEnd   = indx(pNewEndPt);
splitParts.startsOnBoundary = isBound(pNewStart);
splitParts.endsOnBoundary   = isBound(pNewEndPt);

%--------------------------------------------------------------------------

function numParts = numberOfParts(x)

% Determine the number of parts in NaN-separated array x.

numParts = numel(find(isnan(x))) + double(~isempty(x) && ~isnan(x(end)));

%--------------------------------------------------------------------------

function splitParts = addLinksToNextAndPrevious(xIn, yIn, splitParts, yBound)

% For each split part, find the numbers of the split parts that
% immediately preceding and following it on the opposite side of the
% vertical line x == xBound and add them to the split part structures.
% If a part is a loose end, then "nextPart" for the part preceding it is
% set to NaN.  Likewise, if a part is a loose start, then "prevPart" for
% the part following it is set to NaN.  The output splitParts has the
% following form:
%
%          splitParts
%              |
%              |-------- LEFT
%              |           |
%              |           |------ iStart
%              |           |
%              |           |------ iEnd
%              |           |
%              |           |------ startsOnBoundary
%              |           |
%              |           |------ endsOnBoundary
%              |           |
%              |           |------ nextPart
%              |           |
%              |           |------ prevPart
%              |           |
%              |           |------ nextSide
%              |           |
%              |           |------ skipAlongBoundary
%              |
%              |-------- RIGHT
%                          |
%                          |------ iStart
%                          |
%                          |------ iEnd
%                          |
%                          |------ startsOnBoundary
%                          |
%                          |------ endsOnBoundary
%                          |
%                          |------ nextPart
%                          |
%                          |------ prevPart
%                          |
%                          |------ nextSide
%                          |
%                          |------ skipAlongBoundary


% Initialize NaN-filled arrays to track next and previous part numbers.
splitParts.LEFT.nextPart = NaN + zeros(size(splitParts.LEFT.iEnd));
splitParts.LEFT.prevPart = splitParts.LEFT.nextPart;

splitParts.RIGHT.nextPart = NaN + zeros(size(splitParts.RIGHT.iEnd));
splitParts.RIGHT.prevPart = splitParts.RIGHT.nextPart;

% Initialize nextSide cell arrays.
splitParts.LEFT.nextSide = cell(size(splitParts.LEFT.iEnd));
splitParts.RIGHT.nextSide = cell(size(splitParts.RIGHT.iEnd));

% Initialize logical arrays to indicate whether or not the next part (if
% any) originates at the same boundary point (skipAlongEdge == false) or at
% an adjacent boundary point (skipAlongBoundary == true).
splitParts.LEFT.skipAlongBoundary = false(size(splitParts.LEFT.iEnd));
splitParts.RIGHT.skipAlongBoundary = false(size(splitParts.RIGHT.iEnd));

% Save starting and ending y-values for each part.
y.LEFT.Start = yIn.LEFT(splitParts.LEFT.iStart);
y.LEFT.End   = yIn.LEFT(splitParts.LEFT.iEnd);
y.RIGHT.Start = yIn.RIGHT(splitParts.RIGHT.iStart);
y.RIGHT.End   = yIn.RIGHT(splitParts.RIGHT.iEnd);

% Check each crossing point.
for k = 1:numel(yBound)

    p = findEndOnBoundary(  y, 'LEFT',  splitParts, yBound(k));
    q = findStartOnBoundary(y, 'RIGHT', splitParts, yBound(k));
    r = findEndOnBoundary(  y, 'RIGHT', splitParts, yBound(k));
    s = findStartOnBoundary(y, 'LEFT',  splitParts, yBound(k));

    crossLeftToRight = (~isempty(p) && ~isempty(q));
    crossRightToLeft = (~isempty(r) && ~isempty(s));
    continueOnLeft  = (~isempty(p) && ~isempty(s));
    continueOnRight = (~isempty(r) && ~isempty(q));
    
    if crossLeftToRight
        splitParts.LEFT.nextSide{p} = 'RIGHT';
        splitParts.LEFT.nextPart(p) = q;
        splitParts.RIGHT.prevPart(q) = p;
    elseif crossRightToLeft
        splitParts.RIGHT.nextSide{r} = 'LEFT';
        splitParts.RIGHT.nextPart(r) = s;
        splitParts.LEFT.prevPart(s) = r;
    elseif continueOnLeft
        splitParts.LEFT.nextSide{p} = 'LEFT';
        splitParts.LEFT.nextPart(p) = s;
        splitParts.LEFT.prevPart(s) = p;
    elseif continueOnRight
        splitParts.RIGHT.nextSide{r} = 'RIGHT';
        splitParts.RIGHT.nextPart(r) = q;
        splitParts.RIGHT.prevPart(q) = r;
    elseif (k < numel(yBound))
        % No crossings at the k-th boundary point; check the next point up
        % along the boundary, unless we're at the upper-most point.
        splitParts = checkNextBoundaryPoint(...
            p, q, r, s, y, splitParts, yBound(k+1));
    end
end

% Find loose start points that coincide with loose end points
splitParts = addLinksToJoinLooseEnds(xIn, yIn, splitParts, 'LEFT');
splitParts = addLinksToJoinLooseEnds(xIn, yIn, splitParts, 'RIGHT');

%--------------------------------------------------------------------------

function splitParts = addLinksToJoinLooseEnds(xIn, yIn, splitParts, side)

if ~isempty(splitParts.(side).startsOnBoundary) ...
        && ~isempty(splitParts.(side).endsOnBoundary)
    looseStartIndx = find(~(splitParts.(side).startsOnBoundary));
    looseEndIndx   = find(~(splitParts.(side).endsOnBoundary));

    zStart = xIn.(side)(splitParts.(side).iStart(looseStartIndx(:))) ...
        + 1i * yIn.(side)(splitParts.(side).iStart(looseStartIndx(:)));

    zEnd = xIn.(side)(splitParts.(side).iEnd(looseEndIndx(:)))...
        + 1i * yIn.(side)(splitParts.(side).iEnd(looseEndIndx(:)));

    [r,c] = find(repmat(zStart(:),[1 numel(zEnd)]) ...
                  == repmat(transpose(zEnd(:)),[numel(zStart) 1]));

    splitParts.(side).nextPart(looseEndIndx(c)) = looseStartIndx(r);
    splitParts.(side).prevPart(looseStartIndx(r)) = looseEndIndx(c);
    splitParts.(side).nextSide(looseEndIndx(c)) = {side};
end

%--------------------------------------------------------------------------

function splitParts = checkNextBoundaryPoint(...
    p, q, r, s, y, splitParts, yBound)

% Check eight additional possibilities: Moving up and down along the
% boundary and crossing left-to-right, right-to-left, staying on the left,
% or staying on the right.

p1 = findEndOnBoundary(  y, 'LEFT',  splitParts, yBound);
q1 = findStartOnBoundary(y, 'RIGHT', splitParts, yBound);
r1 = findEndOnBoundary(  y, 'RIGHT', splitParts, yBound);
s1 = findStartOnBoundary(y, 'LEFT',  splitParts, yBound);

followBoundaryUpAndCrossLeftToRight = ...
    (~isempty(p) && ~isempty(q1)) ...
    && isnan(splitParts.LEFT.nextPart(p)) ...
    && isnan(splitParts.RIGHT.prevPart(q1));

followBoundaryDownAndCrossLeftToRight = ...
    (~isempty(p1) && ~isempty(q)) ...
    && isnan(splitParts.LEFT.nextPart(p1)) ...
    && isnan(splitParts.RIGHT.prevPart(q));

followBoundaryUpAndCrossRightToLeft = ...
    (~isempty(r) && ~isempty(s1)) ...
    && isnan(splitParts.RIGHT.nextPart(r)) ...
    && isnan(splitParts.LEFT.prevPart(s1));

followBoundaryDownAndCrossRightToLeft = ...
    (~isempty(r1) && ~isempty(s)) ...
    && isnan(splitParts.RIGHT.nextPart(r1)) ...
    && isnan(splitParts.LEFT.prevPart(s));

followBoundaryUpOnLeft = ...
    (~isempty(p) && ~isempty(s1)) ...
    && isnan(splitParts.LEFT.nextPart(p)) ...
    && isnan(splitParts.LEFT.prevPart(s1));

followBoundaryDownOnLeft = ...
    (~isempty(p1) && ~isempty(s)) ...
    && isnan(splitParts.LEFT.nextPart(p1)) ...
    && isnan(splitParts.LEFT.prevPart(s));

followBoundaryUpOnRight = ...
    (~isempty(r)  && ~isempty(q1)) ...
    && isnan(splitParts.RIGHT.nextPart(r)) ...
    && isnan(splitParts.RIGHT.prevPart(q1));

followBoundaryDownOnRight = ...
    (~isempty(r1) && ~isempty(q)) ...
    && isnan(splitParts.RIGHT.nextPart(r1)) ...
    && isnan(splitParts.RIGHT.prevPart(q));

if followBoundaryUpAndCrossLeftToRight
    splitParts.LEFT.nextSide{p} = 'RIGHT';
    splitParts.LEFT.nextPart(p) = q1;
    splitParts.RIGHT.prevPart(q1) = p;
    splitParts.LEFT.skipAlongBoundary(p) = true;
elseif followBoundaryDownAndCrossLeftToRight
    splitParts.LEFT.nextSide{p1} = 'RIGHT';
    splitParts.LEFT.nextPart(p1) = q;
    splitParts.RIGHT.prevPart(q) = p1;
    splitParts.LEFT.skipAlongBoundary(p1) = true;
elseif followBoundaryUpAndCrossRightToLeft
    splitParts.RIGHT.nextSide{r} = 'LEFT';
    splitParts.RIGHT.nextPart(r) = s1;
    splitParts.LEFT.prevPart(s1) = r;
    splitParts.RIGHT.skipAlongBoundary(r) = true;
elseif followBoundaryDownAndCrossRightToLeft
    splitParts.RIGHT.nextSide{r1} = 'LEFT';
    splitParts.RIGHT.nextPart(r1) = s;
    splitParts.LEFT.prevPart(s) = r1;
    splitParts.RIGHT.skipAlongBoundary(r1) = true;
elseif followBoundaryUpOnLeft
    splitParts.LEFT.nextSide{p} = 'LEFT';
    splitParts.LEFT.nextPart(p)  = s1;
    splitParts.LEFT.prevPart(s1) = p;
    splitParts.LEFT.skipAlongBoundary(p) = true;
elseif followBoundaryDownOnLeft
    splitParts.LEFT.nextSide{p1} = 'LEFT';
    splitParts.LEFT.nextPart(p1) = s;
    splitParts.LEFT.prevPart(s)  = p1;
    splitParts.LEFT.skipAlongBoundary(p1) = true;
elseif followBoundaryUpOnRight
    splitParts.RIGHT.nextSide{r} = 'RIGHT';
    splitParts.RIGHT.nextPart(r)  = q1;
    splitParts.RIGHT.prevPart(q1) = r;
    splitParts.RIGHT.skipAlongBoundary(r) = true;
elseif followBoundaryDownOnRight
    splitParts.RIGHT.nextSide{r1} = 'RIGHT';
    splitParts.RIGHT.nextPart(r1) = q;
    splitParts.RIGHT.prevPart(q)  = r1;
    splitParts.RIGHT.skipAlongBoundary(r1) = true;
end

%--------------------------------------------------------------------------

function partNumber = findEndOnBoundary(y, side, splitParts, yBound)

% For the given side ('LEFT' or 'RIGHT'), find the number of the part, if
% any, that ends at the boundary point where y == yBound.  There should be
% at most one such point.  If more than one is found, the input data are
% seriously corrupt.

partNumber = find(y.(side).End == yBound);
if ~isempty(partNumber)
    partNumber = ...
        partNumber(splitParts.(side).endsOnBoundary(partNumber));
    if numel(partNumber) > 1
        error(message('map:topology:sharedEndPoint'))
    end
end

%--------------------------------------------------------------------------

function partNumber = findStartOnBoundary(y, side, splitParts, yBound)

% For the given side ('LEFT' or 'RIGHT'), find the number of the part, if
% any, that starts at the boundary point where y == yBound.  There should be
% at most one such point.  If more than one is found, the input data are
% seriously corrupt.

partNumber = find(y.(side).Start == yBound);
if ~isempty(partNumber)
    partNumber = ...
        partNumber(splitParts.(side).startsOnBoundary(partNumber));
    if numel(partNumber) > 1
        error(message('map:topology:sharedStartPoint'))
    end
end

%--------------------------------------------------------------------------

function [xOut, yOut] = traceAcrossBoundary(xIn, yIn, splitParts)

% Trace the input parts, which have already been split where they touch the
% boundary, back and forth across the boundary, copying their vertices from
% xIn and yIn into xOut and yOut.

% Pre-allocate the output arrays to be large enough to hold both sets of
% input vertices combined plus an extra terminating NaN.  Note that the
% process of joining of joining together the split, input parts to form the
% output parts will never add new vertices, but may remove some duplicates.
xOut = NaN + zeros(numel(xIn.LEFT) + numel(xIn.RIGHT) + 1, 1);
yOut = xOut;

% Initialize logical arrays to track which parts have been used.
unused.LEFT  = true(size(splitParts.LEFT.iStart));
unused.RIGHT = true(size(splitParts.RIGHT.iStart));

% Initialize the index of the element to be filled in the output arrays.
iOutputStart = 1;

% Loop until all output parts have been constructed.
while any(unused.LEFT) || any(unused.RIGHT)
    % Decide where to start the next output part.
    [side, part] = locateStartOfOutputPart(splitParts, unused);
    
    % Loop within the current output part, copying vertices from input
    % parts on alternating sides of the boundary.  Stop after reaching a
    % loose end or after closing a loop.  (Note that the first input part
    % will always be copied, but it might be an isolated segment.)
    currentOutputPartIsComplete ...
            = atLooseEndOrBackToStartOfLoop(side, part, unused);
    while ~currentOutputPartIsComplete
        % Identify index ranges to copy from and to.
        iInputStart = splitParts.(side).iStart(part);
        iInputEnd   = splitParts.(side).iEnd(part);
        iOutputEnd = iOutputStart + (iInputEnd - iInputStart);

        % Copy vertices for the current part.
        xOut(iOutputStart:iOutputEnd) = xIn.(side)(iInputStart:iInputEnd);
        yOut(iOutputStart:iOutputEnd) = yIn.(side)(iInputStart:iInputEnd);

        % Make sure not use the same input part more than once.
        unused.(side)(part) = false;
        
        % Move on to the next input part.
        skipAlongBoundary = splitParts.(side).skipAlongBoundary(part);
        nextPart = splitParts.(side).nextPart(part);
        side = splitParts.(side).nextSide{part};
        part = nextPart;
        
        % Check termination condition.
        currentOutputPartIsComplete ...
            = atLooseEndOrBackToStartOfLoop(side, part, unused);
        
        % Determine where to start writing the next output vertices.
        if ~currentOutputPartIsComplete
            % Get ready overwrite the last vertex, because the next input
            % start point will duplicate it,  unless it originates at an
            % adjacent boundary point.
            if ~skipAlongBoundary
                iOutputStart = iOutputEnd;
            else
                iOutputStart = iOutputEnd + 1;
            end
        else
            % Move forward by two elements.  The first step is needed to
            % avoid overwriting the last vertex.  The second step is needed
            % to leave a NaN in place to serve as a separator.
            iOutputStart = iOutputEnd + 2;
        end
    end
end

% Remove any extra trailing NaNs, leaving a single NaN-terminator.
[xOut, yOut] = removeExtraNanSeparators(xOut, yOut);

%--------------------------------------------------------------------------

function [side, partNumber] = locateStartOfOutputPart(splitParts, unused)

% Choose the next part (left side or right side + part number) to copy to
% the output.  If there are any loose ends left, start with one of them.
% Otherwise start with any unused part.

unusedLooseEndStartsLeft  = find(unused.LEFT  & isnan(splitParts.LEFT.prevPart));
unusedLooseEndStartsRight = find(unused.RIGHT & isnan(splitParts.RIGHT.prevPart));
if any(unusedLooseEndStartsLeft)
    side = 'LEFT';
    partNumber = unusedLooseEndStartsLeft(1);
elseif any(unusedLooseEndStartsRight)
    side = 'RIGHT';
    partNumber = unusedLooseEndStartsRight(1);
elseif any(unused.LEFT)
    side = 'LEFT';
    indx = find(unused.LEFT);
    partNumber = indx(1);
elseif any(unused.RIGHT)
    side = 'RIGHT';
    indx = find(unused.RIGHT);
    partNumber = indx(1);
else
    error(message('map:internalProblem:topology', ...
        'Unexpected condition in subfunction locateStartOfOutputPart.'))
end

%--------------------------------------------------------------------------

function tf = atLooseEndOrBackToStartOfLoop(side, partNumber, unused)

% Return true if and only if the current output part is complete.

atLooseEnd = isnan(partNumber);
backToStartOfLoop = ~atLooseEnd && ~unused.(side)(partNumber);
tf = atLooseEnd || backToStartOfLoop;
