function [xi, yi, ii] = polyxpoly(x1, y1, x2, y2, filterCode)
%POLYXPOLY Intersection points for lines or polygon edges
%
%   [XI,YI] = POLYXPOLY(X1,Y1,X2,Y2) returns the intersection points of
%   two polylines in a planar, Cartesian system. X1 and Y1 are vectors
%   containing the x- and y-coordinates of the vertices in the first
%   polyline, and X2 and Y2 contain the vertices in the second polyline.
%   The output variables, XI and YI, are column vectors containing the
%   x- and y-coordinates of each point at which a segment of the first
%   polyline intersects a segment of the second. In the case of
%   overlapping, collinear segments, the intersection is actually a line
%   segment rather than a point, and both endpoints are included in XI, YI.
%
%   [XI,YI,II] = POLYXPOLY(...) returns a two-column array of line
%   segment indices corresponding to the intersection points. The k-th
%   row of II indicates which polyline segments give rise to the
%   intersection point XI(k), YI(k). To remember how these indices work,
%   just think of segments and vertices as fence sections and posts. The
%   i-th fence section connects the i-th post to the (i+1)-th post. In
%   general, letting i and j denote the scalar values comprised by the
%   k-th row of II, the intersection indicated by that row occurs where
%   the i-th segment of the first polyline intersects the j-th segment
%   of the second polyline. But when an intersection falls precisely on
%   a vertex of the first polyline, then i is the index of that vertex.
%   Likewise with the second polyline and the index j. In the case of an
%   intersection at the i-th vertex of the first line, for example,
%   XI(k) equals X1(i) and YI(k) equals Y1(i). In the case of
%   intersections between vertices, i and j can be interpreted as
%   follows: the segment connecting X1(i), Y1(i) to X1(i+1), Y1(i+1)
%   intersects the segment connecting X2(j), Y2(j) to X2(j+1), Y2(j+1)
%   at the point XI(k), YI(k).
%
%   [XI,YI] = POLYXPOLY(...,'unique') filters out duplicate intersections,
%   which may result if the input polylines are self-intersecting.
%
%   Example
%   -------
%   % Define and fill a rectangular area in the plane
%   xlimit = [3 13];
%   ylimit = [2  8];
%   xbox = xlimit([1 1 2 2 1]);
%   ybox = ylimit([1 2 2 1 1]);
%   mapshow(xbox,ybox,'DisplayType','polygon','LineStyle','none')
%
%   % Define and display a two-part polyline
%   x = [0 6  4  8 8 10 14 10 14 NaN 4 4 6 9 15];
%   y = [4 6 10 11 7  6 10 10  6 NaN 0 3 4 3  6];
%   mapshow(x,y,'Marker','+')
%
%   % Intersect the polyline with the rectangle
%   [xi, yi] = polyxpoly(x, y, xbox, ybox);
%   mapshow(xi,yi,'DisplayType','point','Marker','o')
%
%   % Display the intersection points; note that the point (12, 8) appears
%   % twice because of a self-intersection near the end of the first part
%   % of the polyline.
%   [xi yi]
%
%   % You could suppress this duplicate by using the 'unique' option.
%   [xi, yi] = polyxpoly(x, y, xbox, ybox, 'unique');
%   [xi yi]
%
%   See also CROSSFIX, GCXGC, GCXSC, NAVFIX, SCXSC, RHXRH.

% Copyright 1996-2015 The MathWorks, Inc.

narginchk(4,5)

if nargin < 5
    filterCode = 'all';
else
    filterCode = validateFilterCode(filterCode);
end

% Work with column vectors.
x1 = x1(:);
y1 = y1(:);
x2 = x2(:);
y2 = y2(:);

% Validate coordinate vectors.
checkxy(x1, y1, mfilename, 'X1', 'Y1', 1, 2)
checkxy(x2, y2, mfilename, 'X2', 'Y2', 3, 4)

