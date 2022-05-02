function varargout = eqdazim(varargin)
%EQDAZIM  Equidistant Azimuthal Projection
%
%  This is an equidistant projection.  It is neither equal-area nor conformal.
%  In the polar aspect, scale is true along any meridian.  The projection is
%  distortion free only at the center point.  Distortion is moderate for the
%  inner hemisphere, but it becomes extreme in the outer hemisphere.
%
%  This projection may have been first used by the ancient Egyptians for star
%  charts.  Several cartographers used it during the sixteenth century,
%  including Guillaume Postel, who used it in 1581.  Other names for this
%  projections include Postel and Zenithal Equidistant.
%
%  This projection is available only on the sphere.

% Copyright 1996-2015 The MathWorks, Inc.

mproj.default = @eqdazimDefault;
mproj.forward = @eqdazimFwd;
% mproj.inverse = @eqdazimInv;
mproj.auxiliaryLatitudeType = 'geodetic';
mproj.classCode = 'Azim';

varargout = applyAzimuthalProjection(mproj, varargin{:});

%--------------------------------------------------------------------------

function outputs = applyAzimuthalProjection(mproj, varargin)

n = numel(varargin);
if n == 1
    outputs{1} = mproj.default(varargin{1});
elseif n == 5 || n == 6  || n == 7
    mproj.applyForward = @applyForward;
    mproj.applyInverse = @applyInverse;
    outputs = doApplyProj(mproj, varargin{:});
else
    error(message('map:validate:invalidArgCount'))
end

%--------------------------------------------------------------------------

function [x, y, savepts] = applyForward(mproj, mstruct, lat, lon, objectType)

% Convert origin and frame latitude limits to radians
[origin, flatlimit] = ...
    toRadians(mstruct.angleunits, mstruct.origin, mstruct.flatlimit);

% The maximum range (radius of circle to trim to) is encoded in flatlimit
% (usually as the second element).
maxRange = max(flatlimit);

% Convert to radians
[lat, lon] = toRadians(mstruct.angleunits, real(lat), real(lon));

newTrimming = strcmp(objectType,'notrim') || strncmp(objectType, 'geo', 3);
if newTrimming
    % Trim to maxRange (skip savepts)
    lat0 = origin(1);
    lon0 = origin(2);
    radius = ellipsoidprops(mstruct);
    switch(objectType)
        case {'geopoint','geomultipoint'}
            [rng, az] = latlon2rngaz(lat, lon, lat0, lon0);
            needsTrim = (rng > maxRange);
            az( needsTrim) = [];
            rng(needsTrim) = [];
            lon(needsTrim) = [];
            
        case 'geoline'
            [rng, az] = latlon2rngaz(lat, lon, lat0, lon0);
            [rng, az] = trimPolylineToCircle(rng, az, maxRange);
            [~, lon] = rngaz2latlon(rng, az, lat0, lon0);
            
        case 'geopolygon'
            inc = 2.0*pi/180;
            [lat, lon] = trimPolygonToSmallCircle( ...
                lat, lon, lat0, lon0, maxRange, inc);
            [rng, az] = latlon2rngaz(lat, lon, lat0, lon0);
            
        case 'geosurface'
            % Ranges and azimuths
            lat0 = origin(1);
            lon0 = origin(2);
            [rng, az] = distance('gc', lat0, lon0, lat, lon, 'radians');
            
            % Trim data exceeding specified range from the origin
            [rng, az, ~] = trimdata( ...
                rng, [-inf maxRange], az, [-inf inf], 'surface');
            
        otherwise % 'notrim'
            [rng, az] = latlon2rngaz(lat, lon, lat0, lon0);
    end
    savepts.trimmed = [];
    savepts.clipped = [];
    rng = radius * rng;
else
    %  This projection is highly sensitive around poles and the date
    %  line.  The azimuth calculation in the inverse direction will
    %  transform -180 deg longitude into 180 deg longitude if an
    %  insufficient epsilon is supplied.  Trial and error yielded
    %  an epsilon of 0.01 degrees to back-off from the date line and
    %  the poles.
    epsilon = deg2rad(0.01);
    
    %  Back off edge points.  This must be done before the
    %  azimuth and distance calculations, since azimuth is
    %  sensitive to points near the poles and dateline.
    lon = backOffAtPi(lon, epsilon);
    lat = backOffAtPoles(lat, epsilon);
    
    % Ranges and azimuths
    radius = ellipsoidprops(mstruct);
    lat0 = origin(1);
    lon0 = origin(2);
    [rng, az] = distance('gc', lat0, lon0, lat, lon, radius, 'radians');
    
    % Trim data exceeding specified range from the origin,
    % save structure of altered points
    [rng, az, trimmed] = trimdata( ...
        rng, [-inf maxRange*radius], az, [-inf inf], objectType);
    savepts.trimmed = addLatLonToTrimList(trimmed, lat, lon);
    savepts.clipped = [];
