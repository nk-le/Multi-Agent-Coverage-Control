function [x1,x2] = solve2x2(a11,a12,a21,a22,b1,b2)
%solve2x2 Elementwise solution of 2-by-2 linear systems
%
%   [x1,x2] = solve2x2(a11,a12,a21,a22,b1,b2) solves the linear system:
%
%        [a11(k) a12(k)  * [x1(k)  = [b1(k)
%         a21(k) a22(k)]    x2(k)]    b2(k)]
%
%    where k = 1, 2, ..., N, given six numeric inputs arguments all having
%    the same size and a total of N elements each. The two output arguments
%    are numeric and have this size also.
%
%    A simplistic implementation of this function might look like this:
%
%        for k = 1:numel(a11)
%            A = [a11(k) a12(k); a21(k) a22(k)];
%            b = [b1(k); b2(k)];
%            x = mldivide(A,b);
%            x1(k) = x(1);
%            x2(k) = x(2);
%        end

% Copyright 2014 The MathWorks, Inc.

% Keep track of original shape.
sz = size(a11);

% Reshape inputs into column vectors.
a11 = a11(:);
a12 = a12(:);
a21 = a21(:);
a22 = a22(:);
b1 = b1(:);
b2 = b2(:);

% Allocated outputs. This step is required because the sizes must match in
% order to use logicial subscripting below, it's not just to manage memory.
x1 = zeros(sz);
x2 = x1;

% Organize the inputs into four sets, depending on which of the four
% matrix elements a11, a12, a21, a22 has the largest value for a given k.
[p11,p12,p21,p22] = selectPivots(a11,a12,a21,a22);

% Solve each set separately, swapping rows and/or columns as needed.
[x1(p11),x2(p11)] = solve2x2NoPivot(a11(p11),a12(p11),a21(p11),a22(p11),b1(p11),b2(p11));
[x2(p12),x1(p12)] = solve2x2NoPivot(a12(p12),a11(p12),a22(p12),a21(p12),b1(p12),b2(p12));
[x1(p21),x2(p21)] = solve2x2NoPivot(a21(p21),a22(p21),a11(p21),a12(p21),b2(p21),b1(p21));
[x2(p22),x1(p22)] = solve2x2NoPivot(a22(p22),a21(p22),a12(p22),a11(p22),b2(p22),b1(p22));

% Reshape outputs to match original shape of inputs.
x1 = reshape(x1,sz);
x2 = reshape(x2,sz);

%--------------------------------------------------------------------------

function [p11,p12,p21,p22] = selectPivots(a11,a12,a21,a22)
% For each k = 1, 2, ..., N, where N is the length of the four input
% vectors a11, a12, a21, and a22, determine which vector contains the
% largest absolute value. Return the results in the form of four vectors,
% p11, p12, p21, and p22 also having length N, such that for each k exactly
% of the four values p11(k), p12(k), p21(k) and p22(k) is true. Which one
% of these values is true indicates which of the four numbers a11(k),
% a12(k), a21(k), and a22(k) has the largest absolute value.
%
% In the event of a tie for largest, the first of the four, in the order
% listed, will be chosen.
%
% If, for example p21(k) is true for some given k, that indicates that
% abs(a21(k)) is at least as large as abs(a11(k)), abs(a12(k)), and
% abs(a22(k)).

v11 = abs(a11);
v12 = abs(a12);
v21 = abs(a21);
v22 = abs(a22);

p11 = (v11 >= v12 & v11 >= v21 & v11 >= v22);
p12 = ~p11 & (v12 >= v11 & v12 >= v21 & v12 >= v22);
p21 = ~p11 & ~p12 & (v21 >= v11 & v21 >= v12 & v21 >= v22);
p22 = ~p11 & ~p12 & ~p21;

% Note: p22 true implies (v22 >= v11 & v22 >= v12 & v22 >= v21), so we
%       don't need to check these inequalities explicitly.

%--------------------------------------------------------------------------

function [x1,x2] = solve2x2NoPivot(a11,a12,a21,a22,b1,b2)
% Given numeric vectors a11, a12, a21, a22, b1, and b2 all having length N,
% solve the system:
%
%        [a11(k) a12(k)  * [x1(k)  = [b1(k)
%         a21(k) a22(k)]    x2(k)]    b2(k)]
%
% where k = 1, 2, ..., N. The outputs x1 and x2 have the same shape as the
% inputs.
%
% Use elementwise Gaussian elimination and back-substitution, and assume
% that a11(k) is large enough to be a suitable pivot for all values of k.

t = a21 ./ a11;
x2 = (b2 - t.*b1) ./ (a22 - t.*a12);
x1 = (b1 - a12.*x2) ./ a11;
