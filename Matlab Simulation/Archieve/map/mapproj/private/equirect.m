function varargout = equirect(varargin)
%EQUIRECT  Equirectangular Cylindrical Projection
%
%  Spherical version of eqdcylin, with its non-equatorial aspects
%  implemented via rigid-body rotations of the sphere.  This function is
%  private and is provided to support pcarree, giso, and cassini.

% Copyright 2013 The MathWorks, Inc.

mproj.default = @equirectDefault;
mproj.forward = @equirectFwd;
mproj.inverse = @equirectInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Cyln';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = equirectDefault(mstruct)

% Note default of 30 degrees for the latitude of the standard parallel.
[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-180 180], 30);
mstruct.nparallels   = 1;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = equirectFwd(mstruct, lat, lon)

[R, r1] = deriveParameters(mstruct);

x = r1 * lon;
y = R  * lat;

%--------------------------------------------------------------------------

function [lat, lon] = equirectInv(mstruct, x, y)

[R, r1] = deriveParameters(mstruct);

lat = y / R;
lon = x / r1;

%--------------------------------------------------------------------------

function [R, r1] = deriveParameters(mstruct)

[a, ~] = ellipsoidprops(mstruct);
R = a;
phi1 = toRadians(mstruct.angleunits, mstruct.mapparallels(1));
r1 = R * cos(phi1);
