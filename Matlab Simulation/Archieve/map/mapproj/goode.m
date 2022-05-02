function varargout = goode(varargin)
%GOODE  Goode Homolosine Pseudocylindrical Projection
%
%  This is an equal area projection.  Scale is true along all parallels and
%  the central meridian between 40 deg 44 min N and S, and is constant
%  along any parallel and between any pair of parallels equidistant from
%  the Equator for all latitudes.  Its distortion is identical to that of
%  the Sinusoidal projection between 40 deg 44 min N and S, and to that of
%  the Mollweide projection elsewhere. This projection is not conformal or
%  equidistant.
%
%  This projection was developed by J. Paul Goode in 1916.  It is sometimes
%  called simply the Homolosine projection, and it is usually in an
%  interrupted form.  It is a merging of the Sinusoidal and Mollweide
%  projections.
%
%  This projection is available in an uninterrupted form only.

% Copyright 1996-2015 The MathWorks, Inc.

mproj.default = @goodeDefault;
mproj.forward = @goodeFwd;
mproj.inverse = @goodeInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = goodeDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);
mstruct.mapparallels = 0;
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = goodeFwd(mstruct, lat, lon)

radius = rsphere('authalic',mstruct.geoid);

% Back off of the +/- 90 degree points.  This allows
% the differentiation of longitudes at the poles of the transformed
% coordinate system.

epsilon = epsm('radians');
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon)*sign(lat(indx));
end

% Pick up NaN place holders.

x = lon;
y = lat;

% Compute the indices for each component of the projection

breakpt = deg2rad(dms2degrees([40, 44,11.8]));
indx1 = find(abs(lat) >= breakpt);
indx2 = find(abs(lat) < breakpt);

% Mollweide portion of the projection

convergence = epsm('radians');
maxsteps = 100;
steps = 1;
converged = 0;
thetanew = lat(indx1);

while ~converged && (steps <= maxsteps)
    steps = steps + 1;
    thetaold = thetanew;
    deltheta = -(thetaold + sin(thetaold) - pi*sin(lat(indx1))) ./ ...
        (1 + cos(thetaold));
    if max(abs(deltheta(:))) <= convergence
        converged = 1;
    else
        thetanew = thetaold + deltheta;
    end
end
thetanew = thetanew / 2;

x(indx1) = sqrt(8) * radius * lon(indx1) .* cos(thetanew) / pi;
y(indx1) = radius*(sqrt(2) *sin(thetanew) - 0.0528035274542*sign(lat(indx1)) );

% Sinusoid portion of the projection (adjust scale to match mollweide)

x(indx2) = radius * lon(indx2) .* cos(lat(indx2));
y(indx2) = radius * lat(indx2);

%--------------------------------------------------------------------------

function [lat, lon] = goodeInv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

% Pick up NaN place holders.

lon = x;
lat = y;

% Compute the indices for each component of the projection

breakpt = radius*deg2rad(dms2degrees([40, 44, 11.8])); % was previously dms2rad(4444);
indx1 = find(abs(y) >= breakpt);
indx2 = find(abs(y) < breakpt);

% Mollweide portion of the projection

theta = asin( (y(indx1)/radius + 0.0528035274542*sign(y(indx1)))/sqrt(2) );
lat(indx1)  = asin((2*theta +sin(2*theta))/pi);
lon(indx1) = pi*x(indx1) ./ (sqrt(8)*radius*cos(theta));

% Sinusoid portion of the projection

lat(indx2) = y(indx2) / radius;
lon(indx2) = x(indx2) ./ (radius * cos(lat(indx2)) );
