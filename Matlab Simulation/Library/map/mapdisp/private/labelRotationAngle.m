function gamma = labelRotationAngle(mstruct, lat, lon)
%labelRotationAngle Angle rotation angle at scalar location (lat, lon)
%
%   Returns an angle such that the horizontal base of meridian or parallel
%   label text will be aligned with the local orientation of the parallels
%   on the map. Result is in degrees even if mstruct.angleunits is
%   'radians' and lat and lon are in radians.

% Copyright 2014 The MathWorks, Inc.

% One arc-minute; a fairly small angle
delta = fromDegrees(mstruct.angleunits, 1/60);

% Works well in general
[x,y] = feval(mstruct.mapprojection, mstruct, ...
    [lat, lat], [lon - delta, lon + delta], 'geoline', 'forward');

n = isnan(x);
x(n) = [];
y(n) = [];

if length(x) ~= 2
    % May be neeed for polar azimuthal projections
    [x,y] = feval(mstruct.mapprojection, mstruct, ...
        [lat, lat], [lon - delta, lon + delta], 'notrim', 'forward');
end

gamma = atan2d(y(2) - y(1), x(2) - x(1));
if gamma < -90
    gamma = gamma + 180;
elseif gamma > 90
    gamma = gamma - 180;
end
