function lonlim = snapLongitudeLimits(lonlim, deltaNumerator, deltaDenominator)
% lonlim = snapLongitudeLimits(lonlim, deltaNumerator, deltaDenominator)
%
%   Adjust the values in LONLIM to ensure that their difference is a exact
%   multiple of delta = deltaNumerator / deltaDenominator.
% 
%     LONLIM           -- 1-by-2 vector: [western_limit eastern_limit]
%     deltaNumerator   -- Nonzero scalar
%     deltaDenominator -- (Strictly) positive scalar
%
%   Assume degrees and LONLIM(1) < LONLIM(2). If the difference between the
%   input longitude limits is 360 or less, constrain the output limits to
%   likewise span 360 degrees or less.
%
%   Contract:
%
%     * The output LONLIM satisfies LONLIM(1) < LONLIM(2).
%
%     * The output limits equal the input limits if the difference between
%       the input limits is already an integer multiple of delta. Otherwise
%       one or both output limits is "snapped" to an integer multiple of
%       delta.
%
%     * When snapped, a limit is snapped "outward" by an amount less than
%       abs(delta) such that the interval defined by the output limits is a
%       superset of the interval defined by the input limits, except in
%       special cases in which this would cause the output limits to span
%       more than 360 degrees when the input limits spanned 360 degrees or
%       less.
%
%     * Each snapped limit will be an integer multiple of delta.

% Copyright 2014 The MathWorks, Inc.

    if ~rasterExtentIsIntegerMultipleOfDelta( ...
            lonlim, deltaNumerator, deltaDenominator)
        columnsStartFromWest = (deltaNumerator > 0);
        if columnsStartFromWest
            [lonlim1, lonlim2] = snapWestToEast( ...
                lonlim, deltaNumerator, deltaDenominator);
        else
            [lonlim1, lonlim2] = snapEastToWest( ...
                lonlim, deltaNumerator, deltaDenominator);
        end
        lonlim = [lonlim1 lonlim2];
    end
end

%--------------------------------------------------------------------------

function tf = rasterExtentIsIntegerMultipleOfDelta( ...
        lonlim, deltaNumerator, deltaDenominator)

    rasterExtent = lonlim(2) - lonlim(1);
    t = rasterExtent * deltaDenominator;
    N = t / abs(deltaNumerator);
    tf = ((round(N) * abs(deltaNumerator)) == t);
end

%--------------------------------------------------------------------------

function [lonlim1, lonlim2] = snapWestToEast( ...
        lonlim, deltaNumerator, deltaDenominator)

    [lonlim1, lonlim2, N] = snapLonlim(lonlim, deltaNumerator, deltaDenominator);
    if (lonlim(2) - lonlim(1) <= 360) && (lonlim2 > lonlim1 + 360)
        % Adjust new eastern limit if the new limits span more than 360
        % while original limits spanned 360 or less.
        M = floor((360 * deltaDenominator) / deltaNumerator);
        lonlim2 = (deltaNumerator * (N + M)) / deltaDenominator;
    end
end

%--------------------------------------------------------------------------

function [lonlim1, lonlim2] = snapEastToWest( ...
        lonlim, deltaNumerator, deltaDenominator)

    [lonlim1, lonlim2, N] = snapLonlim(lonlim, deltaNumerator, deltaDenominator);
    if (lonlim(2) - lonlim(1) <= 360) && (lonlim1 < lonlim2 - 360)
        % Adjust new western limit if the new limits span more than 360
        % while original limits spanned 360 or less.
        absDeltaNumerator = abs(deltaNumerator);
        M = floor((360 * deltaDenominator) / absDeltaNumerator);
        lonlim1 = (absDeltaNumerator * (N - M)) / deltaDenominator;
    end
end

%--------------------------------------------------------------------------

function [lonlim1, lonlim2, P] = snapLonlim(lonlim, deltaNumerator, deltaDenominator)

    absDeltaNumerator = abs(deltaNumerator);

    N = floor((lonlim(1) * deltaDenominator) / absDeltaNumerator);
    lonlim1 = (absDeltaNumerator * N) / deltaDenominator;

    M = ceil((lonlim(2) * deltaDenominator) / absDeltaNumerator);
    lonlim2 = (absDeltaNumerator * M) / deltaDenominator;

    westToEast = (deltaNumerator > 0);
    if westToEast
        P = N;
    else
        P = M;
    end
end
