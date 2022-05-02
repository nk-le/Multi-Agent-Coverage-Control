function varargout = ortho(varargin)
%ORTHO  Orthographic Azimuthal Projection
%
%  This is a perspective projection on a plane tangent at the center
%  point from an infinite distance (that is, orthogonally).  The center
%  point is a pole in the common polar aspect, but can be any point.
%  This projection has two significant properties.  It looks like a
%  globe, providing views of the Earth resembling those seen from outer
%  space.  Additionally, all great and small circles are either straight
%  lines or elliptical arcs on this projection.  Scale is true only
%  at the center point, and is constant in the circumferential direction
%  along any circle having the center point as its center.  Distortion
%  increases rapidly away from the center point, the only place which
%  is distortion free.  This projection is neither conformal nor
%  equal area.
%
%  This projection appears to have been developed by the Egyptians and
%  Greeks by the second century B.C.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @orthoDefault;
mproj.forward = @orthoFwd;
mproj.inverse = @orthoInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Azim';

varargout = applyAzimuthalProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = orthoDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits, [-Inf 89], [-180 180]);
mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = orthoFwd(mstruct, rng, az)

a = ellipsoidprops(mstruct);
r = a * sin(rng);

x = r .* sin(az);
y = r .* cos(az);

%--------------------------------------------------------------------------

function [rng, az] = orthoInv(mstruct, x, y)

a = ellipsoidprops(mstruct);

rng = asin(hypot(x,y) / a);
az = atan2(x,y);
