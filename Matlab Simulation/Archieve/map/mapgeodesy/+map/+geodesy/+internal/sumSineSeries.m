function y = sumSineSeries(x, b, inDegrees)
%sumSineSeries Sum a truncated sine series
%
%   y = map.geodesy.internal.sumSineSeries(x, b, inDegrees) returns the sum
%   of a truncated sine series in x using a vector of coefficients b, where
%   x is in either degrees or radians.
%
%   Input Arguments
%   ---------------
%   x -- Angle in degrees, specified as scalar value, vector, matrix, or
%        N-D array.  Data Type: single or double.
%
%   b -- Vector of coefficients returned by a function such as
%        map.geodesy.setupSineSeries4.  Data Type: single or double.
%        
%   inDegrees -- Unit of angle flag, specified as a scalar logical. True
%        indicates that x is in degrees; false indicates radians.
%        Data type: logical.
%
%   Output Argument
%   ---------------
%   y -- Sum of the sine series, for each element of x, specified as a
%        scalar value, vector, matrix, or N-D array.  Data type: single or
%        double.
%
%   This function uses Clenshaw summation to sum the series.  In the case
%   of series truncated after the 4-th term, for example, it computes:
%
%    sind(x) * (b(1) + (b(2) + (b(3) + b(4)*cosd(x))*cosd(x))*cosd(x))
%
%   which is equivalent to:
%
%        sind(x) * (a(1) - a(3) + (2*a(2) - 4*a(4)
%            + (4*a(3) + 8*a(4)*cosd(x))*cosd(x))*cosd(x))
%
%   which equals:
%
%        a(1)*sin(x) + a(2)*sin(2*x) + a(3)*sin(3*x) + a(4)*sin(4*x)
%
%   Output Units
%   ------------
%   The unit in which y is expressed depends only on the unit in which b is
%   expressed.  This is a direct consequence of the fact that y is linear
%   in b.  The coefficients in b and the output y can be in any units, but
%   need to be consistent with each other, while the input x is required to
%   be in degrees.  Thus, the units of x have nothing to do with the units
%   of y, even if y is angle-valued.  For example, if the coefficients in b
%   (and thus the output y) happen to be in radians, which can occur in
%   geodetic and mapping applications, then input x is still required to be
%   an angle in degrees when inDegrees is true.  Conversely, the only way
%   that y can be in degrees is for b to be in degrees.
%
%   See also map.geodesy.internal.setUpSineSeries4

% Copyright 2012 The MathWorks, Inc.

if inDegrees
    s = sind(x);
    c = cosd(x);
else
    s = sin(x);
    c = cos(x);
end

n = length(b);
t = b(n);
for k = n-1 : -1 : 1
    t = b(k) + t.*c;
end
y = t .* s;
