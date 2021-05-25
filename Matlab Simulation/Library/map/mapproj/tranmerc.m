function varargout = tranmerc(varargin)
%TRANMERC  Transverse Mercator Projection
%
%  This conformal projection is the transverse form of the Mercator
%  projection and is also known as the Gauss-Krueger projection.  It is
%  not equal area, equidistant, or perspective.
%
%  The scale is constant along the central meridian, and increases to
%  the east and west. The scale at the central meridian can be set true
%  to scale, or reduced slightly to render the mean scale of the overall
%  map more nearly correct.
%
%  The uniformity of scale along its central meridian makes Transverse
%  Mercator an excellent choice for mapping areas that are elongated
%  north-to-south.  Its best known application is the definition of
%  Universal Transverse Mercator (UTM) coordinates.  Each UTM zone spans
%  only 6 degrees of longitude, but the northern half extends from the
%  equator all the way to 84 degrees north and the southern half extends
%  from 80 degrees south to the equator.  Other map grids based on
%  Transverse Mercator include many of the state plane zones in the
%  U.S., and the U.K. National Grid.

% Copyright 2002-2011 The MathWorks, Inc.

mproj.default = @tranmercDefault;
mproj.forward = @tranmercFwd;
mproj.inverse = @tranmercInv;
mproj.auxiliaryLatitudeType = 'geodetic';

% Note: The MAPLIST function groups TRANMERC with the cylindrical
% projections, but it is better to provide a new, more specialized
% classification ('Tmer', for 'Transverse Mercator') so that
% applyProjection can simply shift longitudes rather than calling
% general rotation functions.
mproj.classCode = 'Tran';

% Only the 'normal' aspect is supported, because the projection is
% intrinsically transverse.
if nargin > 1
    mstruct = varargin{1};
    if ~strcmp(mstruct.aspect,'normal')
        warning(message('map:projections:ignoringNonNormalAspect', ...
            'Transverse Mercator'))
        varargin{1} = mstruct;
    end
end

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = tranmercDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-80 80], [-20 20]);
mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
mstruct.scalefactor  = 1;
mstruct.aspect = 'normal';

%--------------------------------------------------------------------------
% Transverse Mercator formulas from the publication:
%   A guide to coordinate systems in Great Britain, Ordnance Survey.
%--------------------------------------------------------------------------

function [x, y] = tranmercFwd(mstruct, phi, lambda)

[scalefactor, a, ecc, e2, phi0, lambda0, x0, y0] = deriveParameters(mstruct);

F0 = scalefactor;

sinphi = sin(phi);
cosphi = cos(phi);
sinphi2 = sinphi.^2;
cosphi2 = cosphi.^2;

dlam2 = (lambda - lambda0).^ 2;

nu = a * F0 ./ sqrt(1 - e2 * sinphi2);
nuOVERrho = (1 - e2 * sinphi2)/(1 - e2);
eta2 = nuOVERrho - 1;

yc = ycentral(phi, a, ecc, scalefactor, phi0, y0);

x = x0 + nu .* cosphi .*  (lambda - lambda0) .* (1 ...
    + dlam2 .* (((nuOVERrho) .* cosphi2 - sinphi2)/6 ...
    + dlam2 .* (((5 + 14 * eta2) .* cosphi2.^2 ...
                     - (18 + 58 * eta2) .* cosphi2 .* sinphi2 + sinphi2.^2))/120));

y = yc + nu .* sinphi .* cosphi .* dlam2 .* (1/2 ...
    + dlam2 .* (((5 + 9 * eta2) .* cosphi2 - sinphi2)/24 ...
    + dlam2 .* (61 * cosphi2.^2 ...
                     - 58 * cosphi2 .* sinphi2 + sinphi.^2)/720));

%--------------------------------------------------------------------------

function [phi, lambda] = tranmercInv(mstruct, x, y)

[scalefactor, a, ecc, e2, phi0, lambda0, x0, y0] = deriveParameters(mstruct);

F0 = scalefactor;

phiP = phicentral(y, a, ecc, scalefactor, phi0, y0);

sinphiP2 = sin(phiP).^2;
nu = a * F0 ./ sqrt(1 - e2 * sinphiP2);
nuOVERrho = (1 - e2 * sinphiP2)/(1 - e2);
eta2 = nuOVERrho - 1;

tanphiP  = tan(phiP);
tanphiP2 = tanphiP.^2;
dx2OVERnu2 = ((x - x0)./nu).^2;

phi = phiP + tanphiP .* nuOVERrho .* dx2OVERnu2 .* (-1/2 ...
      + dx2OVERnu2 .* ((5 + eta2 + tanphiP2 .* (3 - 9 * eta2))/24 ...
      + dx2OVERnu2 .* -(61 + tanphiP2 .* (90 + 45 * tanphiP2))/720));

lambda = lambda0 + sec(phiP) .* ((x - x0)./nu) .* (1 ...
         + dx2OVERnu2 .* (-(nuOVERrho + 2 * tanphiP2)/6 ...
         + dx2OVERnu2 .* ((5 + tanphiP2 .* (28 + 24 * tanphiP2))/120 ...
         + dx2OVERnu2 .* -(61 + tanphiP2 .* (662 + tanphiP2 .* (1320 + 720 * tanphiP2)))/5040)));

%--------------------------------------------------------------------------

function [scalefactor, a, ecc, e2, phi0, lambda0, x0, y0] ...
    = deriveParameters(mstruct)

[a, ecc] = ellipsoidprops(mstruct);
e2 = ecc^2;
phi0 = toRadians(mstruct.angleunits, mstruct.origin(1));

% Parameters that are handled by applyProjection (use nominal values here):
scalefactor = 1;
lambda0 = 0;
x0 = 0;
y0 = 0;

%-----------------------------------------------------------------------

function yc = ycentral(phi, a, ecc, scalefactor, phi0, y0)

% Calculate the northing of the point (phi,lambda0), which lies on the
% central meridian.

F0 = scalefactor;

% Derive semiminor axis, b, and third flattening, n.
e2 = ecc^2;
t = sqrt(1 - e2);
b = a * t;
n = e2 / (1 + t)^2;

dphi = phi - phi0;
pphi = phi + phi0;

yc = y0 + b * F0 ...
          * ( ((4 + n.*(4 + 5*n.*(1 + n)))/4) .* dphi ...
             - (n .* (24 + n.*(24 + n*21))/8) .* sin(dphi)   .* cos(pphi) ...
                   + (15 * n.^2 .* (1 + n)/8) .* sin(2*dphi) .* cos(2*pphi) ...
                           - ((35 * n.^3)/24) .* sin(3*dphi) .* cos(3*pphi));

%-----------------------------------------------------------------------

function phiP = phicentral(y, a, ecc, scalefactor, phi0, y0)

% Fixed point iteration for the latitude of the point (y,x0), which
% lies on the central meridian.

F0 = scalefactor;

tol = 1e-12 * a;

phiP = (y - y0)/(a * F0) + phi0;
yc = ycentral(phiP, a, ecc, F0, phi0, y0);
nIterations = 0;
while any(abs(y(:) - yc(:)) > tol) && nIterations < 10
    phiP = (y - yc)/(a * F0) + phiP;
    yc = ycentral(phiP, a, ecc, scalefactor, phi0, y0);
    nIterations = nIterations + 1;
end
