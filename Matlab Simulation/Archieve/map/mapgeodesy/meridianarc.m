function s = meridianarc(phi1, phi2, ellipsoid)
%MERIDIANARC Ellipsoidal distance along meridian
%
%   S = MERIDIANARC(PHI1, PHI2, ELLIPSOID) calculates the (signed) distance
%   S between latitudes PHI1 and PHI2 along a meridian on the specified
%   ellipsoid. ELLIPSOID is a reference ellipsoid (oblate spheroid) object,
%   a reference sphere object, or a vector of the form [semimajor_axis,
%   eccentricity].  PHI1 and PHI2 are in radians. S has the same units as
%   the semimajor axis of the ellipsoid.  S is negative if phi2 is less
%   than phi1.
%
%   See also MERIDIANFWD.

% Copyright 2004-2011 The MathWorks, Inc.

% The following provides an equivalent (but less efficient) computation:
%
% s = rsphere('rectifying',ellipsoid)...
%        * (convertlat(ellipsoid,phi2,'geodetic','rectifying','radians')...
%         - convertlat(ellipsoid,phi1,'geodetic','rectifying','radians'));

if isobject(ellipsoid)
    a = ellipsoid.SemimajorAxis;
    n = ellipsoid.ThirdFlattening;
else
    a = ellipsoid(1);
    n = ecc2n(ellipsoid(2));
end

n2 = n^2;

% Radius of rectifying sphere
r = a * (1 - n) * (1 - n2) * (1 + ((9/4) + (225/64)*n2)*n2);

f1 = (3/2 - (9/16) * n2) * n;
f2 = (15/16 - (15/32) * n2) * n2;
f3 = (35/48) * n * n2;
f4 = (315/512) * n2 * n2;

% Rectifying latitudes
mu1 = phi1 - f1*sin(2*phi1) + f2*sin(4*phi1) - f3*sin(6*phi1) + f4*sin(8*phi1);
mu2 = phi2 - f1*sin(2*phi2) + f2*sin(4*phi2) - f3*sin(6*phi2) + f4*sin(8*phi2);

s = r * (mu2 - mu1);
