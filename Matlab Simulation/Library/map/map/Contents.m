% Mapping Toolbox
% Version 5.1 (R2021a) 14-Nov-2020
%
% GEOSPATIAL DATA IMPORT AND ACCESS
%
% Geospatial Raster Files
%   georasterinfo  - Information about geospatial raster data file
%   readgeoraster  - Read geospatial raster data file
%
% Standard File Formats
%   geotiffinfo    - Information about GeoTIFF file
%   geotiffwrite   - Write GeoTIFF file
%   getworldfilename - Derive worldfile name from image file name
%   gpxread        - Read GPX file
%   kmlwrite        - Write geographic data to KML file
%   kmlwriteline    - Write geographic line to KML file
%   kmlwritepoint   - Write geographic points to KML file
%   kmlwritepolygon - Write geographic polygon to KML file
%   makeattribspec - Attribute specification structure
%   makedbfspec    - DBF specification structure
%   sdtsinfo       - Information about SDTS data set
%   shapeinfo      - Information about shapefile
%   shaperead      - Read vector features and attributes from shapefile
%   shapewrite     - Write geographic vector data to shapefile
%   worldfileread  - Read world file and return referencing object or matrix
%   worldfilewrite - Write world file from referencing object or matrix
%   map.geotiff.RPCCoefficientTag - Rational Polynomial Coefficients Tag
%
% Web Map Service
%   wmsfind         - Search local database for Web map servers and layers
%   wmsinfo         - Information about WMS server from capabilities document
%   wmsread         - Retrieve WMS map from server
%   wmsupdate       - Synchronize WMSLayer object with server
%   WebMapServer    - Web map server object
%   WMSCapabilities - Web Map Service capabilities object
%   WMSLayer        - Web Map Service layer object
%   WMSMapRequest   - Web Map Service map request object
%
% Gridded Terrain and Bathymetry Product Filenames
%   dteds        - DTED filenames for latitude-longitude quadrangle
%   globedems    - GLOBE data filenames for latitude-longitude quadrangle
%   gtopo30s     - GTOPO30 data filenames for latitude-longitude quadrangle
%   usgsdems     - USGS 1-Degree DEM filenames for latitude-longitude quadrangle
%
% Vector Map Products
%   dcwdata      - Read selected DCW worldwide basemap data
%   dcwgaz       - Search DCW worldwide basemap gazette file
%   dcwread      - Read DCW worldwide basemap file
%   dcwrhead     - Read DCW worldwide basemap file headers
%   gshhs        - Read Global Self-consistent Hierarchical High-resolution Shoreline
%   vmap0data    - Read selected data from Vector Map Level 0
%   vmap0read    - Read Vector Map Level 0 file
%   vmap0rhead   - Read Vector Map Level 0 file headers
%
% Miscellaneous Data Sets
%   avhrrgoode   - Read AVHRR data product stored in Goode projection
%   avhrrlambert - Read AVHRR data product stored in eqaazim projection
%
%  GUIs for Data Import 
%   demdataui    - UI for selecting digital elevation data
%   vmap0ui      - UI for selecting data from Vector Map Level 0
%
% VECTOR MAP DATA AND GEOGRAPHIC DATA STRUCTURES
%
% Geographic Data Representation
%   geopoint - Geographic point vector
%   geoshape - Geographic shape vector
%   mappoint - Planar point vector
%   mapshape - Planar shape vector
%   extractfield - Field values from structure array
%   extractm     - Coordinate data from line or patch display structure
%   updategeostruct - Convert line or patch display structure to geostruct
%
% Data Manipulation
%   bufferm     - Buffer zones for latitude-longitude polygons
%   flatearthpoly - Insert points along dateline to pole
%   interpm     - Densify latitude-longitude sampling in lines or polygons
%   intrplat    - Interpolate latitude at given longitude
%   intrplon    - Interpolate longitude at given latitude
%   ispolycw    - True if polygon vertices are in clockwise order
%   nanclip     - Clip vector data with NaNs at specified pen-down locations
%   poly2ccw    - Convert polygon contour to counterclockwise vertex ordering
%   poly2cw     - Convert polygon contour to clockwise vertex ordering
%   poly2fv     - Convert polygonal region to patch faces and vertices
%   polycut     - Compute branch cuts for holes in polygons
%   polymerge   - Merge line segments with matching endpoints
%   reducem     - Reduce density of points in vector data
%
% Utilities for NaN-Separated Polygons and Lines
%   closePolygonParts  - Close all rings in multipart polygon
%   isShapeMultipart   - True if polygon or line has multiple parts
%   polyjoin    - Convert line or polygon parts from cell arrays to vector form
%   polysplit   - Convert line or polygon parts from vector form to cell arrays
%   removeExtraNanSeparators - Clean up NaN separators in polygons and lines
%
%
% GEOREFERENCED IMAGES AND DATA GRIDS
%
% Raster Reference Objects
%   georefcells    - Reference raster cells to geographic coordinates
%   georefpostings - Reference raster postings to geographic coordinates
%   maprefcells    - Reference raster cells to map coordinates
%   maprefpostings - Reference raster postings to map coordinates
%   georasterref - Construct geographic raster reference object
%   maprasterref - Construct map raster reference object
%   refmatToGeoRasterReference - Referencing matrix to geographic raster reference object
%   refmatToMapRasterReference - Referencing matrix to map raster reference object
%   refvecToGeoRasterReference - Referencing vector to geographic raster reference object
%   map.rasterref.GeographicCellsReference - Reference raster cells to geographic coordinates
%   map.rasterref.GeographicPostingsReference - Reference raster postings to geographic coordinates
%   map.rasterref.MapCellsReference - Reference raster cells to map coordinates
%   map.rasterref.MapPostingsReference - Reference raster postings to map coordinates
%
% Raster Referencing
%   latlon2pix  - Convert latitude-longitude coordinates to pixel coordinates
%   map2pix     - Convert map coordinates to pixel coordinates
%   mapoutline  - Compute outline of georeferenced image or data grid
%   pix2latlon  - Convert pixel coordinates to latitude-longitude coordinates
%   pix2map     - Convert pixel coordinates to map coordinates
%   refmatToWorldFileMatrix - Convert referencing matrix to world file matrix
%
% Terrain Analysis
%   gradientm   - Calculate gradient, slope and aspect of data grid
%   los2        - Line of sight visibility between two points in terrain
%   viewshed    - Areas visible from point on terrain elevation grid
%
% Other Analysis/Access
%   areamat     - Surface area covered by non-zero values in binary data grid
%   filterm     - Filter latitudes/longitudes based on underlying data grid
%   findm       - Latitudes and longitudes of non-zero data grid elements
%   geocontourxy - Contour grid in local system with latitude-longitude results
%   geointerp   - Geographic raster interpolation
%   mapinterp   - Map raster interpolation
%   mapprofile  - Interpolate between waypoints on regular data grid
%
% Construction and Modification
%   changem     - Substitute values in data array
%   encodem     - Fill in regular data grid from seed values and locations
%   geocrop     - Crop a geographic raster
%   geoloc2grid - Convert geolocated data array to regular data grid
%   georesize   - Resize an unprojected raster
%   imbedm      - Encode data points into regular data grid
%   mapcrop     - Crop a projected raster
%   mapresize   - Resize a projected raster
%   neworig     - Orient regular data grid to oblique aspect
%   vec2mtx     - Convert latitude-longitude vectors to regular data grid
%
%
% MAP PROJECTIONS AND COORDINATES
%
% Coordinate Reference System Representation
%   geocrs      - Geographic coordinate reference system
%   projcrs     - Projected coordinate reference system
%
% Available Map Projection IDs (for map axes and map projection structures)
%   maps        - List map projections for map axes and map projection structures
%   maplist     - Map projection support for map axes and map projection structures
%   projlist    - GeoTIFF info structure support for PROJFWD and PROJINV
%
% Map Projection Transformations
%   projfwd     - Project latitude-longitude coordinates to x-y map coordinates
%   projinv     - Unproject x-y map coordinates to latitude-longitude coordinates
%
% Angles, Scales and Distortions
%   vfwdtran    - Direction angle in map plane from azimuth on ellipsoid
%   vinvtran    - Azimuth on ellipsoid from direction angle in map plane
%   distortcalc - Distortion parameters for map projections
%
% Visualizing Map Distortions
%   mdistort    - Display contours of constant map distortion
%   tissot      - Project Tissot indicatrices on map axes
%
% Cylindrical Projections
%   balthsrt    - Balthasart Cylindrical Projection
%   behrmann    - Behrmann Cylindrical Projection
%   bsam        - Bolshoi Sovietskii Atlas Mira Cylindrical Projection
%   braun       - Braun Perspective Cylindrical Projection
%   cassini     - Cassini Transverse Cylindrical Projection
%   cassinistd  - Cassini Transverse Cylindrical Projection -- Standard
%   ccylin      - Central Cylindrical Projection
%   eqacylin    - Equal Area Cylindrical Projection
%   eqdcylin    - Equidistant Cylindrical Projection
%   giso        - Gall Isographic Cylindrical Projection
%   gortho      - Gall Orthographic Cylindrical Projection
%   gstereo     - Gall Stereographic Cylindrical Projection
%   lambcyln    - Lambert Equal Area Cylindrical Projection
%   mercator    - Mercator Cylindrical Projection
%   miller      - Miller Cylindrical Projection
%   pcarree     - Plate Carree Cylindrical Projection
%   tranmerc    - Transverse Mercator Projection
%   trystan     - Trystan Edwards Cylindrical Projection
%   wetch       - Wetch Cylindrical Projection
%
% Pseudocylindrical Projections
%   apianus     - Apianus II Pseudocylindrical Projection
%   collig      - Collignon Pseudocylindrical Projection
%   craster     - Craster Parabolic Pseudocylindrical Projection
%   eckert1     - Eckert I Pseudocylindrical Projection
%   eckert2     - Eckert II Pseudocylindrical Projection
%   eckert3     - Eckert III Pseudocylindrical Projection
%   eckert4     - Eckert IV Pseudocylindrical Projection
%   eckert5     - Eckert V Pseudocylindrical Projection
%   eckert6     - Eckert VI Pseudocylindrical Projection
%   flatplrp    - McBryde-Thomas Flat-Polar Parabolic Projection
%   flatplrq    - McBryde-Thomas Flat-Polar Quartic Projection
%   flatplrs    - McBryde-Thomas Flat-Polar Sinusoidal Projection
%   fournier    - Fournier Pseudocylindrical Projection
%   goode       - Goode Homolosine Pseudocylindrical Projection
%   hatano      - Hatano Asymmetrical Equal Area Pseudocylindrical Projection
%   kavrsky5    - Kavraisky V Pseudocylindrical Projection
%   kavrsky6    - Kavraisky VI Pseudocylindrical Projection
%   loximuth    - Loximuthal Pseudocylindrical Projection
%   modsine     - Tissot Modified Sinusoidal Pseudocylindrical Projection
%   mollweid    - Mollweide Pseudocylindrical Projection
%   putnins5    - Putnins P5 Pseudocylindrical Projection
%   quartic     - Quartic Authalic Pseudocylindrical Projection
%   robinson    - Robinson Pseudocylindrical Projection
%   sinusoid    - Sinusoidal Pseudocylindrical Projection
%   wagner4     - Wagner IV Pseudocylindrical Projection
%   winkel      - Winkel I Pseudocylindrical Projection
%
% Conic Projections
%   eqaconic    - Albers Equal Area Conic Projection
%   eqaconicstd - Albers Equal Area Conic Projection -- Standard
%   eqdconic    - Equidistant Conic Projection
%   eqdconicstd - Equidistant Conic Projection -- Standard
%   lambert     - Lambert Conformal Conic Projection
%   lambertstd  - Lambert Conformal Conic Projection -- Standard
%   murdoch1    - Murdoch I Conic Projection
%   murdoch3    - Murdoch III Minimum Error Conic Projection
%
% Polyconic and Pseudoconic Projections
%   bonne       - Bonne Pseudoconic Projection
%   polycon     - Polyconic Projection
%   polyconstd  - Polyconic Projection -- Standard
%   vgrint1     - Van Der Grinten I Polyconic Projection
%   werner      - Werner Pseudoconic Projection
%
% Azimuthal, Pseudoazimuthal and Modified Azimuthal Projections
%   aitoff      - Aitoff Modified Azimuthal Projection
%   breusing    - Breusing Harmonic Mean Azimuthal Projection
%   bries       - Briesemeister's Modified Azimuthal Projection
%   eqaazim     - Lambert Equal Area Azimuthal Projection
%   eqdazim     - Equidistant Azimuthal Projection
%   gnomonic    - Gnomonic Azimuthal Projection
%   hammer      - Hammer Modified Azimuthal Projection
%   ortho       - Orthographic Azimuthal Projection
%   stereo      - Stereographic Azimuthal Projection
%   vperspec    - Vertical Perspective Azimuthal Projection
%   wiechel     - Wiechel Equal Area Pseudoazimuthal Projection
%
% UTM and UPS Systems
%   ups         - Universal Polar Stereographic system
%   utm         - Universal Transverse Mercator system
%   utmgeoid    - Select ellipsoid for given UTM zone
%   utmzone     - Select UTM zone given latitude and longitude
%
% Rotating Coordinates on the Sphere
%   newpole     - Origin vector to place specific point at pole
%   org2pol     - Location of north pole on rotated map
%   putpole     - Origin vector to place north pole at specific point
%
% Map Trimming
%   maptriml    - Trim lines to latitude-longitude quadrangle
%   maptrimp    - Trim polygons to latitude-longitude quadrangle
%
% Trimming and Clipping
%   clipdata    - Clip data to +/- pi in longitude, +/- pi/2 in latitude
%   trimcart    - Trim graphic objects to map frame
%   trimdata    - Trim map data exceeding projection limits
%   undoclip    - Remove object clips introduced by CLIPDATA
%   undotrim    - Remove object trims introduced by TRIMDATA
%
%
% MAP DISPLAY AND INTERACTION
%
% Map Creation and High-Level Display
%   axesm       - Define map axes and set map properties
%   displaym    - Display geographic data from display structure
%   geoshow     - Display map latitude and longitude data
%   grid2image  - Display regular data grid as image
%   mapshow     - Display map data without projection
%   mapview     - Interactive map viewer
%   usamap      - Construct map axes for United States of America
%   worldmap    - Construct map axes for given region of world
%
% Vector Symbolization
%   makesymbolspec  - Construct vector symbolization specification 
%
% Displaying Lines and Contours
%   contourm    - Project 2-D contour plot of map data
%   contour3m   - Project 3-D contour plot of map data
%   contourfm   - Project filled 2-D contour plot of map data 
%   linem       - Project line object on map axes
%   plotm       - Project 2-D lines and points on map axes
%   plot3m      - Project 3-D lines and points on map axes
%
% Displaying Patch Data
%   fillm       - Project filled 2-D patch objects on map axes
%   fill3m      - Project filled 3-D patch objects on map axes
%   patchesm    - Project patches on map axes as individual objects
%   patchm      - Project patch objects on map axes
%
% Displaying Data Grids
%   meshm       - Project regular data grid on map axes
%   pcolorm     - Project regular data grid on map axes in z = 0 plane
%   surfacem    - Project and add geolocated data grid to current map axes
%   surfm       - Project geolocated data grid on map axes
%
% Displaying Light Objects and Lighted Surfaces
%   lightm      - Project light objects on map axes
%   meshlsrm    - 3-D lighted shaded relief of regular data grid
%   surflm      - 3-D shaded surface with lighting on map axes
%   surflsrm    - 3-D lighted shaded relief of geolocated data grid
%   shaderel    - Construct cdata and colormap for shaded relief
%
% Displaying Thematic Maps
%   quiverm     - Project 2-D quiver plot on map axes
%   quiver3m    - Project 3-D quiver plot on map axes
%   scatterm    - Project point markers with variable color and area
%   stem3m      - Project stem plot on map axes
%   symbolm     - Project point markers with variable size
%
% Annotating Map Displays
%   clabelm     - Add contour labels to map contour display
%   clegendm    - Add legend labels to map contour display
%   contourcbar - Color bar for filled contour map display
%   framem      - Toggle and control display of map frame
%   gridm       - Toggle and control display of graticule lines
%   lcolorbar   - Append colorbar with text labels
%   mlabel      - Toggle and control display of meridian labels
%   mlabelzero22pi - Convert meridian labels to 0 to 360-degree range
%   northarrow  - Add graphic element pointing to geographic North Pole
%   plabel      - Toggle and control display of parallel labels
%   rotatetext  - Rotate text to projected graticule
%   scaleruler  - Add or modify graphic scale on map axes
%   textm       - Project text annotation on map axes
%
% Colormaps for Map Displays
%   contourcmap - Contour colormap and colorbar for current axes
%   demcmap     - Colormaps appropriate to terrain elevation data
%   polcmap     - Colormaps appropriate to political regions
%
% Interactive Map Positions
%   gcpmap      - Get current mouse point from map axes
%   gtextm      - Place text on map using mouse
%   inputm      - Return latitudes and longitudes of mouse click locations
%
% Interactive Track and Circle Definition
%   scircleg    - Small circle defined via mouse input
%   sectorg     - Sector of small circle defined via mouse input
%   trackg      - Great circle or rhumb line defined via mouse input
%   scirclui    - Interactive tool for adding small circles to a map
%   trackui     - Interactive tool for adding great circles and rhumb lines to a map
%
% Graphical User Interfaces
%   axesmui     - Interactively define map axes properties
%   clrmenu     - Add colormap menu to figure window
%   maptrim     - Customize map data sets
%   maptool     - Add menu activated tools to map figure
%   originui    - Interactively modify map origin
%   parallelui  - Interactively modify map parallels
%   surfdist    - Interactive distance, azimuth and reckoning calculations
%   uimaptbx    - Process button down callbacks for mapped objects
%   utmzoneui   - Choose or identify UTM zone by clicking on map
%
% Map Object and Projection Properties
%   cart2grn    - Transform projected coordinates to Greenwich system
%   defaultm    - Initialize or reset map projection structure
%   gcm         - Current map projection structure
%   geotiff2mstruct - Convert GeoTIFF information to map projection structure
%   getm        - Map object properties
%   handlem     - Handles of displayed map objects
%   ismap       - True for axes with map projection
%   ismapped    - True if object is projected on map axes
%   namem       - Determine names for valid map graphics objects
%   rotatem     - Transform map data to new origin and orientation
%   setm        - Set properties of map axes and graphics objects
%   tagm        - Set tag property of map graphics objects
%   zdatam      - Adjust z-plane of displayed map objects
%
% Controlling Map Appearance
%   axesscale   - Resize axes for equivalent scale
%   camposm     - Set camera position using geographic coordinates
%   camtargm    - Set camera target using geographic coordinates
%   camupm      - Set camera up vector using geographic coordinates
%   daspectm    - Control vertical exaggeration in map display
%   paperscale  - Set figure properties for printing at specified map scale
%   previewmap  - Preview map at printed size
%   tightmap    - Remove white space around map
%
% Clearing Map Displays/Managing Visibility
%   clma        - Clear current map axes
%   clmo        - Clear specified graphic objects from map axes
%   hidem       - Hide specified graphic objects on map axes
%   showaxes    - Toggle display of map coordinate axes
%   showm       - Show specified graphic objects on map axes
%
% Three-Dimensional Globe Display
%   geoglobe    - Create 3-D geographic globe
%   geoplot3    - Geographic globe plot
%
%
% WEB MAP DISPLAY
%
% Open/Close/Print Web Map
%   webmap      - Open web map
%   wmclose     - Close web map
%   wmprint     - Print web map
%
% Display/Remove Data on Web Map
%   wmline      - Display geographic line on web map
%   wmmarker    - Display geographic marker on web map
%   wmpolygon   - Display geographic polygon on web map
%   wmremove    - Remove overlay on web map
%
% Set/Obtain Web Map Extent
%   wmcenter    - Set or obtain web map center point
%   wmlimits    - Set or obtain web map limits
%   wmzoom      - Set or obtain web map zoom level
%
% Add/Remove Custom Basemaps
%   addCustomBasemap    - Add use of custom basemap
%   removeCustomBasemap - Remove use of custom basemap
%
%
% GEOGRAPHIC CALCULATIONS
%
% Geometry of Sphere and Ellipsoid
%   antipode    - Point on opposite side of globe
%   areaint     - Surface area of polygon on sphere or ellipsoid
%   areaquad    - Surface area of latitude-longitude quadrangle
%   azimuth     - Azimuth between points on sphere or ellipsoid
%   departure   - Departure of longitudes at specific latitudes
%   distance    - Distance between points on sphere or ellipsoid
%   ellipse1    - Geographic ellipse from center, semimajor axes, eccentricity and azimuth
%   gc2sc       - Center and radius of great circle
%   meridianarc - Ellipsoidal distance along meridian
%   meridianfwd - Reckon position along meridian
%   reckon      - Point at specified azimuth, range on sphere or ellipsoid
%   scircle1    - Small circles from center, range and azimuth
%   scircle2    - Small circles from center and perimeter
%   track1      - Geographic tracks from starting point, azimuth and range
%   track2      - Geographic tracks from starting and ending points
%
% Reference Ellipsoids, Spheroids, and Geoid
%   axes2ecc    - Eccentricity of ellipse from axes lengths
%   earthRadius - Mean radius of planet Earth
%   ecc2flat    - Flattening of ellipse from eccentricity
%   ecc2n       - Third flattening of ellipse from eccentricity
%   egm96geoid  - Geoid height from Earth Gravitational Model 1996 (EGM96)
%   flat2ecc    - Eccentricity of ellipse from flattening
%   majaxis     - Semimajor axis of ellipse
%   minaxis     - Semiminor axis of ellipse
%   n2ecc       - Eccentricity of ellipse from third flattening
%   rcurve      - Ellipsoidal radii of curvature
%   rsphere     - Radii of auxiliary spheres
%   oblateSpheroid - Oblate ellipsoid of revolution
%   referenceEllipsoid - Reference ellipsoid
%   referenceSphere    - Reference sphere
%   wgs84Ellipsoid - Reference ellipsoid for World Geodetic System 1984
%
% Auxiliary Latitudes
%   geocentricLatitude - Convert geodetic to geocentric latitude
%   parametricLatitude - Convert geodetic to parametric latitude
%   geodeticLatitudeFromGeocentric - Convert geocentric to geodetic latitude
%   geodeticLatitudeFromParametric - Convert parametric to geodetic latitude
%   map.geodesy.AuthalicLatitudeConverter   - Convert between geodetic and authalic latitudes
%   map.geodesy.ConformalLatitudeConverter  - Convert between geodetic and conformal latitudes
%   map.geodesy.IsometricLatitudeConverter  - Convert between geodetic and isometric latitudes
%   map.geodesy.RectifyingLatitudeConverter - Convert between geodetic and rectifying latitudes
%
% Three-Dimensional Coordinate Transformations between Global Systems
%   geodetic2ecef - Transform geodetic to geocentric (ECEF) coordinates
%   ecef2geodetic - Transform geocentric (ECEF) to geodetic coordinates
%   ecefOffset - Cartesian ECEF offset between geodetic positions
%   lookAtSpheroid - Line of sight intersection with oblate spheroid
%
% Three-Dimensional Global-Local Coordinate Transformations
%   geodetic2enu - Geodetic to local Cartesian ENU
%   geodetic2ned - Geodetic to local Cartesian NED
%   geodetic2aer - Geodetic to local spherical AER
%   enu2geodetic - Local Cartesian ENU to geodetic
%   ned2geodetic - Local Cartesian NED to geodetic
%   aer2geodetic - Local spherical AER to geodetic
%   ecef2enu - Geocentric ECEF to local Cartesian ENU
%   ecef2ned - Geocentric ECEF to local Cartesian NED
%   ecef2aer - Geocentric ECEF to local spherical AER
%   enu2ecef - Local Cartesian ENU to geocentric ECEF
%   ned2ecef - Local Cartesian NED to geocentric ECEF
%   aer2ecef - Local spherical AER to geocentric ECEF
%
% Three-Dimensional Coordinate Transformations between Local Systems
%   aer2enu - Local spherical AER to local Cartesian ENU
%   aer2ned - Local spherical AER to local Cartesian NED
%   enu2aer - Local Cartesian ENU to local spherical AER
%   ned2aer - Local Cartesian NED to local spherical AER
%
% Three-Dimensional Vector Rotations between Cartesian Systems
%   ecef2enuv - Rotate vector from geocentric ECEF to local ENU
%   ecef2nedv - Rotate vector from geocentric ECEF to local NED
%   enu2ecefv - Rotate vector from local ENU to geocentric ECEF
%   ned2ecefv - Rotate vector from local NED to geocentric ECEF
%
% Geographic Quadrangles
%   bufgeoquad  - Expand limits of geographic quadrangle
%   geoquadline - Geographic quadrangle bounding multi-part line
%   geoquadpt   - Geographic quadrangle bounding scattered points
%   ingeoquad   - True for points inside or on lat-lon quadrangle
%   intersectgeoquad - Intersection of two latitude-longitude quadrangles
%   outlinegeoquad   - Polygon outlining geographic quadrangle
% 
% Overlaying Geometric Objects
%   circcirc    - Intersections of circles in Cartesian plane
%   gcxgc       - Intersection points for pairs of great circles
%   gcxsc       - Intersection points for great and small circle pairs
%   linecirc    - Intersections of circles and lines in Cartesian plane
%   polyshape   - Create polyshape object (MATLAB Toolbox)
%   polyxpoly   - Intersection points for lines or polygon edges
%   rhxrh       - Intersection points for pairs of rhumb lines
%   scxsc       - Intersection points for pairs of small circles
%
% Geographic Statistics
%   eqa2grn     - Convert from equal area to Greenwich coordinates
%   grn2eqa     - Convert from Greenwich to equal area coordinates
%   hista       - Histogram for geographic points with equal-area bins
%   histr       - Histogram for geographic points with equirectangular bins
%   meanm       - Mean location of geographic points
%   stdist      - Standard distance for geographic points
%   stdm        - Standard deviation for geographic points
%
% Navigation
%   crossfix    - Cross fix positions from bearings and ranges
%   dreckon     - Dead reckoning positions for track
%   driftcorr   - Heading to correct for wind or current drift
%   driftvel    - Wind or current velocity from heading, course, and speeds
%   gcwaypts    - Equally spaced waypoints along great circle track
%   legs        - Courses and distances between navigational waypoints
%   navfix      - Mercator-based navigational fix
%   timezone    - Time zone based on longitude
%   track       - Track segments to connect navigational waypoints
%
% Spherical Distance Conversions
%   deg2km      - Convert distance from degrees to kilometers
%   deg2nm      - Convert distance from degrees to nautical miles
%   deg2sm      - Convert distance from degrees to statute miles
%   km2deg      - Convert distance from kilometers to degrees
%   km2rad      - Convert distance from kilometers to radians
%   nm2deg      - Convert distance from nautical miles to degrees
%   nm2rad      - Convert distance from nautical miles to radians
%   rad2km      - Convert distance from radians to kilometers
%   rad2nm      - Convert distance from radians to nautical miles
%   rad2sm      - Convert distance from radians to statute miles
%   sm2deg      - Convert distance from statute miles to degrees
%   sm2rad      - Convert distance from statute miles to radians
%
%
% UTILITIES
%
% Angle Unit Conversions
%   deg2rad     - Convert angles from degrees to radians (MATLAB Toolbox)
%   rad2deg     - Convert angles from radians to degrees (MATLAB Toolbox)
%   degrees2dm  - Convert degrees to degrees-minutes
%   degrees2dms - Convert degrees to degrees-minutes-seconds
%   dm2degrees  - Convert degrees-minutes to degrees
%   dms2degrees - Convert degrees-minutes-seconds to degrees
%   fromDegrees - Convert angles from degrees
%   fromRadians - Convert angles from radians
%   str2angle   - Convert strings to angles in degrees
%   toDegrees   - Convert angles to degrees
%   toRadians   - Convert angles to radians
%
% Length Unit Conversions
%   km2nm       - Convert kilometers to nautical miles
%   km2sm       - Convert kilometers to statute miles
%   nm2km       - Convert nautical miles to kilometers
%   nm2sm       - Convert nautical to statute miles
%   sm2km       - Convert statute miles to kilometers
%   sm2nm       - Convert statute to nautical miles
%
% Conversion Factors for Angle and Length Units
%   unitsratio  - Unit conversion factors
%
% Image Conversion
%   ind2rgb8    - Convert indexed image to uint8 RGB image
%
% Longitude or Azimuth Wrapping
%  unwrapMultipart - Unwrap vector of angles with NaN-delimited parts
%  wrapTo180    - Wrap angle in degrees to [-180 180]
%  wrapTo360    - Wrap angle in degrees to [0 360]
%  wrapToPi     - Wrap angle in radians to [-pi pi]  
%  wrapTo2Pi    - Wrap angle in radians to [0 2*pi]
%
% String Formatters
%   angl2str     - Format angle strings
%   dist2str     - Format distance strings
%
% Validation
%   map.geodesy.isDegree - True if string matches 'degree' and false if 'radian'
%   validateLengthUnit - Validate and standardize length unit string

