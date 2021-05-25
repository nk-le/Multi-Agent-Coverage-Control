function [xi, yi, index] ...
    = intersectLineSegments(x1, y1, x2, y2, x3, y3, x4, y4)
%intersectLineSegments Intersect pairs of line segments
%
%   Given column vectors in which each element represents a coordinate
%   in a different pair of line segments, locate all the intersections
%   such that the line segment connecting x1(k), y1(k) to x2(k), y2(k)
%   intersects the segment connecting x3(k), y3(k) to x4(k), y4(k).
%   Return the result in a pair of column vectors xi, yi along with an
%   an index (a column vector that matches xi and yi in size) that
%   indicates the pair number to which each element of xi and yi
%   corresponds. In cases in which the two segments are collinear and
%   overlapping, return two points of intersection -- the points at
%   which the overlap begins and ends, unless the overlap itself is
%   limited to a single point.

% Copyright 2010-2015 The MathWorks, Inc.

% If possible, we're going to use P1 and P2 to define a similarity
% transformation, but we can't do that if they coincide. And if they are
% very close, there could be unnecessary loss of precision as well. So we
% start out by swapping P1 and P2 with P3 and P4 if P3 and P4 are further
% apart than P1 and P2 ... with these exceptions: Never swap if P1 and P2
% are distinct and fall exactly on a perfectly vertical or horizontal line,
% and always swap if P1 and P2 do not fall on a vertical or horizontal line
% but P3 and P4 are distinct and do fall on a perfectly vertical or
% horizontal line. By maintaining these exceptions, we can be assured that
% intersections involving collinear points on perfectly vertical or
% horizontal lines will not be altered or missed due to floating point
% imprecision.

p12vh = ((x2 == x1) & (y2 ~= y1)) | ((y2 == y1) & (x2 ~= x1));
p34vh = ((x4 == x3) & (y4 ~= y3)) | ((y4 == y3) & (x4 ~= x3));
alwaysSwap = ~p12vh &  p34vh;
neverSwap  =  p12vh & ~p34vh;
% In many cases alwaysSwap and neverSwap will both be false, but they
% cannot both be true.
swap = ~neverSwap & (alwaysSwap ...
    | (hypot(x2 - x1, y2 - y1) < hypot(x4 - x3, y4 - y3)));
[x1, y1, x3, y3] = swapPoints(x1, y1, x3, y3, swap);
[x2, y2, x4, y4] = swapPoints(x2, y2, x4, y4, swap);

% Handle the special case in which all four points coincide.
q = (x2 == x1) & (x3 == x1) & (x4 == x1) ...
  & (y2 == y1) & (y3 == y1) & (y4 == y1);
xiCoincident = x1(q);
yiCoincident = y1(q);
iCoincident = find(q);

% In the more typical situation, P1 and P2 are distinct, P3 and P4 may
% or may not be distinct.
q = ~((x1 == x2) & (y1 == y2));
[xiTypical, yiTypical, iTypical] = subfun( ...
    @intersectTypical, q, x1, y1, x2, y2, x3, y3, x4, y4);

% Combine the results and sort by ascending index.
xi = [xiCoincident; xiTypical];
yi = [yiCoincident; yiTypical];
[index, iSort] = sort([iCoincident; iTypical],1);
xi = xi(iSort);
yi = yi(iSort);

%--------------------------------------------------------------------------

function [xi, yi, index] = intersectTypical(x1, y1, x2, y2, x3, y3, x4, y4)
% Process four different configurations with respect to P3 and P4.

% Assuming that P1 and P2 are non-coincident, define a similarity that
% maps P1 takes to (0,0) and P2 to (0, (x2 - x1).^2 + (y2 - y1).^2), and
% apply it to P3 and P4.
[s, u3, v3, u4, v4] = similarity(x1, y1, x2, y2, x3, y3, x4, y4);

% Process pairs in which P3 and P4 fall on opposite sides of the v-axis.
q = (u3 < 0 & 0 < u4) | (u4 < 0 & 0 < u3);
[xiOpposite, yiOpposite, iOpposite] = subfun( ...
    @checkOppositeSides, q, s, x1, y1, x2, y2, u3, v3, u4, v4);

% Process pairs in which P3 and P4 both fall on the v-axis.
q = (u3 == 0 & u4 == 0);
[xiBothOnAxis, yiBothOnAxis, iBothOnAxis] = subfun( ...
    @checkBothOnAxis, q, s, v3, v4, x1, y1, x2, y2, x3, y3, x4, y4);

