function varargout = vgrint1(varargin)
%VGRINT1  Van Der Grinten I Polyconic Projection
%
%  In this projection, the world is enclosed in a circle.  Scale is true
%  along the Equator and increases rapidly away from the Equator. Area
%  distortion is extreme near the poles.  This projection is neither
%  conformal nor equal area.
%
%  This projection was presented by Alphons J. van der Grinten 1898. He
%  obtained a U.S. patent for it in 1904.  It is also known simply as the
%  Van der Grinten projection (without a "I").

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @vgrint1Default;
mproj.forward = @vgrint1Fwd;
mproj.inverse = @vgrint1Inv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Poly';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = vgrint1Default(mstruct)

% The trimlon values below are pulled in by eps(180) to keep
% diff(trimlon) < 360, which ensures that subfunction adjustFrameLimits
% in private/resetmstruct.m will clamp the frame longitude limit to
% trimlon.  That's appropriate for this special projection that is
% intended to display the entire earth.  If the FLonLimit interval is
% not forced to be a subset of [-180 180], the projection may not be
% one-to-one.  Near one limit or the other, two different points
% (in the geographic system) could project to the same point in the map
% plane, resulting in a map that appears to fold back onto itself.

mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];
[mstruct.trimlat, mstruct.trimlon] = fromDegrees( ...
    mstruct.angleunits, [-90 90], [-180 + eps(180), 180 - eps(180)]);

%--------------------------------------------------------------------------

function [x, y] = vgrint1Fwd(mstruct, lat, lon)

epsilon = 10*epsm('radians');
a = ellipsoidprops(mstruct);

% Back off of the +/- 90 degree points.  This allows
% the differentiation of longitudes at the poles of the transformed
% coordinate system.

indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

% Pick up NaN place holders

x = lon;
y = lat;

% Compute the projection parameter theta

theta = asin(2*abs(lat)/pi);

% Process 0 latitude and longitude separately

indx1 = find(abs(lon) <= epsilon);
indx2 = find(abs(lat) <= epsilon);
indx3 = find(abs(lat) > epsilon & abs(lon) > epsilon);

% Points at zero longitude

if ~isempty(indx1)
    x(indx1) = 0;
    y(indx1) = tan(theta(indx1)/2);
end

% Points at zero latitude

if ~isempty(indx2)
    x(indx2) = abs(lon(indx2))/pi;
    y(indx2) = 0;
end

% Points at non-zero longitude and non-zero latitude

if ~isempty(indx3)
    theta0 = theta(indx3);   lon0 = lon(indx3);
    A = abs( pi./lon0 - lon0/pi) / 2;
    G = cos(theta0) ./ (sin(theta0) + cos(theta0) - 1);
    P = G .* (2./sin(theta0) - 1);
    Q = A.^2 + G;

    fact1 = A .* (G - P.^2);
    fact2 = P.^2 + A.^2;
    fact3 = fact1 + sqrt( fact1.^2  - fact2.*(G.^2 - P.^2));
    fact4 = P.*Q - A.*sqrt((A.^2 + 1).*fact2 - Q.^2);

    x(indx3) = fact3 ./ fact2;
    y(indx3) = fact4 ./ fact2;
end

% Final calcs

x = a * pi * sign(lon) .* x;
y = a * pi * sign(lat) .* y;

%--------------------------------------------------------------------------

function [lat, lon] = vgrint1Inv(mstruct, x, y)

a = ellipsoidprops(mstruct);

% Normalize by the radius

x = x / (pi*a);
y = y / (pi*a);

% Pick up NaN place holders and points at (0,0)

lon = x;
lat = y;

% Process points not at (0,0)

indx1 = find(x ~= 0 | y ~= 0);
indx2 = find(x ~= 0);

% Inverse transformation

if ~isempty(indx1)

    fact1 = x(indx1).^2 + y(indx1).^2;
    c1 = -abs(y(indx1)) .* (1 + fact1);
    c2 = c1 - 2* y(indx1).^2 + x(indx1).^2;
    c3 = -2*c1 + 1 + 2* y(indx1).^2 + fact1.^2;

    d = y(indx1).^2 ./ c3 + (2*c2.^3./c3.^3 - 9*c1.*c2./c3.^2)/27;
    a1 = (c1 - c2.^2./(3*c3))./c3;
    m1 = 2*sqrt(-a1/3);
    cos_theta1_times3 = 3*d ./ (a1.*m1);
    % Correct for possible round off/noise
    cos_theta1_times3(cos_theta1_times3 < -1) = -1;
    cos_theta1_times3(cos_theta1_times3 >  1) =  1;
    theta1 = acos(cos_theta1_times3)/3;
    lat(indx1) = pi * sign(y(indx1)) .* ...
        (-m1.*cos(theta1+pi/3)-c2./(3*c3));

    % Points at non-zero longitude

    if ~isempty(indx2)
        c1 = x(indx2).^2 + y(indx2).^2;
        c2 = x(indx2).^2 - y(indx2).^2;
        c3 = (c1 - 1 + sqrt(1 + 2*c2 + c1.^2));
        lon(indx2) = pi * c3 ./ (2*x(indx2));
    end
end
