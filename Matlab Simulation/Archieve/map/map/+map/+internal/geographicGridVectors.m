function [latv,lonv] = geographicGridVectors(R)
%geographicGridVectors Grid vectors for cell center or sample location points
%
%   [LATV, LONV] = map.internal.geographicGridVectors(R) returns a
%   geographic (latitude-longitude) mesh in which each element corresponds
%   to a row and column in the raster grid or image associated with
%   referencing object R.
%
%   If R.RasterInterpretation is 'cells', then the mesh specifies the
%   geographic coordinates of the cell center points.
%
%   If R.RasterInterpretation is 'postings', then the mesh specifies the
%   geographic coordinates of the sample point locations.
%
%   Examples
%   --------
%   % A raster of cells such that each value is at the center of
%   % a geographic cell having finite area:
%   R = georasterref('LatitudeLimits',[27 28],'LongitudeLimits',[86 87], ...
%       'RasterSize',[120 120],'RasterInterpretation','cells')
%   [latv,lonv] = map.internal.geographicGridVectors(R);
%   size(latv)
%   size(lonv)
%
%   % A raster of posting points such that each value is the
%   % specific point location of a sample or measurement:
%   R = georasterref('LatitudeLimits',[27 28],'LongitudeLimits',[86 87], ...
%       'RasterSize',[121 121],'RasterInterpretation','postings')
%   [latv,lonv] = map.internal.geographicGridVectors(R);
%   size(latv)
%   size(lonv)
%
%   Input Argument
%   --------------
%   R -- Geographic raster reference object.
%
%   Output Arguments
%   ----------------
%   LATV -- M-by-1 vector indicating the latitude of each row in a
%     geographic mesh, such that the latitude of the (I,J)-the element of
%     the associated M-by-N raster grid is given by LATV(I)
%     Data type: double.
%
%   LONV -- 1-by-N vector indicating the longitude of each row in a
%     geographic mesh, such that the longitude of the (I,J)-the element of
%     the associated M-by-N raster grid is given by LONV(J)
%     Data type: double.
%
%   M is equal to R.RasterSize(1) and N is equal to R.RasterSize(2).

% Copyright 2019 The MathWorks, Inc.

nrows = R.RasterSize(1);
ncols = R.RasterSize(2);

% Vectors containing centers/sample locations in intrinsic coordinates.
x =  1:ncols;
y = (1:nrows)';

% Vectors containing centers/sample locations in geographic coordinates.
latv = intrinsicYToLatitude(R,y);
lonv = intrinsicXToLongitude(R,x);
