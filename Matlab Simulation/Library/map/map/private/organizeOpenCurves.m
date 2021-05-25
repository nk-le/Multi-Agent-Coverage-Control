function [B, E, x, y] = organizeOpenCurves(x, y, xlimit, ylimit)
% Given a set of curves defined by the NaN-separated vectors X and Y and
% bounded by the rectangle defined by XLIMIT and YLIMIT, compute several
% properties of the subset comprising curves that are open. (X,Y) may be
% a combination of simple closed curves and open curves, with the added
% constraint that every open curve begins and ends on one of the edges
% of the rectangle.
%
% The key property computed here is the "position" of each end point.
% Position is defined to be a normalized distance from the lower left
% corner (where x == xlimit(1) and y == ylimit(1)), measured clockwise
% along the perimeter of the rectangle. Along the horizontal edges,
% distance is normalized by the width of the rectangle, diff(xlimit) and
% along the vertical edges it is normalized by the height of the rectangle,
% diff(ylimit).
%
% Because of the normalization scheme, the corner points of the rectangle
% have integer position values:
%
%    Lower left corner:   Position = 0
%    Upper left corner:   Position = 1
%    Upper right corner:  Position = 2
%    Lower right corner:  Position = 3
%
% The position property thus makes it possible to identify corners and to
% tell if one must pass one or more corners when traveling along the edge
% of the rectangle from one of the endpoints of one of the open curves to
% one of the endpoints of a different curve (or the other endpoint of the
% same curve).
%
% This function returns two structure arrays. The first output, B, contains
% one element for each of the open curves and has four fields:
%
%    B(k).First -- The index of the first vertex of the k-th open curve in
%                  the coordinate arrays x and y
%
%    B(k).Last  -- The index of the last vertex of the k-th open curve in
%                  the coordinate arrays x and y
%
%    B(k).PosFirst -- Position value of the first vertex of the k-th open
%                     curve
%
%    B(k).PosLast -- Position value of the last vertex of the k-th open
%                    curve
%
%    B(k).LeftSector -- Number of sector on the left side of the curve.
%
%    B(k).RightSector -- Number of sector on the right side of the curve.
%
% The second output, E, has one element for each open-curve end point. (So
% it has twice as many elements as B.) E has the three fields:
%
%    E(k).Index -- Indexes the corresponding element of B
%
%    E(k).IsFirst -- True for the start point of an open curve, false for
%                    the end point
%
%    E(k).Position -- Position value of the corresponding end point
%
% Array E is sorted in terms of ascending values of position.

% Copyright 2010-2016 The MathWorks, Inc.

[first, last] = internal.map.findFirstLastNonNan(x);

% Identify "sector" boundaries
[openCurves, x, y] = identifyOpenCurves(x, y, xlimit, ylimit, first, last);

if any(openCurves)
    B(numel(openCurves),1) = struct( ...
        'First', [], ...
        'Last', [], ...
        'PosFirst', [], ...
        'PosLast', [], ...
        'LeftSector', [], ...
        'RightSector', []);
    
    % Display sectors only
    for k = 1:numel(openCurves)
        j = openCurves(k);
        B(k).First = first(j);
        B(k).Last  = last(j);
    end
    
    % Initialize E, a structure array of endpoints.
    E(2*numel(openCurves),1) = struct( ...
        'Index', [], ...
        'IsFirst', [], ...
        'Position', []);
    
    % Allocate endpoint coordinate arrays to use in computing position
    ex = zeros(size(E));
    ey = zeros(size(E));
    
    % Assign Index and IsFirst fields and ex and ey arrays.
    for k = 1:2:(2*numel(B))
        index = 1 + (k-1)/2;
        E(k).Index = index;
        E(k).IsFirst = true;
        E(k+1).Index = index;
        E(k+1).IsFirst = false;
        iFirst = B(index).First;
        iLast  = B(index).Last;
        ex(k) = x(iFirst);
        ey(k) = y(iFirst);
        ex(k+1) = x(iLast);
        ey(k+1) = y(iLast);
    end
    
    position = computePositionOnBoundary(ex, ey, xlimit, ylimit);
    for k = 1:numel(E)
        E(k).Position = position(k);
    end
    
    for k = 1:numel(B)
        B(k).PosFirst = position(2*k-1);
        B(k).PosLast  = position(2*k);
    end
    
    % Sort E by position.
    [~, indx] = sort(position);
    E = E(indx);
    
    % Adjust order of coincident end points, if any.
    E = orderCoincidentEndPoints(B, E);
