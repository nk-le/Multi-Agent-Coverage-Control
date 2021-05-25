function varargout = loximuth(varargin)
%LOXIMUTH  Loximuthal Pseudocylindrical Projection
%
%  This projection has the special property that from the central point
%  (the intersection of the central latitude with the central meridian, or
%  map origin), rhumb lines (or loxodromes) are shown as straight, true to
%  scale, and correct in azimuth from the center.  This differs from the
%  Mercator projection, in that rhumb lines are here shown in true scale,
%  and that unlike the Mercator projection, this projection does not
%  maintain true azimuth for all points along rhumb lines.  Scale is true
%  along the central meridian, and is constant along any parallel, but not,
%  generally, between parallels.  It is free of distortion only at the
%  central point, and can be severely distorted in places.  However, this
%  projection is designed for its special property, in which distortion is
%  not a concern.
%
%  This projection was presented by Karl Siemon in 1935, and independently
%  by Waldo R. Tobler in 1966.  The Bordone Oval projection of 1520 was
%  very similar to the Equator-centered Loximuthal.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @loximuthDefault;
mproj.forward = @loximuthFwd;
mproj.inverse = @loximuthInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = loximuthDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);
mstruct.mapparallels = 0;
mstruct.nparallels   = 1;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = loximuthFwd(mstruct, lat, lon)

[a, phi1, epsilon] = deriveParameters(mstruct);

% Back off of the +/- 90 degree points.  This allows
% the differentiation of longitudes at the poles of the transformed
% coordinate system.
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

% Back off the lat == phi1 points.  This allows the straightforward
% application of the transformation equations below.
indx = find(abs(phi1 - lat) <= epsilon);
if ~isempty(indx)
    lat(indx) = phi1 + epsilon;
end

% Projection transformation
factor1 = log(tan(pi/4 + lat/2) / tan(pi/4 + phi1/2));
x = a * lon .* (lat - phi1) ./ factor1;
y = a * (lat - phi1);

%--------------------------------------------------------------------------

function [lat, lon] = loximuthInv(mstruct, x, y)

[a, phi1, epsilon] = deriveParameters(mstruct);

lat = y/a + phi1;
indx = find(abs(phi1 - lat) <= epsilon);
if ~isempty(indx)
    lat(indx) = phi1 + epsilon;
end

factor1 = log(tan(pi/4 + lat/2) / tan(pi/4 + phi1/2));
factor2 = lat - phi1;
lon = x .* factor1 ./ (a * factor2);

%--------------------------------------------------------------------------

function [a, phi1, epsilon] = deriveParameters(mstruct)

a = ellipsoidprops(mstruct);
phi1 = toRadians(mstruct.angleunits, mstruct.mapparallels(1));
epsilon = epsm('radians');

%  Eliminate singularity with a parallel at -90 degrees
if (phi1 + pi/2) <= epsilon
    phi1 = -pi/2 + epsilon;
end
