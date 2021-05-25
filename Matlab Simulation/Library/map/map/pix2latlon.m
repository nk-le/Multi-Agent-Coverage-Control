function [lat, lon] = pix2latlon(R, row, col)
%PIX2LATLON Convert pixel coordinates to latitude-longitude coordinates
%
%   [LAT, LON] = PIX2LATLON(R,ROW,COL) calculates latitude-longitude
%   coordinates LAT, LON from pixel coordinates ROW, COL.  R is either a
%   3-by-2 referencing matrix that transforms intrinsic pixel coordinates
%   to geographic coordinates, or a geographic raster reference object.
%   ROW and COL are vectors or arrays of matching size. The outputs LAT and
%   LON have the same size as ROW and COL.
%
%   Example 
%   -------
%   % Find the latitude and longitude of the upper left and lower right 
%   % outer corners of a 2-by-2 degree gridded data set.
%   R = georefcells([-90 90],[0 360],2,2,'ColumnsStartFrom','north')
%   [UL_lat, UL_lon] = pix2latlon(R, .5, .5)
%   [LR_lat, LR_lon] = pix2latlon(R, 90.5, 180.5)
%
%   See also map.rasterref.GeographicCellsReference/intrinsicToGeographic

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(3,3)

% Validate referencing matrix or geographic raster reference object.
map.rasterref.internal.validateRasterReference(R, ...
    'geographic', 'pix2latlon', 'R', 1)

if isobject(R)
    [lat, lon] = intrinsicToGeographic(R, col, row);
else
    [lon, lat] = pix2map(R, row, col);
end
