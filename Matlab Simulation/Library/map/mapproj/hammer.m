function varargout = hammer(varargin)
%HAMMER Hammer Modified Azimuthal Projection
%
% This projection is equal-area.  The world is displayed as an ellipse,
% with curved parallels and meridians.  It is neither conformal nor equal
% area. The only point free of distortion is the center point.  Distortion
% of shape and area are moderate throughout.
% 
% This projection was presented by H.H. Ernst von Hammer in 1892.  It is a 
% modification of the Lambert azimuthal equal area projection.  Inspired by 
% Aitoff projection, it is also known as the Hammer-Aitoff.  It in turn 
% inspired the Briesemeister, a modified oblique Hammer projection.  John 
% Bartholomew's Nordic projection is an oblique Hammer centered on 45
% degrees north and the Greenwich meridian.  The Hammer projection is used
% in whole-world maps and astronomical maps in galactic coordinates.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @hammerDefault;
mproj.forward = @hammerFwd;
mproj.inverse = @hammerInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Mazi';

if nargin > 1
    mstruct = varargin{1};

    % Special override:  "The forward and inverse formulas are not
    % consistent [in the ellipsoidal case].  Until the difference can be
    % resolved, HAMMER and BRIES will ignore the elliptical component of
    % the [ellipsoid] vector."
    [a,~] = ellipsoidprops(mstruct);
    mstruct.geoid = [a 0];

    % Eliminate singularities in transformations at ? 90 origin.
    epsilon = epsm('radians');
    if abs(abs(mstruct.origin(1)) - pi/2) <= epsilon
        mstruct.origin(1) = sign(mstruct.origin(1))*(pi/2 - epsilon);
    end

    varargin{1} = mstruct;
end

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = hammerDefault(mstruct)

% The trimlon values below are pulled in by eps(180) to keep
% diff(trimlon) < 360, which ensures that subfunction adjustFrameLimits
% in private/resetmstruct.m will clamp the frame longitude limit to
% trimlon.  That's appropriate for this special projection that is
% intended to display the entire earth.  If the FLonLimit interval is
% not forced to be a subset of [-180 180], the projection may not be
% one-to-one.  Near one limit or the other, two different points
% (in the geographic system) could project to the same point in the map
% plane, resulting in a map that appears to fold back onto itself.

[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits,...
        [-90  90], [-180 + eps(180), 180 - eps(180)], dm2degrees([40 44]));

mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = hammerFwd(mstruct, lat, lon)

[~,~,radius] = ellipsoidpropsAuthalic(mstruct);

% Back off of the +/- 90 degree points.  This allows
% the differentiation of longitudes at the poles of the transformed
% coordinate system.

epsilon = epsm('radians');
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

%  Perform the projection calculations

w = 0.5;
d = 2./(1 + cos(lat) .* cos(w*lon));
d = reshape(d,size(lat));

x = radius * sqrt(d)/w .* cos(lat) .* sin(w*lon);
y = radius * sqrt(d) .* sin(lat);

%--------------------------------------------------------------------------

function [lat, lon] = hammerInv(mstruct, x, y)

[a, e, radius] = ellipsoidpropsAuthalic(mstruct);
m1 = cos(mstruct.origin(1))/sqrt(1-(e*sin(mstruct.origin(1)))^2);
D = a * m1 / (radius * cos(mstruct.origin(1)));

x = x/2;
rho = hypot(x/D, D*y);

indx = find(rho ~= 0);

lat = x;
lon = y;

if ~isempty(indx)
    ce  = 2*asin(rho(indx)/(2*radius));
    lat(indx)  = asin(D*y(indx).*sin(ce)./rho(indx));
    lon(indx) = atan2(x(indx).*sin(ce), D*rho(indx).*cos(ce));
end
lon = 2*lon;
