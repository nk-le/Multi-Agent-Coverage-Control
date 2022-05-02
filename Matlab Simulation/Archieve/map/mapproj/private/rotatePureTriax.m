function [lat, lon] = rotatePureTriax(lat, lon, origin, direction)
% This function is like rotatem, but without any special numerical
% adjustments and without a units option.  All inputs and outputs are in
% radians.

% Copyright 2006-2011 The MathWorks, Inc.

phi0    = origin(1);
lambda0 = origin(2);
alpha   = origin(3);

if strcmp(direction,'forward')
    [lat,lon] = rotateFwd(lat,lon,phi0,lambda0,alpha);
elseif strcmp(direction,'inverse')
    [lat,lon] = rotateInv(lat,lon,phi0,lambda0,alpha);
else
    error(message('map:validate:invalidDirectionString', ...
        direction, 'forward', 'inverse'))
end

%--------------------------------------------------------------------------

function [phi,lambda] = rotateFwd(phi,lambda,phi0,lambda0,alpha)

% Most of the time, phi0 is zero, and alpha is zero almost all the time,
% so it's worth checking and avoiding unnecessary trig calls and
% rotations when possible. Note that the following implementation is
% much more efficient than actually constructing a 3-by-3 rotation
% matrix.

lambda = wrapToPi(lambda - lambda0);
rotateAboutY = (phi0 ~= 0);
rotateAboutX = (alpha ~= 0);
if rotateAboutX || rotateAboutY
    % Save the cosine of latitude
    cosphi = cos(phi);
    
    % Transform to 3-D Cartesian
    x = cosphi.*cos(lambda);
    y = cosphi.*sin(lambda);
    z = sin(phi);
    
    % Process each rotation separately, but make sure to rotate about
    % the Y-axis first.
    if rotateAboutY
        c = cos(phi0);
        s = sin(phi0);
        t = x;
        x =  c*t + s*z;
        z = -s*t + c*z;
    end
    
    if rotateAboutX
        c = cos(alpha);
        s = sin(alpha);
        t = y;
        y =  c*t + s*z;
        z = -s*t + c*z;
    end
    
    % Transform from 3-D Cartesian
    lambda = atan2(y,x);
    phi = atan2(z,hypot(x,y));
end

%--------------------------------------------------------------------------

function [phi,lambda] = rotateInv(phi,lambda,phi0,lambda0,alpha)

% Most of the time, phi0 is zero, and alpha is zero almost all the time, so
% it's worth checking and avoiding unnecessary trig calls and rotations
% when possible. Note that the following implementation is
% much more efficient than actually constructing a 3-by-3 rotation
% matrix.

% The operations below are the same as in the forward case, except for
% two things: (1) The order of the three rotations is reversed and (2)
% the sign of each rotation is reversed.
rotateAboutX = (alpha ~= 0);
rotateAboutY = (phi0 ~= 0);
if rotateAboutX || rotateAboutY
    cosphi = cos(phi);
    x = cosphi.*cos(lambda);
    y = cosphi.*sin(lambda);
    z = sin(phi);
    if rotateAboutX
        c = cos(-alpha);
        s = sin(-alpha);
        t = y;
        y =  c*t + s*z;
        z = -s*t + c*z;
    end
    if rotateAboutY
        c = cos(-phi0);
        s = sin(-phi0);
        t = x;
        x =  c*t + s*z;
        z = -s*t + c*z;
    end
    lambda = atan2(y,x);
    phi = atan2(z,hypot(x,y));
end
lambda = wrapToPi(lambda + lambda0);
