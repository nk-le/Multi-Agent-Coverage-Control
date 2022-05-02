function [lat, lon] = antipode(lat, lon, angleUnit)
%ANTIPODE Point on opposite side of globe
%
%   [ALAT, ALON] = ANTIPODE(LAT, LON) returns the geographic
%   coordinates of the points exactly opposite on the globe from the
%   input points given by LAT and LON.  The latitude and longitude angles
%   are in degrees by default.
%
%   [...] = ANTIPODE(..., angleUnit) uses angleUnit, which matches either
%   'degrees' or 'radians', to specify the units of the input and output
%   latitudes and longitudes.
%
%   Example: Antipode of Bangalore
%   ------------------------------
%   lat = 12.9909;
%   lon = 77.6022;
%   [alat,alon] = antipode(lat,lon)

% Copyright 1996-2017 The MathWorks, Inc.

% Note:  In order to map a longitude of zero to 180 degrees
% (or to pi, when working in radians), we use formulas like:
%
%   lon = 180 - mod(-lon, 360);
%
% rather than the more obvious:
%
%   lon = mod(lon, 360) - 180;

lat = -lat;
if nargin < 3 || map.geodesy.isDegree(angleUnit)
    lon = 180 - mod(-lon, 360);
else
    lon = pi - mod(-lon, 2*pi);
end
