function [out1, out2] = goodeih(direction, in1, in2)
%GOODEIH Interrupted Goode Homolosine Pseudocylindrical Projection
%
%   This is an interrupted version of Goode's Homolosine pseudocylindrical
%   projection and has the same properties, except for the fact that it is
%   interrupted at longitude 40 W in the Northern Hemisphere and longitudes
%   100 W, 20 W and 80 E in the Southern Hemisphere.
%
%   This projection was developed by J. Paul Goode in 1923.
%
%   References
%   ----------
%   Snyder, John P. and Voxland, Philip M., "An Album of Map Projections",
%   U.S. Geological Survey Professional Paper 1453 , United State
%   Government Printing Office, Washington D.C., 1989.
% 
%   Snyder, John P., "Map Projections--A Working Manual", U.S. Geological
%   Survey Professional Paper 1395 (Supersedes USGS Bulletin 1532), United
%   State Government Printing Office, Washington D.C., 1987.
% 
%   Goode, J.P., "The Homolosine projection:  a new device for portraying
%   the Earth's surface entire",  Assoc. Am. Geographers, Annals, v. 15,
%   119-125, 1925.
% 
%   Steinwand, Daniel R., "Mapping Raster Imagery to the Interrupted Goode
%   Homolosine Projection", International Journal of Remote Sensing,
%   v. 15, 3463-3471, 1994.
%
%   [X, Y] = GOODEIH('FWD', LAT, LON) returns the X and Y map coordinates
%   from the forward projection.  LAT and LON are arrays of latitude and 
%   longitude coordinates in units of degree. LON limits are [-180 180].
%
%   [LAT, LON] = GOODEIH('INV', X, Y) returns the latitude and longitude
%   coordinates from the inverse projection in units of degree. X and Y are
%   map coordinates in units of meter.
%
%   Example
%   -------
%   load coast
%   [x,y] = goodeih('fwd',lat,long);
%   figure
%   plot(x,y)
%
%   [lat2,lon2] = goodeih('inv',x,y);
%   figure
%   plot(lon2,lat2)
%
%   See also AVHRRGOODE, GOODE.

% Copyright 2007-2015 The MathWorks, Inc.

%  This code is derived from a C utility program written by:
%  D. Steinwand, HSTX/EROS Data Center June, 1993
%  and available at: 
%  ftp://edcftp.cr.usgs.gov/pub/software/misc/gihll2ls.c

if isequal(direction,'fwd')
    [out1, out2] = goodeFwd(in1,in2);
else
    [out1, out2] = goodeInv(in1,in2);
end

%--------------------------------------------------------------------------

function [x, y] = goodeFwd(lat, lon)

R = 6370997.0;
[lon_center, feast] = goode_init(R);

lat = deg2rad(lat);
lon = deg2rad(lon);
x = nan(size(lon));
y = nan(size(lat));

regionArray = findRegion(lat, lon, 1.0);

% Forward equations
% -----------------

index = unique(regionArray(~isnan(regionArray)));
for k=1:numel(index)
    
    region = index(k);
    regionIndx = region+1;
    indx1 = regionArray == region;
    sinusoidalRegion = any(region == [1,3,4,5,8,9]);
        
    if sinusoidalRegion
        delta_lon = adjust_lon(lon(indx1) - lon_center(regionIndx));
        x(indx1) = feast(regionIndx) + R .* delta_lon .* cos(lat(indx1));
        y(indx1) = R .* lat(indx1);
    else
        delta_lon = adjust_lon(lon(indx1) - lon_center(regionIndx));       
        theta = solveForTheta(lat(indx1));
        x(indx1) = feast(regionIndx) + ...
            0.900316316158 .* R .* delta_lon .* cos(theta);
        y(indx1) = R .* (sqrt(2) .* sin(theta) - ...
            0.0528035274542 .* sign(lat(indx1)));
    end
    
end

%--------------------------------------------------------------------------

function theta = solveForTheta(phi)
% Solve the equation:
%    2*theta + sin(2*theta) = pi * sin(phi)

EPSLN = 1.0e-10;
constant = pi .* sin(phi);
maxIteration = 100;

% Apply the Newton-Raphson method. 
theta = phi;
converged = false;
k = 1;
while ~converged && k < maxIteration
    delta_theta = ...
        -(theta + sin(theta) - constant) ./ (1.0 + cos(theta));
    theta = theta + delta_theta;  
    converged = max(abs(delta_theta(:))) <= EPSLN;
    k = k + 1;
end

if (k >= maxIteration)
    error(message('map:avhrr:fwdConverge'));
end

theta = theta / 2.0;

%--------------------------------------------------------------------------

function region = findRegion(lat, lon, R)

region = NaN + lat;

breakpt = R * deg2rad(dms2degrees([40, 44, 11.8]));

% Northern Hemisphere

dn40 = R * deg2rad(-40);

lonzone1 = (lon <= dn40);
lonzone2 = (dn40 < lon);

latzone = (lat >= breakpt);
region(latzone & lonzone1) = 0;
region(latzone & lonzone2) = 2;

latzone = (0 <= lat) & (lat < breakpt);
region(latzone & lonzone1) = 1;
region(latzone & lonzone2) = 3;

% Southern Hemisphere

dn100 = R * deg2rad(-100);
dn20  = R * deg2rad( -20);
d80   = R * deg2rad(  80);

