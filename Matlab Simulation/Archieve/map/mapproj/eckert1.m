function varargout = eckert1(varargin)

%ECKERT1  Eckert I Pseudocylindrical Projection
%
%  In this projection, scale is true along the 47 deg, 10 min parallels,
%  and is constant along any parallel, between any pair of parallels
%  equidistant from the Equator and along any given meridian.  It is not
%  free of distortion at any point, and the break at the Equator introduces
%  excessive distortion there; regardless of their appearance, Tissot
%  indicatrices are of indeterminate shape along the Equator. This novelty
%  projection is not equal area or conformal.
%
%  This projection was presented by Max Eckert in 1906.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @eckert1Default;
mproj.forward = @eckert1Fwd;
mproj.inverse = @eckert1Inv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = eckert1Default(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([47 10]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eckert1Fwd(mstruct, lat, lon)

a = ellipsoidprops(mstruct);

x = 2 * sqrt(2/(3*pi)) * a * lon .* (1 - abs(lat)/pi);
y = 2 * sqrt(2/(3*pi)) * a * lat;

%--------------------------------------------------------------------------

function [lat, lon] = eckert1Inv(mstruct, x, y)

a = ellipsoidprops(mstruct);

lat = sqrt(3*pi/2) * y / (2*a);
lon = sqrt(3*pi/2) * x ./ (2*a*(1 - abs(lat)/pi));
