function dm = degrees2dm(angleInDegrees)
%DEGREES2DM Convert degrees to degrees-minutes
%
%   DM = degrees2dm(angleInDegrees) converts angles from values in
%   degrees which may include a fractional part (sometimes called
%   "decimal degrees") to degree-minutes representation.
%
%   The input should be a real-valued column vector.  Given N-by-1
%   input, DM will be N-by-2, with one row per input angle.
%
%   The first column of DM contains the "degrees" element and is
%   integer-valued.  The second column contains the "minutes" element
%   and may have a non-zero fractional part.
%
%   In any given row of DM, the sign of the first non-zero element indicates
%   the sign of the overall angle.  A positive number indicates north
%   latitude or east longitude; a negative number indicates south
%   latitude or west longitude.  Any remaining elements in that row will
%   have non-negative values.
%
%   Example
%   -------
%   angleInDegrees = [ 30.8457722555556; ...
%                     -82.0444189583333; ...
%                      -0.504756513888889;...
%                       0.004116666666667];
%
%   dm = degrees2dm(angleInDegrees)
%
%   See also: dm2degrees, deg2rad, degrees2dms, rad2deg
    
% Copyright 2006-2015 The MathWorks, Inc.

% Ensure column-vector input.
inputSize = size(angleInDegrees);
angleInDegrees = angleInDegrees(:);
if ~isequal(size(angleInDegrees),inputSize)
    warning('map:degrees2dm:reshapingInput',...
        'Reshaping input into %d-by-1 column vector.  Output will be %d-by-2.',...
        numel(angleInDegrees), numel(angleInDegrees));
end

% Construct a DM array in which each nonzero
% element in a given row has the same sign.
dm = [fix(angleInDegrees) 60*rem(angleInDegrees,1)];

% Flip the sign in the minutes column (from negative to positive)
% if degrees is negative.
negativeD = (dm(:,1) < 0);
dm(negativeD,2) = -dm(negativeD,2);
