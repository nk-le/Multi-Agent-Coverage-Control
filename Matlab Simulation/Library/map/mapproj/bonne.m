function varargout = bonne(varargin)
%BONNE  Bonne Pseudoconic Projection
%
%  This is an equal area projection.  The curvature of the standard
%  parallel is identical to that on a cone tangent at that latitude.  The
%  central meridian and the central parallel are free of distortion.  This
%  projection is not conformal.
%
%  This projection dates in a rudimentary form back to Claudius Ptolemy
%  (about A.D. 100).  It was further developed by Bernardus Sylvanus in
%  1511.  It derives its name from its considerable use by Rigobert Bonne,
%  especially in 1752.  It has two interesting limiting forms. If a pole is
%  employed as the standard parallel, a Werner projection results;  if the
%  Equator is used, a Sinusoidal projection results.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @bonneDefault;
mproj.forward = @bonneFwd;
mproj.inverse = @bonneInv;
mproj.auxiliaryLatitudeType = 'rectifying';
mproj.classCode = 'Pcon';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = bonneDefault(mstruct)

mstruct.mapparallels = [];
mstruct.nparallels   = 1;
[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = bonneFwd(mstruct, lat, lon)

[radius, parallels, rectifies, a, e, m1] = deriveParameters(mstruct);

latgeod = convertlat([a e], lat, 'rectifying', 'geodetic', 'nocheck');

% Back off of the +/- 90 degree points.  This allows the differentiation of
% longitudes at the poles of the transformed coordinate system.

epsilon = epsm('radians');
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
    latgeod(indx) = (pi/2 - epsilon) * sign(latgeod(indx));
end

%  Perform the projection calculations

m   = cos(latgeod) ./ sqrt(1 - (e*sin(latgeod)).^2);
if parallels(1) ~= 0
    rho = a*m1/(sin(parallels(1))) + radius*(rectifies(1) - lat);
    E   = a*m .* lon ./ rho;

    x = rho .* sin(E);
    y = a*m1/sin(parallels(1)) - rho .* cos(E);
else
    x = a * m .* lon;
    y = radius * lat;
end

%--------------------------------------------------------------------------

function [lat, lon] = bonneInv(mstruct, x, y)

% Inverse projection
[radius, parallels, rectifies, a, e, m1] = deriveParameters(mstruct);
if parallels(1) ~= 0
    factor1 = a*m1/sin(parallels(1));
    factor2 = sign(parallels(1));
    rho = factor2*hypot(x, factor1 - y);

    lat  = (factor1 + radius*rectifies(1) - rho) / radius;
    latgeod = convertlat([a e], lat, 'rectifying', 'geodetic', 'nocheck');
    m = cos(latgeod) ./ sqrt(1 - (e*sin(latgeod)).^2);
    lon = rho .* atan2(factor2*x, factor2*(factor1-y)) ./ (a*m);
else
    lat = y ./ radius;
    latgeod = convertlat([a e], lat, 'rectifying', 'geodetic', 'nocheck');
    m = cos(latgeod) ./ sqrt(1 - (e*sin(latgeod)).^2);
    lon = x ./ (a*m);
end

%--------------------------------------------------------------------------

function [radius, parallels, rectifies, a, e, m1] = deriveParameters(mstruct)

% Compute several derived projection parameters from the defining
% parameters in the mstruct.

[a, e, radius] = ellipsoidpropsRectifying(mstruct);

parallels = toRadians(mstruct.angleunits, mstruct.mapparallels);

rectifies = convertlat([a e], parallels, 'geodetic', 'rectifying', 'nocheck');

m1 = cos(parallels(1)) ...
     / sqrt((1 + e*sin(parallels(1))) * (1 - e*sin(parallels(1))));
