function lonlim = unwrapLongitudeLimits(lonlim)
%unwrapLongitudeLimits Adjust wrapping of longitude-limit vector
%
%   LONLIM = map.internal.unwrapLongitudeLimits(LONLIM) adds or subtracts
%   multiples of 360 degrees from each element in a two-element
%   longitude-limit vector of the form LONLIM = [western_limit
%   eastern_limit], shifting the output into the half-open interval
%   (-360 360] while ensuring that mod(lonlim,360) remains unchanged
%   and that the following conditions hold upon output:
%
%                     0 <= diff(lonlim)
%                    diff(lonlim) <= 360
%                     lonlim(1) <= 180
%                     -180 < lonlim(2)
%
%   Inputs that meet these conditions are left unchanged. If
%
%                    lonlim(1) == lonlim(2)
%
%   upon input, this remains true upon output. In addition, when possible,
%   the limits span (or touch) the prime (lon == 0) meridian such that:
%
%             lonlim(1) <= 0 and 0 <= lonlim(2)
%
%   Finally, when the limits are placed symmetrically about the 180-degree
%   meridian (e.g., [170 -170]), the positive option is selected (e.g.,
%   [170 190] rather than [-190 -170]).
%
%   Both inputs and outputs are both in units of degrees.
%
%   The caller should ensure that lonlim is class single or double with
%   real, finite values.

% Copyright 2016-2017 The MathWorks, Inc.

    zeroWidth = (lonlim(1) == lonlim(2));

    % Shift limits into the half-open interval (-360 360].
    lonlim = lonlim - 360 * max(0, ceil((lonlim - 360)/360));
    lonlim = lonlim + 360 * max(0, 1 + floor((-360 - lonlim)/360));

    w = lonlim(1);
    e = lonlim(2);

    % There are six possible ways that 0, w, and e can be ordered. Nothing
    % need be done when the order is (0 w e), except when both w and e
    % exceed 180. Likewise for (w e 0), except when both w and e are less
    % than -180.
    
    if e <= w && w <= 0 && ~zeroWidth
        % (e w 0)
        e = e + 360;
    elseif 0 <= e && e <= w && ~zeroWidth
        % (0 e w)
        w = w - 360;
    elseif w < 0 && 0 < e
        % (w 0 e)
        if (e - w) > 360
            if abs(w) < e
                e = e - 360;
            else
                w = w + 360;
            end
        end
    elseif e < 0 && 0 < w
        % (e 0 w)
        if (w - e) >= 360
            w = w - 360;
            e = e + 360;
        else
            if abs(e) < w
                w = w - 360;
            else
                e = e + 360;
            end
        end
    elseif w <= e && e <= -180
        % Special case of (w e 0)
        w = w + 360;
        e = e + 360;
    elseif 180 < w && w <= e
        % Special case of (0 w e)
        w = w - 360;
        e = e - 360;
    end
    lonlim = [w e];
end
