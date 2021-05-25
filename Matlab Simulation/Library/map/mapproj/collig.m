function varargout = collig(varargin)

%COLLIG  Collignon Pseudocylindrical Projection
%
%  This is a novelty projection showing a straight-line, equal area
%  graticule.  Scale is true along the 15 deg, 15 min N parallel, is
%  constant along any parallel, and is different for any pair of parallels.
%  Distortion is severe in many regions, and is only absent at 15 deg, 15
%  min N on the central meridian.  This projection is not conformal or
%  equidistant.
%
%  This projection was presented by Edouard Collignon in 1865.

% Copyright 1996-2005 The MathWorks, Inc.

mproj.default = @colligDefault;
mproj.forward = @colligFwd;
mproj.inverse = @colligInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = colligDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([15 51]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = colligFwd(mstruct, lat, lon)

radius = rsphere('authalic',mstruct.geoid);

x = 2 * radius * lon .* sqrt(1 - sin(lat)) / sqrt(pi);
y = sqrt(pi) * radius * (1 - sqrt(1 - sin(lat)));

%--------------------------------------------------------------------------

function [lat, lon] = colligInv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

lat = asin(1 - (1 - y /(radius*sqrt(pi))).^2);
lon = sqrt(pi) * x ./ (2*radius*sqrt(1 - sin(lat)));
