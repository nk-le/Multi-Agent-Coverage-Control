function [x,y] = grn2eqa(lat,lon,origin,ellipsoid,units)
%GRN2EQA  Convert from Greenwich to equal area coordinates
%
%   [X,Y] = GRN2EQA(LAT,LON) transforms from Greenwich latitude and
%   longitude coordinates to equal area cylindrical coordinates. The
%   transformation assumes that the origin of the cylindrical coordinate
%   plane is at (LAT,LON) = (0,0).  The inputs are in degrees.
%
%   [X,Y] = GRN2EQA(LAT,LON,ORIGIN) assumes that the origin of the
%   cylindrical coordinate plate is given by the input ORIGIN. This input
%   is of the form [LAT0,LON0] where LAT0 and LON0 are in degrees.
%
%   [X,Y] = GRN2EQA(LAT,LON,ORIGIN,ELLIPSOID) assumes that the data is
%   distributed on the ellipsoid defined by the input ELLIPSOID. ELLIPSOID
%   is a reference ellipsoid (oblate spheroid) object, a reference sphere
%   object, or a vector of the form [semimajor_axis, eccentricity]. If
%   omitted, the unit sphere, ELLIPSOID = [1 0], is assumed.
%
%   [X,Y] = GRN2EQA(LAT,LON,ORIGIN,ANGLEUNITS) and
%   [X,Y] = GRN2EQA(LAT,LON,ORIGIN,ELLIPSOID,ANGLEUNITS) use ANGLEUNITS 
%   to specify the angle units of the inputs and outputs.
%   ANGLEUNITS can be 'degrees' or 'radians'.
%
%   MAT = GRN2EQA(...) returns a single output such that MAT = [X Y].
%
%  See also EQA2GRN.

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
    ellipsoid = checkellipsoid(ellipsoid,'GRN2EQA','ELLIPSOID',4);
end

if isempty(origin)
    origin = [0 0 0];
end

if ~isequal(size(lat),size(lon))
    error(message('map:validate:inconsistentSizes2','GRN2EQA','LAT','LON'))
end

%  Transform the location to an equal area coordinate frame
[x0,y0] = eqacalc(lat,lon,origin,'forward',units,ellipsoid);

%  Set the output arguments
if nargout <= 1
    x = [x0 y0];
else
    x = x0;
    y = y0;
end
