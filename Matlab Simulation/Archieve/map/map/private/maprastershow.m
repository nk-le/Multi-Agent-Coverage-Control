function h = maprastershow(varargin)
%MAPRASTERSHOW Display raster map data
%
%   MAPRASTERSHOW(X,Y,Z, ..., 'DisplayType', DISPLAYTYPE, ...) where X and
%   Y are M-by-N coordinate arrays, Z is an M-by-N array of class double,
%   and DISPLAYTYPE is 'surface', 'mesh', 'texturemap', or 'contour',
%   displays a geolocated data grid, Z. Z may contain NaN values.  
%
%   MAPRASTERSHOW(X,Y,I)  
%   MAPRASTERSHOW(X,Y,BW) 
%   MAPRASTERSHOW(X,Y,A,CMAP) 
%   MAPRASTERSHOW(X,Y,RGB)
%   where I is a grayscale image, BW is a logical image, A is an indexed
%   image with colormap CMAP, or RGB is a truecolor image, displays a
%   geolocated image. The image is rendered as a texturemap on a
%   zero-elevation surface.  If specified, 'DisplayType' must be set to
%   'image'.  Examples of geolocated images include a color composite from
%   a satellite swath or an image originally referenced to a different
%   coordinate system.
%
%   MAPRASTERSHOW(Z,R, ..., 'DisplayType', DISPLAYTYPE,...) where Z is
%   class double and  DISPLAYTYPE is 'surface', 'mesh', 'texturemap', or
%   'contour', displays a regular M-by-N data grid.  R is a referencing
%   matrix or referencing vector.
%
%   MAPRASTERSHOW(I,R) 
%   MAPRASTERSHOW(BW,R) 
%   MAPRASTERSHOW(RGB,R) 
%   MAPRASTERSHOW(A,CMAP,R) 
%   displays a georeferenced image.  It is rendered as an image object if
%   the display geometry permits; otherwise, the image is rendered as a
%   texturemap on a zero-elevation surface. If specified, 'DisplayType'
%   must be set to 'image'.
%
%   MAPRASTERSHOW(FILENAME) displays data from FILENAME, according to the
%   type of file format. The DisplayType parameter is automatically set,
%   according to the following table:
%
%       Format                          DisplayType
%       ------                          -----------
%       GeoTIFF                         'image'
%       TIFF/JPEG/PNG with a world file 'image'
%       ARC ASCII GRID                  'surface' (may be overridden)
%       SDTS raster                     'surface' (may be overridden)
%
%
%   MAPRASTERSHOW(AX, ...) sets the axes parent to AX. This is equivalent
%   to MAPRASTERSHOW(..., 'Parent', ax).
%
%   H = MAPRASTERSHOW(...) returns a handle to a MATLAB graphics object.
%
%   MAPRASTERSHOW(..., PARAM1, VAL1, PARAM2, VAL2, ...) specifies
%   parameter/value pairs that modify the type of display or set MATLAB
%   graphics properties. Parameter names can be abbreviated and are
%   case-insensitive.
%
%   Parameters include:
%
%   'DisplayType'  The DisplayType parameter specifies the type of graphic
%                  display for the data.  The value must be consistent with
%                  the type of data being displayed as shown in the
%                  following table:
%
%                  Data type      Value
%                  ---------      -----
%                  image          'image'
%                  grid           'surface', 'mesh', 'texturemap', or
%                                 'contour'
%
%   Graphics       Refer to the MATLAB Graphics documentation on 
%   Properties     image and surface for a complete description of these 
%                  properties and their values.
%
%   Example 1 
%   ---------
%   % View the Mount Washington SDTS DEM terrain data.
%   % View the Mount Washington terrain data as a mesh.
%   figure
%   h = maprastershow('9129CATD.ddf','DisplayType','mesh');
%   Z = get(h,'ZData');
%   demcmap(Z)
%
%   % View the Mount Washington terrain data as a surface.
%   figure
%   maprastershow('9129CATD.ddf');
%   demcmap(Z)
%   view(3); % View  as a 3-d surface
%   axis normal;
%
%   Example 2 
%   ----------
%   % Display the grid and contour lines of Mount Washington 
%   % and Mount Dartmouth.
%   [Z_W, R_W] = readgeoraster('MtWashington-ft.grd','OutputType','double');
%   [Z_D, R_D] = readgeoraster('MountDartmouth-ft.grd','OutputType','double');
%   info_W = georasterinfo('MtWashington-ft.grd');
%   info_D = georasterinfo('MountDartmouth-ft.grd');
%   Z_W = standardizeMissing(Z_W,info_W.MissingDataIndicator);
%   Z_D = standardizeMissing(Z_D,info_D.MissingDataIndicator);
%   figure
%   hold on
%   maprastershow(Z_W, R_W, 'DisplayType','surface');
%   maprastershow(Z_D, R_D, 'DisplayType','surface');
%   maprastershow(Z_W, R_W, 'DisplayType','contour', ...
%      'LineColor','black');
%   maprastershow(Z_D, R_D, 'DisplayType','contour', ...
%      'LineColor','black');
%
%   % Set the surface to zero to show the contour lines.
%   zdatam(handlem('surface'), 0.0);
%   demcmap(Z_W)
%
%   Example 3 
%   ----------
%   % Display the Boston GeoTIFF image with tight axes limits.
%   figure
%   maprastershow('boston.tif');
%   axis image
%
%   See also GEORASTERSHOW, MAPSHOW

