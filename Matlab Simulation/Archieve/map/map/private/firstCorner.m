function corner = firstCorner(center, delta)
%   Return the world coordinate of the first corner of a rectilinear,
%   cell-oriented, spatially-referenced image or raster, working in a
%   single dimension. The function should be invoked once each for
%   Latitude and Longitude, or once each for WorldX and WorldY.
%
%   In the case of postings, corner = center, so this function is not
%   needed.
%
%   Inputs
%   ------
%   center -- World coordinate of the center of the first (1,1) cell
%
%   delta -- Signed rate of change of the world coordinate with respect to
%            the corresponding intrinsic coordinate
%
%   Output
%   ------
%   corner -- World coordinate of the first corner of the raster (the outer
%             corner of the first (1,1) cell)

% Copyright 2010-2013 The MathWorks, Inc.

cornerOverAbsoluteDelta = center/abs(delta) + sign(delta)/2;
N = round(cornerOverAbsoluteDelta);
if abs(cornerOverAbsoluteDelta - N) <= 2*eps(N)
    % In many cases the corner position is an integer multiple of the cell
    % dimension (or sample spacing).  If that's not quite the case, but
    % their ratio is within 2*eps of the nearest integer, snap the ratio to
    % that integer value. Moreover, if it's also true that delta can be
    % exactly represented as a "nice" ratio of two integers, use that
    % representation in the corner computation.
    [deltaNumerator, deltaDenominator] ...
        = map.rasterref.internal.simplifyRatio(delta,1);
    corner = abs(deltaNumerator) * N / deltaDenominator;
else
    wholeNumberOffset = fix(center);
    [oNum, oDen] = rat(center - wholeNumberOffset);
    [dNum, dDen] = rat(delta);
    if abs(wholeNumberOffset + (oNum / oDen) - center) < 5*eps(center) ...
            && delta == dNum / dDen
        % Try an alternate rational approximation, as long as it is
        % reasonable with respect to machine precision.
        
        % Least common multiple of center denominator and 2x delta denominator
        lcmDen = lcm(oDen, 2 * dDen);
        
        corner = wholeNumberOffset ...
            + (2 * oNum * (lcmDen/oDen) + dNum * (lcmDen/dDen)) / (2 * lcmDen);
    else
        % Use naive formula.
        corner = center + delta - delta / 2;
    end
end
