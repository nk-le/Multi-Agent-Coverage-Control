function varargout = geoshow(varargin)
%GEOSHOW Display map latitude and longitude data 
%
%   GEOSHOW(LAT, LON) or 
%   GEOSHOW(LAT, LON, ..., 'DisplayType', DISPLAYTYPE, ...) projects and
%   displays the latitude and longitude vectors, LAT and LON, using the
%   projection stored in the axes. If there is no projection, the latitudes
%   and longitudes are projected using a default Plate Carree projection.
%   LAT and LON may contain embedded NaNs, delimiting individual lines or
%   polygon parts. DISPLAYTYPE can be 'point', 'line', or 'polygon' and
%   defaults to 'line'.
%
%   GEOSHOW(LAT,LON,Z, ..., 'DisplayType', DISPLAYTYPE, ...) projects and
%   displays a geolocated data grid.  LAT and LON are M-by-N
%   latitude-longitude arrays and Z is an M-by-N array of class double.
%   Lat, Lon, and Z may contain NaN values. DISPLAYTYPE must be set to
%   'surface', 'mesh', 'texturemap', or 'contour'.
%
%   GEOSHOW(Z,R, ..., 'DisplayType', DISPLAYTYPE,...) projects and displays
%   a regular data grid. Z is a 2-D array of class double.  R can be a
%   geographic raster reference object, a referencing vector, or a
%   referencing matrix.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z).
%
%   If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R.
%
%   If R is a referencing matrix, it must define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel. DISPLAYTYPE 
%   must be set to 'surface', 'mesh', 'texturemap', or 'contour'. If
%   DISPLAYTYPE is 'texturemap', GEOSHOW constructs a surface with ZData
%   values set to 0.
%
%   GEOSHOW(LAT,LON,I)  
%   GEOSHOW(LAT,LON,BW) 
%   GEOSHOW(LAT,LON,X,CMAP) 
%   GEOSHOW(LAT,LON,RGB)
%   GEOSHOW(..., 'DisplayType', DISPLAYTYPE, ...) projects and displays a
%   geolocated image as a texturemap on a zero-elevation surface.  LAT and
%   LON are latitude-longitude geolocation arrays and I is a grayscale
%   image, BW is a logical image, X is an indexed image with colormap CMAP,
%   or RGB is a truecolor image.  LAT, LON, and the image array must match
%   in size.  If specified, DISPLAYTYPE must be set to 'image'. 
%
%   GEOSHOW(I,R) 
%   GEOSHOW(BW,R) 
%   GEOSHOW(RGB,R) 
%   GEOSHOW(A,CMAP,R) 
%   GEOSHOW(..., 'DisplayType', DISPLAYTYPE, ...) projects and displays an
%   image georeferenced to latitude-longitude. The image is shown as a
%   texturemap on a zero-elevation surface. If specified, DISPLAYTYPE must
%   be set to 'image'.
%
%   GEOSHOW(S) or GEOSHOW(S, ..., 'SymbolSpec', SYMSPEC, ...) displays the
%   vector geographic features stored in S as points, multipoints, lines,
%   or polygons according to the 'Geometry' field of S.  If S is either a
%   geopoint vector, a geoshape vector, or a geostruct (with 'Lat' and
%   'Lon' coordinate fields) vertices are projected to map coordinates. If
%   S is either a mappoint vector, mapshape vector, or a mapstruct (with
%   'X' and 'Y fields), vertices are plotted as (pre-projected) map
%   coordinates and a warning is issued. SYMSPEC specifies the
%   symbolization rules used for the vector data through a structure
%   returned by MAKESYMBOLSPEC.
%
%   GEOSHOW(FILENAME) projects and displays data from FILENAME, according
%   to the type of file format. The DisplayType parameter is set
%   automatically, according to the following table:
%
%       Format                          DisplayType
%       ------                          -----------
%       shapefile                       'point', 'multipoint, 'line', 
%                                       or 'polygon'
%       GeoTIFF                         'image'
%       TIFF/JPEG/PNG with a world file 'image'
%       ARC ASCII GRID                  'surface' (may be overridden)
%       SDTS raster                     'surface' (may be overridden)
%
%   GEOSHOW(AX, ...) sets the axes parent to AX. This is equivalent to 
%   GEOSHOW(..., 'Parent', AX, ...)
%
%   H = GEOSHOW(...) returns a handle to a MATLAB graphics object or, in
%   the case of polygons, a modified patch object.  If a geopoint vector,
%   geoshape vector, geostruct, or shapefile name is input, GEOSHOW returns
%   the handle to an hggroup object with one child per feature, excluding
%   any features that are completely trimmed away.  In the case of polygon
%   vector data, each child is a modified patch object; otherwise it is a
%   line object.
%
%   GEOSHOW(..., Name, Value) specifies name-value pairs that modify the
%   type of display or set MATLAB graphics properties. Parameter names can
%   be abbreviated and are case-insensitive. Refer to the MATLAB Graphics
%   documentation on line, patch, image, surface, mesh, and contour for a
%   complete description of these properties and their values.
%
%   Map Projection
%   --------------
%   When projecting data, GEOSHOW uses the projection stored with the axes,
%   if available.  Otherwise it constructs a default Plate Carree
%   projection with a scale factor of 180/pi, enabling direct readout of
%   coordinates in degrees.
%
%   Example 1 
%   ---------
%   % Display world land areas using a default Plate Carree projection.
%   figure
%   geoshow('landareas.shp','FaceColor',[0.5 1.0 0.5])
%
%   Example 2 
%   ---------
%   % Create a world map of North America, and
%   % override default polygon properties.
%   figure
%   worldmap('na');
%
%   % Read the USA high resolution data.
%   states = shaperead('usastatehi','UseGeoCoords',true);
%
%   % Create a SymbolSpec to display Alaska and Hawaii as red polygons.
%   symbols = makesymbolspec('Polygon', ...
%       {'Name','Alaska','FaceColor','red'}, ...
%       {'Name','Hawaii','FaceColor','red'});
%
%   % Display all the other states in blue.
%   geoshow(states, 'SymbolSpec',symbols, ...
%       'DefaultFaceColor','blue','DefaultEdgeColor','black')
%   
%   Example 3 
%   ---------
%   % Create a map of the Korea data grid
%   % and display as a texture map.
%   load korea5c
%   figure
%   worldmap(korea5c,korea5cR)
%
%   % Display the Korean data grid as a texture map.
%   geoshow(gca,korea5c,korea5cR,'DisplayType','texturemap');
%   demcmap(korea5c)
%
%   % Display the land area boundary as black lines.
%   S = shaperead('landareas','UseGeoCoords',true);
%   geoshow([S.Lat], [S.Lon], 'Color' ,'black')
%
%   Example 4
%   ---------
%   % Display the EGM96 geoid heights as a texture map
%   % using the Eckert projection.
%   R = georefcells([-90 90],[0 360],1,1);
%   N = egm96geoid(R);
%
%   % Create a figure with an Eckert projection.
%   figure
%   axesm eckert4;
%   framem
%   gridm
%   axis off
%
%   % Display the geoid height as a texture map.
%   geoshow(N,R,'DisplayType','texturemap')
%
%   % Create a colorbar and title.
%   cb = colorbar('southoutside');
%   xlabel = cb.XLabel;
%   xlabel.String = 'EGM96 Geoid Height in Meters';
%
%   % Mask out all the land.
%   geoshow('landareas.shp', 'FaceColor', 'black');
%
%   Example 5
%   ---------
%   % Display the EGM96 geoid heights as a 3-D surface
%   % using the Eckert projection.
%   R = georefcells([-90 90],[0 360],1,1);
%   N = egm96geoid(R);
%
%   % Create the figure with an Eckert projection.
%   figure
%   axesm eckert4;
%   axis off
%
%   % Display the geoid as a surface.
%   h = geoshow(N,R,'DisplayType','surface');
%
%   % Add light and material.
%   light
%   material(0.6*[ 1 1 1]);
%
%   % View as a 3-D surface.
%   view(3)
%   axis normal
%
%   Example 6
%   ---------
%   % Display the moon albedo image using a default Plate Carree projection
%   % and an orthographic projection.
%   load moonalb20c
%   
%   % Plate Carree projection.
%   figure
%   geoshow(moonalb20c,moonalb20cR)
%   
%   % Orthographic projection.
%   figure
%   axesm ortho 
%   geoshow(moonalb20c,moonalb20cR,'DisplayType','texturemap')
%   colormap gray
%   axis off
%
%   See also AXESM, MAKESYMBOLSPEC, MAPSHOW, MAPVIEW

% Copyright 1996-2020 The MathWorks, Inc.

% Verify the number of inputs.
narginchk(1,Inf)

[varargin{:}] = convertStringsToChars(varargin{:});

% Designate first argument (axes handle) as Parent if present.
varargin = designateAxesArgAsParentArg(mfilename, varargin{:});

% Read data from file if filename provided in argument list and insert
% results at the beginning of argument list.
varargin = importFromFileAndSetDataArgs(mfilename, varargin{:});

% Decide which function to use to display the data (based mainly on the
% data arguments at the beginning of varargin).
options.showVectorFcn = @geovectorshow;
options.showStructFcn = @geostructshow;
options.showVecFcn    = @geovecshow;
options.showRasterFcn = @georastershow;
showFcn = determineShowFcn(options, varargin{:});

% Show the data.
h = showFcn(varargin{:});

% Set the axes appearance properties.
setAxesProperties(h);

% Suppress output if called with no return value and no semicolon.
if nargout == 1
  varargout{1} = h;
end
