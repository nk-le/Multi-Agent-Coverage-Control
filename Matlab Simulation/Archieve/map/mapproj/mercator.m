function varargout = mercator(varargin)
%MERCATOR  Mercator Cylindrical Projection
%
%  This is a projection with parallel spacing calculated to maintain
%  conformality.  It is not equal area, equidistant, or perspective. Scale
%  is true along the standard parallels and constant between two parallels
%  equidistant from the Equator.  It is also constant in all directions
%  near any given point.  Scale becomes infinite at the poles.  The
%  appearance of the Mercator projection is unaffected by the selection of
%  the standard parallels;  they serve only to define the latitude of true
%  scale.
%
%  The Mercator, which may be the most famous of all projections, has the
%  special feature that all rhumb lines, or loxodromes (lines that make
%  equal angles with all meridians, i.e. lines of constant heading) are
%  straight lines.  This makes it an excellent projection for navigational
%  purposes.
%
%  The transverse and oblique aspects of the projection are often used for
%  topographic mapping and atlas maps.  Its normal aspect is often used for
%  maps of the entire world, for which it is really quite inappropriate.
%
%  The Mercator projection is named for Geradus Mercator, who presented it
%  "for navigation" in 1569.  It is now known to have been used for the
%  Tunhuang star chart as early as 940 by Ch'ien Lo-Chih.  It was first
%  used in Europe by Erhard Etzlaub in 1511.  It is also, but rarely,
%  called the Wright projection, after Edward Wright, who developed the
%  mathematics behind the projection in 1599.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @mercatorDefault;
mproj.forward = @mercatorFwd;
mproj.inverse = @mercatorInv;
mproj.auxiliaryLatitudeType = 'conformal';
mproj.classCode = 'Cyln';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = mercatorDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-86 86], [-180 180]);
mstruct.mapparallels = 0;
mstruct.nparallels   = 1;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = mercatorFwd(mstruct, chi, lambda)

% CHI is conformal latitude in radians, LAMBDA is longitude in radians.

[a, chi1] = deriveParameters(mstruct);

x = a * lambda * cos(chi1);
y = a * sign(chi) .* log(tan(pi/4 + abs(chi)/2)) * cos(chi1);

%--------------------------------------------------------------------------

function [chi, lambda] = mercatorInv(mstruct, x, y)

[a, chi1] = deriveParameters(mstruct);

lambda = x / (a * cos(chi1));
chi  = pi/2 - 2 * atan(exp(-y / (a * cos(chi1))));

%--------------------------------------------------------------------------

function [a, chi1] = deriveParameters(mstruct)

[a, e] = ellipsoidprops(mstruct);

% Convert standard parallel to conformal latitude in radians.
phi1 = toRadians(mstruct.angleunits, mstruct.mapparallels(1));
chi1 = convertlat([a e], phi1, 'geodetic', 'conformal', 'nocheck');
