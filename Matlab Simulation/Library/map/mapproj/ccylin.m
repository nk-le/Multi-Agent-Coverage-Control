function varargout = ccylin(varargin)
%CCYLIN  Central Cylindrical Projection
%
%  This is a perspective projection from the center of the Earth onto a
%  cylinder tangent at the equator.  It is not equal area, equidistant, nor
%  conformal.  Scale is true along the Equator and constant between two
%  parallels equidistant from the Equator.  Scale becomes infinite at the
%  poles.  There is no distortion along the Equator, but it increases
%  rapidly away from the Equator.
%
%  The origin of the projection is unknown;  it has little use beyond the
%  educational aspects of its method of projection and as a comparison to
%  the Mercator projection which is not perspective.  The transverse aspect
%  of the Central Cylindrical is called the Wetch projection.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @ccylinDefault;
mproj.forward = @ccylinFwd;
mproj.inverse = @ccylinInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Cyln';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = ccylinDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-75 75], [-180 180]);
mstruct.mapparallels = 0;
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = ccylinFwd(mstruct, lat, lon)

a = ellipsoidprops(mstruct);

x = a * lon;
y = a * tan(lat);

%--------------------------------------------------------------------------

function [lat, lon] = ccylinInv(mstruct, x, y)

a = ellipsoidprops(mstruct);

lat  = atan(y / a);
lon = x / a;