% Process pairs in which P3 only falls on the v-axis.
q = (u3 == 0) & (0 <= v3) & (v3 <= s) & (u4 ~= 0);
xiP3OnAxis = x3(q);
yiP3OnAxis = y3(q);
iP3OnAxis = find(q);

% Process pairs in which P4 only falls on the v-axis.
q = (u4 == 0) & (0 <= v4) & (v4 <= s) & (u3 ~= 0);
xiP4OnAxis = x4(q);
yiP4OnAxis = y4(q);
iP4OnAxis = find(q);

% Combine the results.
xi = [xiOpposite; xiBothOnAxis; xiP3OnAxis; xiP4OnAxis];
yi = [yiOpposite; yiBothOnAxis; yiP3OnAxis; yiP4OnAxis];
index = [iOpposite; iBothOnAxis; iP3OnAxis; iP4OnAxis];

%--------------------------------------------------------------------------

function [xi, yi, index] = subfun(f, q, varargin)
% Assume that varargin contains a set of column vectors with matching
% lengths.  Apply the line intersection function f to the elements of the
% column vectors for which the corresponding element of the logical column
% vector q is true.  Return the coordinates at which intersections are
% found (xi, yi) and a linear index, relative to the original inputs, of
% segment pairs that intersect.

if any(q)
    % In each element of varargin, select the rows for which q is true.
    varargin = cellfun(@(a) a(q), varargin, 'UniformOutput', false);
    
    % Apply f
    [xi, yi, index] = f(varargin{:});
    
    % Map the linear index relative to the subset for which q is
    % true back to the original, full set of inputs.
    t = find(q);
    index = t(index);
else
    % Return empty column vectors.
    e = reshape([],[0 1]);
    xi = e;
    yi = e;
    index = e;
end

%--------------------------------------------------------------------------

function [s, x3, y3, x4, y4] = similarity(x1, y1, x2, y2, x3, y3, x4, y4)
% Assuming that P1 and P2 are distinct, define a similarity that
% maps P1 to (0,0) and P2 to (0, s) where:
%
%              s = (x2 - x1).^2 + (y2 - y1).^2
%
% and apply it to P3 and P4.  The computations are vectorized, so each
% set of scalars x1(k), y1(k), x2(k), ... will map to an interval having
% a length of its own, but that's fine.  There is no need for
% normalization to force P2 to (0,1).

% Note: Collinearity is preserved when P1 and P2 fall on the same vertical
% line, because b = 0, and when P3 falls on that line t = x3 - x1 = 0 so
% that after the transformation x3 is precisely 0. Likewise, when P4 falls
% on that line, t = x4 - x1 = 0, so after the transformation x4 is
% precisely 0. That is, points exactly on the vertical line through P1 and
% P2 end up precisely on the vertical line x == 0.
%
% Similarly, when P1 and P2 fall on the same horizontal line, then a = 0
% and when P3 falls on that line (y3 - y1) = 0 so that after the
% transformation x3 is precisely 0. Likewise, when P4 falls on that line,
% (y4 - y1) = 0 so that after the transformation x4 is precisely 0. Points
% exactly on the horizontal line through P1 and P2 end up precisely on the
% vertical line x == 0.

a = y2 - y1;
b = x2 - x1;

s = a.^2 + b.^2;

t  = x3 - x1;
y3 = y3 - y1;

x3 = a .* t - b .* y3;
y3 = b .* t + a .* y3;

t  = x4 - x1;
y4 = y4 - y1;

x4 = a .* t - b .* y4;
y4 = b .* t + a .* y4;

%--------------------------------------------------------------------------

function [xi, yi, index] = checkOppositeSides(s, x1, y1, x2, y2, u3, v3, u4, v4)
% Identify intersections for pairs of segments in which P3 and P4 have been
% mapped to opposite sides of the v-axis. The inputs x1, y1, x2, and y2
% specify the original coordinates of P1 and P2, but u3, v3, v4, and y4
% specify the transformed coordinates of P3 and P4.  Assume 0 < s.

% Swap points 3 and 4, as needed, to ensure that u3 <= u4.
swap = (u4 < u3);
[u3, v3, u4, v4] = swapPoints(u3, v3, u4, v4, swap);

