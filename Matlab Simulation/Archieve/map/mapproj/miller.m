function varargout = miller(varargin)
%MILLER  Miller Cylindrical Projection
%
%  This is a projection with parallel spacing calculated to maintain a look
%  similar to the Mercator projection while reducing the distortion near
%  the poles, thus allowing the poles to be displayed.  It is not equal
%  area, equidistant, conformal or perspective.  Scale is true along the
%  Equator and constant between two parallels equidistant from the Equator.
%  There is no distortion near the Equator, and it increases moderately
%  away from the Equator, but becomes severe at the poles.
%
%  The Miller Cylindrical projection is derived from the Mercator
%  projection;  parallels are spaced from the Equator by calculating the
%  distance on the Mercator for a parallel at 80% of the true latitude and
%  dividing the result by 0.8.  The result is that the two projections are
%  almost identical near the Equator.
%
%  This projection was presented by Osborn Maitland Miller of the American
%  Geographical Society in 1942.  It is often used in place of the Mercator
%  projection for atlas maps of the world, for which it is somewhat more
%  appropriate.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @millerDefault;
mproj.forward = @millerFwd;
mproj.inverse = @millerInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Cyln';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = millerDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);
mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = millerFwd(mstruct, lat, lon)

a = ellipsoidprops(mstruct);

x = a * lon;
y = a * asinh(tan(0.8*lat)) / 0.8;

%--------------------------------------------------------------------------

function [lat, lon] = millerInv(mstruct, x, y)

a = ellipsoidprops(mstruct);

lat  = atan(sinh(0.8*y/a)) / 0.8;
lon = x / a;
