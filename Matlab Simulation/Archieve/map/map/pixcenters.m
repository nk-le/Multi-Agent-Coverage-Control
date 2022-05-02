function [x,y] = pixcenters(varargin)
%PIXCENTERS Compute pixel centers for georeferenced image or data grid
%
%      PIXCENTERS will be removed in a future release.
%      Use worldGrid or geographicGrid instead.
%
%   [X,Y] = PIXCENTERS(R, HEIGHT, WIDTH) computes the center coordinates
%   for each pixel in an image or regular gridded data set georeferenced
%   to a planar map coordinate system.  R is either a 3-by-2 referencing
%   matrix or a map raster reference object.  HEIGHT and WIDTH are the
%   image dimensions.  If R does not include a rotation, then X is a
%   1-by-WIDTH vector and Y is a 1-by-HEIGHT vector. In this case, the map
%   coordinates of the pixel in row ROW and column COL are given by X(COL),
%   Y(ROW). Otherwise, X and Y are each a HEIGHT-by-WIDTH matrix such that
%   X(COL,ROW), Y(COL,ROW) are the map coordinates of the center of the
%   pixel with subscripts (ROW, COL).
%
%   [X,Y] = PIXCENTERS(R, SIZEA) accepts the size vector
%   SIZEA = [HEIGHT, WIDTH, ...] instead of HEIGHT and WIDTH.
%
%   [X,Y] = PIXCENTERS(INFO) accepts a scalar struct array with the fields:
%
%              'RefMatrix'   A 3-by-2 referencing matrix
%              'Height'      A scalar number
%              'Width'       A scalar number
%
%   [X,Y] = PIXCENTERS(..., 'makegrid') returns X and Y as HEIGHT-by-WIDTH
%   matrices even if R (or INFO.RefMatrix) is irrotational. This can be
%   helpful when calling PIXCENTERS from within a function or script.
%
%   PIXCENTERS is useful for working with SURF, MESH, or SURFACE, or for
%   coordinate transformations.
%
%   The help for MAPSHOW provides an alternative version of the following
%   example.
%
%   Example
%   -------
%   [Z,R] = readgeoraster('MtWashington-ft.grd','OutputType','double');
%   info = georasterinfo('MtWashington-ft.grd');
%   Z = standardizeMissing(Z,info.MissingDataIndicator);
%   [x,y] = pixcenters(R, size(Z));
%   h = surf(x,y,Z); axis equal; demcmap(Z)
%   set(h,'EdgeColor','none')
%   xlabel('x (easting in meters)'); ylabel('y (northing in meters')
%   zlabel('elevation in feet')

% Copyright 1996-2020 The MathWorks, Inc.  

narginchk(1,4)

[R, height, width, gridrequest] ...
    = parsePixMapInputs('PIXCENTERS', 'makegrid', varargin{:});

if isobject(R)
    [x, y] = pixcenters_MapRasterReference(R, height, width, gridrequest);
else
    [x, y] = pixcenters_refmat(R, height, width, gridrequest);
end

%--------------------------------------------------------------------------
function [x, y] = pixcenters_MapRasterReference(R, height, width, gridrequest)
% Use map raster reference input.

if gridrequest || strcmp(R.TransformationType, 'affine')
    [r,c] = ndgrid(1:height,1:width);
    [x,y] = R.intrinsicToWorld(c,r);
else
    [x,~] = R.intrinsicToWorld(1:width, ones(1,width));
    [~,y] = R.intrinsicToWorld(ones(1,height), 1:height);
end

%--------------------------------------------------------------------------
function [x, y] = pixcenters_refmat(R, height, width, gridrequest)
% Use referencing matrix input.

if (gridrequest || (R(1,1) ~= 0) || (R(2,2) ~= 0))
    [r,c] = ndgrid(1:height,1:width);
    [x,y] = pix2map(R,r,c);
else
    [x,~] = pix2map(R,ones(1,width),1:width);
    [~,y] = pix2map(R,1:height,ones(1,height));
end
