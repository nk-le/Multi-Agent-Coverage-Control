function latlim = snapLatitudeLimits(latlim, deltaNumerator, deltaDenominator)
% latlim = snapLatitudeLimits(latlim, deltaNumerator, deltaDenominator)
%
%   Adjust the values in LATLIM to ensure that their difference is a exact
%   multiple of delta = deltaNumerator / deltaDenominator.
% 
%     LATLIM           -- 1-by-2 vector: [southern_limit northern_limit]
%     deltaNumerator   -- Nonzero scalar
%     deltaDenominator -- (Strictly) positive scalar
%
%   Assume degrees and valid LATLIM input with:
%
%                -90 <= LATLIM(1) < LATLIM(2) <= 90.
%
%   Contract:
%
%     * The output LATLIM satifies: -90 <= LATLIM(1) < LATLIM(2) <= 90.
%
%     * The output limits equal the input limits if the difference between
%       the input limits is already an integer multiple of delta. Otherwise
%       one or both output limits is "snapped" to a value within delta of
%       its input value.
%
%     * When snapped, a limit is snapped "outward" such that the interval
%       defined by the output limits is a superset of the interval defined
%       by the input limits, except in special cases in which an input
%       limit falls within abs(delta) of -90 or +90.
%
%     * Each snapped limit is an integer multiple of delta, except in
%       special cases in which an input limit falls within abs(delta) of
%       -90 or +90. In the special cases, the lower limit will be either
%       -90 or (90 - N*abs(delta)) and the upper limit will be either (-90
%       + N*abs(delta)) or +90, where N is a positive integer. In other
%       words, the limits are snapped to integer-multiple-of-delta offsets
%       from +/- 90 rather than from 0.

% Copyright 2014 The MathWorks, Inc.

    if ~differenceIsIntegerMultipleOfDelta( ...
            latlim, deltaNumerator, deltaDenominator)
        columnsStartFromSouth = (deltaNumerator > 0);
        if columnsStartFromSouth
            [latlim1, latlim2] = snapSouthToNorth( ...
                latlim, deltaNumerator, deltaDenominator);
        else
            [latlim1, latlim2] = snapNorthToSouth( ...
                latlim, deltaNumerator, deltaDenominator);
        end
        latlim = [latlim1 latlim2];
    end
end

%--------------------------------------------------------------------------

function tf = differenceIsIntegerMultipleOfDelta( ...
        latlim, deltaNumerator, deltaDenominator)

    t = (latlim(2) - latlim(1)) * deltaDenominator;
    N = round(t / abs(deltaNumerator));
    tf = (N * abs(deltaNumerator) == t);
end

%--------------------------------------------------------------------------

function [latlim1, latlim2] = snapSouthToNorth( ...
        latlim, deltaNumerator, deltaDenominator)

    N = floor((latlim(1) * deltaDenominator) / deltaNumerator);
    latlim1 = (deltaNumerator * N) / deltaDenominator;
    if latlim1 >= -90
        M = ceil((latlim(2) * deltaDenominator) / deltaNumerator);
        latlim2 = (deltaNumerator * M) / deltaDenominator;
        if latlim2 > 90
            latlim2 = (deltaNumerator * (M - 1)) / deltaDenominator;
        end
    else
        latlim1 = -90;
        M = ceil(((90 + latlim(2)) * deltaDenominator) / deltaNumerator);
        latlim2 = -90 + (deltaNumerator * M) / deltaDenominator;
        if latlim2 > 90
            latlim2 = -90 + (deltaNumerator * (M - 1)) / deltaDenominator;
        end
    end
end

%--------------------------------------------------------------------------

function [latlim1, latlim2] = snapNorthToSouth( ...
        latlim, deltaNumerator, deltaDenominator)

    absDeltaNumerator = abs(deltaNumerator);
    
    N = ceil((latlim(2) * deltaDenominator) / absDeltaNumerator);
    latlim2 = (absDeltaNumerator * N) / deltaDenominator;
    if latlim2 <= 90
        M = floor((latlim(1) * deltaDenominator) / absDeltaNumerator);
        latlim1 = (absDeltaNumerator * M) / deltaDenominator;
        if latlim1 < -90
            latlim1 = (absDeltaNumerator * (M + 1)) / deltaDenominator;
        end
    else
        latlim2 = 90;
        M = ceil(((90 - latlim(1)) * deltaDenominator) / absDeltaNumerator);
        latlim1 = 90 - (absDeltaNumerator * M) / deltaDenominator;
        if latlim1 < -90
            latlim1 = 90 - (absDeltaNumerator * (M - 1)) / deltaDenominator;
        end
    end
end
