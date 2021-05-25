function varargout = eqaconic(varargin)
%EQACONIC  Albers Equal Area Conic Projection
%
%  This is an equal area projection.  Scale is true along the one or two
%  selected standard parallels.  Scale is constant along any parallel; the
%  scale factor of a meridian at any given point is the reciprocal of that
%  along the parallel to preserve equal area.  This projection is free of
%  distortion along the standard parallels.  Distortion is constant along
%  any other parallel.  This projection is neither conformal nor
%  equidistant.
%
%  This projection was presented by Heinrich Christian Albers in 1805 and
%  it is also known as a Conical Orthomorphic projection.  The cone of
%  projection has interesting limiting forms.  If a pole is selected as a
%  single standard parallel, the cone is a plane, and a Lambert Equal Area
%  Conic projection is the result.  If the Equator is chosen as a single
%  parallel, the cone becomes a cylinder and a Lambert Cylindrical Equal
%  Area Projection is the result.  Finally, if two parallels equidistant
%  from the Equator are chosen as the standard parallels, a Behrmann or
%  other cylindrical equal area projection is the result.
%
%  See also EQACONICSTD.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @eqaconicDefault;
mproj.forward = @eqaconicFwd;
mproj.inverse = @eqaconicInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Coni';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = eqaconicDefault(mstruct)

if length(mstruct.mapparallels) ~= 2
    % 1/6th and 5/6th of the northern hemisphere
    mstruct.mapparallels = fromDegrees(mstruct.angleunits, [15 75]);
end
mstruct.nparallels = 2;
[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-135 135]);
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eqaconicFwd(mstruct, lat, lon)

[n, radius, C, qp, rho0] = deriveParameters(mstruct);

theta = n*lon;
rho = radius * sqrt(2*C/qp - 2*n*sin(lat)) / n;

x = rho .* sin(theta);
y = rho0 - rho .* cos(theta);

%--------------------------------------------------------------------------

function [lat, lon] = eqaconicInv(mstruct, x, y)

[n, radius, C, qp, rho0] = deriveParameters(mstruct);

rho = hypot(x, rho0 - y);
theta = atan2(sign(n)*x, sign(n)*(rho0-y));

lat  = asin( (2*C/qp - (n*rho/radius).^2) / (2*n));
lon = theta/n;

%--------------------------------------------------------------------------

function [n, radius, C, qp, rho0] = deriveParameters(mstruct)

% Compute several derived projection parameters from the defining
% parameters in the mstruct.

[a, e, radius] = ellipsoidpropsAuthalic(mstruct);
parallels = toRadians(mstruct.angleunits, mstruct.mapparallels);

%  Eliminate singularities in transformations at 0 and ? 90 parallel.

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

authalics = convertlat([a e], parallels, 'geodetic', 'authalic', 'nocheck');

if e == 0
    qp = 2;
else
    qp = 1 - (1-e^2)/(2*e) * log((1-e)/(1+e));
end

den1 = (1 + e*sin(parallels(1))) * (1 - e*sin(parallels(1)));
m1   = cos(parallels(1)) / sqrt(den1);


if (length(parallels) == 1) || (abs(diff(parallels)) < epsilon)
    n = sin(parallels(1));
else
    if diff(abs(parallels)) < epsilon
         parallels(2) = parallels(2) - sign(parallels(2))*epsilon;
    end
    den2 = (1 + e*sin(parallels(2))) * (1 - e*sin(parallels(2)));
    m2   = cos(parallels(2)) / sqrt(den2);
    n    = (m1^2 - m2^2) / (qp * (sin(authalics(2))-sin(authalics(1))) );
end

C    = m1^2 + qp*n*sin(authalics(1));
rho0 = radius * sqrt(C)/n;
