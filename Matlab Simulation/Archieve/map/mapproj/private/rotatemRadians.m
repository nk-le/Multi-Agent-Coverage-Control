function [lat1,lon1] = rotatemRadians(lat, lon, origin, direction)
%rotatemRadians   Special version of ROTATEM that assumes radians
%
%  This special version of ROTATEM avoids calls to ANGLEDIM to convert
%  angle units/encoding, resulting in efficiency and allowing non-double
%  inputs to be handled.  It achieves additional efficiency by skipping
%  input validation steps, since it cannot be called except by other
%  toolbox functions, and avoiding the call to npi2pi.
%
%  [lat1,lon1] = rotatemRadians(lat, lon, origin, 'forward') uses
%  Euler angle rotations to transform data from one coordinate
%  system to another.  In the forward direction, ROTATEM transforms
%  from a Greenwich system to a coordinate system specified by
%  the origin input.  This transformed system is centered at
%  lat = origin(1), lon = origin(2) and has an north pole orientation
%  defined by origin(3).  If origin(3) is omitted, then origin(3) = 0.
%  These three elements of origin correspond to Euler angle
%  rotations about the Y, X and Z axes respectively, executed
%  in a rotation order of X, Y and Z.
%
%  [lat1,lon1] = rotatemRadians(lat, lon, origin, 'inverse') transforms
%  from the rotated system to the Greenwich coordinate system.
%
%  Note:  The rotation calculations are highly sensitive to
%         round-off errors, especially around the poles and
%         +/- 180 in longitude.  It is extremely difficult to
%         be consistent in the forward and inverse directions
%         near these singularities.  Hence, the various truncation
%         schemes employed below.

% Copyright 2006-2011 The MathWorks, Inc.

%  Construct the three rotation matrices.
%  Rot1 is about the x axis
%  Rot2 is about the y axis
%  Rot3 is about the z axis

rot1 = [cos(origin(2))  sin(origin(2))  0
       -sin(origin(2))  cos(origin(2))  0
	    0               0               1];

rot2 = [cos(origin(1))  0     sin(origin(1))
        0               1     0
	   -sin(origin(1)) 0     cos(origin(1))];

rot3 = [1      0               0
        0     cos(origin(3))  sin(origin(3))
        0    -sin(origin(3))  cos(origin(3))];

%  Construct the complete euler angle rotation matrix
if strcmp(direction,'forward')
    rotation = rot3 * rot2 * rot1;
elseif strcmp(direction,'inverse')
    rotation = (rot3 * rot2 * rot1)';
else
    error(message('map:validate:invalidDirectionString', ...
        direction, 'forward', 'inverse'))
end

%  Move pi/2 points epsilon inward to prevent round-off problems
%  with identically pi/2 points.  The longitude data collapses
%  to zero if a point is identically at + or - pi/2
epsilon = 10*epsm('radians');
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
	lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

%  Eliminate confusion with points at identically +180 or -180 degrees
if strcmp(direction,'forward')
    % Replacing call:  lon = npi2pi(lon,'radians','inward');
    %  Move data epsilon towards (inward) the origin.  Eliminates any
    %  points which start identically on a multiple of pi.  Then
    %  use the atan2 function.
    epsilon = epsm('radians');
    lon = lon*(1 - epsilon);
	lon = atan2(sin(lon),cos(lon));
end

%  Compute the new x,y,z point in Cartesian space

x = rotation(1,1) * cos(lat).*cos(lon) + ...
    rotation(1,2) * cos(lat).*sin(lon) + ...
	rotation(1,3) * sin(lat);

y = rotation(2,1) * cos(lat).*cos(lon) + ...
    rotation(2,2) * cos(lat).*sin(lon) + ...
	rotation(2,3) * sin(lat);

z = rotation(3,1) * cos(lat).*cos(lon) + ...
    rotation(3,2) * cos(lat).*sin(lon) + ...
	rotation(3,3) * sin(lat);

%  Points with essentially zero x and y will be treated as 0,0.  Otherwise,
%  the atan2 operation in cart2sph treats these small distances as
%  coordinates and computes the corresponding angle (generally much
%  greater than zero.  Typically closer to 45 degrees).

epsilon = 1.0E-8;
indx = find(abs(x) <= epsilon & abs(y) <= epsilon);
if ~isempty(indx)
    x(indx) = 0;
    y(indx) = 0;
end

%  Transform the Cartesian point to spherical coordinates
[lon1, lat1] = cart2sph(x,y,z);
