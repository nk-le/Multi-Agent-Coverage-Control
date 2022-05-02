function [D,M,S,sgn] = roundedDMS(X,N)
%roundedDMS Decompose angle into degrees, minutes, and rounded seconds
%
%   [D,M,S,SGN] = roundedDMS(X) decomposes the absolute value of angle X
%   into degrees, minutes, and seconds of arc, with the seconds component
%   rounded to the nearest integer. sign(X) is returned as the fourth
%   output argument. The rounding is such that:
%
%                  (D + (M + S/60)/60).*SGN
%
%   equals X to within 1 second of arc (1/3600 degree).
%
%   [D,M,S,SGN] = roundedDMS(X,N) decomposes the absolute value of angle X
%   into degrees, minutes, and seconds of arc, with the seconds component
%   rounded to N digits to the right of the decimal point. The rounding is
%   such that:
%
%                  (D + (M + S/60)/60).*SGN
%
%   equals X to within 10^-N seconds of arc.
%
%   Input Arguments
%   ---------------
%   X - Angle in degrees, specified as a real scalar, vector, matrix, or
%       multidimensional array. Data types: single | double.
%
%   N - Number of digits, specified as a real scalar integer greater than
%       or equal to -2.  N corresponds to the second argument of the MATLAB
%       ROUND function; the seconds component of the output, S, is rounded
%       to the nearest multiple of 10^-N.
%
%   Output Arguments
%   ----------------
%   D - Degrees component of abs(X), returned as a real scalar, vector,
%       matrix, or multidimensional array, containing nonnegative integer
%       values.
%
%   M - Minutes component of abs(X), returned as a real scalar, vector,
%       matrix, or multidimensional array, containing nonnegative integer
%       values ranging up to 59.
%
%   S - Seconds component of abs(X), returned as a real scalar, vector,
%       matrix, or multidimensional array, containing values in the
%       half-open interval [0 60) rounded to the nearest multiple of
%       10^-N with a precision of roughly eps(3600*X).
%
%   SGN - Sign indicator, returned as a as a scalar, vector, matrix, or
%       multidimensional array containing the values -1, 0, or 1. SGN is
%       zero when the corresponding element of (D + (M + S/60)/60) is zero.
%       Otherwise it equals the corresponding element of sign(X).
%
%   Examples
%   --------
%   % Convert the value of one radian (in degrees) to degrees, minutes,
%   % and seconds, rounded to the nearest whole second.
%   [D,M,S,sgn] = roundedDMS(rad2deg(1));
%   sprintf('%2dd %2dm %2ds',D,M,S)
%
%   % Convert the value of minus one radian (in degrees) to degrees,
%   % minutes, and seconds, rounded to the nearest 1/100th second.
%   [D,M,S,sgn] = roundedDMS(rad2deg(-1),2);
%   hemisphere = {'N','','S'};
%   H = hemisphere{sgn == [1 0 -1]};
%   sprintf('%s %2dd %2dm %5.2fs',H,D,M,S)
%
%   See also ROUND, roundedDM.

% Copyright 2015 The MathWorks, Inc.

validateattributes(X,{'single','double'},{'real'},'','X')
if nargin < 2
    N = 0;
else
    validateattributes(N,{'numeric'},{'real','scalar','integer','>=',-2},'','N')
end

if N >= -1
    t = round(abs(3600*X),N);
    S = rem(t,60);
    t = round(t - S)/60;
    M = rem(t,60);
    D = floor(t/60);
else
    % N == -2
    S = zeros(size(X),'like',X);
    t = round(abs(60*X));
    M = rem(t,60);
    D = floor(t/60);
    q = ~isfinite(X);
    D(q) = NaN;
    S(q) = NaN;
end
sgn = sign(X);
sgn(D + (M + S/60)/60 == 0) = 0;
