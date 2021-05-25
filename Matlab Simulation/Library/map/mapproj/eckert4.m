function varargout = eckert4(varargin)
%ECKERT4  Eckert IV Pseudocylindrical Projection
%
%  This is an equal area projection.  Scale is true along the 40 deg, 30
%  min parallels, and is constant along any parallel and between any pair
%  of parallels equidistant from the Equator.  It is not free of distortion
%  at any point except at 40 deg, 30 min N and S along the central
%  meridian.  This projection is not conformal or equidistant.
%
%  This projection was presented by Max Eckert in 1906.

% Copyright 1996-2006 The MathWorks, Inc.

mproj.default = @eckert4Default;
mproj.forward = @eckert4Fwd;
mproj.inverse = @eckert4Inv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = eckert4Default(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([40 30]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eckert4Fwd(mstruct, lat, lon)

radius = rsphere('authalic',mstruct.geoid);

% convergence was selected to ensure successful testing of forward
% and inverse points (the hard point set) using TMAPCALC.
convergence = 1E-10;

maxsteps = 100;
steps = 1;
converged = 0;
thetanew = lat/2;

while ~converged && (steps <= maxsteps)
    steps = steps + 1;
    thetaold = thetanew;
    deltheta = -(thetaold + sin(thetaold).*cos(thetaold) + ...
        2*sin(thetaold) - (2+pi/2)*sin(lat)) ./ ...
        (2*cos(thetaold) .* (1 + cos(thetaold)));
    if max(abs(deltheta(:))) <= convergence
        converged = 1;
    else
        thetanew = thetaold + deltheta;
    end
end

x = 2 * radius * lon .* (1 + cos(thetanew)) / sqrt(pi*(4+pi));
y = 2 * sqrt(pi) * radius * sin(thetanew) / sqrt(4+pi);

%--------------------------------------------------------------------------

function [lat, lon] = eckert4Inv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

theta = asin(sqrt(4+pi)*y/(2*sqrt(pi)*radius));

lat = asin( (theta+sin(theta).*cos(theta)+2*sin(theta) )/(2 + pi/2) );
lon = sqrt(pi*(4+pi))*x ./ (2*radius*(1+cos(theta)));