end

% Project
[x, y] = mproj.forward(mstruct, rng, az, reshape(lon,size(rng)));
[x, y] = applyScaleAndOriginShift(mstruct, x, y);                    

%--------------------------------------------------------------------------

function [lat, lon, savepts] = applyInverse( ...
    ~, mstruct, x, y, objectType, savepts)

origin = toRadians(mstruct.angleunits, mstruct.origin);
epsilon = deg2rad(0.01);

% Undo projection
[x, y] = undoScaleAndOriginShift(mstruct, x, y);
if abs(pi/2 - abs(origin(1))) <= epsilon
    az = pi + zeros(size(x));
    lon0 = -sign(origin(1))*atan2(x,y) - pi + origin(2);
else
    az  = atan2(x,y) - origin(3);
    lon0 = origin(2) + zeros(size(x));
end
rng = hypot(x,y);
lat0 = origin(1) + zeros(size(x));
radius = ellipsoidprops(mstruct);
[lat, lon] = reckon('gc', lat0, lon0, rng, az, radius, 'radians');

% Undo trimming
[lat, lon] = undotrim(lat, lon, savepts.trimmed, objectType);

% Restore edge points
[lat, lon] = resetAtPiAndPoles(lat, lon, epsilon);

% Restore angle units
[lat, lon] = fromRadians(mstruct.angleunits, lat, lon);

%--------------------------------------------------------------------------

function mstruct = eqdazimDefault(mstruct)

[mstruct.trimlat, mstruct.trimlon] ...
    = fromDegrees(mstruct.angleunits, [-Inf 179.5], [-180 180]);
mstruct.flatlimit = [-Inf 160];
mstruct.mapparallels = [];
mstruct.nparallels   = 0;
mstruct.fixedorient  = [];

%--------------------------------------------------------------------------

function [x, y] = eqdazimFwd(mstruct, rng, az, lon)

origin = toRadians(mstruct.angleunits, mstruct.origin);

phi0    = origin(1);
lambda0 = origin(2);

epsilon = deg2rad(0.01);
if abs(pi/2 - abs(phi0)) <= epsilon
    az = -sign(phi0)*(lon + pi - lambda0);
else
    az  = az + origin(3); %  Adjust the azimuths for the orientation
end
x = rng .* sin(az);
y = rng .* cos(az);

%--------------------------------------------------------------------------

function [lat, lon] = resetAtPiAndPoles(lat, lon, epsilon)

%  Reset the +/- 180 degree points.  Account for round-off
%  by expanding epsilon to 1.02*epsilon
indx = find( abs(pi - abs(lon)) <= 1.02*epsilon);
if ~isempty(indx)
    lon(indx) = sign(lon(indx))*pi;
end

%  Reset the +/- 90 degree points.
indx = find(abs(pi/2 - abs(lat)) <= 1.02*epsilon);
if ~isempty(indx)
    lat(indx) = sign(lat(indx))*pi/2;
end

%--------------------------------------------------------------------------

function [rng, az] = latlon2rngaz(lat, lon, latCenter, lonCenter)

% Transforms latitude-longitude to range-azimuth and unwrap the
% azimuth angles.  Note special handling when the center is a pole.
if latCenter >= pi/2
    rng = pi/2 - lat;
    az = -lon;
elseif latCenter <= -pi/2
    rng = lat + pi/2;
    az  = lon;
else
    [rng, az] = distance(latCenter, lonCenter, lat, lon, 'radians');
end
az = unwrapMultipart(az);

%--------------------------------------------------------------------------

function [lat, lon] = rngaz2latlon(rng, az, latCenter, lonCenter)

% Transforms range-azimuth to latitude-longitude.
if latCenter >= pi/2
    lat = pi/2 - rng;
    lon = -az;
elseif latCenter <= -pi/2
    lat = rng - pi/2;
    lon = az;
else
    [lat, lon] = reckon(latCenter, lonCenter, rng, az, 'radians');
end