% Copyright 2006-2020 The MathWorks, Inc.

% Parse the inputs from the command line.
[ax, dataArgs,  displayType, HGpairs] = ...
   parseRasterInputs('mapshow', varargin{:});

% Validate the map raster data. Return Z (the matrix to be displayed), the
% spatial referencing information, and updated HGpairs and displayType.
[Z, SpatialRef, displayType, HGpairs] = ...
    validateMapRasterData('mapshow', dataArgs,  displayType, HGpairs);

% Display the raster data onto the axes.
h0 = displayMapRasterData(ax, displayType, Z, SpatialRef, HGpairs);

% Restack to ensure standard child order in the map axes (if present).
map.graphics.internal.restackMapAxes(h0)

% Suppress output if called with no return value and no semicolon.
if nargout > 0
   h = h0;
end

%--------------------------------------------------------------------------

function h = displayMapRasterData(ax, displayType, Z, SpatialRef, HGpairs)
% Display the raster data onto the axes.

if isequal(size(SpatialRef), [3 2])
    SpatialRef = refmatToMapRasterReference(SpatialRef, size(Z));
end

switch displayType   
    case 'mesh'
        h = mapmesh(ax, Z, SpatialRef, HGpairs);
        
    case 'surface'
        h = mapsurface(ax, Z, SpatialRef, HGpairs);
        
    case 'contour'
        h = mapcontour(ax, Z, SpatialRef, HGpairs);  
        
    case 'image'
        h = mapimage(ax, Z, SpatialRef, HGpairs);        
end

%--------------------------------------------------------------------------

function h = mapmesh(ax, Z, SpatialRef, HGpairs)
% Display the map surface as a mesh by wrapping the mesh function.

if ~isstruct(SpatialRef)
    [x, y] = worldGrid(SpatialRef,"gridvectors");
else
    x = SpatialRef.XMesh;
    y = SpatialRef.YMesh;
end

h = mesh(ax, x, y, Z, HGpairs{:});

%--------------------------------------------------------------------------

function h = mapcontour(ax, Z, SpatialRef, HGpairs)
% Contour the map data grid by wrapping the contour function.

if ~isstruct(SpatialRef)
    [x, y] = worldGrid(SpatialRef,"gridvectors");
else
    x = SpatialRef.XMesh;
    y = SpatialRef.YMesh;
end

% Contour the grid.
[~, h] = contour(x, y, Z, 'Parent', ax, HGpairs{:});

% Set the Tag to 'Contour' for HANDLEM.
set(h,'Tag','Contour');

%--------------------------------------------------------------------------

function h = mapsurface(ax, Z, SpatialRef, HGpairs)
% Display a map data grid by wrapping the surface function.

if ~isstruct(SpatialRef)
    [x, y] = worldGrid(SpatialRef,"gridvectors");
else
    x = SpatialRef.XMesh;
    y = SpatialRef.YMesh;
end

h = surface(x, y, Z, 'EdgeColor', 'none', 'Parent', ax, HGpairs{:});

%--------------------------------------------------------------------------

function h = mapimage(ax, A, R, HGpairs)
% Display a map image by wrapping the image function.

M = size(A,1);
N = size(A,2);
cc = pix2map(R, [1 1; M N]);
XData = cc(:,1);
YData = cc(:,2);

h = image('Parent', ax, 'CData', A, ...
    'XData',  XData, 'YData', YData, HGpairs{:});
