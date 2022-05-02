function limits = snapLimits(limits, deltaNumerator, deltaDenominator)
% limits = snapLimits(limits, deltaNumerator, deltaDenominator)
%
%   Adjust the values in LIMITS to ensure that their difference is an exact
%   integer multiple of delta = deltaNumerator / deltaDenominator.
% 
%     LIMITS           -- 1-by-2 vector: [lower_limit upper_limit]
%     deltaNumerator   -- Nonzero scalar
%     deltaDenominator -- Positive scalar
%
%   Assume LIMITS(1) < LIMITS(2) on input.
%
%   The output limits equal the input limits if the difference between the
%   input limits is already an integer multiple of delta. Otherwise one or
%   both limits is "snapped outward" to a value within delta of its input
%   value. The interval defined by the output limits is a superset of the
%   interval defined by the input limits.

% Copyright 2014 The MathWorks, Inc.

    absDeltaNumerator = abs(deltaNumerator);
    
    if ~differenceIsIntegerMultipleOfDelta( ...
            limits, absDeltaNumerator, deltaDenominator)
        
        N = floor((limits(1) * deltaDenominator) / absDeltaNumerator);
        lim1 = (absDeltaNumerator * N) / deltaDenominator;
        
        M = ceil((limits(2) * deltaDenominator) / absDeltaNumerator);
        lim2 = (absDeltaNumerator * M) / deltaDenominator;
        
        limits = [lim1 lim2];
    end
end

%--------------------------------------------------------------------------

function tf = differenceIsIntegerMultipleOfDelta( ...
        limits, absDeltaNumerator, deltaDenominator)

    t = (limits(2) - limits(1)) * deltaDenominator;
    N = round(t / abs(absDeltaNumerator));
    tf = (N * abs(absDeltaNumerator) == t);
end
