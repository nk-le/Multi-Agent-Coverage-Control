function varargout = modsine(varargin)
%MODSINE  Tissot Modified Sinusoidal Pseudocylindrical Projection
%
%  This is an equal-area projection.  Scale is constant along any parallel
%  or any pair of equidistant parallels, and along the central meridian.
%  It is not equidistant or conformal.
%
%  This projection was first described by N. A. Tissot in 1881.
%
%  This projection is available only on the sphere.

% Copyright 1996-2007 The MathWorks, Inc.

mproj.default = @modsineDefault;
mproj.forward = @modsineFwd;
mproj.inverse = @modsineInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = modsineDefault(mstruct)

mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);

%--------------------------------------------------------------------------

function [x, y] = modsineFwd(mstruct, lat, lon)

[radius, m, n] = deriveParameters(mstruct);

% Back off of the +/- 90 degree points.  This allows
% the differentiation of longitudes at the poles of the transformed
% coordinate system.
epsilon = epsm('radians');
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

% Projection transformation
x = n * radius * lon .* cos(lat);
y = m * radius * lat;

%--------------------------------------------------------------------------

function [lat, lon] = modsineInv(mstruct, x, y)

[radius, m, n] = deriveParameters(mstruct);

lat = y / (m*radius);
lon = x ./ (n*radius * cos(lat));

%--------------------------------------------------------------------------

function [radius, m, n] = deriveParameters(mstruct)

radius = rsphere('authalic',mstruct.geoid);
m = 0.875;
n = 1.25;
