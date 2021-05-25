function b = setUpSineSeries4(a)
%setUpSineSeries4 Set up summation for 4-element sine series
%
%   b = setUpSineSeries4(a) returns a 4-vector b to be used with function
%   map.geodesy.applySineSeries to compute the following truncated series
%   via Clenshaw summation:
%
%     a(1)*sind(x) + a(2)*sind(2*x) + a(3)*sind(3*x) + a(4)*sind(4*x),
%
%   where x is an angle in degrees.
%
%   Example
%   -------
%   % In the following, the output y matches the result of direct summation
%   % to within eps(1), but can be computed more quickly, especially if
%   % the size of x is made larger.
%   a = [1 1/2 1/4 1/8];
%   x = 0:5:360;
%   b = map.geodesy.internal.setUpSineSeries4(a);
%   y = map.geodesy.internal.sumSineSeries(x,b);
%   y0 = a(1)*sind(x) + a(2)*sind(2*x) + a(3)*sind(3*x) + a(4)*sind(4*x);
%
%   Input Argument
%   --------------
%   a -- Vector of sine series coefficients.  Data type: single or double.
%
%   Output Argument
%   ---------------
%   b -- Vector of coefficients derived from a, ready for use in evaluating
%        the series via map.geodesy.sumSineSeries.
%
%   Reference
%   ---------
%   Snyder, J.F., Map Projections - A Working Manual, U.S. Geological
%   Survey Professional Paper 1395, U.S. Government Printing Office, 1987,
%   equations 3-34 and 3-35, page 19.
%
%   See also map.geodesy.internal.sumSineSeries

% Copyright 2012 The MathWorks, Inc.

b = [ ...
    1  0 -1  0; ...
    0  2  0 -4; ...
    0  0  4  0; ...
    0  0  0  8] * a(:);

b = reshape(b,size(a));
