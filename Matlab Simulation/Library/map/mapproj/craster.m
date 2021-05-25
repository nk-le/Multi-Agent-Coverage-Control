function varargout = craster(varargin)
%CRASTER  Craster Parabolic Pseudocylindrical Projection
%
%  This is an equal area projection.  Scale is true along the 36 deg, 46
%  min parallels, and is constant along any parallel, and between any pair
%  of parallels equidistant from the equator.  Distortion is severe near
%  the outer meridians at high latitudes, but less so than the Sinusoidal
%  projection.  It is free of distortion only at the two points where the
%  central meridian intersects the 36 deg, 46 min parallels.  This
%  projection is not conformal or equidistant.
%
%  This projection was developed by John Evelyn Edmund Craster in 1929; it
%  was further developed by Charles H. Deetz and O. S. Adams in 1934. It
%  was presented independently in 1934 by Putnins as his P4 projection.

% Copyright 1996-2006 The MathWorks, Inc.

mproj.default = @crasterDefault;
mproj.forward = @crasterFwd;
mproj.inverse = @crasterInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = crasterDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([36 46]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = crasterFwd(mstruct, lat, lon)

radius = rsphere('authalic',mstruct.geoid);

x = sqrt(3) * radius * lon .* (2*cos(2*lat/3) - 1) / sqrt(pi);
y = sqrt(3*pi) * radius * sin(lat/3);

%--------------------------------------------------------------------------

function [lat, lon] = crasterInv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

lat = 3 * asin(y / (sqrt(3*pi)*radius));
lon = sqrt(pi) * x ./ (sqrt(3) * radius * (2*cos(2*lat/3) - 1) );