% The segment connecting P3 and P3 intersects the v-axis at (0, r) where r
% is given by a weighted average of v3 and v4:
r = (u4 .* v3 - u3 .* v4) ./ (u4 - u3);

% There is an intersection if and only if the following is true.
q = (0 <= r & r <= s);

% If there is an intersection, its location is a linear combination
% of the locations of P1 and P2.

w2 = r(q) ./ s(q);
w1 = 1 - w2;

xi = w1 .* x1(q) + w2 .* x2(q);
yi = w1 .* y1(q) + w2 .* y2(q);

index = find(q);

%--------------------------------------------------------------------------

function [xi, yi, index] ...
    = checkBothOnAxis(s, v3, v4, x1, y1, x2, y2, x3, y3, x4, y4)
% When P3 and P4 map to the vertical axis, there are two points of
% intersection (bounding a segment along which the inputs overlap),
% except when v3 and v4 are equal (and hence P3 and P4 coincide).

% There's a unique intersection per pair in the following cases.
q1  = (v3 == v4) & (0 <= v3) & (v3 <= s) ...
    | ((v4 < 0) & (v3 == 0)) | ((s == v3) & (s < v4));
  
q8 = ((v3 < 0) & (v4 == 0)) | ((s == v4) & (s < v3));

% There are two intersections per pair of segments in the following cases.
q2 = ((v3 <= 0 & s <= v4) | (v4 <= 0 & s <= v3));
q3 = ((0 < v3 & v3 < s) & (0 < v4 & v4 < s)) & (v3 ~= v4);
q4 = ((0 < v3 & v3 < s) & (v4 <= 0));
q5 = ((0 < v3 & v3 < s) & (s <= v4));
q6 = ((0 < v4 & v4 < s) & (v3 <= 0));
q7 = ((0 < v4 & v4 < s) & (s <= v3));

q = (q2 |q3 | q4 | q5 | q6 | q7);

% Allocate 2-by-n arrays to hold the intersection points. (These will be
% reshaped to 2*n-by-1 after they've been populated.)

n = sum(q);
xi = zeros(2,n);
yi = zeros(2,n);

% Remove from q1, q2, q3, ... those elements which don't correspond to
% elements of xi and yi. Then copy values from vectors with m elements to
% arrays with n columns where n <= m and m is the length of the input
% vectors.

p = q2(q);
xi(1,p) = x1(q2);
yi(1,p) = y1(q2);
xi(2,p) = x2(q2);
yi(2,p) = y2(q2);

p = q3(q);
xi(1,p) = x3(q3);
yi(1,p) = y3(q3);
xi(2,p) = x4(q3);
yi(2,p) = y4(q3);

p = q4(q);
xi(1,p) = x3(q4);
yi(1,p) = y3(q4);
xi(2,p) = x1(q4);
yi(2,p) = y1(q4);

p = q5(q);
xi(1,p) = x3(q5);
yi(1,p) = y3(q5);
xi(2,p) = x2(q5);
yi(2,p) = y2(q5);

p = q6(q);
xi(1,p) = x4(q6);
yi(1,p) = y4(q6);
xi(2,p) = x1(q6);
yi(2,p) = y1(q6);

p = q7(q);
xi(1,p) = x4(q7);
yi(1,p) = y4(q7);
xi(2,p) = x2(q7);
yi(2,p) = y2(q7);

% Combine the unique and paired intersection points.
xi = [x3(q1); x4(q8); reshape(xi,[2*n 1])];
yi = [y3(q1); y4(q8); reshape(yi,[2*n 1])];

% Set up an index vector matching xi and yi in length, with duplicate,
% adjacent entries as required to correspond to pairs of intersection
% points.
iPairs  = find(q)';
iPairs  = reshape(iPairs, [1 numel(iPairs)]);
if ~isempty(iPairs)
    iPairs  = iPairs([1 1],:);
end
index = [find(q1); find(q8); iPairs(:)];

%--------------------------------------------------------------------------

function [x1, y1, x2, y2] = swapPoints(x1, y1, x2, y2, swap)
% Swap x1(swap), y1(swap) with x2(swap), y2(swap).  x1, y1, x2, and y2
% are column vectors that match in size, and swap is a logical column
% vector with that size also.

t = x1(swap);
x1(swap) = x2(swap);
x2(swap) = t;

t = y1(swap);
y1(swap) = y2(swap);
y2(swap) = t;
