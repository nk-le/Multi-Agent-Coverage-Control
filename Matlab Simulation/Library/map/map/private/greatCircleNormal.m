function [nx, ny, nz] = greatCircleNormal(phi, lambda, az)
% The radial projection of the unit vector (nx, ny, nz) intersects the
% sphere at one of the poles of the great circle that passes through
% (phi,lambda) at azimuth az. Another way to look it is that every great
% circle is the intersection of the sphere and a plane through the center
% of the sphere, and (nx, ny, nz) is normal to that plane. All input angles
% are in degrees. This is an elementwise function.

% Copyright 2014 The MathWorks, Inc.

    % The following implements a special case of the forward problem for
    % great circles -- locating a point 90 degrees from (phi, lambda) in
    % the direction (az + 90).
    
    sinAz = sind(az);

    nx = sind(phi).*sinAz;
    ny = cosd(az);
    nz = -cosd(phi).*sinAz;
    
    [nx, ny] = rotateInPlane(nx, ny, lambda);
end


function [vx, vy] = rotateInPlane(vx, vy, omega)
% Rotate vector [vx, vy] counter-clockwise through angle omega. The
% rotation angle omega is in degrees. This is an elementwise function.
%
% See also private/geolinebuf.m>rotateInPlane

    c = cosd(omega);
    s = sind(omega);

    t = vx;

    vx = c .* t - s .* vy;
    vy = s .* t + c .* vy;
end
