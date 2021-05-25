function varargout = flatplrq(varargin)
%FLATPLRQ  McBryde-Thomas Flat-Polar Quartic Projection
%
%  This is an equal area projection.  Scale is true along the 33 deg, 45
%  min parallels, and is constant along any parallel and between any pair
%  of parallels equidistant from the Equator.  Distortion is severe near
%  the outer meridians at high latitudes, but less so than on the
%  pointed-polar projections.  It is free of distortion only at the two
%  points where the central meridian intersects the 33 deg, 45 min
%  parallels.  This projection is not conformal or equidistant.
%
%  This projection was presented by F. Webster McBryde and Paul D. Thomas
%  in 1949 and is also known simply as the Flat-Polar Quartic projection.

% Copyright 1996-2006 The MathWorks, Inc.

mproj.default = @flatplrqDefault;
mproj.forward = @flatplrqFwd;
mproj.inverse = @flatplrqInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = flatplrqDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([33 45]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = flatplrqFwd(mstruct, lat, lon)

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
    deltheta = -(thetaold/2 + sin(thetaold) - (1+sqrt(2)/2)*sin(lat)) ./ ...
        (1/2 + cos(thetaold));
    if max(abs(deltheta(:))) <= convergence
        converged = 1;
    else
        thetanew = thetaold + deltheta;
    end
end

x = radius * lon .* (1+2*cos(thetanew)./cos(thetanew/2) ) / ...
    sqrt(3*sqrt(2) + 6);
y = 2*sqrt(3/(2+sqrt(2))) * radius * sin(thetanew/2);

%--------------------------------------------------------------------------

function [lat, lon] = flatplrqInv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

theta = 2*asin(y / (2*sqrt(3/(2+sqrt(2)))*radius) );

lat = asin((theta/2 +sin(theta))/(1+sqrt(2)/2) );
lon = sqrt(3*sqrt(2) + 6)*x ./ ...
    (radius * (1+2*cos(theta)./cos(theta/2)) );
