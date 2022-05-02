function varargout = hatano(varargin)
%HATANO  Hatano Asymmetrical Equal Area Pseudocylindrical Projection
%
%  This is an equal area projection.  Scale is true along 40 deg, 42 min N
%  and 38 deg, 27 min S, and is constant along any parallel but generally
%  not between pairs of parallels equidistant from the Equator.  It is free
%  of distortion along the central meridian at 40 deg, 42 min N and 38 deg,
%  27 min S.  This projection is not conformal or equidistant.
%
%  This projection was presented by Masataka Hatano in 1972.

% Copyright 1996-2006 The MathWorks, Inc.

mproj.default = @hatanoDefault;
mproj.forward = @hatanoFwd;
mproj.inverse = @hatanoInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = hatanoDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([38 27;40 42]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = hatanoFwd(mstruct, lat, lon)

radius = rsphere('authalic',mstruct.geoid);

% Determine the location of positive and negative entries, which is
% necessary since this projection treats northern and southern
% latitudes differently.

indx1 = find(lat >= 0);
indx2 = find(lat < 0);

% Pick up NaN place holders in the output data.

x = lon;
y = lat;

% Projection transformation

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
    delnorth = -(thetaold(indx1) + sin(thetaold(indx1)) - ...
        2.67595*sin(lat(indx1))) ./ ...
        (1 + cos(thetaold(indx1)));

    delsouth = -(thetaold(indx2) + sin(thetaold(indx2)) - ...
        2.43763*sin(lat(indx2))) ./ ...
        (1 + cos(thetaold(indx2)));

    if (~isempty(delnorth) && max(abs(delnorth(:))) <= convergence) && ...
       (~isempty(delsouth) && max(abs(delsouth(:))) <= convergence)
        converged = 1;
    else
        thetanew(indx1) = thetaold(indx1) + delnorth;
        thetanew(indx2) = thetaold(indx2) + delsouth;
    end
end
thetanew = thetanew / 2;

x(indx1) = 0.85 * radius * lon(indx1) .* cos(thetanew(indx1));
x(indx2) = 0.85 * radius * lon(indx2) .* cos(thetanew(indx2));
y(indx1) = 1.75859 * radius * sin(thetanew(indx1));
y(indx2) = 1.93052 * radius * sin(thetanew(indx2));

%--------------------------------------------------------------------------

function [lat, lon] = hatanoInv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

% Pick up NaN place holders in the output data.

lon = x;
lat = y;

% Determine the location of positive and negative entries, which is
% necessary since this projection treats northern and southern
% latitudes differently.

indx1 = find(y >= 0);
indx2 = find(y < 0);

%  Northern latitudes

theta = asin(y(indx1) ./ (1.75859 * radius));
lat(indx1)  = asin((2*theta +sin(2*theta))/2.67595);
lon(indx1) = x(indx1) ./(0.85*radius*cos(theta));

%  Southern Latitudes

theta = asin(y(indx2) ./ (1.93052 * radius));
lat(indx2)  = asin((2*theta +sin(2*theta))/2.43763);
lon(indx2) = x(indx2) ./(0.85*radius*cos(theta));
