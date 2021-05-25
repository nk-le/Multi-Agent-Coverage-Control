function varargout = eqacylin(varargin)
%EQACYLIN  Equal Area Cylindrical Projection
%
%  This is an orthographic projection onto a cylinder secant at the
%  standard parallels.  It is equal area, but distortion of shape increases
%  with distance from the standard parallels.  Scale is true along the
%  standard parallels and constant between two parallels equidistant from
%  the Equator.  This projection is not equidistant.
%
%  This projection was proposed by Johann Heinrich Lambert (1772), a
%  prolific cartographer who proposed seven different important
%  projections.  The form of the projection tangent at the Equator is often
%  called the Lambert Equal Area Cylindrical projection.  That and other
%  special forms of this projection are included separately in the toolbox,
%  including the Gall Orthographic, the Behrmann Cylindrical, the
%  Balthasart Cylindrical, and the Trystan Edwards Cylindrical projections.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @eqacylinDefault;
mproj.forward = @eqacylinFwd;
mproj.inverse = @eqacylinInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Cyln';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = eqacylinDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-180 180], 0);
mstruct.nparallels   = 1;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eqacylinFwd(mstruct, lat, lon)

[a, k0, qp] = deriveParameters(mstruct);

x = a * k0 * lon;
y = a * qp * sin(lat) / (2*k0);

%--------------------------------------------------------------------------

function [lat, lon] = eqacylinInv(mstruct, x, y)

[a, k0, qp] = deriveParameters(mstruct);

lat = asin(2*k0*y / (a*qp));
lon = x / (a*k0);

%--------------------------------------------------------------------------

function [a, k0, qp] = deriveParameters(mstruct)

% Compute several derived projection parameters from the defining
% parameters in the mstruct.

phiS = toRadians(mstruct.angleunits, mstruct.mapparallels(1));

[a, e] = ellipsoidprops(mstruct);
if e == 0
    qp = 2;
else
    qp = 1 - (1-e^2)/(2*e) * log((1-e)/(1+e));
end

k0 = cos(phiS) / sqrt((1 + e*sin(phiS)) * (1 - e*sin(phiS)));
