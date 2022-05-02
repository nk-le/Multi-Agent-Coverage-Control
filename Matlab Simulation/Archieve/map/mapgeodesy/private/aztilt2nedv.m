function [uNorth, vEast, wDown] = aztilt2nedv(az, tilt)
%aztilt2nedv Azimuth and tilt to NED direction cosines
%
%   [uNorth, vEast, wDown] = aztilt2nedv(az, tilt) converts azimuth and
%   tilt angles in degrees to unit vectors indicating direction in a
%   north-east-down (NED) system. Azimuth is measured east of north, which
%   is counterclockwise from x when the x-y (north-east) plane is viewed
%   from the positive z-axis. Tilt is the angle from the z-axis, and should
%   fall in the interval [0 180]. Ignoring for roundoff in the deg2rad
%   conversions, this function is equivalent to:
%
%    [uNorth, vEast, wDown] = sph2cart(deg2rad(az), deg2rad(90 - tilt), 1)

% Copyright 2016 The MathWorks, Inc.

r = sind(tilt);
uNorth = r .* cosd(az);
vEast  = r .* sind(az);
wDown = cosd(tilt);
