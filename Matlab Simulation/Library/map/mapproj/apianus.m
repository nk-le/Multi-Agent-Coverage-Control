function varargout = apianus(varargin)
%APIANUS  Apianus II Pseudocylindrical Projection
%
%  Scale is constant along any parallel or pair of parallels equidistant
%  from the Equator, as well as along the Central Meridian.  The Equator is
%  free of angular distortion.  This projection is not equal-area,
%  equidistant or conformal.
%
%  This projection was first described in 1524 by Peter Apian (or Bienewitz).
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @apianusDefault;
mproj.forward = @apianusFwd;
mproj.inverse = @apianusInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = apianusDefault(mstruct)

mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);

%--------------------------------------------------------------------------

function [x, y] = apianusFwd(mstruct, lat, lon)

%  Back off of the +/- 90 degree points.  This allows
%  the differentiation of longitudes at the poles of the transformed
%  coordinate system.
epsilon = epsm('radians');
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

a = ellipsoidprops(mstruct);
psi = asin(2*lat/pi);

x = a * lon .* cos(psi);
y = a * (pi/2) * sin(psi);

%--------------------------------------------------------------------------

function [lat, lon] = apianusInv(mstruct, x, y)

a = ellipsoidprops(mstruct);
psi  = asin(2*y / (pi * a));

lon = x ./ (a * cos(psi));
lat = pi * sin(psi)/2;
