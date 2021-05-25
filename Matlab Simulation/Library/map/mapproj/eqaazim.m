function varargout = eqaazim(varargin)
%EQAAZIM  Lambert Equal Area Azimuthal Projection
%
%  This non-perspective projection is equal area.  Only the center point is
%  free of distortion, but distortion is moderate within 90 degrees of this
%  point.  Scale is true only at the center point, increasing tangentially
%  and decreasing radially with distance from the center point.  This
%  projection is neither conformal nor equidistant.
%
%  This projection was presented by Johann Heinrich Lambert in 1772. It is
%  also know as the Zenithal Equal Area and the Zenithal Equivalent
%  projections, and the Lorgna projection in its polar aspect.

% Copyright 1996-2013 The MathWorks, Inc.

mproj.default = @eqaazimDefault;
mproj.forward = @eqaazimFwd;
mproj.inverse = @eqaazimInv;
mproj.auxiliaryLatitudeType = 'authalic';
mproj.classCode = 'Azim';

varargout = applyAzimuthalProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function outputs = applyAzimuthalProjection(mproj, varargin)

n = numel(varargin);
if n == 1
    outputs{1} = mproj.default(varargin{1});
elseif n == 5 || n == 6 || n == 7
    mproj.applyForward = @applyForward;
    mproj.applyInverse = @applyInverse;
    outputs = doApplyProj(mproj, varargin{:});
else
    error(message('map:validate:invalidArgCount'))
end

%--------------------------------------------------------------------------

function [x, y, savepts] = applyForward(mproj, mstruct, lat, lon, objectType)

[a, e] = ellipsoidprops(mstruct);

% Convert origin to radians & auxiliary sphere
origin = convertOrigin(mproj, mstruct);

% Radius for trimming
maxRange = flatlimitToRadius(mstruct, mproj.auxiliaryLatitudeType);

% Convert input coordinates to radians
[lat, lon] = toRadians(mstruct.angleunits, real(lat), real(lon));
        
% Convert to auxiliary latitude
lat = convertlat([a e], lat, 'geodetic', 'authalic', 'nocheck');

% Convert lat-lon to range-azimuth and trim data
newTrimming = strcmp(objectType,'notrim') || strncmp(objectType, 'geo', 3);
if newTrimming
    % Convert to auxiliary latitude
    lat = convertlat([a e], lat, 'geodetic', 'authalic', 'nocheck');
    
    % Rotate before trimming
    [lat, lon] = rotatePureTriax(lat, lon, origin, 'forward');
    
    % Trim to maxRange (skip savepts)
    switch(objectType)
        case {'geopoint','geomultipoint'}
            rng = distance('gc', 0, 0, lat, lon, 'radians');
            needsTrim = (rng > maxRange);
            lat(needsTrim) = [];
            lon(needsTrim) = [];
            
        case 'geoline'
            [rng, az] = distance('gc', 0, 0, lat, lon, 'radians');
            [rng, az] = trimPolylineToCircle(rng, az, maxRange);
            [lat, lon] = reckon(0, 0, rng, az, 'radians');
            
        case 'geopolygon'
            inc = 2.0*pi/180;
            [lat, lon] = trimPolygonToSmallCircle( ...
                lat, lon, 0, 0, maxRange, inc);
            
        case 'geosurface'
            % Ranges and azimuths on rotated auxiliary sphere
            [rng, az] = distance('gc', 0, 0, lat, lon, 'radians');
            
            % Trim data exceeding specified range from the origin
            [~,~,trimmed] = trimdata( ...
                rng, [-inf maxRange], az, [-inf inf], 'surface');
            [~, indx] = addLatLonToTrimList(trimmed, lat, lon);
            lat(indx) = NaN;
            lon(indx) = NaN;
            
        otherwise
            % notrim -- nothing to do in this case
    end
    savepts.trimmed = [];
    savepts.clipped = [];
