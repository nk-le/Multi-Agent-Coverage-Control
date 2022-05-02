function varargout = eckert2(varargin)
%ECKERT2  Eckert II Pseudocylindrical Projection
%
%  This is an equal area projection.  Scale is true along the 55 deg, 10
%  min parallels, and is constant along any parallel and between any pair
%  of parallels equidistant from the Equator.  It is not free of distortion
%  at any point except at 55 deg, 10 min N and S along the central
%  meridian.  The break at the Equator introduces excessive distortion
%  there;  regardless of their appearance, Tissot indicatrices are of
%  indeterminate shape along the Equator.  This novelty projection is not
%  conformal or equidistant.
%
%  This projection was presented by Max Eckert in 1906.

% Copyright 1996-2006 The MathWorks, Inc.

mproj.default = @eckert2Default;
mproj.forward = @eckert2Fwd;
mproj.inverse = @eckert2Inv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = eckert2Default(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([55 10]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eckert2Fwd(mstruct, lat, lon)

radius = rsphere('authalic',mstruct.geoid);

x = 2 * radius * lon .* sqrt(4 - 3*sin(abs(lat)))/sqrt(6*pi);
y = sqrt(2*pi/3) * radius * (2 - sqrt(4 - 3*sin(abs(lat))) ).*sign(lat);

%--------------------------------------------------------------------------

function [lat, lon] = eckert2Inv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

factor1 = (2 - sqrt(3/(2*pi)) * abs(y) / radius).^2;

lat = asin((4 - factor1)/3) .* sign(y);
lon = sqrt(6*pi) * x ./ (2*radius*sqrt(4 - 3*sin(abs(lat))) );
