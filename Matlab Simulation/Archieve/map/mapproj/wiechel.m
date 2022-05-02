function varargout = wiechel(varargin)
%WIECHEL  Wiechel Equal Area Pseudoazimuthal Projection
%
%  This equal area projection is a novelty map, usually centered at
%  a pole, showing semicircular meridians in a pinwheel arrangement.
%  Scale is correct along the meridians.  This projection is not
%  conformal.
%
%  This projection was presented by H. Wiechel in 1879.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @wiechelDefault;
mproj.forward = @wiechelFwd;
mproj.inverse = @wiechelInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Pazi';

varargout = applyAzimuthalProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = wiechelDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits, [-Inf 65], [-180 180]);
mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = wiechelFwd(mstruct, rng, az)

a = ellipsoidprops(mstruct);
r = 2 * a * sin(rng/2);

x = r .* sin(az + rng/2);
y = r .* cos(az + rng/2);

%--------------------------------------------------------------------------

function [rng, az] = wiechelInv(mstruct, x, y)

a = ellipsoidprops(mstruct);

rng = 2 * asin(hypot(x,y) / (2*a));
az = atan2(x,y) - rng/2;
