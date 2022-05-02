function [latf,lonf] = flatearthpoly(lat, lon, longitudeOrigin)
%FLATEARTHPOLY Insert points along dateline to pole
%
%   [LATF, LONF] = FLATEARTHPOLY(LAT, LON) trims NaN-separated polygons
%   specified by the latitude and longitude vectors LAT and LON to the
%   limits [-180 180] in longitude and [-90 90] in latitude, inserting
%   straight segments along the +/- 180-degree meridians and at the
%   poles. Inputs and outputs are in degrees.
%
%   [LATF, LONF] = FLATEARTHPOLY(LAT, LON, longitudeOrigin) centers the
%   longitude limits on the longitude specified by the scalar longitude
%   longitudeOrigin.
%
%   Example
%   -------
%   antarctica = shaperead('landareas', 'UseGeoCoords', true,...
%        'Selector', {@(name) strcmp(name,'Antarctica'), 'Name'});
%
%   figure; plot(antarctica.Lon, antarctica.Lat); ylim([-100 -60])
%  
%   [latf, lonf] = flatearthpoly(antarctica.Lat', antarctica.Lon');
%   figure; mapshow(lonf, latf, 'DisplayType', 'polygon')
%   ylim([-100 -60])
%
%   See also MAPTRIMP.

% Copyright 1996-2009 The MathWorks, Inc.

% Parse and validate inputs
checklatlon(lat, lon, mfilename, 'LAT', 'LON', 1, 2)
if nargin == 2
    longitudeOrigin = 0;
elseif ~isscalar(longitudeOrigin) || ~isnumeric(longitudeOrigin)
    error(['map:' mfilename ':invalidOriginLongitude'], ...
        'Origin must be a numeric scalar longitude.')
end

% Construct the new polygons
latlim = [-90 90];
lonlim = longitudeOrigin + [-180 180];
[latf, lonf] = maptrimp(lat, lon, latlim, lonlim);
