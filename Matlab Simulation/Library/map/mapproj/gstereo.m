function varargout = gstereo(varargin)
%GSTEREO  Gall Stereographic Cylindrical Projection
%
%  This is a perspective projection from a point on the Equator opposite a
%  given meridian onto a cylinder secant at the 45 degree parallels.  It is
%  not equal area, equidistant, or conformal. Scale is true along the
%  standard parallels and constant between two parallels equidistant from
%  the Equator.  There is no distortion along the standard parallels, but
%  it increases moderately away from these parallels, becoming severe at
%  the poles.
%
%  This projection was presented by James Gall in 1855.  It is also known
%  simply as the Gall projection.  It is special form of the Braun
%  Perspective Cylindrical projection secant at 45 deg N and S.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @gstereoDefault;
mproj.forward = @gstereoFwd;
mproj.inverse = @gstereoInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Cyln';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = gstereoDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
          = fromDegrees(mstruct.angleunits, [-90 90], [-180 180], 45);
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = gstereoFwd(mstruct, lat, lon)

a = ellipsoidprops(mstruct);

x = a * lon / sqrt(2);
y = a * ( 1 + sqrt(2)/2) * tan(lat/2);

%--------------------------------------------------------------------------

function [lat, lon] = gstereoInv(mstruct, x, y)

a = ellipsoidprops(mstruct);

lat  = 2 * atan(y / (a*(1+sqrt(2)/2)));
lon = sqrt(2) * x / a;
