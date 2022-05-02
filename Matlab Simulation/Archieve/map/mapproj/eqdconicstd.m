function varargout = eqdconicstd(varargin)
%EQDCONICSTD  Equidistant Conic Projection -- Standard
%
%  EQDCONICSTD Implements the Equidistant Conic projection directly on a
%  reference ellipsoid, consistent with the industry-standard definition
%  of this projection.  See EQDCONIC for an alternative implementation
%  based on rotating the rectifying sphere. 
%
%  In this projection, scale is true along each meridian and the one or two
%  selected standard parallels.  Scale is constant along any parallel.
%  This projection is free of distortion along the two standard parallels.
%  Distortion is constant along any other parallel. This projection
%  provides a compromise in distortion between conformal and equal area
%  conic projections, of which it is neither.
%
%  In a rudimentary form, this projection dates back to Claudius Ptolemy,
%  about A.D. 100.  Improvements were developed by Johannes Ruysch in 1508,
%  Gerardus Mercator in the late 16th century, and Nicolas de l'Isle in
%  1745.  It is also known as the Simple Conic or Conic projection.  The
%  cone of projection has interesting limiting forms. If a pole is selected
%  as a single standard parallel, the cone is a plane, and an Equidistant
%  Azimuthal projection results.  If the Equator is so chosen, the cone
%  becomes a cylinder and a Plate Carree projection results.  If two
%  parallels equidistant from the Equator are chosen as the standard
%  parallels, an Equidistant Cylindrical projection results.

% Copyright 2006-2011 The MathWorks, Inc.

mproj.default = @eqdconicstdDefault;
mproj.forward = @eqdconicstdFwd;
mproj.inverse = @eqdconicstdInv;
mproj.auxiliaryLatitudeType = 'rectifying';
mproj.classCode = 'Cstd';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = eqdconicstdDefault(mstruct)

if length(mstruct.mapparallels) ~= 2
    % 1/6th and 5/6th of the northern hemisphere
    mstruct.mapparallels = fromDegrees(mstruct.angleunits, [15 75]);
end
mstruct.nparallels = 2;
[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-135 135]);
mstruct.fixedorient = [];

%--------------------------------------------------------------------------

function [x, y] = eqdconicstdFwd(mstruct, lat, lon)

[radius, a, n, G, rho0] = deriveParameters(mstruct);

theta = n*lon;
rho = a*G - radius*lat;
x = rho .* sin(theta);
y = rho0 - rho .* cos(theta);

%--------------------------------------------------------------------------

function [lat, lon] = eqdconicstdInv(mstruct, x, y)

[radius, a, n, G, rho0] = deriveParameters(mstruct);

rho = sign(n)*hypot(x, rho0 - y);
theta = atan2(sign(n)*x, sign(n)*(rho0-y));

lat = (a*G - rho)/radius;
lon = theta/n;

%--------------------------------------------------------------------------

function [radius, a, n, G, rho0] = deriveParameters(mstruct)

[a, e, radius] = ellipsoidpropsRectifying(mstruct);

parallels = toRadians(mstruct.angleunits, mstruct.mapparallels);

% Eliminate singularities in transformations with 0 parallel.
epsilon = epsm('radians');
indx = find(abs(parallels) <= epsilon);
if ~isempty(indx)
    parallels(indx) = epsilon;
end

% Compute projection parameters.
rectifies = convertlat([a e], parallels, 'geodetic', 'rectifying', 'nocheck');

den1 = (1 + e*sin(parallels(1))) * (1 - e*sin(parallels(1)));
m1   = cos(parallels(1)) / sqrt(den1);

if (length(parallels) == 1) || (abs(diff(parallels)) < epsilon)
    n = sin(parallels(1));
else
    if diff(abs(parallels)) < epsilon
         parallels(2) = parallels(2) - sign(parallels(2))*epsilon;
    end
    den2 = (1 + e*sin(parallels(2))) * (1 - e*sin(parallels(2)));
    m2 = cos(parallels(2)) / sqrt(den2);
    n = a * (m1 - m2) / (radius * (rectifies(2)-rectifies(1)) );
end

G = m1/n + radius*rectifies(1)/a;

% Replace the following line from eqdconic.m, which assumes that phi0 is
% zero,
%
%     rho0 = a*G;
%
% with:

phi0 = toRadians(mstruct.angleunits, mstruct.origin(1));
M0 = meridianarc(0, phi0, [a e]);
rho0 = a*G - M0;