lonzone1 = (lon <= dn100);
lonzone2 = (dn100 < lon) & (lon <= dn20);
lonzone3 = ( dn20 < lon) & (lon <=  d80);
lonzone4 = (  d80 < lon);

latzone = (-breakpt <= lat) & (lat < 0);
region(latzone & lonzone1) = 4;
region(latzone & lonzone2) = 5;
region(latzone & lonzone3) = 8;
region(latzone & lonzone4) = 9;

latzone = (lat < -breakpt);
region(latzone & lonzone1) =  6;
region(latzone & lonzone2) =  7;
region(latzone & lonzone3) = 10;
region(latzone & lonzone4) = 11;

%--------------------------------------------------------------------------

function [lat, lon] = goodeInv(x, y)

R = 6370997.0;
half_pi = pi/2;
EPSLN = 1.0e-10;

[lon_center, feast] = goode_init(R);
lat = nan(size(y));
lon = nan(size(x));

regionArray = findRegion(y, x, R);

% Inverse equations
% -----------------

index = unique(regionArray(~isnan(regionArray)));
for k=1:numel(index)
    region = index(k);
    regionIndx = region+1;
    indx1 = regionArray == region;
    x(indx1) = x(indx1) - feast(regionIndx);

    if ismember(region, [1, 3, 4, 5, 8, 9])
        lat(indx1) = y(indx1) ./ R;
        if any(abs(lat(indx1)) > half_pi)
            error(message('map:avhrr:invConverge'))
        end
        temp = abs(lat(indx1)) - half_pi;
        if (abs(temp) > EPSLN)
            temp = lon_center(regionIndx) + x(indx1) ./ (R.*cos(lat(indx1)));
            lon(indx1) = adjust_lon(temp);
        else
            lon(indx1) = lon_center(regionIndx);
        end
    else
        [lat(indx1),lon(indx1)] = ...
            applyInvEquations(x(indx1),y(indx1),R,lon_center(regionIndx));
    end

    % Are we in a interrupted area?  If so, set values to NaN.
    % --------------------------------------------------------
    switch region
        case 0
            indx = lon < -pi | lon > deg2rad(-40);

        case 1
            indx = lon < -pi | lon > deg2rad(-40);

        case 2
            indx = lon < deg2rad(-40) | lon > pi;

        case 3
            indx = lon < deg2rad(-40) | lon > pi;

        case 4
            indx = lon < -pi | lon > deg2rad(-100);

        case 5
            indx = lon < deg2rad(-100) | lon > deg2rad(-20);

        case 6
            indx = lon < -pi | lon > deg2rad(-100);

        case 7
            indx = lon < deg2rad(-100) | lon > deg2rad(-20);

        case 8
            indx = lon < deg2rad(-20) | lon > deg2rad(80);

        case 9
            indx = lon < deg2rad(80) | lon > pi;

        case 10
            indx = lon < deg2rad(-20) | lon > deg2rad(80);

        case 11
            indx = lon < deg2rad(80) | lon > pi;
    end

    indx2 = indx & indx1;
    lat(indx2) = NaN;
    lon(indx2) = NaN;
end

lat = rad2deg(lat);
lon = rad2deg(lon);

%--------------------------------------------------------------------------

function [lat, lon] = applyInvEquations(x, y, R, lon_center)

arg = (y + 0.0528035274542 .* R .* sign(y)) ./  (1.4142135623731 * R);
theta = asin(arg);
theta(~isnumeric(theta)) = NaN;

lon = lon_center + (x ./ (0.900316316158 .* R .* cos(theta)));
indx = lon < -pi;
arg = (2.0 * theta + sin(2.0 * theta)) / pi;
lat = asin(arg);

lat(indx) = NaN;
lon(indx) = NaN;
lon(~isnumeric(lon)) = NaN;
lat(~isnumeric(lat)) = NaN;

%--------------------------------------------------------------------------

function [lon_center, feast] = goode_init(R)

% Initialize central meridians for each of the 12 regions
% -------------------------------------------------------
lon_center(1) = deg2rad(-100);
lon_center(2) = deg2rad(-100);
lon_center(3) = deg2rad(30);
lon_center(4) = deg2rad(30);
lon_center(5) = deg2rad(-160);
lon_center(6) = deg2rad(-60);
lon_center(7) = deg2rad(-160);
lon_center(8) = deg2rad(-60);
lon_center(9) = deg2rad(20);
lon_center(10) = deg2rad(140);
lon_center(11) = deg2rad(20);
lon_center(12) = deg2rad(140);

% Initialize false eastings for each of the 12 regions
% ----------------------------------------------------
feast(1) = R * deg2rad(-100);
feast(2) = R * deg2rad(-100);
feast(3) = R * deg2rad(30);
feast(4) = R * deg2rad(30);
feast(5) = R * deg2rad(-160);
feast(6) = R * deg2rad(-60);
feast(7) = R * deg2rad(-160);
feast(8) = R * deg2rad(-60);
feast(9) = R * deg2rad(20);
feast(10) = R * deg2rad(140);
feast(11) = R * deg2rad(20);
feast(12) = R * deg2rad(140);

%--------------------------------------------------------------------------

function x = adjust_lon(x)
indx = abs(x) >= pi;
x(indx) = x(indx) - (sign(x(indx)).*2.*pi);
