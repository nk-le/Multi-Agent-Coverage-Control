function varargout = mapoutline(varargin)
%MAPOUTLINE Compute outline of georeferenced image or data grid
%
%   [X,Y] = MAPOUTLINE(R, HEIGHT, WIDTH) computes the outline of a
%   georeferenced image or regular gridded data set in map coordinates.
%   R is a 3-by-2 referencing matrix or a map raster reference object.
%   HEIGHT and WIDTH are the image dimensions.  X and Y are 4-by-1 column
%   vectors containing the map coordinates of the outer corners of the
%   corner pixels, in the following order:
%
%             (1,1), (HEIGHT,1), (HEIGHT, WIDTH), (1, WIDTH).
%
%   [X,Y] = MAPOUTLINE(R, SIZEA) accepts SIZEA = [HEIGHT, WIDTH, ...]
%   instead of HEIGHT and WIDTH.
%
%   [X,Y] = MAPOUTLINE(INFO) accepts a scalar struct array with the fields:
%
%                'RefMatrix'   A 3-by-2 referencing matrix
%                'Height'      A scalar number
%                'Width'       A scalar number
%
%   [X, Y] = MAPOUTLINE(...,'close') returns X and Y as 5-by-1 vectors,
%   appending the coordinates of the first of the four corners to the end.
%
%   [LON,LAT] = MAPOUTLINE(R,...), where R is a referencing matrix that
%   georeferences pixels to longitude and latitude rather than map
%   coordinates, returns the outline in geographic coordinates.
%   Longitude must precede latitude in the output argument list.
%
%   OUTLINE = MAPOUTLINE(...) returns the corner coordinates in a 4-by-2 or
%   5-by-2 array.
%
%   Example
%   --------
%   % Draw a red outline delineating the Boston GeoTIFF image, which is 
%   % referenced to the Massachusetts Mainland State Plane coordinate 
%   % system with units of survey feet.
%   figure
%   info  = geotiffinfo('boston.tif');
%   [x,y] = mapoutline(info, 'close');
%   hold on
%   plot(x,y,'r')
%   xlabel('MA Mainland State Plane easting, survey feet')
%   ylabel('MA Mainland State Plane northing, survey feet')
%
%   % Draw a black outline delineating a TIFF image of Concord, 
%   % Massachusetts, while lies roughly 25 km north west of Boston.
%   % Convert world file units to survey feet from meters to be consistent 
%   % with the Boston image.
%   [X,cmap] = imread('concord_ortho_w.tif');
%   R = worldfileread('concord_ortho_w.tfw','planar',size(X));
%   R.XWorldLimits = R.XWorldLimits * unitsratio('sf','meter');
%   R.YWorldLimits = R.YWorldLimits * unitsratio('sf','meter');
%   [x,y] = mapoutline(R, R.RasterSize, 'close');
%   plot(x,y,'k')
%
%   See also MAPREFCELLS, WORLDFILEREAD

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(1,4)
nargoutchk(0,2)

% Obtain R, height, width, and close logical
[R, h, w, closeOutline] = parsePixMapInputs('MAPOUTLINE', 'close', varargin{:});

if isobject(R)
    % Compute outline from spatial referencing object
    varargout = mapoutline_MapRasterReference(R, closeOutline, nargout);
else
    % Compute outline from referencing matrix input
    varargout = mapoutline_refmat(R, h, w, closeOutline, nargout); 
end

%-----------------------------------------------------------------------------

function output = mapoutline_MapRasterReference(R, closeOutline, nOut)
% Compute outline from spatial referencing object

if closeOutline
    xi = R.XIntrinsicLimits([1 1 2 2 1])';
    yi = R.YIntrinsicLimits([1 2 2 1 1])';
else
    xi = R.XIntrinsicLimits([1 1 2 2])';
    yi = R.YIntrinsicLimits([1 2 2 1])';
end
[xw, yw] = R.intrinsicToWorld(xi, yi);

% Setup the return arguments
if nOut <= 1
    output = {[xw, yw]};
else
    output = {xw, yw};
end

%-----------------------------------------------------------------------------

function output = mapoutline_refmat(R, h, w, closeOutline, nOut)
% Compute outline from referencing matrix input

% Get the outline values
if closeOutline
    outline = [(0.5 + [0  0;...
                       h  0;...
                       h  w;...
                       0  w;...
                       0  0]), ones(5,1)] * R;
else
    outline = [(0.5 + [0  0;...
                       h  0;...
                       h  w;...
                       0  w]), ones(4,1)] * R;
end

% Setup the return arguments 
if nOut <= 1
   output = {outline};
else
    output = {outline(:,1), outline(:,2)};
end
