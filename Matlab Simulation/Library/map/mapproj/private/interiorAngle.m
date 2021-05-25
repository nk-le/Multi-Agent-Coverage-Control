function theta = interiorAngle(ux, uy, vx, vy)
%interiorAngle Angle between vectors placed head-to-tail in the plane
%
%   Interior angle THETA is measured counterclockwise in the plane from
%   vector [ux uy] to vector [vx vy], after connecting the vectors head
%   (u) to tail (v). THETA is in radians, and is wrapped such that
%   0 <= THETA < 2*pi. If the vectors represent two connecting edges of a
%   polygon, then a small value of THETA (up to pi/2) indicates an acute
%   angle and a convex corner. A larger value (up to pi) indicates an
%   obtuse angle, and also a convex corner. A value of pi indicates a
%   straight edge. A value greater than pi indicates a concave corner.
%
%   If the inputs are non-scalar (but matching in size), then interior
%   angles are computed for each pair of vectors [ux(k) uy(k)] and
%   [vx(k) vy(k)], for k = 1:numel(ux).

% Copyright 2011 The MathWorks, Inc.

% Define a rotation about the origin that would make u parallel to the
% vector [-1 0], and then apply that rotation to v.
wx = -( ux.*vx + uy.*vy);
wy = -(-uy.*vx + ux.*vy);

% The desired result is simply the angle measured counter-clockwise from
% the positive x-axis to the vector w (the rotated v), modulo 2*pi.
theta = mod(atan2(wy,wx),2*pi);
