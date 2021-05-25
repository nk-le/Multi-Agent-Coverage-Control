function [phi,lambda] = greatcirclefwd(phi0, lambda0, az, rng, r)
% On a sphere of radius A, compute points on a great circle at specified
% azimuths and ranges.  PHI, LAMBDA, PHI0, LAMBDA0, and AZ are angles in
% radians, and RNG is a distance having the same units as R.

% Copyright 2006 The MathWorks, Inc.

% Reference
% ---------
% J. P. Snyder, "Map Projections - A Working Manual,"  US Geological Survey
% Professional Paper 1395, US Government Printing Office, Washington, DC,
% 1987, pp. 29-32.

% Convert the range to an angle on the sphere (in radians).
rng = rng / r(1);

% Ensure correct azimuths at either pole.
epsilon = 10*epsm('radians');    % Set tolerance
az(phi0 >= pi/2-epsilon) = pi;    % starting at north pole
az(phi0 <= epsilon-pi/2) = 0;     % starting at south pole

% Calculate coordinates of great circle end point using spherical trig.
phi = asin( sin(phi0).*cos(rng) + cos(phi0).*sin(rng).*cos(az) );

lambda = lambda0 + atan2( sin(rng).*sin(az),...
                      cos(phi0).*cos(rng) - sin(phi0).*sin(rng).*cos(az) );