else
    % There are no open curves.
    B = [];
    E = [];
end

%---------------------------------------------------------------------------

function [openCurves, x, y] = identifyOpenCurves(x, y, xLimit, yLimit, first, last)
% Return a logical array indicating whether the corresponding curve is open
% or closed. Consider a curve closed when its endpoints are
% coincident or when the curve starts and ends on the boundary and the
% computed position values of its endpoints along the boundary are
% coincident. In the latter case, force its endpoints to be the same.

closed = (x(first) == x(last)) & (y(first) == y(last));
oc = find(~closed);

if any(oc)
    posfirst = computePositionOnBoundary(x(first(oc)), y(first(oc)), xLimit, yLimit);
    poslast = computePositionOnBoundary(x(last(oc)), y(last(oc)), xLimit, yLimit);
    posmatch = (posfirst == poslast);
    if any(posmatch)
        index = oc(posmatch);
        closed(index) = true;
        
        xmean = mean([x(first(index)), x(last(index))]);
        x(first(index)) = xmean;
        x(last(index)) = xmean;
        
        ymean = mean([y(first(index)), y(last(index))]);
        y(first(index)) = ymean;
        y(last(index)) = ymean;
    end
end

openCurves = find(~closed);

%---------------------------------------------------------------------------

function position = computePositionOnBoundary(x, y, xLimit, yLimit)
% Assuming that vectors x and y define points on the edges of the rectangle
% defined by xLimit and yLimit, assign a "position" to each point in terms
% of a normalized distance measured clockwise along the edge from the
% "starting corner" (xLimit(1), yLimit(1)). Values are normalized such that
% on the vertical edge with x == xLimit(1) they range from 0 to 1, on the
% horizontal edge with y == yLimit(2) they range from 1 to 2, on the
% vertical edge with x = xLimit(2) they range from 2 to 3, and on the
% horizontal edge with y = yLimit(1) they range from 1 to just under 4.
% (The starting corner has position 0, so that position can get arbitrarily
% close to 4 but can never actually assume that value.)

position = zeros(numel(x),1);

q = (y == yLimit(1));
position(q) = 3 + (xLimit(2) - x(q))/diff(xLimit);

q = (x == xLimit(2));
position(q) = 2 + (yLimit(2) - y(q))/diff(yLimit);

q = (y == yLimit(2));
position(q) = 1 + (x(q) - xLimit(1))/diff(xLimit);

q = (x == xLimit(1));
position(q) = 0 + (y(q) - yLimit(1))/diff(yLimit);

%--------------------------------------------------------------------------

function E = orderCoincidentEndPoints(B, E)
% The elements of E are already ordered by position, but there might be one
% or more pairs having the same position. In other words, there might be at
% least one pair in which the two curves have a common end point. In this
% case, it's necessary to impose a secondary ordering to support traversing
% the sectors.

if ~isempty(E)
    duplicatePairs = find(diff([E.Position]) == 0);
    for m = duplicatePairs
        % E(m).Position and E(m+1).Position are the same. This means that
        % two different curves end or start at this position. Determine the
        % position of the opposite end point for each of these curves.
        opposite = [0 0];
        for k = 1:2
            % When k is 1, j equals m.
            % When k is 2, j equals m + 1.
            j = m + k - 1;
            if E(j).IsFirst
                opposite(k) = B(E(j).Index).PosLast;
            else
                opposite(k) = B(E(j).Index).PosFirst;
            end
        end
        
        % Determine the positions of the opposite end points relative to
        % the "current position", which equals both E(m).Position and
        % E(m+1).Position.
        relative = mod(opposite - E(m).Position, 4);
        
        % The curve with the larger relative position should come first,
        % such that the following sequence comes in clockwise order:
        % (opposite end point of curve with end point m; point with current
        % position; opposite end point of curve with end point m+1). If
        % this is not true, then swap the elements m and m+1 in E.
        if relative(1) < relative(2)
            % Swap the members of the duplicate pair.
            t = E(m);
            E(m) = E(m+1);
            E(m+1) = t;
        end
    end
end
