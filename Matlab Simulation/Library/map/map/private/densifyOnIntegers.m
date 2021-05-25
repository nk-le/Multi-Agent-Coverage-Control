function [xNew, yNew] = densifyOnIntegers(x, y, xLimit, yLimit, edgesampling)
%densifyOnIntegers Insert vertices at integer values in x or y
%
%   Given line or polygon vertex arrays X and Y, insert additional
%   vertices with integer values in X (interpolating linearly for values
%   in Y) or with integer values in Y (interpolating linearly for values
%   in X). Insert new vertices when a pair of adjacent elements in X or Y
%   fall on opposite sides of a integer and are separated by an absolute
%   difference of 2 or more in either X or Y. Make exceptions (i.e., do
%   not insert additional vertices) for points on the edges of the
%   rectangle defined by the 2-vectors xLimit (with xLimit(2) >
%   xLimit(1)) and yLimit (with yLimit(2) > yLimit(1)), depending on the
%   values of the fields of the scalar edgesampling structure:
%
%        SparseOnFirstHorizontalEdge
%        SparseOnLastHorizontalEdge
%        VerticalEdgesMeet
%
%   X and Y may contain NaN-separators.

% Copyright 2010 The MathWorks, Inc.

% Work with column vectors throughout, but keep track of input shape.
rowVectorInput = (size(x,2) > 1);
x = x(:);
y = y(:);

% Determine the number of integers between each pair of adjacent
% elements in x. Note that all(nx >= 0) is true.
nx = ceil(x(2:end))   - floor(x(1:end-1)) - 1;
t  = ceil(x(1:end-1)) - floor(x(2:end))   - 1;
xrising = diff(x) > 0;
nx(~xrising) = t(~xrising);
nx(isnan(nx)) = 0;

% Determine the number of integers between each pair of adjacent
% elements in y. Note that all(ny >= 0) is true.
ny = ceil(y(2:end))   - floor(y(1:end-1)) - 1;
t  = ceil(y(1:end-1)) - floor(y(2:end))   - 1;
yrising = diff(y) > 0;
ny(~yrising) = t(~yrising);
ny(isnan(ny)) = 0;

% Allow one integer to be skipped, as long as the difference in x or y
% between adjacent vertices is less than 2.
nx(nx == 1 & abs(diff(x)) < 2) = 0;
ny(ny == 1 & abs(diff(y)) < 2) = 0;

% Make a preliminary determination of the number of vertices to insert
% between each pair of adjacent vertices. (If nx is larger, we'll insert
% new vertices at integer values of x and linearly interpolate to find
% y values that correspond to them. Otherwise we'll insert new vertices
% at integer values in y and linearly interpolate to find corresponding
% values in x.)
n = max(nx,ny);

% Identify certain exceptions and remove them from consideration by
% setting the corresponding element of n to 0.
if edgesampling.SparseOnFirstHorizontalEdge
    % Ignore adjacent vertices on the lower edge.
    n(y(1:end-1) == yLimit(1) & y(2:end) == yLimit(1)) = 0;
end

if edgesampling.SparseOnLastHorizontalEdge
    % Ignore adjacent vertices on the upper edge.
    n(y(1:end-1) == yLimit(2) & y(2:end) == yLimit(2)) = 0;
end

if edgesampling.VerticalEdgesMeet
    % Ignore adjacent vertices at which a curve wraps from one vertical
    % edge to the opposite vertical edge.
    n(abs(diff(x)) > diff(xLimit) - 1) = 0;
end

% Pre-allocate output vertex arrays.
xNew = nan(numel(x) + sum(n), 1);
yNew = xNew;

% For each nonzero element of n, insert a sequence of vertices into the
% original input arrays. (The following loop will execute only if there
% are one or more adjacent vertex pairs between which points need to be
% interpolated.)
indx = find(n);
s = 1;
sNew = 1;
for k = 1:numel(indx)
    % Insert vertices between x(indx(k)), y(indx(k))
    % and x(1 + indx(k)), y(1 + indx(k)).
    
    % First copy the elements of x and y that precede the current
    % insertion point.
    e = indx(k);
    eNew = sNew + e - s;
    xNew(sNew:eNew) = x(s:e);
    yNew(sNew:eNew) = y(s:e);
    
    % Advance s to be ready for the next iteration (or final copy),
    % and also for use in the insertion step below.
    s = 1 + e;
    
    % Compute the new vertices that are to be inserted between the
    % vertices x(e),y(e) and x(s),y(s). (Take careful note: at this
    % stage in the loop, s > e.)
    if nx(e) > ny(e)
        if xrising(e)
            % Ascending sequence of integers
            xInsert = (1 + floor(x(e))):(ceil(x(s)) - 1);
        else
            % Descending sequence of integers
            xInsert = (ceil(x(e)) - 1):-1:(floor(x(s)) + 1);
        end
        % Linear interpolation
        yInsert = y(e) + (y(s) - y(e)) * (xInsert - x(e)) / (x(s) - x(e));
    else
        if yrising(e)
            % Ascending sequence of integers
            yInsert = (1 + floor(y(e))):(ceil(y(s)) - 1);
        else
            % Descending sequence of integers
            yInsert = (ceil(y(e)) - 1):-1:(floor(y(s)) + 1);
        end
        % Linear interpolation
        xInsert = x(e) + (x(s) - x(e)) * (yInsert - y(e)) / (y(s) - y(e));
    end
    
    % Copy the new vertices into the output arrays.
    sNew = eNew + 1;
    eNew = eNew + n(e);
    xNew(sNew:eNew) = xInsert;
    yNew(sNew:eNew) = yInsert;
    
    % Advance sNew to be read for the next iteration (or final copy).
    sNew = eNew + 1;
end

% Append any vertices that come after the last insertion point. Note
% that if all(n == 0), we'll have skipped the loop, s will equal 1, and
% we'll be making an exact copy of the inputs.
xNew(sNew:end) = x(s:end);
yNew(sNew:end) = y(s:end);

% Make shape consistent with input.
if rowVectorInput
    xNew = xNew';
    yNew = yNew';
end
