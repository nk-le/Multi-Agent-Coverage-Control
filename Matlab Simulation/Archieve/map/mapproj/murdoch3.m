function varargout = murdoch3(varargin)
%MURDOCH3  Murdoch III Minimum Error Conic Projection
%
%  This is an equidistant projection which is minimum-error.  Scale is true
%  along any meridian and is constant along any parallel.  Scale is also
%  true along two standard parallels, which must calculated from the input
%  limiting parallels.  The total area of the mapped area is correct, but
%  it is not equal area everywhere.
%
%  This was first described by Patrick Murdoch in 1758, with errors only
%  corrected by Everett in 1904.
%
%  This projection is available only on the sphere.  Points at longitudes
%  greater than 135 degrees east or west of the central meridian are
%  trimmed.

% Copyright 1996-2011 The MathWorks, Inc.

mproj.default = @murdoch3Default;
mproj.forward = @murdoch3Fwd;
mproj.inverse = @murdoch3Inv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Coni';

varargout = applyProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function mstruct = murdoch3Default(mstruct)

% Put standard parallels at 1/6th and 5/6th of the northern hemisphere
mstruct.nparallels = 2;
mstruct.fixedorient = [];
[mstruct.trimlat, mstruct.trimlon, mstruct.mapparallels] ...
    = fromDegrees(mstruct.angleunits, [-90 90], [-135 135], [15 75]);

%--------------------------------------------------------------------------

function [x, y] = murdoch3Fwd(mstruct, lat, lon)

[a, m, n] = deriveParameters(mstruct);

lat = pi/2 - lat; % Compute co-lats
r = m + lat;
theta = n * lon;
x =  a * r .* sin(theta);
y = -a * r .* cos(theta);

%--------------------------------------------------------------------------

function [lat, lon] = murdoch3Inv(mstruct, x, y)

[a, m, n] = deriveParameters(mstruct);

lon = atan2(x,-y) / n;
lat = pi/2 - hypot(x,y)/a + m;

%--------------------------------------------------------------------------

function [a, m, n] = deriveParameters(mstruct)

a = ellipsoidprops(mstruct);
parallels = toRadians(mstruct.angleunits, mstruct.mapparallels);

%  Adjust for equal parallels, or parallels at each pole
epsilon = epsm('radians');
if length(parallels) == 1
    parallels = [parallels parallels];
end
if any( abs([diff(parallels) sum(parallels)]) <= epsilon )
     parallels(1) = parallels(1) + epsilon;
end
if abs(abs(diff(parallels)) - pi) <= epsilon
     parallels = [min(parallels)+epsilon max(epsilon)];
end

%  Compute the projection parameters
parallels = sort(parallels);   %  Parallels of form:  [South  North]
add = sum(parallels)/2;
sub = -diff(parallels)/2;      %  Want:  South - North parallel

m = tan(add) * (sub*cot(sub));
n = sin(sub)/sub * sin(add)/(m+add);
