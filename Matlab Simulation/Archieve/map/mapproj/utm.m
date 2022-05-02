function varargout = utm(varargin)
%UTM  Universal Transverse Mercator system
%
%  This is a conformal projection with parameters chosen to minimize 
%  distortion over a defined set of small areas.  It is not equal area, 
%  equidistant, or perspective.  Scale is true along two straight lines
%  on the map approximately 180 kilometers east and west of the central 
%  meridian, and is constant along other straight lines equidistant from
%  the central meridian.  Scale is less than true between, and greater
%  than true outside the lines of true scale.
%  
%  The UTM system divides the world between 80 degrees S and 84 degrees
%  N into a set of quadrangles called zones.  Zones generally cover 6
%  degrees of longitude and 8 degrees of latitude.  Each zone has a set
%  of defined projection parameters, including central meridian, false
%  eastings and northings and the reference ellipsoid.  The projection
%  equations are the Gauss-Krueger versions of the transverse Mercator.
%  The projected coordinates form a grid system, in which a location is
%  specified by the zone, easting and northing.
%  
%  The UTM system was introduced in the 1940s by the U.S. Army.  It is 
%  widely used in topographic and military mapping.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @utmDefault;
mproj.forward = @utmFwd;
mproj.inverse = @utmInv;
mproj.auxiliaryLatitudeType = 'geodetic';

% Only the 'normal' aspect is supported, because the projection is
% intrinsically transverse.
if nargin > 1
    mstruct = varargin{1};
    if ~strcmp(mstruct.aspect,'normal')
        warning(message('map:projections:ignoringNonNormalAspect', ...
            'UTM'))
        varargin{1} = mstruct;
    end
end

% Note: The MAPLIST function groups UTM with the cylindrical
% projections, but it is better to provide a new, more specialized
% classification ('Tmer', for 'Transverse Mercator') so that
% applyProjection can simply shift longitudes rather than calling
% general rotation functions.
mproj.classCode = 'Tran';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = utmDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
          = fromDegrees(mstruct.angleunits, [-80 84], [-180 180]);
mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
mstruct.falseeasting = 5e5;
mstruct.scalefactor  = 0.9996;

% If no zone value is provided, use '31N' as the default zone.  Note that
% 'N' here refers to the latitudinal zone, not to the hemisphere.  The
% quadrangle that comprises longitudinal zone 31, latitudinal zone N has
% its lower left corner at lat = 0, lon = 0.  In addition, empty out any
% projection and map axex properties that are affected by the choice of
% zone.
if isempty(mstruct.zone)
    mstruct.zone = '31N';
    mstruct.geoid = [];
    mstruct.maplatlimit = [];
    mstruct.maplonlimit = [];
    mstruct.flatlimit = [];
    mstruct.flonlimit = [];
    mstruct.origin = [];
    mstruct.mlinelocation = [];
    mstruct.plinelocation = [];
    mstruct.mlabellocation = [];
    mstruct.plabellocation = [];
    mstruct.mlabelparallel = [];
    mstruct.plabelmeridian = [];
    mstruct.falsenorthing  = [];
end

% Actual values will be set by DEFAULTM, which has a large block of code
% specifically devoted to handling UTM.  AXESM also has UTM-specific code.

%--------------------------------------------------------------------------

function [x, y] = utmFwd(mstruct, lat, lon)

[a, e2, e4, e6, ep2] = deriveParameters(mstruct);

phi = lat;
dlam = lon;

N = a./sqrt(1 - e2*(sin(phi)).^2);
T = (tan(phi)).^2;
C = ep2*(cos(phi)).^2;
A = dlam.*cos(phi);

Z1 = 1 - e2/4 - 3*e4/64 - 5*e6/256;
Z2 = 3*e2/8 + 3*e4/32 + 45*e6/1024;
Z3 = 15*e4/256 + 45*e6/1024;
Z4 = 35*e6/3072;

M = a*( Z1*phi - Z2*sin(2*phi) + Z3*sin(4*phi) - Z4*sin(6*phi) );

Za = 1 - T + C;
Zb = 5 - 18*T + T.^2 + 72*C - 58*ep2;
Zc = 5 - T + 9*C + 4*C.^2;
Zd = 61 - 58*T + T.^2 +600*C - 330*ep2;

x = N .* ( A + Za.*A.^3/6 + Zb.*A.^5/120 );
y = ( M + N.*tan(phi).*( A.^2/2 + Zc.*A.^4/24 + Zd.*A.^6/720 ) );

%--------------------------------------------------------------------------

function [lat, lon] = utmInv(mstruct, x, y)

[a, e2, e4, e6, ep2] = deriveParameters(mstruct);

e1 = (1-sqrt(1-e2))/(1+sqrt(1-e2));
M = y;
mu = M / ( a*(1 - e2/4 - 3*e4/64 - 5*e6/256) );

Z1 = 3*e1/2 - 27*e1^3/32;
Z2 = 21*e1^2/16 - 55*e1^4/32;
Z3 = 151*e1^3/96;
Z4 = 1097*e1^4/512;

phi1 = mu + Z1*sin(2*mu) + Z2*sin(4*mu) + Z3*sin(6*mu) + Z4*sin(8*mu);

C1 = ep2*(cos(phi1)).^2;
T1 = (tan(phi1)).^2;
N1 = a ./ sqrt( 1 - e2*(sin(phi1)).^2 );
R1 = a*(1-e2) ./ ( 1 - e2*(sin(phi1)).^2 ).^(3/2);
D = x ./ N1;

Za = 5 + 3*T1 + 10*C1 - 4*C1.^2 - 9*ep2;
Zb = 61 + 90*T1 + 298*C1 + 45*T1.^2 - 252*ep2 - 3*C1.^2;
Zc = 1 + 2*T1 + C1;
Zd = 5 - 2*C1 + 28*T1 - 3*C1.^2 + 8*ep2 + 24*T1.^2;
phi = phi1 - (N1.*tan(phi1)./R1).*(D.^2/2 - Za.*D.^4/24 + Zb.*D.^6/720);
dlam = (D - Zc.*D.^3./6 + Zd.*D.^5/120) ./ cos(phi1);

lat = phi;
lon = dlam;

%--------------------------------------------------------------------------

function [a, e2, e4, e6, ep2] = deriveParameters(mstruct)

[a, ecc] = ellipsoidprops(mstruct);

% powers of eccentricity
e2 = ecc^2;
e4 = e2^2;
e6 = e2^3;

% second eccentricity
ep2 = e2/(1-e2);
