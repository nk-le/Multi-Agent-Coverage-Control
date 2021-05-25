function angleInDegrees = dms2degrees(dms)
% DMS2DEGREES Convert degrees-minutes-seconds to degrees
%  
%     angleInDegrees = dms2degrees(DMS) converts angles from
%     degree-minutes-seconds representation to values in degrees which
%     may include a fractional part (sometimes called "decimal
%     degrees.")
%  
%     DMS should be N-by-3 and real-valued, with one row per angle.  The
%     output will be an N-by-1 column vector whose k-th element
%     corresponds to the k-th row of DMS.
%  
%     The first column of DMS contains the "degrees" element and should be
%     integer-valued.  The second column contains the "minutes" element
%     and should be integer-valued.  The third column contains the
%     "seconds" element and may have a fractional part.
%  
%     For an angle that is positive (north latitude or east longitude) or
%     equal to zero, all elements in the row need to be non-negative.  For
%     a negative angle (south latitude or west longitude), the first
%     non-zero element in the row should be negative and the remaining
%     values should be positive.
%  
%     Thus, for an input row with value [D M S], with integer-valued D and
%     M, and real D, M, and S, the output value will be:
%  
%               SGN * (abs(D) + abs(M)/60 + abs(S)/3600)
%     
%     where SGN is 1 if D, M, and S are all non-negative and -1 if the
%     first non-zero element of [D M S] is negative.  (An error results
%     if a non-zero element is followed by a negative element.)
% 
%     Any fractional parts in the first (degrees) and second (minutes)
%     columns of DMS are ignored.  An error results unless the absolute
%     values of all elements in the second (minutes) and third (seconds)
%     columns are less than 60.
%  
%     Example
%     -------
%     dms = [ ...
%           30  50 44.78012; ...
%          -82   2 39.90825; ...
%            0 -30 17.12345; ...
%            0   0 14.82000];
%     format long g
%     angleInDegrees = dms2degrees(dms)
%  
%     See also: DEGREES2DMS, DEG2RAD, DM2DEGREES, STR2ANGLE

% Copyright 2006-2015 The MathWorks, Inc.

validateInput(dms)
sgn = 1 - 2* any(dms < 0, 2);
angleInDegrees ...
    = sgn .* (abs(dms(:,1)) + (abs(dms(:,2)) + abs(dms(:,3))/60)/60);

%-----------------------------------------------------------------------

function validateInput(dms)

if ~isreal(dms)
    eid = sprintf('%s:%s:complexInput', 'map', mfilename);
    error(eid, 'DMS input array must be real-valued.')
end

numberOfColumns = size(dms,2);
if (numberOfColumns ~= 3 || ndims(dms) ~= 2)
    eid = sprintf('%s:%s:invalidSize', 'map', mfilename);
    error(eid, 'DMS input array must be N-by-3.')
end

nonzero  = (dms ~= 0);
negative = (dms  < 0);

negativeFollowsNonzero = ...
    (nonzero(:,1) & (negative(:,2) | negative(:,3))) |...            
    (nonzero(:,2) & negative(:,3));                              

if any(negativeFollowsNonzero)
    eid = sprintf('%s:%s:negativeFollowsNonzero', 'map', mfilename);
    error(eid, ...
        'Negative element follows non-zero element in row %d.', ...
        find(negativeFollowsNonzero,1,'first'))
end

minutesGTorEqual60 = (abs(dms(:,2)) >= 60);
secondsGTorEqual60 = (abs(dms(:,3)) >= 60);

if any(minutesGTorEqual60)
    eid = sprintf('%s:%s:minutesGTorEqual60', 'map', mfilename);
    error(eid, ...
        'Absolute value of minutes greater than or equal to 60 in row %d.', ...
        find(minutesGTorEqual60,1,'first'))
end

if any(secondsGTorEqual60)
    eid = sprintf('%s:%s:secondsGTorEqual60', 'map', mfilename);
    error(eid, ...
        'Absolute value of seconds greater than or equal to 60 in row %d.', ...
        find(secondsGTorEqual60,1,'first'))
end

% Exempt NaN from non-integer status
nonIntegerDegrees = ~isnan(dms(:,1)) & (dms(:,1) ~= round(dms(:,1)));
nonIntegerMinutes = ~isnan(dms(:,2)) & (dms(:,2) ~= round(dms(:,2)));

if any(nonIntegerDegrees)
    eid = sprintf('%s:%s:nonIntegerDegrees', 'map', mfilename);
    error(eid, ...
        'Non-integer found in degrees column in row %d.', ...
        find(nonIntegerDegrees,1,'first'))
end

if any(nonIntegerMinutes)
    eid = sprintf('%s:%s:nonIntegerMinutes', 'map', mfilename);
    error(eid, ...
        'Non-integer found in minutes column in row %d.', ...
        find(nonIntegerMinutes,1,'first'))
end
