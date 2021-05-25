function varargout = flatplrs(varargin)
%FLATPLRS  McBryde-Thomas Flat-Polar Sinusoidal Projection
%
%  This is an equal area projection.  Scale is true along the 55 deg, 51
%  min parallels, and is constant along any parallel and between any pair
%  of parallels equidistant from the Equator.  Distortion is severe near
%  the outer meridians at high latitudes, but less so than on the
%  pointed-polar projections.  It is free of distortion only at the two
%  points where the central meridian intersects the 55 deg, 51 min
%  parallels.  This projection is not conformal or equidistant.
%
%  This projection was presented by F. Webster McBryde and Paul D. Thomas
%  in 1949.

% Copyright 1996-2006 The MathWorks, Inc.

mproj.default = @flatplrsDefault;
mproj.forward = @flatplrsFwd;
mproj.inverse = @flatplrsInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = flatplrsDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([55 51]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = flatplrsFwd(mstruct, lat, lon)

radius = rsphere('authalic',mstruct.geoid);

% convergence was selected to ensure successful testing of forward
% and inverse points (the hard point set) using TMAPCALC.
convergence = 1E-10;

maxsteps = 100;
steps = 1;
converged = 0;
thetanew = lat;

while ~converged && (steps <= maxsteps)
    steps = steps + 1;
    thetaold = thetanew;
    deltheta = -(thetaold/2 + sin(thetaold) - (1+pi/4)*sin(lat)) ./ ...
        (1/2 + cos(thetaold));
    if max(abs(deltheta(:))) <= convergence
        converged = 1;
    else
        thetanew = thetaold + deltheta;
    end
end

x = sqrt(6/(4+pi)) * radius * lon .* (0.5+cos(thetanew)) / 1.5;
y = sqrt(6/(4+pi)) * radius * thetanew;

%--------------------------------------------------------------------------

function [lat, lon] = flatplrsInv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

theta = y ./ (sqrt(6/(4+pi))*radius);
lat = asin((theta/2 +sin(theta))/(1+pi/4) );
lon = 1.5*x ./(sqrt(6/(4+pi)) * radius * (0.5+cos(theta)));
