function varargout = fournier(varargin)
%FOURNIER  Fournier Pseudocylindrical Projection
%
%  This projection is equal-area.  Scale is constant along any parallel or
%  pair of parallels equidistant from the Equator.  This projection is
%  neither equidistant nor conformal.
%
%  This projection was first described in 1643 by Georges Fournier.  This
%  is actually his second projection, the Fournier II.

% Copyright 1996-2007 The MathWorks, Inc.

mproj.default = @fournierDefault;
mproj.forward = @fournierFwd;
mproj.inverse = @fournierInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = fournierDefault(mstruct)

mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-90  90], [-180 180]);

%--------------------------------------------------------------------------

function [x, y] = fournierFwd(mstruct, lat, lon)

radius = rsphere('authalic',mstruct.geoid);

% This transformation is sensitive to points  at the poles, so the
% epsilon use to back off must be larger than epsm.  In addition,
% for this projection, the inverse calculations must also
% address the points backed off of the pole since the epsilon
% is significant to the trig functions (but not necessarily to
% the display of the projection).
epsilon = 500*epsm('radians');

% Back off of the +/- 90 degree points.  This allows
% the differentiation of longitudes at the poles of the transformed
% coordinate system.

indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

% Projection transformation

x = radius * lon .* cos(lat) / sqrt(pi);
y = sqrt(pi) * radius * sin(lat) / 2;

%--------------------------------------------------------------------------

function [lat, lon] = fournierInv(mstruct, x, y)

radius = rsphere('authalic',mstruct.geoid);

% Inverse projection

lat = asin(2*y / (sqrt(pi)*radius));
lon = sqrt(pi) * x ./ (radius * cos(lat));

% Reset the +/- 90 degree points.  Account for trig round-off
% by expanding epsilon to 1.01*epsilon
epsilon = 500*epsm('radians');
indx = find(abs(pi/2 - abs(lat)) <= 1.01*epsilon);
if ~isempty(indx)
    lat(indx) = pi/2 * sign(lat(indx));
end
