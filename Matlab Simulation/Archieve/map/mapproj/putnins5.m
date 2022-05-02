function varargout = putnins5(varargin)
%PUTNINS5  Putnins P5 Pseudocylindrical Projection
%
%  For this projection, scale is true along the 21 deg, 14 min parallels,
%  and is constant along any parallel, between any pair of parallels
%  equidistant from the Equator, and along the central meridian.  It is not
%  free of distortion at any point. This projection is not equal area,
%  conformal or equidistant.
%
%  This projection was presented by Reinholds V. Putnins in 1934.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @putnins5Default;
mproj.forward = @putnins5Fwd;
mproj.inverse = @putnins5Inv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = putnins5Default(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([21 14]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = putnins5Fwd(mstruct, lat, lon)

a = ellipsoidprops(mstruct);

% Back off of the +/- 90 degree points.  This allows
% the differentiation of longitudes at the poles of the transformed
% coordinate system.
epsilon = epsm('radians');
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon)*sign(lat(indx));
end

% Projection transformation
factor1 = 1 + 12*lat.^2 / pi^2;
x = 1.01346 * a * lon .* (2 - sqrt(factor1));
y = 1.01346 * a * lat;

%--------------------------------------------------------------------------

function [lat, lon] = putnins5Inv(mstruct, x, y)

a = ellipsoidprops(mstruct);

lat = y / (1.01346 * a);
factor1 = 1 + 12*lat.^2 / pi^2;
lon = x ./ (1.01346 * a * (2 - sqrt(factor1)) );
