function [phi, lambda] = rhumblinefwd(phi0, lambda0, alpha, s, in5)
%RHUMBLINEFWD Forward rhumbline problem on a sphere or ellipsoid.
%
%   [PHI, LAMBDA] = RHUMBLINEFWD(PHI0, LAMBDA0, ALPHA, S, ELLIPSOID)
%   calculates the point at geodetic latitude PHI and longitude LAMBDA
%   given azimuth ALPHA and distance S along a rhumb line from a starting
%   point at geodetic latitude PHI0 and longitude LAMBDA0, on the ellipsoid
%   defined by the 1-by-2 vector ELLIPSOID.  PHI0, LAMBDA0, ALPHA, and S
%   must be either scalars or vectors of matching size.  PHI and LAMBDA
%   will also be this size. PHI0, LAMBDA0, PHI, LAMBDA, and ALPHA are in
%   radians.  S must have the same length units as ELLIPSOID(1), the
%   semimajor axis of the ellipsoid.
%
%   [PHI, LAMBDA] = RHUMBLINEFWD(PHI0, LAMBDA0, ALPHA, S, RADIUS)
%   calculates the new point on a sphere defined by scalar RADIUS.  S has
%   the same units as RADIUS.  Set RADIUS = 1 if S is an angular distance
%   in radians.
%
%   See also MERIDIANFWD, RHUMBLINEINV

%   Copyright 2004-2019 The MathWorks, Inc.

phi0(phi0 >  pi/2) =  pi/2;
phi0(phi0 < -pi/2) = -pi/2;

if numel(in5) == 1
    % Use spherical calculations when IN5 is a scalar RADIUS.
    [phi, lambda] = rhspherefwd(phi0, lambda0, alpha, s, in5);
else
    % Assume that IN5 is a 1-by-2 ELLIPSOID vector.
    [phi, lambda] = rhellipsoidfwd(phi0, lambda0, alpha, s, in5);
end

phi(phi >  pi/2) =  pi/2;
phi(phi < -pi/2) = -pi/2;
lambda = wrapToPi(lambda);

%--------------------------------------------------------------------------

function [phi, lambda] = rhspherefwd(phi0, lambda0, alpha, s, radius)
% Forward rhumbline problem on a sphere.

cosalpha = cos(alpha);
sinalpha = sin(alpha);

s = s / radius;  % Normalize to unit sphere

phi = phi0 + s .* cosalpha;
lambda = zeros(size(phi0));

q = useExactFormula(alpha);
if any(q)
    psi  = isometric(phi(q));
    psi0 = isometric(phi0(q));
    lambda(q) = lambda0(q) + (sinalpha(q)./cosalpha(q)) .* (psi - psi0);
end

if any(~q)
    lambda(~q) = lambda0(~q) + (sinalpha(~q)./cos(phi0(~q))) .* s(~q);
end

%--------------------------------------------------------------------------

function [phi, lambda] = rhellipsoidfwd(phi0, lambda0, alpha, s, ellipsoid)
% Forward rhumbline problem on an ellipsoid.

a = ellipsoid(1);
e = ellipsoid(2);

phi    = zeros(size(phi0));
lambda = zeros(size(phi0));

q = useExactFormula(alpha);
if any(q)
    phi(q) = meridianfwd(phi0(q), s(q) .* cos(alpha(q)), ellipsoid);
    lambda(q) = lambda0(q)...
        + tan(alpha(q)) .* (isometric(phi(q),e) - isometric(phi0(q),e));
end

if any(~q)
    d = sqrt(1 - (e * sin(phi0(~q))).^2);
    phi(~q)    = phi0(~q)    + cos(alpha(~q)) .* s(~q) .* d.^3 / (a*(1 - e^2));
    lambda(~q) = lambda0(~q) + sin(alpha(~q)) .* s(~q) .* d   ./ (a*cos(phi0(~q)));
end

%--------------------------------------------------------------------------

function psi = isometric(phi, e)
% Convert geodetic latitude PHI to isometric latitude PSI.

% Exploit the antisymmetry of the isometric latitude:
%   Calculate tan(abs(phi)/2 + pi/4) instead of tan(abs(phi)/2 + pi/4) to
%   avoid log(0) at the south pole.
if nargin > 1
    t = e * sin(abs(phi));
    psi = sign(phi) .* log(tan(abs(phi)/2 + pi/4) .* ((1 - t) ./ (1 + t)).^(e/2));
else
    psi = sign(phi) .* log(tan(abs(phi)/2 + pi/4));
end

%--------------------------------------------------------------------------

function tf = useExactFormula(alpha)
% Specify a cutoff value:  If |cos(ALPHA)| > cutoff, use a formula for
% longitude that is exact but undefined for small cos(ALPHA). Otherwise,
% use an approximation that is both accurate and stable for very small
% cos(ALPHA).  The specific cutoff value used here is optimal in the sense
% that it leads to roughly errors (less than 1e-10 radians in longitude,
% negligible in latitude) with both methods
cutoff = 1e-5;
tf = (abs(cos(alpha)) > cutoff);
