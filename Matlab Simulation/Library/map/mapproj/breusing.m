function varargout = breusing(varargin)
%BREUSING  Breusing Harmonic Mean Azimuthal Projection
%
%  This is a harmonic mean between a Stereographic and Lambert Equal-Area
%  Azimuthal projection.  It is not equal-area, equidistant, or conformal.
%  There is no point at which scale is accurate in all directions.  The
%  primary feature of this projection is that it is minimum error -
%  distortion is moderate throughout.
%
%  F. A. Arthur Breusing developed a geometric mean version of this
%  projection in 1892.  A. E. Young modified this to the harmonic mean
%  version presented here in 1920.  This projection is virtually
%  indistinguishable from the Airy Minimum Error Azimuthal Projection,
%  presented by George Airy in 1861.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @breusingDefault;
mproj.forward = @breusingFwd;
mproj.inverse = @breusingInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Azim';

varargout = applyAzimuthalProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = breusingDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-Inf 89], [-180 180]);

mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = breusingFwd(mstruct, rng, az)

a = ellipsoidprops(mstruct);
r = 4 * a * tan(rng/4);

x = r .* sin(az);
y = r .* cos(az);

%--------------------------------------------------------------------------

function [rng, az] = breusingInv(mstruct, x, y)

a = ellipsoidprops(mstruct);

rng = 4 * atan(hypot(x,y) / (4*a));
az = atan2(x,y);
