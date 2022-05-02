function h = georastershow(varargin)
%GEORASTERSHOW Display map latitude and longitude raster data
%
%   GEORASTERSHOW(LAT,LON,Z, ..., 'DisplayType', DISPLAYTYPE, ...) where
%   LAT and LON are M-by-N coordinate arrays, Z is an M-by-N array of class
%   double, and DISPLAYTYPE is 'texturemap' or 'contour', displays a
%   geolocated data grid.  Z may contain NaN values.  
%
%   GEORASTERSHOW(LAT,LON,I)  
%   GEORASTERSHOW(LAT,LON,BW) 
%   GEORASTERSHOW(LAT,LON,X,CMAP) 
%   GEORASTERSHOW(LAT,LON,RGB)
%   where I is a grayscale image, BW is a logical image, X is an indexed
%   image with colormap CMAP, or RGB is a truecolor image, displays a
%   geolocated image. The image is rendered as a texturemap on a
%   zero-elevation surface.  If specified, 'DisplayType' must be set to
%   'image'.  Examples of geolocated images include a color composite from
%   a satellite swath or an image originally referenced to a different
%   coordinate system. 
%
%   GEORASTERSHOW(Z,R, ..., 'DisplayType', DISPLAYTYPE,...) where Z is
%   class double and DISPLAYTYPE is 'surface', 'contour', or 'texturemap',
%   displays a regular M-by-N data grid.  R is a referencing vector. R may
%   also be a referencing matrix, provided that it is convertible to a
%   referencing vector. For DISPLAYTYPE set to 'surface' or 'texturemap',
%   GEORASTERSHOW constructs a surface with ZData values set to 0.
%
%   GEORASTERSHOW(I,R) 
%   GEORASTERSHOW(BW,R) 
%   GEORASTERSHOW(RGB,R) 
%   GEORASTERSHOW(A,CMAP,R) 
%   displays an image georeferenced to latitude/longitude.  The image is
%   rendered as a texturemap on a zero-elevation surface. If specified,
%   'DisplayType' must be set to 'image'. R is a referencing vector. R may
%   be a referencing matrix, provided that it is convertible to a
%   referencing vector.
% 
%   GEORASTERSHOW(FILENAME) displays data from FILENAME, according to the
%   type of file format. The DisplayType parameter is automatically set,
%   according to the following table:
%
%       Format                           DisplayType
%       ------                           -----------
%       GeoTIFF                         'image'
%       TIFF/JPEG/PNG with a world file 'image'
%       ARC ASCII GRID                  'surface' (may be overridden)
%       SDTS raster                     'surface' (may be overridden)
%
%
%   GEORASTERSHOW(AX, ...) sets the axes parent to AX. This is equivalent
%   to GEORASTERSHOW(..., 'Parent', ax).
%
%   H = GEORASTERSHOW(...) returns a handle to a MATLAB graphics object.
%
%   GEORASTERSHOW(..., PARAM1, VAL1, PARAM2, VAL2, ...) specifies
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
%                  grid           'surface', 'texturemap', or 'contour' 
%
%   Graphics       Refer to the MATLAB Graphics documentation on image and
%   Properties     surface for a complete description of these properties
%                  and their values. 
%                 
%   See also AXESM, GEOSHOW, MAPRASTERSHOW, MAPSHOW, SURFACEM

% Copyright 2006-2020 The MathWorks, Inc.

% Parse the inputs from the command line.
[ax, dataArgs, displayType, HGpairs] = ...
    parseRasterInputs('geoshow', varargin{:});

% Validate the geographic raster data. Return Z (the matrix to be
% displayed), the spatial referencing information, and updated displayType.
[Z, SpatialRef, displayType] = ...
    validateGeoRasterData('geoshow', dataArgs, displayType);

% Display the raster data onto the axes.
h0 = displayGeoRasterData(ax, displayType, Z, SpatialRef, HGpairs);

%  Restack to ensure standard child order in the map axes.
map.graphics.internal.restackMapAxes(h0)

% Suppress output if called with no return value and no semicolon.
if nargout > 0
   h = h0;
end

%--------------------------------------------------------------------------

function h = displayGeoRasterData(ax, displayType, Z, SpatialRef, HGpairs)
% Display the geographic raster data onto the axes.

switch displayType  
    case 'mesh'
        h = geomesh(ax, Z, SpatialRef, HGpairs);
              
    case {'surface','texturemap'}
        h = geosurface(ax, Z, SpatialRef, displayType, HGpairs);
        
    case 'contour'
        h = geocontour(ax, Z, SpatialRef, HGpairs);
end

%--------------------------------------------------------------------------

function h = geocontour(ax, Z, SpatialRef, HGpairs)
% Contour the geographic data grid by wrapping the contourm function.

if ~isstruct(SpatialRef)
    [~, h] = contourm(Z, SpatialRef, 'Parent', ax, HGpairs{:});
else
    lon = SpatialRef.LonMesh;
    lat = SpatialRef.LatMesh;
    [~, h] = contourm(lat, lon, Z, 'Parent', ax, HGpairs{:});
end

%--------------------------------------------------------------------------

function h = geosurface(ax, Z, SpatialRef, displayType, HGpairs)
% Display a geographic geolocated data grid by wrapping the surface
% function.

% Obtain the display type.
if strcmpi(displayType, 'surface')
    displayType = '3D';
else
    displayType = '2D';
end

% Display the surface.
g = internal.mapgraph.GeoRaster(ax, Z, SpatialRef, ...
    'DisplayType', displayType, HGpairs{:});
h = g.getPrimarySurfaceHandle;

% Set the referencing information for mapprofile.
setRefVecInUserData(h, SpatialRef, size(Z));

%--------------------------------------------------------------------------

function h = geomesh(ax, Z, SpatialRef, HGpairs)
% Display a geographic data grid as a mesh by wrapping the mesh function.

% Display the surface with mesh properties.
meshProps = [{ ...
    'EdgeColor', 'flat', ...
    'FaceColor' , [1 1 1], ...
    'LineStyle', '-', ...
    'FaceLighting', 'none', ...
    'EdgeLighting', 'flat'}, HGpairs];
g = internal.mapgraph.GeoRaster( ...
    ax, Z, SpatialRef, 'DisplayType', '3D', meshProps{:});
h = g.getPrimarySurfaceHandle;

% Set UserData and referencing vector for MAPPROFILE
setRefVecInUserData(h, SpatialRef, size(Z));

%--------------------------------------------------------------------------

function setRefVecInUserData(h, R, sz)
% Add maplegend to UserData for use with MAPPROFILE

if ~isstruct(R)
   userData = get(h,'UserData');
   try
      refvec = map.internal.referencingMatrixToVector(R, sz);
   catch  %#ok<CTCH>
      refvec = R;
   end
   userData.maplegend = refvec;
   set(h, 'UserData', userData);
end
