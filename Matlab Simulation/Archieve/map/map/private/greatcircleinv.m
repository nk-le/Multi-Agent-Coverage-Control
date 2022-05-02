function [rng, az] = greatcircleinv(phi1, lambda1, phi2, lambda2, r)
% Calculate great circle distance and azimuth between points on a
% sphere.  Use the Haversine Formula for distance.  PHI1, LAMBDA, PHI2,
% LAMBDA2 are in radians.  RNG is a length and has the same units as the
% radius of the sphere, R.  (If R is 1, then RNG is effectively arc
% length in radians.)  Azimuths are undefined at the poles, so we choose
% a convention: zero at the north pole and pi at the south pole.

% Copyright 2006 The MathWorks, Inc.

cosphi1 = cos(phi1);
cosphi2 = cos(phi2);

a = sin((phi2-phi1)/2).^2 ...
    + cosphi1 .* cosphi2 .* sin((lambda2-lambda1)/2).^2;
    
rng = 2 * r(1) * atan2(sqrt(a),sqrt(1 - a));

if nargout == 2
    az = atan2(cosphi2 .* sin(lambda2-lambda1),...
        cosphi1 .* sin(phi2) - sin(phi1) .* cosphi2 .* cos(lambda2-lambda1));
    az(phi1 <= -pi/2) = 0;
    az(phi2 >=  pi/2) = 0;
    az(phi2 <= -pi/2) = pi;
    az(phi1 >=  pi/2) = pi;
end
