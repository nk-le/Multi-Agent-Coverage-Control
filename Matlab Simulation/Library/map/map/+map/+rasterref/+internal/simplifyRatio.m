function [num, den] = simplifyRatio(num, den)
%simplifyRatio Simplify rational number
%
%   [num, den] = simplifyRatio(num, den) simplifies the rational number
%   num/den, under the conditions described below in the rationalize
%   subfunction. Otherwise return their ratio in num and 1 in den. In
%   either case ensure that den is positive on output. The inputs must be
%   real and scalar, and den must be nonzero.
%
%   Examples
%   --------
%   [n,d] = map.rasterref.internal.simplifyRatio(20,720)
%   [n,d] = map.rasterref.internal.simplifyRatio(-1234,567)
%   [n,d] = map.rasterref.internal.simplifyRatio(20,1/10)
%   [n,d] = map.rasterref.internal.simplifyRatio(5000/72,-3/360)
%   [n,d] = map.rasterref.internal.simplifyRatio(-123.4,-567.89)
%   [n,d] = map.rasterref.internal.simplifyRatio(pi,10)

% Copyright 2013-2016 The MathWorks, Inc.

validateattributes(num, {'double'}, {'real','scalar'},'','NUM')
validateattributes(den, {'double'}, {'real','scalar','nonzero'},'','DEN')

sgn = sign(num) * sign(den);
num = abs(num);
den = abs(den);
if isIntegerValued(num) && isIntegerValued(den)
    [num, den] = simplify(num, den);
else
    [num, den] = rationalize(num, den);
end
num = sgn * num;

%--------------------------------------------------------------------------

function [num, den] = simplify(num, den)
% Simplify NUM/DEN assuming positive finite integer values.

g = gcd(num, den);
num = num ./ g;
den = den ./ g;

%--------------------------------------------------------------------------

function [num, den] = rationalize(num, den)
% Convert NUM/DEN to rational form, given NUM and DEN, positive and not
% necessarily integer-valued, if each one is equal to some integer divided
% by the "very round number" 720,000. This allows for denominators that
% involve integer multiples of 10, 100, 1000, or 10000, (which make sense
% when working in map coordinates in feet or meters) along with multiples
% of 30, 60, 120, 360, 1200, 3600, etc. (which make sense when working in
% degrees).

scale = 720000;
n = scale * num;
d = scale * den;

if isIntegerValued(n) && isIntegerValued(d)
    [num, den] = simplify(n,d);
else
    num = num / den;
    den = 1;
end

%--------------------------------------------------------------------------

function tf = isIntegerValued(x)
% Returns true if and only if X is integer-valued. X can have any numeric
% class, but would typically be double or single. Not to be confused with
% the MATLAB function ISINTEGER.
tf = isfinite(x) & (x == round(x));
