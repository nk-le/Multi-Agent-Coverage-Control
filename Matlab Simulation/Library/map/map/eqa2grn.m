function [lat,lon] = eqa2grn(x,y,origin,ellipsoid,units)
%EQA2GRN  Convert from equal area to Greenwich coordinates
%
%   [LAT,LON] = EQA2GRN(X,Y) transforms from equal area cylindrical
%   coordinates to Greenwich latitude and longitude coordinates. The
%   transformation assumes that the origin of the cylindrical coordinate
%   plane is at (LAT,LON) = (0,0).  The outputs are returned in degrees.
%
%   [LAT,LON] = EQA2GRN(X,Y,ORIGIN) assumes that the origin of the
%   cylindrical coordinate plate is given by the input ORIGIN. This input
%   is of the form [LAT0,LON0] where LAT0 and LON0 are in degrees.
%
%   [LAT,LON] = EQA2GRN(X,Y,ORIGIN,ELLIPSOID) assumes that the data is
%   distributed on the ellipsoid defined by the input ELLIPSOID. ELLIPSOID
%   is a reference ellipsoid (oblate spheroid) object, a reference sphere
%   object, or a vector of the form [semimajor_axis, eccentricity]. If
%   omitted, the unit sphere, ELLIPSOID = [1 0], is assumed.
%
%   [LAT,LON] = EQA2GRN(X,Y,ORIGIN,ANGLEUNITS) and
%   [LAT,LON] = EQA2GRN(X,Y,ORIGIN,ELLIPSOID,ANGLEUNITS) use ANGLEUNITS to
%   specify the angle units of the inputs and outputs. ANGLEUNITS can be
%   'degrees' or 'radians'.
%
%   MAT = EQA2GRN(...) returns a single output such that MAT = [LAT LON].
%
%   See also GRN2EQA.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(2, 5)

if nargin > 3
    ellipsoid = convertStringsToChars(ellipsoid);
end

if nargin > 4
    units = convertStringsToChars(units);
end

if nargin == 2
    origin = [];
    units = [];
    ellipsoid = [];
elseif nargin == 3
    units = [];
    ellipsoid= [];
elseif nargin == 4 && ischar(ellipsoid)
    units = ellipsoid;
    ellipsoid = [];
elseif nargin == 4 && ~ischar(ellipsoid)
    units = [];
end

if isempty(units)
    units  = 'degrees';
end

if isempty(ellipsoid)
    ellipsoid  = [1 0];
else
    ellipsoid = checkellipsoid(ellipsoid,'EQA2GRN','ELLIPSOID',4);
end

if isempty(origin)
    origin = [0 0 0];
end

if ~isequal(size(x),size(y))
    error(message('map:validate:inconsistentSizes2','EQA2GRN','X','Y'))
end

%  Transform the location to an equal area coordinate frame
[lat0,lon0] = eqacalc(x,y,origin,'inverse',units,ellipsoid);

%  Set the output arguments
if nargout <= 1
    lat = [lat0 lon0];  
else
    lat = lat0;
    lon = lon0;
end