else
    % Back off at +/- 180 degrees
    epsilon = 5*epsm('radians');
    lon = backOffAtPi(lon, epsilon);
    
    % Ranges and azimuths on rotated auxiliary sphere
    [lat, lon] = rotatemRadians(lat, lon, origin, 'forward');
    [rng, az] = distance('gc', 0, 0, lat, lon, 'radians');
    
    % Trim data exceeding specified range from the origin,
    % save structure of altered points
    [~,~,trimmed] = trimdata( ...
        rng, [-inf maxRange], az, [-inf inf], objectType);
    [trimmed, indx] = addLatLonToTrimList(trimmed, lat, lon);
    lat(indx) = NaN;
    lon(indx) = NaN;
    savepts.trimmed = trimmed;
    savepts.clipped = [];
end

% Project
[x, y] = mproj.forward(mstruct, lat, lon);
[x, y] = applyScaleAndOriginShift(mstruct, x, y);

%--------------------------------------------------------------------------

function [lat, lon, savepts] = applyInverse( ...
    mproj, mstruct, x, y, objectType, savepts)

% Undo projection
[x, y] = undoScaleAndOriginShift(mstruct, x, y);
[lat, lon] = mproj.inverse(mstruct, x, y);

% Undo trimming
[lat, lon] = undotrim(lat, lon, savepts.trimmed, objectType);

% Undo rotation and restore geodetic latitude
origin = convertOrigin(mproj, mstruct);
[lat,lon] = rotatemRadians(lat, lon, origin, 'inverse');
[a, e] = ellipsoidprops(mstruct);
lat = convertlat([a e], lat, 'authalic', 'geodetic', 'nocheck');

% Restore angle units
[lat, lon] = fromRadians(mstruct.angleunits, lat, lon);

%--------------------------------------------------------------------------

function origin = convertOrigin(~, mstruct)
% Convert origin to radians & auxiliary sphere

origin = toRadians(mstruct.angleunits, mstruct.origin);

%  Avoid singularities if origin is near a pole
epsilon = epsm('radians');
if abs(abs(origin(1)) - pi/2) <= epsilon
      origin(1) = sign(origin(1))*(pi/2 - epsilon);
end

%  Adjust origin and trimming latitudes to auxiliary sphere
[a, e] = ellipsoidprops(mstruct);
origin(1) = convertlat([a e], origin(1), 'geodetic', 'authalic', 'nocheck');

%--------------------------------------------------------------------------

function mstruct = eqaazimDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-Inf 179.5], [-180 180]);
mstruct.flatlimit = [-Inf 160];
mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eqaazimFwd(mstruct, lat, lon)

[radius, D] = deriveParameters(mstruct);
B = radius * sqrt(2 ./ (1 + cos(lat) .* cos(lon)));

x = B * D .* cos(lat) .* sin(lon);
y = (B/D) .* sin(lat);

%--------------------------------------------------------------------------

function [lat, lon] = eqaazimInv(mstruct, x, y)

[radius, D] = deriveParameters(mstruct);

rho = hypot(x/D, D*y);

indx = find(rho ~= 0);

lat = zeros(size(x));
lon = zeros(size(x));
if ~isempty(indx)
    ce  = 2 * asin(rho(indx) / (2*radius));
    lat(indx) = asin(D * y(indx) .* sin(ce) ./ rho(indx));
    lon(indx) = atan2(x(indx).*sin(ce), D*rho(indx).*cos(ce));
end

%--------------------------------------------------------------------------

function [radius, D] = deriveParameters(mstruct)

[a, e, radius] = ellipsoidpropsAuthalic(mstruct);
phi0 = toRadians(mstruct.angleunits, mstruct.origin(1));

%  Eliminate singularities if origin is near a pole
epsilon = epsm('radians');
if abs(abs(phi0) - pi/2) <= epsilon
    phi0 = sign(phi0) * (pi/2 - epsilon);
end

m1 = cos(phi0)/sqrt(1 - (e*sin(phi0))^2);

%  Adjust the origin latitude to the auxiliary sphere
beta0 = convertlat([a e], phi0, 'geodetic', 'authalic', 'nocheck');

%  Another projection parameter (which needs the authalic origin)
D = a * m1 / (radius * cos(beta0));
