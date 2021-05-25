function varargout = kavrsky6(varargin)
%KAVRSKY6  Kavraisky VI Pseudocylindrical Projection
%
%  This is an equal-area projection.  Scale is constant along any parallel
%  or pair of equidistant parallels.  This projection is neither conformal
%  nor equidistant.
%
%  This projection was described by V. V. Kavraisky in 1936.  It is also
%  called the Wagner I, for Karlheinz Wagner, who described it in 1932.

% Copyright 1996-2007 The MathWorks, Inc.

mproj.default = @kavrsky6Default;
mproj.forward = @kavrsky6Fwd;
mproj.inverse = @kavrsky6Inv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = kavrsky6Default(mstruct)

mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-180 180]);

%--------------------------------------------------------------------------

function [x, y] = kavrsky6Fwd(mstruct, lat, lon)

[m, n, radius] = deriveParameters(mstruct);

psi = asin(sqrt(3) * sin(lat) / 2);
x = m * radius * lon .* cos(psi);
y = n * radius * psi;

%--------------------------------------------------------------------------

function [lat, lon] = kavrsky6Inv(mstruct, x, y)

[m, n, radius] = deriveParameters(mstruct);

psi  = y / (n*radius);
lat  = asin(2*sin(psi)/sqrt(3));
lon = x ./ (m*radius*cos(psi));

%--------------------------------------------------------------------------

function [m, n, radius] = deriveParameters(mstruct)

m = 0.877;
n = 1.3161;
radius = rsphere('authalic',mstruct.geoid);
