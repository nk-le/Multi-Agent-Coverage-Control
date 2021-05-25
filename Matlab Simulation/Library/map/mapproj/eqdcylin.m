function varargout = eqdcylin(varargin)
%EQDCYLIN  Equidistant Cylindrical Projection
%
%  This is a projection onto a cylinder secant at the standard parallels.
%  Distortion of both shape and area increase with distance from the
%  standard parallels.  Scale is true along all meridians (i.e. it is
%  equidistant) and the standard parallels, and is constant along any
%  parallel and along the parallel of opposite sign.
%
%  By default, the standard parallels are at +/- 30 degrees in geodetic
%  latitude.
%
%  When projecting a sphere, the origin vector is used to specify a
%  triaxial rigid-body rotation.
%
%  When projecting an ellipsoid:
%
%    * The origin longitude (2nd element of the origin vector) determines
%      which meridian maps to the line x == false easting.
%
%    * The origin latitude (1st element of the origin vector) is used to
%      shift the natural origin off the equator via a constant y-offset,
%      in addition to any false northing that may be specified.
%
%    * The grid convergence is fixed at 0, even if the 3rd element of the
%      origin vector is nonzero.
%
%  This projection was first used by Marinus of Tyre, about A.D. 100.
%  Special forms of this projection are the Plate Carree, with a standard
%  parallel at 0 deg, and the Gall Isographic, with standard parallels at
%  45 deg N and S.  Other names for this projection include
%  Equirectangular, Rectangular, Projection of Marinus, La Carte
%  Parallelogrammatique, and Die Rechteckige Plattkarte.

% Copyright 1996-2013 The MathWorks, Inc.

mstruct = varargin{1};
[~, e] = ellipsoidprops(mstruct);
if e == 0
    % Spherical case
    varargout = cell(1,max(nargout,1));
    [varargout{:}] = equirect(varargin{:});
else
    % Ellipsoidal case
    mproj.default = @eqdcylinDefault;
    mproj.forward = @eqdcylinFwd;
    mproj.inverse = @eqdcylinInv;
    mproj.auxiliaryLatitudeType = 'rectifying';
    mproj.classCode = 'Cstd';
    
    varargout = applyProjection(mproj, varargin{:});
end

%--------------------------------------------------------------------------

function mstruct = eqdcylinDefault(mstruct)

% Note default of 30 degrees for the latitude of the standard parallel.
[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-180 180], 30);
mstruct.nparallels   = 1;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eqdcylinFwd(mstruct, mu, lambda)
% mu is rectifying latitude in radians.
% lambda is difference in longitude from the origin, in radians.

[mu1, rectifyingRadius, r1] = deriveParameters(mstruct);

x = r1 * lambda;
y = rectifyingRadius * (mu - mu1);

%--------------------------------------------------------------------------

function [mu, lambda] = eqdcylinInv(mstruct, x, y)
% mu is rectifying latitude in radians.
% lambda is difference in longitude from the origin, in radians.

[mu1, rectifyingRadius, r1] = deriveParameters(mstruct);

mu = y/rectifyingRadius + mu1;
lambda = x / r1;

%--------------------------------------------------------------------------

function [mu1, rectifyingRadius, r1] = deriveParameters(mstruct)

[a, e] = ellipsoidprops(mstruct);

% Latitudes of standard parallel
phi1 = toRadians(mstruct.angleunits, mstruct.mapparallels(1));
mu1 = convertlat([a e], phi1, 'geodetic', 'rectifying', 'nocheck');

% Convert eccentricity e to n2, the square of the third flattening.
e2 = e*e;
n = e2 ./ (1 + sqrt(1 - e2)).^2;
n2 = n*n;

% Radius of rectifying sphere (copied from meridianarc.m).
rectifyingRadius = a * (1 - n) * (1 - n2) * (1 + ((9/4) + (225/64)*n2)*n2);

% Radius of curvature in the prime vertical, aka transverse radius of
% curvature (copied from rcurve.m), at the latitude of the standard
% parallel.
N1 = a ./ sqrt(1 - (e * sin(phi1)).^2);

% Radius of the standard parallel.
r1 = N1 * cos(phi1);
