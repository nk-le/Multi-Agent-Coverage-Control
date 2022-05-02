function phi2 = meridianfwd(phi1, s, ellipsoid)
%MERIDIANFWD Reckon position along meridian
% 
%   PHI2 = MERIDIANFWD(PHI1,S,ELLIPSOID) determines the geodetic latitude
%   PHI2 reached by starting at geodetic latitude PHI1 and traveling
%   distance S north (positive S) or south (negative S) along an a meridian
%   on the specified ellipsoid.  ELLIPSOID is a reference ellipsoid (oblate
%   spheroid) object, a reference sphere object, or a vector of the form
%   [semimajor_axis, eccentricity].  PHI1 and PHI2 are in radians and S has
%   the same units as the semimajor axis of the ellipsoid.
%
%   See also MERIDIANARC.

% Copyright 2004-2011 The MathWorks, Inc.

% The following provides an equivalent (but less efficient) computation:
%
% phi2 = convertlat(ellipsoid,...
%          convertlat(ellipsoid, phi1, 'geodetic', 'rectifying', 'radians')...
%          + (s / rsphere('rectifying',ellipsoid)), 'rectifying', 'geodetic', 'radians');
     
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
mu2 = mu1 + (s/r);

t1 = (3/2 - (27/32) * n2) * n;
t2 = (21/16 -(55/32) * n2) * n2;
t3 = (151/96) * n * n2;
t4 = (1097/512) * n2 * n2;

phi2 = mu2 + t1*sin(2*mu2) + t2*sin(4*mu2) + t3*sin(6*mu2) + t4*sin(8*mu2);

% Guard against round off taking us past the pole
phi2(phi2 >  pi/2) =  pi/2;
phi2(phi2 < -pi/2) = -pi/2;
