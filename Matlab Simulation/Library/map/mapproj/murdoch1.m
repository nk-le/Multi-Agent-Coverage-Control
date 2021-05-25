function varargout = murdoch1(varargin)
%MURDOCH1  Murdoch I Conic Projection
%
%  This is an equidistant projection which is nearly minimum-error.  Scale
%  is true along any meridian and is constant along any parallel.  Scale is
%  also true along two standard parallels, which must calculated from the
%  input limiting parallels.  The total area of the mapped area is correct,
%  but it is not equal area everywhere.
%
%  This was first described by Patrick Murdoch in 1758.
%
%  This projection is available only on the sphere.  Longitude
%  data greater than 135 degrees east or west of the central meridian is
%  trimmed.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @murdoch1Default;
mproj.forward = @murdoch1Fwd;
mproj.inverse = @murdoch1Inv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Coni';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = murdoch1Default(mstruct)

% Put standard parallels at 1/6th and 5/6th of the northern hemisphere
mstruct.nparallels   = 2;
mstruct.fixedorient  = [];
[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-135 135], [15 75]);

%--------------------------------------------------------------------------

function [x, y] = murdoch1Fwd(mstruct, lat, lon)

[a, m, n] = deriveParameters(mstruct);

lat = pi/2 - lat; % Compute co-lats
r = m + lat;
theta = n * lon;
x =  a * r .* sin(theta);
y = -a * r .* cos(theta);

%--------------------------------------------------------------------------

function [lat, lon] = murdoch1Inv(mstruct, x, y)

[a, m, n] = deriveParameters(mstruct);

lon = atan2(x,-y) / n;
lat = pi/2 - hypot(x,y)/a + m;

%--------------------------------------------------------------------------

function [a, m, n] = deriveParameters(mstruct)

a = ellipsoidprops(mstruct);

parallels = toRadians(mstruct.angleunits, mstruct.mapparallels);
epsilon = epsm('radians');

%  Adjust for equal parallels, or parallels at each pole
if length(parallels) == 1
    parallels = [parallels parallels];
end
if abs(diff(parallels)) <= epsilon
    parallels(1) = parallels(1) + epsilon;
end
if abs(abs(diff(parallels)) - pi) <= epsilon
     parallels = [min(parallels)+epsilon max(epsilon)];
end

%  Compute the projection parameters
parallels = sort(parallels);   %  Parallels of form:  [South  North]
add = sum(parallels)/2;
sub = -diff(parallels)/2;      %  Want:  South - North parallel

n = cos(add);
m = tan(add) * (sin(sub)/sub - add);