% Compute all intersection points.
[xi, yi, ia, ib] = intersectSegments(x1, y1, x2, y2);

if strcmp(filterCode,'unique') && (nargout < 3)
    % Filter out all duplicate intersections; retain original order as
    % much as possible.
    [~,index] = unique([xi yi],'rows');
    index = sort(index);
    xi = xi(index);
    yi = yi(index);
else
    % Ensure that intersections falling on vertices are reported only once.
    if numel(xi) > 1
        [xi, yi, ia, ib] = filterIntersectionsAtVertices(xi, yi, ia, ib);
    end
    
    % Combine columns.
    ii = [ia ib];
    
    if strcmp(filterCode,'unique')
        warning('map:polyxpoly:ignoringUnique', ...
            '''%s'' flag is ignored when third output (%s) is requested.', ...
            'unique', 'II')
    end
end

%-----------------------------------------------------------------------

function filterCode = validateFilterCode(filterCode)
% Error unless filterCode is a match for 'all' or 'unique'.

try
    filterCode = validatestring(...
        filterCode, {'all','unique'}, mfilename, 'filterCode', 5);
catch e
    if strcmp(e.identifier, 'MATLAB:polyxpoly:unrecognizedStringChoice')
        error('map:polyxpoly:invalidFilterCode', ...
            ['If provided, the 5-th input argument to function %s', ...
            ' must match this string: ''%s''.'], mfilename, 'unique')
    else
        rethrow(e)
    end
end

%-----------------------------------------------------------------------

function [xi, yi, ia, ib] = intersectSegments(xa, ya, xb, yb)
% Intersect each of the segments in the polyline xa, ya with each of the
% segments in xb, yb.  Return the intersection points and the associated
% segment indices.

% Break curve a into M segments, separating start and end points such
% that the k-th segment connects x1(k), y1(k) to x2(k), y2(k) and
% stripping out NaN-separators.  aIndex maps the elements of x1, y1, x2,
% and y2 back to the original vertices of xa, ya.  It is needed to track
% this relationship because of the removal of the NaNs. 
[x1, y1, x2, y2, aIndex] = formSegments(xa, ya);

% Likewise, break curve b into N segments.
[x3, y3, x4, y4, bIndex] = formSegments(xb, yb);

M = numel(x1);  % Number of segments in curve a
N = numel(x3);  % Number of segments in curve b

% Create an outer product with every possible pairing of one segment
% from curve a and one segment from curve b:  Make N interleaved copies
% of the segments from a and M sequential copies of the segments from b.
% (This is basically what function MESHGRID does.)

onesN = ones(1,N);
onesM = ones(M,1);

x1 = x1(:, onesN);
y1 = y1(:, onesN);
x2 = x2(:, onesN);
y2 = y2(:, onesN);

x3 = x3';  x3 = x3(onesM, :);
y3 = y3';  y3 = y3(onesM, :);
x4 = x4';  x4 = x4(onesM, :);
y4 = y4';  y4 = y4(onesM, :);

% Check for all possible intersections between the two curves. Column
% vectors xi and yi contain the intersection points and index is a column
% vector of indices. If the k-th element of index is i, then the segment
% connecting x1(i), y1(i) to x2(i), y2(i) intersects the segment
% connecting x3(i), y3(i) to x4(i), y4(i) at xi(k), yi(k).
[xi, yi, index] = intersectLineSegments( ...
    x1(:), y1(:), x2(:), y2(:), x3(:), y3(:), x4(:), y4(:));

% Refer the index of intersecting segments back to the input curves,
% constructing array ii of size numel(index)-by-2, where numel(index) is
% the number of intersections found.  If the k-th row of ii is [i j],
% then the k-th intersection occurs because the segment connecting the
% i-th and (i+1)-th vertices of curve a intersects the segment
% connecting the j-th and (j+1)-th vertices of curve b.

% Compute indices equivalent to [r, c] = ind2sub([M N],index).
r = 1 + mod(index-1, M);
c = 1 + floor((index-1)/M);

% Construct the columns of ii.
ia = aIndex(r);
ib = bIndex(c);

%-----------------------------------------------------------------------

function [x1, y1, x2, y2, index] = formSegments(x, y)
% Break the NaN-separated curve with vertex coordinates X, Y into
% segments, and return an index that maps each segment back to the
% original indices in the input curve.

% Break the curve into segments, ignoring possible NaN values.
x1 = x(1:end-1,1);
y1 = y(1:end-1,1);
x2 = x(2:end,1);
y2 = y(2:end,1);

% Identify and remove segments that are artificial because they involve
% separating or terminating NaN values.
q = isnan(x1) | isnan(x2);
x1(q) = [];
y1(q) = [];
x2(q) = [];
y2(q) = [];

% Ensure column vectors.
if isempty(x1)
    x1 = reshape(x1,[0 1]);
    y1 = reshape(y1,[0 1]);
    x2 = reshape(x2,[0 1]);
    y2 = reshape(y2,[0 1]);
end

% Save the original indices of the non-artificial segments.
index = find(~q);

% Identify parts consisting of just a single vertex and pair up each
% such vertex with a replica.
[first, last] = internal.map.findFirstLastNonNan(x);
k = first(first == last);
if ~isempty(k)
    % There's at least one single-vertex part.
    n = numel(k);
    xs = x(k);
    ys = y(k);
    x1(end+1:end+n) = xs;
    y1(end+1:end+n) = ys;
    x2(end+1:end+n) = xs;
    y2(end+1:end+n) = ys;
    index(end+1:end+n) = k;
end

%-----------------------------------------------------------------------

function [xi, yi, ia, ib] = filterIntersectionsAtVertices(xi, yi, ia, ib)
% Ensure that intersections falling on vertices are reported only once.
% When we compute intersections independently for the segments of a vs. the
% segments of b, intersections involving vertices will be repeated. If an
% intersection falls on a vertex of polyline a, for example, that
% intersection will be reported once for the segment preceding the
% intersection and once for the segment following it. And if a and b share
% a common vertex, it may be reported up to 4 times. This function filters
% out these artificial repetitions and assign values to the indices ia and
% ib such when an intersection occurs at a vertex of a, ia contains the
% index of that vertex in a and when an intersection falls on a vertex of
% b, ib contains index of that vertex in b.

% Sort on ia, then ib
n = 1 + max(ib);
k = n * ia + ib;
[~, index] = sort(k);
xi = xi(index);
yi = yi(index);
ia = ia(index);
ib = ib(index);

% Find pairs of duplicates in which ia is the same and ib differs by 1 and
% remove the first element from each such pair.

remove = false(size(xi));

u = unique([xi yi],'rows');
for k = 1:size(u,1)
    j = find((u(k,1) == xi) & (u(k,2) == yi));
    if numel(j) > 1
        % We've found a set of duplicates. Some may need to be removed.
        m = j([((diff(ia(j)) == 0) & (diff(ib(j)) ==  1)); false]);
        remove(m) = true;
    end
end

xi(remove) = [];
yi(remove) = [];
ia(remove) = [];
ib(remove) = [];

% Sort on ib, then ia
n = 1 + max(ia);
k = n * ib + ia;
[~, index] = sort(k);
xi = xi(index);
yi = yi(index);
ia = ia(index);
ib = ib(index);

% Find pairs of duplicates in which ib is the same and ia differs by 1 and
% remove the first element from each such pair.

remove = false(size(xi));

u = unique([xi yi],'rows');
for k = 1:size(u,1)
    j = find((u(k,1) == xi) & (u(k,2) == yi));
    if numel(j) > 1
        % We've found a set of duplicates. Some may need to be removed.
        m = j([((diff(ia(j)) == 1) & (diff(ib(j)) ==  0)); false]);
        remove(m) = true;
    end
end

xi(remove) = [];
yi(remove) = [];
ia(remove) = [];
ib(remove) = [];
