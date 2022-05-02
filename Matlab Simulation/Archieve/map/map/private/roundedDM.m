function [D,M,sgn] = roundedDM(X,N)
%roundedDM Decompose angle into degrees and rounded minutes
%
%   [D,M,SGN] = roundedDMS(X) decomposes the absolute value of angle X
%   into degrees and minutes of arc, with the minutes component
%   rounded to the nearest integer. sign(X) is returned as the third
%   output argument. The rounding is such that:
%
%                       (D + M/60).*SGN
%
%   equals X to within 1 minute of arc (1/60 degree).
%
%   [D,M,SGN] = roundedDMS(X,N) decomposes the absolute value of angle X
%   into degrees and minutes of arc, with the minutes component rounded to
%   N digits to the right of the decimal point. The rounding is such that:
%
%                       (D + M/60).*SGN
%
%   equals X to within 10^-N minutes of arc.
%
%   Input Arguments
%   ---------------
%   X - Angle in degrees, specified as a real scalar, vector, matrix, or
%       multidimensional array. Data types: single | double.
%
%   N - Number of digits, specified as a real scalar integer greater than
%       or equal to -2.  N corresponds to the second argument of the MATLAB
%       ROUND function; the minutes component of the output, M, is rounded
%       to the nearest multiple of 10^-N.
%
%   Output Arguments
%   ----------------
%   D - Degrees component of abs(X), returned as a real scalar, vector,
%       matrix, or multidimensional array, containing nonnegative integer
%       values.
%
%   M - Minutes component of abs(X), returned as a real scalar, vector,
%       matrix, or multidimensional array, containing values in the
%       half-open interval [0 60) rounded to the nearest multiple of
%       10^-N with a precision of roughly eps(60*X).
%
%   SGN - Sign indicator, returned as a as a scalar, vector, matrix, or
%       multidimensional array containing the values -1, 0, or 1. SGN is
%       zero when the corresponding element of (D + M/60) is zero.
%       Otherwise it equals the corresponding element of sign(X).
%
%   Examples
%   --------
%   % Convert the value of one radian (in degrees) to degrees and minutes,
%   % rounded to the nearest whole second.
%   [D,M,sgn] = roundedDM(rad2deg(1));
%   sprintf('%2dd %2dm',D,M)
%
%   % Convert the value of minus one radian (in degrees) to degrees and
%   % minutes, rounded to the nearest 1/100th minute.
%   [D,M,sgn] = roundedDM(rad2deg(-1),2);
%   hemisphere = {'E','','W'};
%   H = hemisphere{sgn == [1 0 -1]};
%   sprintf('%s %2dd %5.2fm',H,D,M)
%
%   See also ROUND, roundedDMS.

% Copyright 2015 The MathWorks, Inc.

validateattributes(X,{'single','double'},{'real'},'','X')
if nargin < 2
    N = 0;
else
    validateattributes(N,{'numeric'},{'real','scalar','integer','>=',-2},'','N')
end

if N >= -1
    t = round(abs(60*X),N);
    t(~isfinite(X)) = NaN;
    M = rem(t,60);
    D = floor(t/60);
else
    % N == -2
    M = zeros(size(X),'like',X);
    D = round(abs(X));
    q = ~isfinite(X);
    D(q) = NaN;
    M(q) = NaN;
end
sgn = sign(X);
sgn(D + M/60 == 0) = 0;
