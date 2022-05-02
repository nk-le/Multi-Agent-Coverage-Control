function varargout = eckert3(varargin)
%ECKERT3  Eckert III Pseudocylindrical Projection
%
%  In this projection, scale is true along the 35 deg, 58 min parallels,
%  and is constant along any parallel.  No point is free of all scale
%  distortion, but the Equator is free of angular distortion.  This
%  projection is not equal area, conformal or equidistant.
%
%  This projection was presented by Max Eckert in 1906.
%
%  This projection is available only on the sphere.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @eckert3Default;
mproj.forward = @eckert3Fwd;
mproj.inverse = @eckert3Inv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Pcyl';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = eckert3Default(mstruct)

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
                 [-90  90], [-180 180], dm2degrees([35 58]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eckert3Fwd(mstruct, lat, lon)

a = ellipsoidprops(mstruct);

factor1 = 2 * (1 + sqrt(1 - (2*lat/pi).^2));
x = a * lon .* factor1 / sqrt(pi*(4+pi));
y = 4 * a * lat /  sqrt(pi*(4+pi));


%--------------------------------------------------------------------------

function [lat, lon] = eckert3Inv(mstruct, x, y)

a = ellipsoidprops(mstruct);

lat = sqrt(pi*(4+pi)) * y / (4*a);
factor1 = 2 * (1 + sqrt(1 - (2*lat/pi).^2));
lon = sqrt(pi*(4+pi)) * x ./ (a*factor1);