% Copyright 1996-2020 The MathWorks, Inc.

% Not recommended or to be removed: MAP
%   almanac     - Parameters for Earth, planets, Sun, and Moon
%   angledim    - Convert angle units
%   combntns    - All possible combinations of a set of values
%   convertlat  - Convert between geodetic and auxiliary latitudes
%   distdim     - Convert distance units
%   eastof      - Wrap longitudes to values east of specified meridian
%   elevation   - Local vertical elevation angle, range, and azimuth
%   epsm        - Accuracy in angle units for certain map computations
%   npi2pi      - Wrap latitudes to [-180 180] degree interval
%   polybool    - Set operations on polygonal regions
%   smoothlong  - Remove discontinuities in longitude data
%   unitstr     - Check unit strings or abbreviations
%   westof      - Wrap longitudes to values west of specified meridian
%   zero22pi    - Wrap longitudes to [0 360) degree interval
%
%   aut2geod - Convert authalic latitude to geodetic latitude
%   cen2geod - Convert geocentric latitude to geodetic latitude
%   cnf2geod - Convert conformal latitude to geodetic latitude
%   iso2geod - Convert isometric latitude to geodetic latitude
%   par2geod - Convert parametric latitude to geodetic latitude
%   rec2geod - Convert rectifying latitude to geodetic latitude
%
%   geod2aut - Convert geodetic latitude to authalic latitude
%   geod2cen - Convert geodetic latitude to geocentric latitude
%   geod2cnf - Convert geodetic latitude to conformal latitude
%   geod2iso - Convert geodetic latitude to isometric latitude
%   geod2par - Convert geodetic latitude to parametric latitude
%   geod2rec - Convert geodetic latitude to rectifying latitude
%
%   refmat2vec - Convert referencing matrix to referencing vector
%   refvec2mat - Convert referencing vector to referencing matrix
%
%   limitm     - Latitude and longitude limits for regular data grid
%   makerefmat - Construct affine spatial-referencing matrix
%   mapbbox    - Compute bounding box of georeferenced image or data grid
%   meshgrat   - Construct map graticule for surface object display
%   pixcenters - Compute pixel centers for georeferenced image or data grid
%   setltln    - Convert data grid rows and columns to latitude-longitude
%   setpostn   - Convert latitude-longitude to data grid rows and columns
%   worldFileMatrixToRefmat - Convert world file matrix to referencing matrix
%
%   nanm    - Construct regular data grid of NaNs
%   onem    - Construct regular data grid of 1s
%   spzerom - Construct sparse regular data grid of 0s
%   zerom   - Construct regular data grid of 0s
%   sizem   - Row and column dimensions needed for regular data grid
%
%   ltln2val - Extract data grid values for specified locations
%   maptrims - Trim regular data grid to latitude-longitude quadrangle
%   resizem - Resize regular data grid
%
%   spatialref.GeoRasterReference - Reference raster to geographic coordinates
%   spatialref.MapRasterReference - Reference raster to map coordinates
%
% Not recommended or to be removed: MAPDISP
%   colorm      - Create index map colormaps
%   colorui     - Interactively define RGB color
%   cometm      - Project 2-D comet plot on map axes
%   comet3m     - Project 3-D comet plot on map axes
%   getseeds    - Interactively assign seeds for data grid encoding
%   lightmui    - Control position of lights on globe or 3-D map
%   makemapped  - Convert ordinary graphics object to mapped object
%   mlayers     - Control plotting of display structure elements
%   mobjects    - Manipulate object sets displayed on map axes
%   panzoom     - Zoom settings on 2-D map
%   project     - Project displayed map graphics object
%   qrydata     - Create queries associated with map axes
%   restack     - Restack objects within map axes
%   rootlayr    - Construct cell array of workspace variables for MLAYERS tool
%   seedm       - Interactively fill regular data grids with seed values
%
% Not recommended or to be removed: MAPFORMATS
%   arcgridread - Read gridded data set in ArcGrid ASCII or GridFloat format
%   dted         - Read U.S. Dept. of Defense Digital Terrain Elevation Data (DTED)
%   etopo       - Read gridded global relief data (ETOPO products)
%   etopo5      - Read 5-minute gridded terrain/bathymetry from global ETOPO5 data set
%   fipsname    - Read FIPS name file used with TIGER thinned boundary files
%   geotiffread - Read GeoTIFF file
%   globedem    - Read Global Land One-km Base Elevation (GLOBE) data
%   grepfields  - Identify matching records in fixed record length files
%   gtopo30     - Read 30-arc-second global digital elevation data (GTOPO30)
%   readfields  - Read fields or records from fixed format file
%   readfk5     - Read Fifth Fundamental Catalog of stars
%   readmtx     - Read matrix stored in file
%   satbath     - Read 2-minute global terrain/bathymetry from Smith and Sandwell
%   sdtsdemread - Read data from SDTS raster/DEM data set
%   spcread     - Read columns of data from ASCII text file
%   tbase       - Read 5-minute global terrain elevations from TerrainBase
%   tgrline     - Read TIGER/Line data
%   usgs24kdem  - Read USGS 7.5-minute (30-m or 10-m) Digital Elevation Model
%   usgsdem     - Read USGS 1-degree (3-arc-second) Digital Elevation Model
%
% Not recommended or to be removed: MAPOBSOLETE (formerly SHARED/MAPGEODESY)
%   ecef2lv - Convert geocentric (ECEF) to local vertical coordinates
%   lv2ecef - Convert local vertical to geocentric (ECEF) coordinates
%   geocentric2geodeticLat - Convert geocentric to geodetic latitude
%   geodetic2geocentricLat - Convert geodetic to geocentric latitude
%
% Not recommended or to be removed: MAPPROJ
%   mfwdtran    - Project geographic features to map coordinates
%   minvtran    - Unproject features from map to geographic coordinates
%
% Not recommended or to be removed: SHARED/MAPUTILS
%   degtorad - Convert angles from degrees to radians
%   radtodeg - Convert angles from radians to degrees
%   roundn   - Round to multiple of 10^n
%
% Undocumented functions: MAP
%   checkangleunits - Check and standardize angle units string
%   checkellipsoid  - Check validity of reference ellipsoid vector
%   checkgeoquad    - Validate limits of geographic quadrangle
%   checklatlon     - Validate pair of latitude-longitude arrays
%   ignoreComplex   - Convert complex input to real and issue warning
%   mapdemos        - Index of Mapping Toolbox examples
%   num2ordinal     - Convert positive integer to ordinal string
%
% Undocumented functions: MAPDISP (used by MAPTOOL)
%   clrpopup    - Processes callback from color popup menus
%   varpick     - Modal pick list to select a variable from the workspace
%
% Undocumented functions: MAPDISP (used outside MAPDISP)
%   degchar     - Return the LaTeX degree symbol character
%   leadblnk    - Delete leading characters common to all rows of a string matrix
%   shiftspc    - Left or right justify a string matrix
%
% Deleted functions: MAP
%   checkrefmat - Check validity of referencing matrix (was undocumented)
%   checkrefvec - Check validity of referencing vector (was undocumented)
%   deg2dm      - Convert angles from degrees to deg:min encoding
%   deg2dms     - Convert angles from degrees to deg:min:sec encoding
%   dms2deg     - Convert angles from deg:min:sec encoding to degrees
%   dms2dm      - Convert angles from deg:min:sec to deg:min encoding
%   dms2mat     - Expand deg:min:sec encoded vector to [deg min sec] matrix
%   dms2rad     - Convert angles from deg:min:sec encoding to radians
%   hms2hm      - Convert time from hrs:min:sec to hrs:min encoding
%   hms2hr      - Convert time from hrs:min:sec encoding to hours
%   hms2mat     - Expand hrs:min:sec encoded vector to [hrs min sec] matrix
%   hms2sec     - Convert time from hrs:min:sec encoding to seconds
%   hr2hm       - Convert time from hours to hrs:min encoding
%   hr2hms      - Convert time from hours to hrs:min:sec encoding
%   hr2sec      - Convert time from hours to seconds
%   mat2dms     - Collapse [deg min sec] matrix to deg:min:sec encoding
%   mat2hms     - Collapse [hrs min sec] matrix to hrs:min:sec encoding
%   rad2dm      - Convert angles from radians to deg:min encoding
%   rad2dms     - Convert angles from radians to deg:min:sec encoding
%   sec2hm      - Convert time from seconds to hrs:min encoding
%   sec2hms     - Convert time from seconds to hrs:min:sec encoding
%   sec2hr      - Convert time from seconds to hours
%   time2str    - Format time strings
%   timedim     - Convert time units or encodings
%
% Deleted functions: MAPDISP
%   contorm     - Project a contour plot of data onto the current map axes
%   contor3m    - Project a 3D contour plot of data onto the current map axes
%   cmapui      - Create custom colormap
%   maphlp1     - Help Utility for Selected GUIs (undocumented function)
%   maphlp2     - Help Utility for Selected GUIs (undocumented function)
%   maphlp3     - Help Utility for Selected GUIs (undocumented function)
%   maphlp4     - Help Utility for Selected GUIs (undocumented function)
%
% Deleted functions: MAPFORMATS
%   tigermif    - Read a TIGER MIF thinned boundary file
%   tigerp      - Read TIGER p and pa thinned boundary files
%
% Deleted functions: MAP (previously public, but undocumented)
%   elpcalc     - Volume and surface area of an oblate spheroid
%   eqacalc     - Transform data to/from an equal area space
%   geoidtst    - Test for a valid geoid vector
%   merccalc    - Transform data to/from a Mercator space
%   sphcalc     - Compute volume and surface area for a sphere
