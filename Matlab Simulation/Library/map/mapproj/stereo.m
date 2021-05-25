function varargout = stereo(varargin)
%STEREO  Stereographic Azimuthal Projection
%
%  This is a perspective projection on a plane tangent at the center
%  point from the point antipodal to the center point.  The center
%  point is a pole in the common polar aspect, but it can be any
%  point.  This projection has two significant properties.  It is
%  conformal, being free from angular distortion.  Additionally, all
%  great and small circles are either straight lines or circular
%  arcs on this projection.  Scale is true only at the center point,
%  and is constant along any circle having the center point as its
%  center.  This projection is not equal area.
%
%  The polar aspect of this projection appears to have been developed
%  by the Egyptians and Greeks by the second century B.C.

% Copyright 1996-2013 The MathWorks, Inc.

mproj.default = @stereoDefault;
mproj.forward = @stereoFwd;
mproj.inverse = @stereoInv;
mproj.auxiliaryLatitudeType = 'conformal';
mproj.classCode = 'Azim';

varargout = applyAzimuthalProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = stereoDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-Inf 179.5], [-180 180]);
mstruct.flatlimit = [-Inf 90];
mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = stereoFwd(mstruct, rng, az)

fact1 = deriveParameters(mstruct);
r = (fact1 * sin(rng)) ./ ( 1 + cos(rng) );

x = r .* sin(az);
y = r .* cos(az);

%--------------------------------------------------------------------------

function [rng, az] = stereoInv(mstruct, x, y)

fact1 = deriveParameters(mstruct);
rho = (x.^2 + y.^2) / fact1^2;

az = atan2(x, y);
rng = acos((1 - rho) ./ (1 + rho));

%--------------------------------------------------------------------------

function fact1 = deriveParameters(mstruct)
% Derive projection parameters.

[a, e] = ellipsoidprops(mstruct);
phi0 = toRadians(mstruct.angleunits, mstruct.origin(1));

if e == 0 || phi0 == 0
    % Sphere (any aspect) or ellipsoid with equatorial aspect
    fact1 = 2*a;
else
    chi0 = convertlat([a e], phi0, 'geodetic', 'conformal', 'nocheck');
    
    % As the origin of an oblique stereographic system approaches a pole
    % (and thus the oblique aspect becomes nearly polar), the expression
    % used in the oblique case for adjusting the map scale to account for
    % the flattening of an ellipsoidal earth becomes numerically unstable.
    % This happens because value of chi0 approaches pi/2, and its cosine
    % approaches zero. To address this problem, replace the scaling
    % expression with its limiting value at the pole when the difference
    % between the conformal latitude of the origin and the polar latitude,
    % measured in radians, is less than a certain value.  This cut-over
    % value below was derived empirically via numerical experiments in
    % MATLAB, and assumes an eccentricity typical of the Earth (about
    % 0.08). The approximation is worst just past the cut-over value itself,
    % where the scaling will be off by about 1 part in 10^11 (a small
    % fraction of a millimeter even for maps covering an entire hemisphere.)
    cutover = deg2rad(2^-8);
    if abs(pi/2 - abs(phi0)) > cutover
        % Oblique aspect
        fact1 = 2*a*cos(phi0) / (cos(chi0) * sqrt((1 - (e*sin(phi0))^2)));
    else
        % Polar or near-polar aspect; note that in the limit as phi0
        % approaches +/- pi/2, and chi0 approaches +/- pi/2 at a slightly
        % slower rate, the ratio cos(phi0)/cos(chi0) approaches the value:
        %
        %       ((1-e)/(1+e))^(e/2) or about 0.993
        
        fact1 = 2*a / sqrt(((1+e)^(1+e))*((1-e)^(1-e)));
    end
end
