function varargout = mollweid(varargin)
%MOLLWEID  Mollweide Pseudocylindrical Projection
%
%  This is an equal area projection.  Scale is true along the 40 deg 44 min
%  parallels, and is constant along any parallel and between any pair of
%  parallels equidistant from the Equator.  It is free of distortion only
%  at the two points where the 40 deg, 44 min parallels intersect the
%  central meridian.  This projection is not conformal or equidistant.
%
%  This projection was presented by Carl B. Mollweide in 1805.  Its other
%  names include the Homolographic, the Homalographic, the Babinet, and the
%  Elliptical projections.  It is occasionally used for thematic world
%  maps, and it is combined with the Sinusoidal to produce the Goode
%  Homolosine projection.

% Copyright 1996-2006 The MathWorks, Inc.

mproj.default = @mollweidDefault;
mproj.forward = @mollweidFwd;
mproj.inverse = @mollweidInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = mollweidDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([40 44]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = mollweidFwd(mstruct, lat, lon)

radius = rsphere('authalic',mstruct.geoid);

% Back off of the +/- 90 degree points.  This allows
% the differentiation of longitudes at the poles of the transformed
% coordinate system.
epsilon = epsm('radians');
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

% convergence was selected to ensure successful testing of forward
% and inverse points (the hard point set) using TMAPCALC.
convergence = 1E-10;

maxsteps = 100;
steps = 1;
thetanew = lat;
converged = 0;

while ~converged && (steps <= maxsteps)
    steps = steps + 1;
    thetaold = thetanew;
    deltheta = -(thetaold + sin(thetaold) -pi*sin(lat)) ./ ...
        (1 + cos(thetaold));
    if max(abs(deltheta(:))) <= convergence
        converged = 1;
    else
        thetanew = thetaold + deltheta;
    end
end
thetanew = thetanew / 2;

x = sqrt(8) * radius * lon .* cos(thetanew) / pi;
y = sqrt(2) * radius * sin(thetanew);

%--------------------------------------------------------------------------

function [lat, lon] = mollweidInv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

theta = asin(y / (sqrt(2)*radius));

lat = asin((2*theta +sin(2*theta))/pi);
lon = pi*x ./(sqrt(8)*radius*cos(theta));
