function [areascale, angdef, a, b, h, k] = distortcalc(varargin)
% DISTORTCALC Distortion parameters for map projections
%
%  areascale = DISTORTCALC(lat,long) computes the area distortion for the 
%  current map projection at the specified geographic location. An area 
%  scale of 1 indicates no scale distortion. Latitude and longitude may 
%  be scalars, vectors or matrices in the angle units of the defined map 
%  projection.  
%
%  areascale = DISTORTCALC(mstruct,lat,long) uses the projection defined in 
%  the map projection structure mstruct.
%
%  [areascale,angdef,maxscale,minscale,merscale,parscale] = DISTORTCALC(...)
%  computes the area scale, maximum angular deformation (in the angle units of
%  the defined projection), the particular maximum and minimum scale 
%  distortions in any direction, and the particular scale along the 
%  meridian and parallel. DISTORTCALC may also be called with fewer output 
%  arguments, in the order shown.
%
%  See also MDISTORT, TISSOT.

% Copyright 1996-2015 The MathWorks, Inc.
% Written by: W. Stumpf

%  Ref. Maling, Coordinate Systems and Map Projections, 2nd Edition, 

[mstruct, lat, lon] = parseInputs(varargin{:});

units = mstruct.angleunits;

%  Direction and scale along the meridian by finite difference

[th,len] = vfwdtran(mstruct,lat,lon,0*ones(size(lat)));

%  Components in x and y directions

th = toRadians(units,th);
dxdphi =  cos(th).*len; % phi = lat
dydphi =  sin(th).*len; % phi = lat

%  Direction and scale along the parallel by finite difference

ang = fromDegrees(units,90);
[th,len] = vfwdtran(mstruct,lat,lon,ang*ones(size(lat)));
th = toRadians(units,th);

%  Components in x and y directions

lat = toRadians(units, lat);
dydlambda =  sin(th).*len.*cos(lat); % lambda = lon
dxdlambda =  cos(th).*len.*cos(lat); % lambda = lon

%  Gauss parameters

E = dxdphi.^2 + dydphi.^2;
F = dxdphi.*dxdlambda + dydphi.*dydlambda ;
G = dxdlambda.^2 + dydlambda.^2;

%  Particular scale along the meridian

h = sqrt(E);

%  Particular scale along the parallel
k = sqrt(G)./cos(lat) ;

%  Parameters used in computing scales
cosThetaPrime = F./(h.*k.*cos(lat));
sinThetaPrime = sin(acos(cosThetaPrime));

aplusb  = sqrt(h.^2 + k.^2 + 2.*h.*k.*sinThetaPrime);
aminusb = sqrt(h.^2 + k.^2 - 2.*h.*k.*sinThetaPrime);

%  Maximum particular scale at a point

a = (aplusb + aminusb)./2;

%  Minimum particular scale at a point

b = aplusb-a;

%  Area scale

areascale = a.*b;

%  Angular deformation

sinomegaby2 = aminusb./aplusb;
angdef = fromRadians(units, 2*asin(sinomegaby2));

%-----------------------------------------------------------------------

function [mstruct, lat, lon] = parseInputs(varargin)

if (nargin >= 1) && isstruct(varargin{1})
    narginchk(3,3)
    mstruct = varargin{1};
    varargin(1) = [];
else
    narginchk(2,2)
    mstruct = gcm;
end

lat = varargin{1};
lon = varargin{2};
