function varargout = flatplrp(varargin)
%FLATPLRP  McBryde-Thomas Flat-Polar Parabolic Projection
%
%  This is an equal area projection.  Scale is true along the 45 deg, 30
%  min parallels, and is constant along any parallel and between any pair
%  of parallels equidistant from the Equator.  Distortion is severe near
%  the outer meridians at high latitudes, but less so than on the
%  pointed-polar projections.  It is free of distortion only at the two
%  points where the central meridian intersects the 45 deg, 30 min
%  parallels.  This projection is not conformal or equidistant.
%
%  This projection was presented by F. Webster McBryde and Paul D. Thomas
%  in 1949.

% Copyright 1996-2006 The MathWorks, Inc.

mproj.default = @flatplrpDefault;
mproj.forward = @flatplrpFwd;
mproj.inverse = @flatplrpInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = flatplrpDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([45 30]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = flatplrpFwd(mstruct, lat, lon)

radius = rsphere('authalic',mstruct.geoid);

theta = asin((7/3)*sin(lat) / sqrt(6));
x = sqrt(6) * radius * lon .* (2*cos(2*theta/3) - 1) / sqrt(7);
y = 9 * radius * sin(theta/3) / sqrt(7);

%--------------------------------------------------------------------------

function [lat, lon] = flatplrpInv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

theta = 3*asin(sqrt(7)*y / (9*radius));
lat = asin(3*sqrt(6)*sin(theta) / 7);
lon = sqrt(7) * x ./ (sqrt(6) * radius * (2*cos(2*theta/3) - 1) );
