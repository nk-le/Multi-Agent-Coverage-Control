function varargout = gnomonic(varargin)
%GNOMONIC  Gnomonic Azimuthal Projection
%
%  This is a perspective projection from the center of the globe on
%  a plane tangent at the center point, which is a pole in the common
%  polar aspect, but can be any point.  Less than one hemisphere
%  can be shown with this projection, regardless of its center
%  point.  The significant property of this projection is that all
%  great circles are straight lines.  This is useful in navigation,
%  as a great circle is the shortest path between two points on
%  the globe.  Only the center point enjoys true scale and zero
%  distortion.  This projection is neither conformal nor equal
%  area.
%
%  This projection may have been first developed by Thales around
%  580 B.C.  Its name is derived from the gnomon, the face of a
%  sundial, since the meridians radiate like hour markings.  This
%  projection is also known as a Gnomic or Central Projection.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @gnomonicDefault;
mproj.forward = @gnomonicFwd;
mproj.inverse = @gnomonicInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Azim';

varargout = applyAzimuthalProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = gnomonicDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits,[-Inf 65],[-180 180]);
mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = gnomonicFwd(mstruct, rng, az)

a = ellipsoidprops(mstruct);
r = a * tan(rng);

x = r .* sin(az);
y = r .* cos(az);

%--------------------------------------------------------------------------

function [rng, az] = gnomonicInv(mstruct, x, y)

a = ellipsoidprops(mstruct);

rng = atan(hypot(x,y) / a);
az = atan2(x,y);
