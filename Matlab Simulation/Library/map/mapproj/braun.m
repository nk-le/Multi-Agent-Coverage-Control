function varargout = braun(varargin)
%BRAUN  Braun Perspective Cylindrical Projection
%
%  This is a perspective projection from a point on the Equator opposite a
%  given meridian onto a cylinder secant at standard parallels.  It is not
%  equal area, equidistant, or conformal. Scale is true along the standard
%  parallels and constant between two parallels equidistant from the
%  Equator.  There is no distortion along the standard parallels, but it
%  increases moderately away from these parallels, becoming severe at the
%  poles.
%
%  This projection was first described by Braun in 1867.  It is less well
%  known than the specific forms of it called the Gall Stereographic and
%  the Bolshoi Sovietskii Atlas Mira projections.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @braunDefault;
mproj.forward = @braunFwd;
mproj.inverse = @braunInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Cyln';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = braunDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);
mstruct.mapparallels = 0;
mstruct.nparallels   = 1;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = braunFwd(mstruct, lat, lon)

% Radius of sphere
a = ellipsoidprops(mstruct);

% Radius of secant cylinder
phi1 = toRadians(mstruct.angleunits, mstruct.mapparallels(1));
r = a * cos(phi1);

x = r * lon;
y = (a + r) * tan(lat/2);

%--------------------------------------------------------------------------

function [lat, lon] = braunInv(mstruct, x, y)

% Radius of sphere
a = ellipsoidprops(mstruct);

% Radius of secant cylinder
phi1 = toRadians(mstruct.angleunits, mstruct.mapparallels(1));
r = a * cos(phi1);

lat = 2 * atan(y / (a + r));
lon = x / r;
