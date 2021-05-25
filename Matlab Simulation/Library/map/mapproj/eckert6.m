function varargout = eckert6(varargin)
%ECKERT6  Eckert VI Pseudocylindrical Projection
%
%  This is an equal area projection.  Scale is true along the 49 deg, 16
%  min parallels, and is constant along any parallel and between any pair
%  of parallels equidistant from the Equator.  It is not free of distortion
%  at any point except at 49 deg, 16 min N and S along the central
%  meridian.  This projection is not conformal or equidistant.
%
%  This projection was presented by Max Eckert in 1906.

% Copyright 1996-2006 The MathWorks, Inc.

mproj.default = @eckert6Default;
mproj.forward = @eckert6Fwd;
mproj.inverse = @eckert6Inv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = eckert6Default(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([49 16]));

mstruct.nparallels   = 1;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eckert6Fwd(mstruct, lat, lon)

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
    deltheta = -(thetaold + sin(thetaold) - (1+pi/2)*sin(lat)) ./ ...
        (1 + cos(thetaold));
    if max(abs(deltheta(:))) <= convergence
        converged = 1;
    else
        thetanew = thetaold + deltheta;
    end
end

x = radius * lon .* (1 + cos(thetanew)) / sqrt(2+pi);
y = 2 * radius * thetanew / sqrt(2+pi);

%--------------------------------------------------------------------------

function [lat, lon] = eckert6Inv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

theta = sqrt(2+pi)*y / (2*radius);

lat = asin( (theta+sin(theta) )/(1 + pi/2) );
lon = sqrt(2+pi)*x ./ (radius*(1+cos(theta)));
