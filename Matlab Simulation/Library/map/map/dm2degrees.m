function angleInDegrees = dm2degrees(dm)
%DM2DEGREES Convert degrees-minutes to degrees
% 
%   angleInDegrees = dm2degrees(DM) converts angles from degree-minutes
%   representation to values in degrees which may include a fractional
%   part (sometimes called "decimal degrees.")
%
%   DM should be N-by-2 and real-valued, with one row per angle.  The
%   output will be an N-by-1 column vector whose k-th element
%   corresponds to the k-th row of DM.
%
%   The first column of DM contains the "degrees" element and should be
%   integer-valued.  The second column contains the "minutes" element
%   and may have a fractional part.
%
%   For an angle that is positive (north latitude or east longitude) or
%   equal to zero, all elements in the row need to be non-negative.  For
%   a negative angle (south latitude or west longitude), the first
%   non-zero element in the row should be negative and the remaining
%   value, if any, should be non-zero.
%
%   Thus, for an input row with value [D M], with integer-valued D and
%   real M, the output value will be:
%
%                     SGN * (abs(D) + abs(M)/60)
%   
%   where SGN is 1 if D and M are both non-negative and -1 if the
%   first non-zero element of [D M] is negative.  (An error results if
%   a non-zero D is followed by a negative M.)
%
%   Any fractional parts in the first (degreees) columns of DM are
%   ignored.  An error results unless the absolute values of all
%   elements in the second (minutes) column are less than 60.
%
%   Example
%   -------
%   dm = [ ...
%         30  44.78012; ...
%        -82  39.90825; ...
%          0 -17.12345; ...
%          0  14.82000];
%   format long g
%   angleInDegrees = dm2degrees(dm)
%
%   See also: degrees2dm, deg2rad, dms2degrees, str2angle

% Copyright 2006-2015 The MathWorks, Inc.

validateInput(dm)
sgn = 1 - 2*any(dm < 0, 2);
angleInDegrees = sgn .* (abs(dm(:,1)) + abs(dm(:,2))/60);

%-----------------------------------------------------------------------

function validateInput(dm)

if ~isreal(dm)
    eid = sprintf('%s:%s:complexInput', 'map', mfilename);
    error(eid, 'DM input array must be real-valued.')
end
   
numberOfColumns = size(dm,2);
if (numberOfColumns ~= 2 || ndims(dm) ~= 2)
    eid = sprintf('%s:%s:invalidSize', 'map', mfilename);
    error(eid, 'DM input array must be N-by-2.')
end

nonzero  = (dm ~= 0);
negative = (dm  < 0);

negativeFollowsNonzero = (nonzero(:,1) & negative(:,2));                              
if any(negativeFollowsNonzero)
    eid = sprintf('%s:%s:negativeFollowsNonzero', 'map', mfilename);
    error(eid, ...
        'Negative element follows non-zero element in row %d.', ...
        find(negativeFollowsNonzero,1,'first'))
end

minutesGTorEqual60 = (abs(dm(:,2)) >= 60);
if any(minutesGTorEqual60)
    eid = sprintf('%s:%s:minutesGTorEqual60', 'map', mfilename);
    error(eid, ...
        'Absolute value of minutes greater than or equal to 60 in row %d.', ...
        find(minutesGTorEqual60,1,'first'))
end

% Exempt NaN from non-integer status
nonIntegerDegrees = ~isnan(dm(:,1)) & (dm(:,1) ~= round(dm(:,1)));
if any(nonIntegerDegrees)
    eid = sprintf('%s:%s:nonIntegerDegrees', 'map', mfilename);
    error(eid, ...
        'Non-integer found in degrees column in row %d.', ...
        find(nonIntegerDegrees,1,'first'))
end
