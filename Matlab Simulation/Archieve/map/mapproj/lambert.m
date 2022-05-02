function varargout = lambert(varargin)
%LAMBERT  Lambert Conformal Conic Projection
%
%  For this projection, scale is true along the one or two selected
%  standard parallels.  Scale is constant along any parallel, and is the
%  same in every direction at any point.  This projection is free of
%  distortion along the standard parallels.  Distortion is constant along
%  any other parallel.  This projection is conformal everywhere but the
%  poles;  it is neither equal area nor equidistant.
%
%  This projection was presented by Johann Heinrich Lambert in 1772, and it
%  is also known as the Conical Orthomorphic projection.  The cone of
%  projection has interesting limiting forms.  If a pole is selected as a
%  single standard parallel, the cone is a plane and a Stereographic
%  Azimuthal projection results.  If the Equator or two parallels
%  equidistant from the Equator are chosen as the standard parallels, the
%  cone becomes a cylinder, and a Mercator projection results.
%
%  See also LAMBERTSTD.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @lambertDefault;
mproj.forward = @lambertFwd;
mproj.inverse = @lambertInv;
mproj.auxiliaryLatitudeType = 'conformal';
mproj.classCode = 'Coni';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = lambertDefault(mstruct)

if length(mstruct.mapparallels) ~= 2
    % 1/6th and 5/6th of the northern hemisphere
    mstruct.mapparallels = fromDegrees(mstruct.angleunits, [15 75]);
end
mstruct.nparallels = 2;
[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-135 135]);
if isempty(mstruct.flatlimit)
    mstruct.flatlimit = fromDegrees(mstruct.angleunits, [0 90]);
end
if isempty(mstruct.mlabelparallel)
    if diff(mstruct.flatlimit) > 0
        mstruct.mlabelparallel = mstruct.flatlimit(1);
    else
        mstruct.mlabelparallel = mstruct.flatlimit(2);
    end
end
mstruct.fixedorient = [];

%--------------------------------------------------------------------------

function [x, y] = lambertFwd(mstruct, lat, lon)

[a, F, n, rho0, epsilon] = deriveParameters(mstruct);

%  Back off of the +/- 90 degree points.  This allows
%  the differentiation of longitudes at the poles of the transformed
%  coordinate system.
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

%  Projection transformation
theta = n*lon;
rho = a*F ./ (tan(lat/2 + pi/4)).^n;
x = rho .* sin(theta);
y = rho0 - rho .* cos(theta);

%--------------------------------------------------------------------------

function [lat, lon] = lambertInv(mstruct, x, y)

[a, F, n, rho0] = deriveParameters(mstruct);

rho = sign(n)*hypot(x, rho0 - y);
theta = atan2(sign(n)*x, sign(n)*(rho0-y));
lat = 2*atan((a*F./rho).^(1/n)) - pi/2;
lon = theta/n;

%--------------------------------------------------------------------------

function [a, F, n, rho0, epsilon] = deriveParameters(mstruct)

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

[a, e] = ellipsoidprops(mstruct);
conformals = convertlat([a e], parallels, 'geodetic', 'conformal', 'nocheck');

den1 = (1 + e*sin(parallels(1))) * (1 - e*sin(parallels(1)));
m1 = cos(parallels(1)) / sqrt(den1);

if (length(parallels) == 1) || (abs(diff(parallels)) < epsilon)
    n = sin(parallels(1));
else
    if diff(abs(parallels)) < epsilon
        parallels(2) = parallels(2) - sign(parallels(2))*epsilon;
    end
    den2 = (1 + e*sin(parallels(2))) * (1 - e*sin(parallels(2)));
    m2 = cos(parallels(2)) / sqrt(den2);
    fact1 = tan(conformals(1)/2 + pi/4);
    fact2 = tan(conformals(2)/2 + pi/4);
    n = log(m1/m2) / log(fact2/fact1);
end

F = (m1/n) * (tan(conformals(1)/2 + pi/4))^n;
rho0 = a*F / (tan(pi/4))^n;
