function lonlim = conditionLongitudeLimits(lonlim)
%conditionLonlim Adjust wrapping of longitude-limit vector
%
%   LONLIM = conditionLonlim(LONLIM) adds or subtracts multiples of 360
%   degrees from each element in a two-element longitude-limit vector of
%   the form LONLIM = [western_limit eastern_limit], ensuring that: 
% 
%                    lonlim(1) < lonlim(2)
%                    diff(lonlim) <= 360
%
%   In addition the limits either span or touch zero whenever possible.
%   And if the interval does not span or touch zero, then it is still
%   placed as close to zero as possible. Finally, in a symmetrical
%   situation where the interval excludes zero (e.g., [170 -170]), the
%   positive option is selected (e.g., [170 190] rather than
%   [-190 -170]).
%
%   Both inputs and outputs are both in units of degrees.
%
%   Note: In the special case of identical values in lonlim(1) and
%   lonlim(2), conditionLonlim assumes that the intention is to span a full
%   360 degrees of longitude.

% Copyright 2008-2019 The MathWorks, Inc.

    % Ensure that 0 < width <= 360.  (If lonlim(1) == lonlim(2), width = 360.)
    width = ceilmod(diff(lonlim),360);

    % Force lonlim(2) to exceed zero.
    lonlim = ceilmod(lonlim(2),360) + [-width 0];

    % But if subtracting 360 would make the limits include or move closer to
    % zero, then do so.  Thus, for example, [270 360] ==> [-90  0].
    if (lonlim(1) > 0) && (360 - lonlim(2) < lonlim(1))
        lonlim = lonlim - 360;
    end
end


function x = ceilmod(x,y)
% Like mod, but return y instead of zero if x is an exact multiple of y.
    x = mod(x,y);
    x(x == 0) = y;
end
