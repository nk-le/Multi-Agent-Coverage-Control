function [x, y, z] = ecef2lv(x, y, z, phi0, lambda0, h0, ellipsoid)
%ECEF2LV Convert geocentric (ECEF) to local vertical coordinates
%
%   ECEF2LV will be removed in a future release.  Use ECEF2ENU instead.
%   In ECEF2ENU, the latitude and longitude of the local origin are in
%   degrees by default, so the optional angleUnit input should be included,
%   with the value 'radians'.
%
%   [XL, YL, ZL] = ECEF2LV(X, Y, Z, PHI0, LAMBDA0, H0, ELLIPSOID) converts
%   geocentric point locations specified by the coordinate arrays X, Y, and
%   Z to the local vertical coordinate system with its origin at geodetic
%   latitude PHI0, longitude LAMBDA0, and ellipsoidal height H0.  X, Y, and
%   Z may be arrays of any shape, as long as they all match in size. PHI0,
%   LAMBDA0, and H0 must be scalars.  ELLIPSOID is an object with
%   SemimajorAxis and Eccentricity properties, or a row vector of the form
%   [semimajor_axis, eccentricity].  X, Y, Z, and H0 must have the same
%   length units as the semimajor axis.  PHI0 and LAMBDA0 must be in
%   radians. The output coordinate arrays, XL, YL, and ZL are the local
%   vertical coordinates of the input points.  They have the same size as
%   X, Y, and Z and have the same length units as the semimajor axis.
%
%   In the local vertical Cartesian system defined by PHI0, LAMBD0, H0, and
%   ELLIPSOID, the XL axis is parallel to the plane tangent to the
%   ellipsoid at (PHI0, LAMBDA0) and points due east.  The YL axis is
%   parallel to the same plane and points due north.  The ZL axis is normal
%   to the ellipsoid at (PHI0, LAMBDA0) and points outward into space. The
%   local vertical system is sometimes referred to as east-north-up or ENU.
%
%   For a definition of the geocentric system, also known as
%   Earth-Centered, Earth-Fixed (ECEF), see the help for GEODETIC2ECEF.
%
% See also ECEF2ENU

% Copyright 2004-2015 The MathWorks, Inc.

% Reference
% ---------
% Paul R. Wolf and Bon A. Dewitt, "Elements of Photogrammetry with
% Applications in GIS," 3rd Ed., McGraw-Hill, 2000 (Appendix F-4).

% Transform the origin of the local vertical system from geodetic to ECEF.
if isnumeric(ellipsoid)
    validateattributes(ellipsoid, {'double'}, ...
        {'real', 'finite', 'nonnegative', 'size', [1 2]}, '', 'ELLIPSOID', 4)
    a  = ellipsoid(1);
    e2 = ellipsoid(2)^2;
    f = e2 / (1 + sqrt(1 - e2));
else
    a = ellipsoid.SemimajorAxis;
    f = ellipsoid.Flattening;
end
inDegrees = false;
[rho0, z0] = map.geodesy.internal.geodetic2cylindrical(phi0, h0, a, f, inDegrees);
[x0, y0] = pol2cart(lambda0,rho0);

% Construct the matrix that rotates Cartesian vectors from geocentric to
% local vertical.
M = ecef2lvRotationMatrix(phi0, lambda0);

% Construct a work array, p, to hold the offset vectors from the local
% vertical origin to the point locations defined by x, y, z.  Each column
% of p is a 3-vector oriented relative to the geocentric system.
n = numel(x);
P = zeros(3,n);
P(1,:) = reshape(x - x0, [1 n]);
P(2,:) = reshape(y - y0, [1 n]);
P(3,:) = reshape(z - z0, [1 n]);

% Rotate each column of P into the local vertical system, overwriting P
% itself to save storage.
P = M * P;

% Each column of P now contains a Cartesian coordinate 3-vector for a point
% in the local vertical system.  Extract and reshape a coordinate array for
% each axis, overwriting x, y, and z to save storage.
inputSize = size(x);
x = reshape(P(1,:),inputSize);
y = reshape(P(2,:),inputSize);
z = reshape(P(3,:),inputSize);
