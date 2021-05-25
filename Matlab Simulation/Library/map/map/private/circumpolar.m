function c = circumpolar(lon)
%Detect circumpolar curves on sphere
%
%   C = CIRCUMPOLAR(LON), given the longitudes LON of the vertices of a
%   set of simple closed curves on the sphere, with NaN-separators
%   distinguishing multiple curves, returns a column vector C with one
%   element per curve with the values 1, -1, and 0 coding for the
%   topology with respect to the poles as follows:
%
%    1  West-to-east circumpolar curve with north pole on left
%       and south pole on right
%
%   -1  East-to-west circumpolar curve with south pole on left
%       and north pole on right
%
%    0  Non-circumpolar curve with both poles on the same side

% Copyright 2010 The MathWorks, Inc.

% The "accumulated angle" technique used below is used also in:
%   toolbox/map/mapproj/private/ispolycwPolar.m

[first, last] = internal.map.findFirstLastNonNan(lon);
lon = unwrapMultipart(lon);
c = zeros(size(first));
for k = 1:numel(first)
    lonk = lon(first(k):last(k));
    accumulatedAngle = sum(diff(lonk));
    % We expect accumulatedAngle to come out very close to one of these
    % three values:
    %
    %  2*pi ==> West-to-east circumpolar curve
    % -2*pi ==> East-to-west circumpolar curve
    %     0 ==> Non-circumpolar curve
    if accumulatedAngle > pi
        % In the interval (pi Inf]; result must be close to 2*pi.
        c(k) = 1;
    elseif accumulatedAngle < -pi
        % In the interval [-Inf -pi); result must be close to -2*pi.
        c(k) = -1;
    else
        % In the interval [-pi pi]; result must be close to 0.
        c(k) = 0;
    end
end
