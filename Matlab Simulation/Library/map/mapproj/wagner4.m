function varargout = wagner4(varargin)
%WAGNER4  Wagner IV Pseudocylindrical Projection
%
%  This is an equal area projection.  Scale is true along the 42 deg, 59
%  min parallels, and is constant along any parallel and between any pair
%  of parallels equidistant from the Equator.  Distortion is not as extreme
%  near the outer meridians at high latitudes as for pointed-polar
%  pseudocylindrical projections, but there is considerable distortion
%  throughout polar regions.  It is free of distortion only at the two
%  points where the 42 deg, 59 min parallels intersect the central
%  meridian.  This projection is not conformal or equidistant.
%
%  This projection was presented by Karlheinz Wagner in 1932.

% Copyright 1996-2006 The MathWorks, Inc.

mproj.default = @wagner4Default;
mproj.forward = @wagner4Fwd;
mproj.inverse = @wagner4Inv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = wagner4Default(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([42 59]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = wagner4Fwd(mstruct, lat, lon)

[radius, n, m, const] = deriveParameters(mstruct);

convergence = epsm('radians');
maxsteps = 100;
steps = 1;
thetanew = lat;
converged = 0;

while ~converged && (steps <= maxsteps)
    steps = steps + 1;
    thetaold = thetanew;
    deltheta = -(thetaold + sin(thetaold) - const*sin(lat)) ./ ...
        (1 + cos(thetaold));
    if max(abs(deltheta(:))) <= convergence
        converged = 1;
    else
        thetanew = thetaold + deltheta;
    end
end
thetanew = thetanew / 2;

x = n * radius * lon .* cos(thetanew);
y = m * radius * sin(thetanew);

%--------------------------------------------------------------------------

function [lat, lon] = wagner4Inv(mstruct, x, y)

[radius, n, m, const] = deriveParameters(mstruct);

theta = asin(y ./ (m*radius));
lat = asin((2*theta +sin(2*theta))/const);
lon = x ./(n*radius*cos(theta));

%--------------------------------------------------------------------------

function [radius, n, m, const] = deriveParameters(mstruct)

radius = rsphere('authalic',mstruct.geoid);
n = 0.86310;
m = 1.56548;
const = (4*pi + 3*sqrt(3))/6;
