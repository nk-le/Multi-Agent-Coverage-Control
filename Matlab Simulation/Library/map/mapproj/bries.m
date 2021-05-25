function varargout = bries(varargin)
%BRIES  Briesemeister's Modified Azimuthal Projection
%
% This equal-area projection groups the continents about the center of the   
% frame. The only point free of distortion is the center point.  Distortion 
% of shape and scale are moderate throughout.
% 
% This projection was presented by William Briesemeister in 1953.  It is an
% oblique Hammer projection with an axis ratio of 1.75 to 1, instead of 2
% to 1.

% Copyright 1996-2015 The MathWorks, Inc.

mproj.default = @briesDefault;
mproj.forward = @briesFwd;
mproj.inverse = @briesInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Mazi';

% Special override:  "The forward and inverse formulas are not consistent
% [in the ellipsoidal case].  Until the difference can be resolved, HAMMER
% and BRIES will ignore the elliptical component of the [ellipsoid] vector."
if nargin > 1
    mstruct = varargin{1};
    [a,~] = ellipsoidprops(mstruct);
    mstruct.geoid = [a 0];
    varargin{1} = mstruct;
end

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = briesDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.origin] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-180 180], [45 10 0]);
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = briesFwd(mstruct, lat, lon)

% Back off of the +/- 90 degree points.  This allows the differentiation of
% longitudes at the poles of the transformed coordinate system.
epsilon = epsm('radians');
indx = (abs(pi/2 - abs(lat)) <= epsilon);
lat(indx) = (pi/2 - epsilon) * sign(lat(indx));

% Apply projection.
w = 0.5;
d = 2./(1 + cos(lat) .* cos(w*lon));
d = reshape(d,size(lat));
[~, ~, radius] = ellipsoidpropsAuthalic(mstruct);
x = radius * sqrt(1.75/2) * sqrt(d)/w .* cos(lat) .* sin(w*lon);
y = radius * 1/sqrt(1.75/2) * sqrt(d) .* sin(lat);

%--------------------------------------------------------------------------

function [lat, lon] = briesInv(mstruct, x, y)

%  Another Projection parameter (which needs the authalic origin)
origin = toRadians(mstruct.angleunits, mstruct.origin);
[a, e, radius] = ellipsoidpropsAuthalic(mstruct);
m1 = cos(origin(1))/sqrt(1-(e*sin(origin(1)))^2);
D = a * m1 / (radius * cos(origin(1)));

%  Inverse projection

x = x/2/sqrt(1.75/2);
y = y*sqrt(1.75/2);

rho = sqrt((x/D).^2 + (D*y).^2);

indx = find(rho ~= 0);

lat = x;
lon = y;   %  Note where x,y = 0, so does lat,lon

if ~isempty(indx)
    ce  = 2*asin(rho(indx)/(2*radius));
    lat(indx)  = asin(D*y(indx).*sin(ce)./rho(indx));
    lon(indx) = atan2(x(indx).*sin(ce), D*rho(indx).*cos(ce));
end
lon = 2*lon;

%  Reset the +/- 90 degree points.
%
%  This projection is highly sensitive around poles and the date
%  line.  The azimuth calculation in the inverse direction will
%  transform -180 deg longitude into 180 deg longitude if an
%  insufficient epsilon is supplied.  Trial and error yielded
%  an epsilon of 0.01 degrees to back-off from the date line and
%  the poles. (Carried over from the azimuthal projection)

epsilon = deg2rad(0.01);

indx = find(abs(pi/2 - abs(lat)) <= 1.02*epsilon);
if ~isempty(indx)
    lat(indx) = sign(lat(indx))*pi/2;
end
