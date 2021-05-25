function varargout = kavrsky5(varargin)
%KAVRSKY5  Kavraisky V Pseudocylindrical Projection
%
%  This is an equal-area projection.  Scale is true along the fixed
%  standard parallels at 35 degrees and 0.9 true along the Equator.  This
%  projection is neither conformal nor equidistant.
%
%  This projection was described by V. V. Kavraisky in 1933.

% Copyright 1996-2007 The MathWorks, Inc.

mproj.default = @kavrsky5Default;
mproj.forward = @kavrsky5Fwd;
mproj.inverse = @kavrsky5Inv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = kavrsky5Default(mstruct)

mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);

%--------------------------------------------------------------------------

function [x, y] = kavrsky5Fwd(mstruct, lat, lon)

[m, n, radius] = deriveParameters(mstruct);

% Back off of the +/- 90 degree points.  This allows
% the differentiation of longitudes at the poles of the transformed
% coordinate system.
epsilon = epsm('radians');
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

% Projection transformation
x = radius * lon .* sec(n*lat) .* cos(lat) / (m*n);
y = radius * m * sin(n*lat);

%--------------------------------------------------------------------------

function [lat, lon] = kavrsky5Inv(mstruct, x, y)

[m, n, radius] = deriveParameters(mstruct);

lat =  asin(y / (m*radius)) / n;
lon = (m*n) * x ./ (radius * cos(lat) .* sec(n*lat) );

%--------------------------------------------------------------------------

function [m, n, radius] = deriveParameters(mstruct)

m = 1.504875;
n = 0.738341;
radius = rsphere('authalic',mstruct.geoid);
