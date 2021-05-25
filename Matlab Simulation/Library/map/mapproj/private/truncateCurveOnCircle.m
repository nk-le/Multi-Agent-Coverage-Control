function [az, r] = truncateCurveOnCircle(az, r, rBound)
% Truncate the multipart curve with vertices defined by the column vectors
% az and r (azimuth and radius), eliminating vertices for which r > rBound,
% and interpolating new vertices on the bounding circle as needed. Assume
% that az and r are equal length and that rBound > 0. Insert NaNs to break
% sections of curves that were connected by loops beyond the bounding
% circle. Filter out isolated points if they fall on the bounding circle
% itself. Azimuth az is in degrees.

% Copyright 2015 The MathWorks, Inc.  

% Find places where the curve has crossed the bounding circle without
% having an intersection point on the circle itself.
signDiff = diff(sign(r - rBound)); 
kCrossing = find(abs(signDiff) == 2);

% Flip kCrossing to facilitate inserting values into az and r. (Insert
% additional points starting toward the end of the arrays so as not to
% invalidate the index values in kCrossing itself.)
kCrossing = flipud(kCrossing);

% For each k in kCrossing, interpolate linearly between (az(k),r(k)) and
% (az(k+1),r(k+1)) to a new point where r == rBound.
for j = 1:numel(kCrossing)
    k = kCrossing(j);
    dr = r(k + 1) - r(k);
    f = (rBound - r(k)) / dr;
    rNew = rBound;
    azNew = interpolateAngleInDegrees(az(k), az(k + 1), f);
    [r, az] = insert(k, azNew, rNew, az, r, dr);
end    

% Remove points beyond the bounding circle.
[r, az] = truncate(az, r, rBound);

%-----------------------------------------------------------------------

function [r, az] = insert(k, azNew, rNew, az, r, dr)
% Insert the new point via a simple contenation and resize operation,
% placing NaNs to separate the new point from the next vertex beyond the
% bounding circle.

outboundCrossing = (dr > 0);
if outboundCrossing
    rInsert  = [ rNew; NaN];
    azInsert = [azNew; NaN];
else
    rInsert =  [NaN;  rNew];
    azInsert = [NaN; azNew];
end
r  = [ r(1:k);  rInsert;  r((k+1):end)];
az = [az(1:k); azInsert; az((k+1):end)];

%-----------------------------------------------------------------------

function [r, az] = truncate(az, r, rBound)
% Eliminate all points for which r > rBound, breaking truncated sections
% along the bounding circle, and removing any isolated vertices left on the
% boundary.

% Replace the coordinate values for all such points with NaN.
q = (r > rBound);
r(q) = NaN;
az(q) = NaN;

% Filter isolated points on the boundary.
onBoundary = (r == rBound);
first = [true; isnan(r(1:end-1))];
last = [isnan(r(2:end)); true];
isolatedOnBoundary = onBoundary & first & last;
r(isolatedOnBoundary) = [];
az(isolatedOnBoundary) = [];

% Remove any excess NaN-separators.
n = isnan(r(:));
firstOrPrecededByNaN = [true; n(1:end-1)];
extraNaN = n & firstOrPrecededByNaN;
r(extraNaN) = [];
az(extraNaN) = [];
if ~isempty(r) && isnan(r(end))
    r(end) = [];
    az(end) = [];
end

%-----------------------------------------------------------------------

function theta = interpolateAngleInDegrees(theta0, theta1, f)
% Interpolate angles that represent positions along a circle, accounting
% for wrapping with a periodicity of 360.  Compute the angle corresponding
% to a position along the shorter arc between the points with angles theta0
% and theta1. Starting at the theta0 point, move a fraction f of the arc
% length toward the theta1 point. Assume 0 <= f <= 1. If the values of
% theta0 and theta1 are such that wrapping is not an issue, then the result
% is simply:
%
%      theta = (1 - f).*theta0 + f.* theta1

dtheta = wrapTo180(theta1 - theta0);
theta = wrapTo180(theta0 + f .* dtheta);
