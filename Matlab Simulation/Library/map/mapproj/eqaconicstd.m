function varargout = eqaconicstd(varargin)
%EQACONICSTD  Albers Equal Area Conic Projection -- Standard
%
%  EQACONICSTD Implements the Albers Equal Area Conic projection
%  directly on a reference ellipsoid, consistent with the
%  industry-standard definition of this projection.  See EQACONIC for
%  an alternative implementation based on rotating the authalic sphere. 
%
%  This is an equal area projection.  Scale is true along the one or
%  two selected standard parallels.  Scale is constant along any parallel;
%  the scale factor of a meridian at any given point is the reciprocal of
%  that along the parallel to preserve equal area.  This projection is
%  free of distortion along the standard parallels.  Distortion is
%  constant along any other parallel.  This projection is neither
%  conformal nor equidistant.
%
%  This projection was presented by Heinrich Christian Albers in 1805 and
%  it is also known as a Conical Orthomorphic projection.  The cone of
%  projection has interesting limiting forms.  If a pole is selected as
%  a single standard parallel, the cone is a plane, and a Lambert Equal
%  Area Conic projection is the result.  If the Equator is chosen as a
%  single parallel, the cone becomes a cylinder and a Lambert Cylindrical
%  Equal Area Projection is the result.  Finally, if two parallels
%  equidistant from the Equator are chosen as the standard parallels, a
%  Behrmann or other cylindrical equal area projection is the result.
%
%  See also EQACONIC.

% Copyright 2006-2011 The MathWorks, Inc.

mproj.default = @eqaconicstdDefault;
mproj.forward = @eqaconicstdFwd;
mproj.inverse = @eqaconicstdInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Cstd';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = eqaconicstdDefault(mstruct)

if length(mstruct.mapparallels) ~= 2
    % 1/6th and 5/6th of the northern hemisphere
    mstruct.mapparallels = fromDegrees(mstruct.angleunits, [15 75]);
end
mstruct.nparallels = 2;
[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-135 135]);
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eqaconicstdFwd(mstruct, beta, lambda)

[n, a, C, qp, rho0] = deriveParameters(mstruct);

theta = n * lambda;
q = qp * sin(beta);
rho   = a * sqrt(C - n * q) / n;

x = rho .* sin(theta);
y = rho0 - rho .* cos(theta);

%--------------------------------------------------------------------------

function [beta, lambda] = eqaconicstdInv(mstruct, x, y)

[n, a, C, qp, rho0] = deriveParameters(mstruct);

rho = hypot(x, rho0 - y);
q   = (C - (rho * n / a).^2) / n;
beta = asin(q/qp);
theta = atan2(sign(n)*x, sign(n)*(rho0-y));
lambda = theta/n;

%--------------------------------------------------------------------------

function [n, a, C, qp, rho0] = deriveParameters(mstruct)

% Compute several derived projection parameters from the defining
% parameters in the mstruct.

parallels = toRadians(mstruct.angleunits, mstruct.mapparallels);

%  Eliminate singularities in transformations at 0 and +/- 90 parallel.

epsilon = epsm('radians');
indx1 = find(abs(parallels) <= epsilon);
indx2 = find(abs(abs(parallels) - pi/2) <= epsilon);

if ~isempty(indx1)
    parallels(indx1) = epsilon;
end
if ~isempty(indx2)
      parallels(indx2) = sign(parallels(indx2))*(pi/2 - epsilon);
end

%  Compute projection parameters

[a, e] = ellipsoidprops(mstruct);
phi0 = toRadians(mstruct.angleunits, mstruct.origin(1));

beta = convertlat([a e], [phi0, parallels], 'geodetic', 'authalic', 'nocheck');
beta0 = beta(1);
authalics = beta(2:end);

if e == 0
    qp = 2;
else
    qp = 1 - (1-e^2)/(2*e) * log((1-e)/(1+e));
end

den1 = (1 + e*sin(parallels(1))) * (1 - e*sin(parallels(1)));
m1   = cos(parallels(1)) / sqrt(den1);
 
if numel(parallels) == 1 || abs(diff(parallels)) < epsilon
    n = sin(parallels(1));
else
    if diff(abs(parallels)) < epsilon
         parallels(2) = parallels(2) - sign(parallels(2))*epsilon;
    end
    den2 = (1 + e*sin(parallels(2))) * (1 - e*sin(parallels(2)));
    m2   = cos(parallels(2)) / sqrt(den2);
    n    = (m1^2 - m2^2) / (qp * (sin(authalics(2))-sin(authalics(1))) );
end

C = m1^2 + qp*n*sin(authalics(1));
q0 = qp * sin(beta0);
rho0 = a * sqrt(C - n * q0)/n;
