function varargout = cassinistd(varargin)
%CASSINISTD  Cassini Transverse Cylindrical Projection -- Standard
%
%  CASSINISTD Implements the Cassini projection directly on a sphere or
%  reference ellipsoid, as opposed to using the equidistant cylindrical
%  projection in transverse mode as in function CASSINI.  Distinct forms
%  are used for the sphere and ellipsoid, because approximations in the
%  ellipsoidal formulation cause it to be appropriate only within a zone
%  that extends 3 or 4 degrees in longitude on either side of the
%  central meridian.
%
%  This is a projection onto a cylinder tangent at the central
%  meridian.  Distortion of both shape and area are functions of distance
%  from the central meridian.  Scale is true along the central meridian
%  and along any straight line perpendicular to the central meridian
%  (i.e., it is equidistant).
%
%  This projection is the transverse aspect of the Plate Carree projection,
%  developed by Cesar Francois Cassini de Thury (1714-84).  It is still
%  used for the topographic mapping of a few countries.

% Copyright 2006-2011 The MathWorks, Inc.

% Reference
% ---------
% Snyder, John P., Map Projections -- A Working Manual, U.S. Geological
% Survey Professional Paper 1395, United States Government Printing
% Office, Washington, 1987, pp. 92-95.

mproj.default = @cassinistdDefault;
mproj.forward = @cassinistdFwd;
mproj.inverse = @cassinistdInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Tran';

% Only the 'normal' aspect is supported, because the projection is
% intrinsically transverse.
if nargin > 1
    mstruct = varargin{1};
    if ~strcmp(mstruct.aspect,'normal')
        warning(message('map:projections:ignoringNonNormalAspect', ...
            'Cassini'))
        varargin{1} = mstruct;
    end
end
varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = cassinistdDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-80 80], [-20 20]);
mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
mstruct.scalefactor  = 1;
mstruct.aspect = 'normal';

%--------------------------------------------------------------------------

function [x, y] = cassinistdFwd(mstruct, phi, lambda)

[a, e] = ellipsoidprops(mstruct);
if e == 0
    % Spherical form
    phi0 = toRadians(mstruct.angleunits, mstruct.origin(1));
    R = a;
    B = cos(phi) .* sin(lambda);
    
    x = R .* asin(B);
    y = R .* (atan(tan(phi)./cos(lambda)) - phi0);
else
    % Ellipsoid form
    e2 = e^2;
    phi0 = toRadians(mstruct.angleunits, mstruct.origin(1));
    
    N = a ./ sqrt(1 - (e * sin(phi)).^2);
    T = tan(phi).^2;
    A = lambda .* cos(phi);
    C = e2 * cos(phi).^2 / (1 - e2);

    % Expand the following as polynomials in A^2 using Horner's rule
    %
    %   x = N .* (A - (T.*A.^3)/6 - (8 - T + 8*C).*(T*A.^5)/120)
    %   y = M - M0 + N .* tan(phi) .* (A.^2/2 + (5 - T + 6*C).*(A.^4)/24)

    A2 = A .^ 2;
    dM = meridianarc(phi0, phi, [a e]);   % M - M0

    x = N .* A .* (1 - A2 .* T .* (1/6 - A2 .* (8 - T + 8*C)/120));
    y = dM + N .* tan(phi) .* A2 .* (1/2 + A2 .* (5 - T + 6*C)/24);
end

%--------------------------------------------------------------------------

function [phi, lambda] = cassinistdInv(mstruct, x, y)

[a, e] = ellipsoidprops(mstruct);
if e == 0
    % Spherical form
    phi0 = toRadians(mstruct.angleunits, mstruct.origin(1));
    R = a;
    D = y/R + phi0;
    
    phi = asin(sin(D) .* cos(x/R));
    lambda = atan(tan(x/R) ./ cos(D));
else
    % Ellipsoidal form
    e2 = e^2;
    phi0 = toRadians(mstruct.angleunits, mstruct.origin(1));

    % mu1 = M1 / (a * (1 - (1/4) * e^2 - 3/64 * e^4 - (5/256) * e^6 - ...));
    %
    %   M1 = M0 + y
    %   M0 = meridianarc(0, phi0, [a e])
    %   Mp = meridianarc(0, pi/2, [a e])
    %      = (a * (1 - (1/4) * e^2 - 3/64 * e^4 - (5/256) * e^6 - ...) * (pi/2)
    %   mu1 = M1 / (Mp / (pi/2))
    %       = (pi/2) * (M1/Mp)
    %       = (pi/2) * (M0 + y) / Mp;

    mu1 = (pi/2) * (meridianarc(0, phi0, [a e]) + y) ...
        / meridianarc(0, pi/2, [a e]);

    % Note: e1 is not needed since convertlat computes it for itself.
    %   e1 = (1 - sqrt(1 - e2)) / (1 + sqrt(1 - e2));

    phi1 = convertlat([a e], mu1, 'rectifying', 'geodetic', 'nocheck');

    T1 = tan(phi1).^2;
    N1 = a ./ sqrt(1 - (e * sin(phi1)).^2);
    % R1 = a * (1 - e2) ./ ((1 - (e * sin(phi1)).^2).^(3/2)
    R1 = (1 - e2) * ( N1.^3) / a^2;
    D = x ./ N1;
    D2 = D.^2;

    % Expand the following as polynomials in D^2 using Horner's rule
    %
    %   phi = phi1 - (N1 .* tan(phi1) ./ R1) ...
    %                    .* (D.^2/2 - (1 + 3*T1).*D^4/24)
    %
    %   lambda = lambda0 + ...
    %       (D - T1.*D^3/3 + (1 + 3*T1).*T1.*D^5/15)/cos(phi1)

    phi = phi1 - (N1 .* tan(phi1) ./ R1) ...
        .* D2 .* (1/2 - D2 .* (1 + 3*T1)/24);

    lambda...
        = D .* (1 - D2 .* T1 * (1/3 + D2 .* (1 + 3*T1)/15)) / cos(phi1);
end
