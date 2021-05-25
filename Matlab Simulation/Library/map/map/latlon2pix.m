function [row, col] = latlon2pix(R, lat, lon)
%LATLON2PIX Convert latitude-longitude coordinates to pixel coordinates
%
%   [ROW, COL] = LATLON2PIX(R,LAT,LON) calculates pixel  coordinates ROW,
%   COL from latitude-longitude coordinates LAT, LON.  R is either a 3-by-2
%   referencing matrix that transforms intrinsic pixel coordinates to
%   geographic coordinates, or a geographic raster reference object.  LAT
%   and LON are vectors or arrays of matching size.  The outputs ROW and
%   COL have the same size as LAT and LON.  LAT and LON must be in degrees.
%
%   Longitude wrapping is handled: Results are invariant under the
%   substitution LON = LON +/- N * 360 where N is an integer.  Any point on
%   the earth that is included in the image or gridded data set
%   corresponding to R will yield row/column values between 0.5 and 0.5 +
%   the image height/width, regardless of what longitude convention is
%   used.
%
%   Example
%   -------
%   % Find the pixel coordinates of the upper left and lower right
%   % outer corners of a 2-by-2 degree gridded data set.  
%   R = georefcells([-90 90],[0 360],2,2,'ColumnsStartFrom','north')
%   [UL_row, UL_col] = latlon2pix(R,  90, 0)
%   [LR_row, LR_col] = latlon2pix(R, -90, 360)
%
%   See also map.rasterref.GeographicCellsReference/geographicToIntrinsic

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(3,3)

% Validate referencing matrix or geographic raster reference object.
map.rasterref.internal.validateRasterReference(R, ...
    'geographic', 'latlon2pix', 'R', 1)

if isobject(R)
    [col, row] = geographicToIntrinsic(R, lat, lon);
else
    [row, col] = latlon2pix_refmat(R, lat, lon);
end

%--------------------------------------------------------------------------

function [row, col] = latlon2pix_refmat(R, lat, lon)
% Compute the transformation using referencing matrix R

cycle = 360;  % Degrees only for now

% Resolve longitude ambiguity:
% For which values of n, if any is row >= 0.5 and col >= 0.5, where
%   [row, col] = map2pix(R, lon + cycle * n, lat)?

% Start with values for n = 0 and n = 1 (all we need because of linearity).
[row0, col0] = map2pix(R, lon, lat);          % n = 0
[row1, col1] = map2pix(R, lon + cycle, lat);  % n = 1

% Find limiting values of n as separately constrained by the rows and
% columns.
[rLower, rUpper] = findLimits(row0,row1);
[cLower, cUpper] = findLimits(col0,col1);

% Choose a value for n within the intersection of the limits (if possible)
n = max(rLower,cLower);
t = min(rUpper,cUpper);
n(n == -Inf) = t(n == -Inf);
n(n ==  Inf) = 0;

[row, col] = map2pix(R, lon + cycle * n, lat);

%--------------------------------------------------------------------------

function [lowerLim, upperLim] = findLimits(c0, c1)

d = c1 - c0;
Z = (0.5 - c0) ./ d;

lowerLim = -Inf * ones(size(Z));
lowerLim(d > 0) = ceil(Z(d > 0));

upperLim = Inf * ones(size(Z));
upperLim(d < 0) = floor(Z(d < 0));
