function varargout = polycon(varargin)
%POLYCON  Polyconic Projection
%
%  For this projection, each parallel has a curvature identical to its
%  curvature on a cone tangent at that latitude.  Since each parallel would
%  have its own cone, this is a "polyconic" projection. Scale is true along
%  the central meridian and along each parallel. This projection is free of
%  distortion only along the central meridian; distortion can be severe at
%  extreme longitudes.  This projection is neither conformal nor equal
%  area.
%
%  This projection was apparently originated about 1820 by Ferdinand
%  Rudolph Hassler.  It is also known as the American Polyconic and the
%  Ordinary Polyconic projections.
%
%  See also POLYCONSTD.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @polyconDefault;
mproj.forward = @polyconFwd;
mproj.inverse = @polyconInv;
mproj.auxiliaryLatitudeType = 'rectifying';
mproj.classCode = 'Poly';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = polyconDefault(mstruct)

mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits, [-90 90], [-75 75]);

%--------------------------------------------------------------------------

function [x, y] = polyconFwd(mstruct, mu, lambda)

[a, e, epsilon, radius] = deriveParameters(mstruct);

% Back off of the +/- 180 degree points.  The inverse
% algorithm has trouble distinguishing points at -180 degrees
% when they are near the pole.

indx = find( abs(pi - abs(lambda)) <= epsilon);
if ~isempty(indx)
    lambda(indx) = lambda(indx) - sign(lambda(indx))*epsilon;
end

% Convert back to geodetic latitude -- both types are needed

phi = convertlat([a e], mu, 'rectifying', 'geodetic', 'nocheck');

% Back off of the +/- 90 degree points.  This allows
% the differentiation of longitudes at the poles of the transformed
% coordinate system.

indx = find(abs(pi/2 - abs(mu)) <= epsilon);
if ~isempty(indx)
    mu(indx)  = (pi/2 - epsilon) * sign(mu(indx));
    phi(indx) = (pi/2 - epsilon) * sign(phi(indx));
end

% Pick up NaN place holders

x = lambda;
y = mu;

% Eliminate singularities in transformations at 0 latitude.

indx1 = find(phi == 0);
indx2 = find(phi ~= 0);

% Points at zero latitude

if ~isempty(indx1)
    x(indx1) = a * lambda(indx1);
    y(indx1) = 0;
end

% Points at non-zero latitude

if ~isempty(indx2)
    N = a ./ sqrt(1 - (e*sin(phi(indx2))).^2);
    E = lambda(indx2) .* sin(phi(indx2));
    x(indx2) = N .* cot(phi(indx2)) .* sin(E);
    y(indx2) = radius*mu(indx2) + ...
        N .* cot(phi(indx2)) .* (1-cos(E));
end

%--------------------------------------------------------------------------

function [mu, lambda] = polyconInv(mstruct, x, y)

[a, e, epsilon] = deriveParameters(mstruct);

%  Eliminate singularities in transformations at 0 latitude.

indx = find(y == 0);
if ~isempty(indx)
    y(indx) = epsilon;
end

A = y / a;
B = (x / a).^2 + A.^2;
convergence = 1E-10;
maxsteps = 100;
steps = 1;
phiNew = A;
converged = 0;

while ~converged && (steps <= maxsteps)
    steps = steps + 1;
    phiOld = phiNew;

    C = sqrt(1 - (e*sin(phiOld)).^2) .* tan(phiOld);

    Ma = (1 - e^2/4 - 3*e^4/64 - 5*e^6/256) * phiOld - ...
        (3*e^2/8 + 3*e^4/32 + 45*e^6/1024) * sin(2*phiOld) + ...
        (15*e^4/256 + 45*e^6/1024) * sin(4*phiOld) - ...
        (35*e^6/3072) * sin(6*phiOld);

    Mp = (1 - e^2/4 - 3*e^4/64 - 5*e^6/256) - ...
        2 * (3*e^2/8 + 3*e^4/32 + 45*e^6/1024) * cos(2*phiOld) + ...
        4 * (15*e^4/256 + 45*e^6/1024) * cos(4*phiOld) - ...
        6 * (35*e^6/3072) * cos(6*phiOld);

    num = A.*(C.*Ma + 1) - Ma - 0.5*(Ma.^2 + B).*C;
    fact1 = (e^2)*sin(2*phiOld) .* (Ma.^2 + B - 2*A.*Ma) ./ (4*C);
    fact2 = (A-Ma) .* (C.*Mp - 2./sin(2*phiOld)) - Mp;
    deltaPhi = num ./ (fact1 + fact2);

    if max(abs(deltaPhi(:))) <= convergence
        converged = 1;
    else
        phiNew = phiOld - deltaPhi;
    end
end

lambda = asin(x.*C/a) ./ sin(phiNew);

phiNew(indx) = 0;       %  Correct for y = 0 points

% Convert to rectifying latitude for use in rotatem
mu = convertlat([a e], phiNew, 'geodetic', 'rectifying', 'nocheck');

%--------------------------------------------------------------------------

function [a, e, epsilon, radius] = deriveParameters(mstruct)

epsilon = 5*epsm('radians');
[a, e, radius] = ellipsoidpropsRectifying(mstruct);
