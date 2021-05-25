function varargout = vperspec(varargin)
%VPERSPEC  Vertical Perspective Azimuthal Projection
%
%  This is a perspective projection on a plane tangent at the center point 
%  from a finite distance.  Scale is true only at the center point, and is 
%  constant in the circumferential direction along any circle having the 
%  center point as its center.  Distortion increases rapidly away from the 
%  center point, the only place which is distortion free.  This projection
%  is neither conformal nor equal area.
%  
%  This projection providing views of the globe resembling those seen from
%  a spacecraft in orbit.  The standard parallel can be interpreted
%  physically as the altitude of the observer above the surface in the same
%  length units as the reference ellipsoid.  The orthographic projection is
%  a limiting form with the observer at an infinite distance.
%  
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @vperspecDefault;
mproj.forward = @vperspecFwd;
mproj.inverse = @vperspecInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Azim';

% Special override:
%    "Reset the frame limits. (See also similar code in framem.)"
if nargin > 1
    mstruct = varargin{1};

    a = ellipsoidprops(mstruct);
    P = mstruct.mapparallels/a + 1;

    deg89 = 1.5533;   % 89 degrees in radians
    maxRange = ...
        min([acos(1/P) - 5*epsm('radians')  max(mstruct.trimlat) deg89]);

    mstruct.trimlat = [-inf maxRange];
    mstruct.flatlimit = fromRadians(mstruct.angleunits, mstruct.trimlat);

    varargin{1} = mstruct;
end

varargout = applyAzimuthalProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = vperspecDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-Inf 89], [-180 180]);
mstruct.mapparallels = 6; % radii
mstruct.nparallels   = 1;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = vperspecFwd(mstruct, rng, az)

a = ellipsoidprops(mstruct);
P = mstruct.mapparallels/a + 1;

% Compute angles of points away from the center of the projection
% as view from point a normalized distance P from the center of 
% the sphere.
kp = (P - 1)./(P - cos(rng));
r = a * kp .* sin(rng);
	 
x = r .* sin(az);
y = r .* cos(az);

%--------------------------------------------------------------------------

function [rng, az] = vperspecInv(mstruct, x, y)

a = ellipsoidprops(mstruct);
P = mstruct.mapparallels/a + 1;

rho = hypot(x,y);
rho(rho == 0) = NaN;

c = asin((P - sqrt(1 - rho.^2*(P+1)/(a^2*(P-1)))) ./ ...
    (a*(P-1)./rho + rho/(a*(P-1))) );

c(isnan(rho)) = 0;

kp = (P - 1)./(P - cos(c));

x = x ./ kp;
y = y ./ kp;

%  Compute range and azimuth

rng = asin(hypot(x,y) / a);
az  = atan2(x,y);
