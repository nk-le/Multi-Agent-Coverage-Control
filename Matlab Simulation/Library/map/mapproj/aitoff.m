function varargout = aitoff(varargin)
%AITOFF Aitoff Modified Azimuthal Projection
%
% This is a modified azimuthal projection.  The world is displayed as an 
% ellipse, with curved parallels and meridians.  It is neither conformal
% nor equal area.  The only point free of distortion is the center point.  
% Distortion of shape and area are moderate throughout.
% 
% This projection was created by David Aitoff in 1889.  It is a
% modification of the azimuthal equidistant projection.  The Aitoff
% projection inspired the similar Hammer projection, which is equal area.
% 
% This projection is available for the sphere only.

% Copyright 1996-2015 The MathWorks, Inc.

mproj.default = @aitoffDefault;
mproj.forward = @aitoffFwd;
mproj.inverse = @aitoffInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Mazi';

% Special overrides
if nargin > 1
    mstruct = varargin{1};

    % Eliminate singularities in transformations at ? 90 origin.
    epsilon = epsm('radians');
    if abs(abs(mstruct.origin(1)) - pi/2) <= epsilon
        mstruct.origin(1) = sign(mstruct.origin(1))*(pi/2 - epsilon);
    end
    
    varargin{1} = mstruct;
end

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = aitoffDefault(mstruct)

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
mstruct.nparallels  = 0;
mstruct.fixedorient = [];

%--------------------------------------------------------------------------

function [x, y] = aitoffFwd(mstruct, lat, lon)

%  Back off of the +/- 90 degree points.  This allows
%  the differentiation of longitudes at the poles of the transformed
%  coordinate system.

epsilon = deg2rad(0.01);
indx = find(abs(pi/2 - abs(lat)) <= epsilon);
if ~isempty(indx)
    lat(indx) = (pi/2 - epsilon) * sign(lat(indx));
end

%  Perform the projection calculations

d = acos(cos(lat) .* cos(lon/2));

zeroindx = find(d==0);   % to avoid divide by zeros
d(zeroindx) = pi/2;      % correct the x and y coordinates below

c = sin(lat) ./ sin(d);

radius = ellipsoidprops(mstruct);
x = radius * 2 * d .* sqrt(1 - c .* c) .* sign(lon);
y = radius * d .* c;

x(zeroindx) = 0;
y(zeroindx) = 0;

%--------------------------------------------------------------------------

function [lat, lon] = aitoffInv(mstruct, x, y)

% Inverse projection: Compute the range and azimuth and 
% reckon the points
	
x = x/2;
rng = hypot(x,y);
az  = atan2(x,y);

radius = ellipsoidprops(mstruct);
[lat,lon] = reckon('gc',0,0,rng,az,[radius 0],'radians');

lon = 2*lon;

% Reset the +/- 90 degree points.  Account for trig round-off
% by expanding epsilon to 1.01*epsilon

epsilon = deg2rad(0.01);
indx = find(abs(pi/2 - abs(lat)) <= 1.01*epsilon);
if ~isempty(indx)
    lat(indx) = pi/2 * sign(lat(indx));
end
