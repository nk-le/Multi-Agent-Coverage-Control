function kmlwrite(varargin)
%KMLWRITE Write geographic data to KML file
%
%   KMLWRITE(FILENAME, S) writes the geographic point, line, or polygon
%   features stored in S to disk in KML format.
%
%   KMLWRITE(FILENAME, ADDRESS) specifies the location of a KML Placemark
%   via an unstructured address with city, state, and/or postal code.
%
%   KMLWRITE(__, Name, Value) specifies name-value pairs that set
%   additional KML feature properties. Parameter names can be abbreviated
%   and are case-insensitive.
%
%   The following syntaxes are not recommended. Use the function 
%   <a href="matlab:help kmlwritepoint">kmlwritepoint</a> instead.
%
%   KMLWRITE(FILENAME, LAT, LON) writes the latitude and longitude points
%   specified by LAT and LON to disk in KML format. The altitude values in
%   the KML file are set to 0 and the interpretation is 'clampToGround'.
%
%   KMLWRITE(FILENAME, LAT, LON, ALT) writes the latitude, longitude, and
%   altitude points specified by LAT, LON, and ALT, to disk in KML format.
%   The altitude values are interpreted as 'relativeToSeaLevel'.
%
%   Input Arguments
%   ---------------
%   FILENAME  - String scalar or character vector specifying the output 
%               file name and location. If an extension is included, it
%               must be '.kml'.
%
%   S         - A geopoint vector, geoshape vector, or a geostruct (with
%              'Lat' and 'Lon' fields).
%
%               If S is a geostruct and includes 'X' and 'Y' fields an
%               error is issued. The attribute fields of S are displayed as
%               a table in the description tag of the placemark for each
%               element of S, in the same order as they appear in S.
%
%               If S contains a field named either Elevation, Altitude, or
%               Height then the field values are written to the file as the
%               KML altitudes. If more than one name is included in S, then
%               a warning is issued and the altitude fields are ignored. If
%               a valid altitude field is contained in S, then the field
%               values are interpreted as 'relativeToSeaLevel', otherwise
%               altitude is set to 0 and is interpreted as 'clampToGround'.
%
%   ADDRESS   - String, character vector or cell array of character vectors 
%               which specifies the location of a KML Placemark. Each
%               entry represents an unstructured address with city, state,
%               and/or postal code. If ADDRESS is a cell array or string
%               vector, each entry represents a unique point.
%
%   LAT       - Vector of class single or double specifying latitudes in 
%               the range [-90 90].
%
%   LON       - Vector of class single or double specifying longitudes.  
%               All longitudes are automatically wrapped to the range 
%               [-180 180], to adhere to the KML specification.
%
%   ALT       - Numeric vector or scalar. If ALT is a scalar, the value is
%               applied to each point, otherwise it has the same length as
%               LAT and LON. The altitude values are in units of meter. The
%               altitude interpretation is 'relativeToSeaLevel'.
%
%   The name-value pairs are listed below:
%
%     Name
%          A string, character vector or cell array of character vectors
%          which specifies a name displayed in the viewer as the label for
%          the object. If the value is a string scalar or character vector,
%          the name is applied to all objects. If the value is a string
%          vector or cell array, it has the same length as LAT and LON, S,
%          or ADDRESS.
%
%          If unspecified, Name is set to 'Address N' for address data,
%          'Point N' for point data, 'Multipoint N' for multipoint data,
%          'Line N' for line data, or 'Polygon N' for polygon data where N
%          is the specific address, point, multipoint, line, or polygon
%          number. If multipoint data is written, the points are placed in
%          the named folder and labeled 'Point M', where M is the specific
%          number of that point. If line data is written and the line
%          contains NaN values, the line segments are placed in the
%          corresponding line folder and labeled 'Segment M' where M is the
%          specific line segment number. If polygon data is written and the
%          polygon vertex list for the feature contains multiple outer
%          rings, each outer ring is placed in the corresponding named
%          folder and labeled 'Part M' where M is the specific polygon
%          outer ring number for that feature.
%
%     Description
%          A string, character vector, cell array of character vectors, or
%          attribute spec, which specifies the contents to be displayed in
%          the feature's description tag(s). The description appears in the
%          description balloon when the user clicks on either the feature
%          name in the Google Earth Places panel or clicks the placemark
%          icon in the viewer window. If the value is a string scalar or
%          character vector, the description is applied to all objects. If
%          the value is a string vector or cell array, it has the same
%          length as LAT and LON, S, or ADDRESS.  Use a string vector or
%          cell array to customize descriptive tags for different
%          placemarks.
%
%          Description elements can be either plain text or marked up with
%          HTML. When it is plain text, Google Earth applies basic
%          formatting, replacing newlines with <br> and giving anchor tags
%          to all valid URLs for the World Wide Web. The URLs are
%          converted to hyperlinks. This means that you do not need to
%          surround a URL with <a href> tags in order to create a simple
%          link. Examples of HTML tags recognized by Google Earth are
%          provided at http://earth.google.com.
%
%          When an attribute spec is provided, the attribute fields of S
%          are displayed as a table in the description tag of the placemark
%          for each element of S. The attribute spec is ignored with LAT
%          and LON input. The attribute spec controls:
%
%             * Which attributes are included in the table
%             * The name for the attribute
%             * The order in which attributes appear
%             * The formatting of numeric-valued attributes
%
%          The easiest way to construct an attribute spec is to call
%          makeattribspec, then modify the output to remove attributes or
%          change the Format field for one or more attributes.
%
%          Note that the latitude and longitude coordinates of S are not
%          considered to be attributes. If included in an attribute spec,
%          they are ignored.
%
%     Icon
%          A string, character vector or cell array of character vectors
%          which specifies a custom icon filename. If the value is a string
%          scalar or character vector, the value is applied to all objects.
%          If the value is a string vector or cell array, it has the same
%          length as LAT and LON, S, or ADDRESS.  If the icon filename is
%          not in the current folder, or in a folder on the MATLAB path,
%          specify a full or relative pathname. The value may be an
%          Internet URL. The URL must include the protocol type.
%
%     IconScale
%          A positive numeric scalar or vector which specifies a scaling
%          factor for the icon. If the value is a scalar, the value is
%          applied to all objects. If the value is a vector, it has the
%          same length as LAT and LON, S, or ADDRESS.
%
%     Color
%          A MATLAB Color Specification (ColorSpec) (char, string, cellstr,
%          or numeric array with values between 0 and 1) that specifies the
%          color of the icons, lines, or the faces and edges of polygons.
%          If the value is a cell array, it is scalar or the same length as
%          LAT and LON, S, or ADDRESS. If the value is a numeric array, it
%          is size M-by-3 where M is the length of LAT, LON, S, or ADDRESS.
%          If S is a polygon geoshape then you may specify the value 'none'
%          to indicate that the polygon is not filled and has no edge. If S
%          is a polygon geoshape, the value is applied to the polygon faces
%          if FaceColor is not specified and polygon edges if EdgeColor is
%          not specified. If unspecified, a value is not included in the
%          file and the color is determined by the viewer.
%
%     Alpha
%          A numeric scalar or vector with values between 0 and 1 that
%          specifies the transparency of the icons, lines, or the faces and
%          edges of polygons. If the value is not scalar, it is the same
%          length as LAT, LON, S, or ADDRESS. If S is a polygon geoshape,
%          the value is applied to the polygon faces if FaceAlpha is not
%          specified and the polygon edges if EdgeAlpha is not specified.
%          If unspecified, the value is 1 (fully opaque).
%
%     LineWidth
%          A positive numeric scalar or vector that specifies the width of
%          the lines or polygon edges in pixels. If the value is scalar it
%          applies to all lines or polygon edges. If the value is a vector,
%          it is the same length as S. If unspecified, a value is not
%          included in the file and the width is determined by the viewer.
%
%     FaceColor
%          A MATLAB Color Specification (ColorSpec) (char, string, cellstr,
%          or numeric array with values between 0 and 1) that specifies the
%          color of polygon faces. If the value is a cell array, it is
%          scalar or the same length as S. If the value is a numeric array,
%          it is size M-by-3 where M is the length of S. The value 'none'
%          indicates that polygons are not filled. If unspecified and Color
%          is specified, the Color value specifies the color of the polygon
%          faces. If both are unspecified, a value is not included in the
%          file and the face color is determined by the viewer.
%
%     FaceAlpha
%          A numeric scalar or vector with values between 0 and 1 that
%          specifies the transparency of the polygon faces. If the value is
%          scalar it applies to all polygon faces. If the value is a
%          vector, it is the same length as S. If unspecified and Alpha is
%          specified, the Alpha value specifies the transparency of the
%          polygon faces. If both are unspecified, the value is 1 (fully
%          opaque).
%
%     EdgeColor
%          A MATLAB Color Specification (ColorSpec) (char, string, cellstr,
%          or numeric array with values between 0 and 1) that specifies the
%          color of the polygon edges. If the value is a cell array, it is
%          scalar or the same length as S. If the value is a numeric array,
%          it is size M-by-3 where M is the length of S. The value 'none'
%          indicates that polygons have no outline. If unspecified and
%          Color is specified, the Color value specifies the color of the
%          polygon edges. If both are unspecified, a value is not included
%          in the file and the edge color is determined by the viewer.
%
%     EdgeAlpha
%          A numeric scalar or vector with values between 0 and 1 that
%          specifies the transparency of the polygon edges. If the value is
%          scalar it applies to all polygon edges. If the value is a
%          vector, it is the same length as S. If unspecified and Alpha is
%          specified, the Alpha value specifies the transparency of the
%          polygon edges. If both are unspecified, the value is 1 (fully
%          opaque).
%
%     Extrude
%          A logical scalar, numeric 0 or 1, or vector that specifies
%          whether to connect polygons to the ground. If the value is
%          scalar, it applies to all polygons. If the value is a vector, it
%          is the same length as S. If unspecified, a value is not included
%          in the file and the polygon is not extruded.
%
%     CutPolygons
%          A logical scalar or numeric 0 or 1 that specifies whether to cut
%          the polygon parts. If true, polygon parts are cut at the
%          PolygonCutMeridian value. If true, and polygon parts require
%          cutting and altitude values are non-uniform, an error is issued.
%          If unspecified, the value is true.
%
%    PolygonCutMeridian 
%          A scalar numeric that specifies the meridian where polygon parts
%          are cut. If unspecified, the value is 180.
%
%     AltitudeMode
%          A string scalar or character vector which specifies how altitude
%          values are interpreted. Permissible values are outlined in the
%          table below. If altitude values are not specified, the default
%          value is 'clampToGround', otherwise the default value is
%          'relativeToSeaLevel'.
%
%          Value                Description                    
%          ---------            -----------    
%          'clampToGround'      Indicates to ignore the altitude values and
%                               set the feature on the ground
%
%          'relativeToGround'   Sets altitude values relative to the actual
%                               ground elevation of a particular feature
%
%          'relativeToSeaLevel' Sets altitude values relative to sea level,
%                               regardless of the actual elevation values
%                               of the terrain beneath the feature
%                                                    
%     LookAt
%          A geopoint vector that defines the virtual camera that views the
%          points or lines. If the value is a scalar, the value is applied
%          to all the objects; otherwise, the length of the value is the
%          same length as LAT and LON, S, or ADDRESS. The value specifies
%          the view in terms of the point of interest that is being viewed.
%          The view is defined by the fields of the geopoint vector,
%          outlined in the table below. LookAt is limited to looking down
%          at a feature, you cannot tilt the virtual camera to look above
%          the horizon into the sky.
%           
%          Property     
%          Name       Description                     Data Type
%          ---------  ---------------------------     ---------
%          Latitude   Latitude of the point the       Scalar double
%                     camera is looking at in degrees
%            
%          Longitude  Longitude of the point the      Scalar double
%                     camera is looking at in degrees 
%
%          Altitude   Altitude of the point the       Scalar numeric
%                     camera is looking at in meters  default: 0
%                     (optional)   
%
%          Heading    Camera direction (azimuth)      Scalar numeric
%                     in degrees (optional)           [0 360], default: 0
%
%          Tilt       Angle between the direction of  Scalar numeric
%                     the LookAt position and the     [0 90], default: 0
%                     normal to the surface of the
%                     Earth (optional)               
% 
%          Range      Distance in meters from the     Scalar numeric
%                     point to the LookAt position    
%
%          AltitudeMode 
%                     Specifies how the altitude is   Permissible values:
%                     interpreted for the LookAt      'relativeToSeaLevel',
%                     point (optional)                'clampToGround', 
%                                           (default) 'relativeToGround'
%
%     Camera
%          A geopoint vector that defines the virtual camera that views the
%          scene. If the value is a scalar, the value is applied to all the
%          objects; otherwise, the length of the value is the same length
%          as LAT and LON, S, or ADDRESS. The value defines the position of
%          the camera relative to the Earth's surface as well as the
%          viewing direction of the camera. The camera position is defined
%          by the fields of the geopoint vector, outlined in the table
%          below. The camera value provides full six-degrees-of-freedom
%          control over the view, so you can position the camera in space
%          and then rotate it around the X, Y, and Z axes. Most
%          importantly, you can tilt the camera view so that you're looking
%          above the horizon into the sky.
%           
%          Property     
%          Name       Description                     Data Type
%          ---------  ---------------------------     ---------
%          Latitude   Latitude of the eye point       Scalar double
%                     (virtual camera) in degrees
%            
%          Longitude  Longitude of the eye point      Scalar double
%                     (virtual camera) in degrees 
%
%          Altitude   Distance of the camera from     Scalar numeric
%                     the Earth's surface, in meters 
%
%          Heading    Camera direction (azimuth)      Scalar numeric
%                     in degrees (optional)           [0 360], default 0
%
%          Tilt       Camera rotation in degrees      Scalar numeric
%                     around the X axis (optional)    [0 180] default: 0
% 
%          Roll       Camera rotation in degrees      Scalar numeric
%                     around the Z axis (optional)    default: 0
%
%          AltitudeMode 
%                     Specifies how camera altitude   Permissible values:
%                     is interpreted. (optional)      'relativeToSeaLevel',
%                                                     'clampToGround',
%                                           (default) 'relativeToGround'
%
%   Example 1
%   ---------
%   % Write the locations of the Boston placenames to a KML file.
%   placenames = gpxread('boston_placenames');
%   filename = 'Boston_Placenames.kml';
%   colors = jet(length(placenames));
%   kmlwrite(filename,placenames,'Name',placenames.Name,'Color',colors)
%
%   Example 2
%   ---------
%   % Write tracks from a GPX file to a KML file as a set of lines. 
%   % Set the color of the first line to red and the second to green.
%   % Set the width of both lines to 2.
%   % Set the description of each to the value in Metadata.Name.
%   % Set the names to 'track1' and 'track2'.
%   tracks = gpxread('sample_tracks', 'Index', 1:2);
%   filename = 'tracks.kml';
%   colors = {'red','green'};
%   description = tracks.Metadata.Name;
%   name = {'track1','track2'};
%   kmlwrite(filename,tracks,'Color',colors,'LineWidth',2, ...
%      'Description',description,'Name',name)
% 
%   Example 3
%   ---------
%   % Write the locations of major European cities to a KML file, including 
%   % the names of the cities, and remove the default description table.
%   latlim = [30; 75];
%   lonlim = [-25; 45];
%   cities = shaperead('worldcities.shp','UseGeoCoords',true, ...
%      'BoundingBox',[lonlim, latlim]);
%   cities = geopoint(cities);
%   filename = 'European_Cities.kml';
%   kmlwrite(filename,cities,'Name',cities.Name,'Description',{})
%
%   Example 4
%   ---------
%   % Write the USA state polygon data to a KML file.
%   S = shaperead('usastatelo','UseGeoCoords',true);
%   S = geoshape(S);
%   filename = 'usastatelo.kml';
%   colors = polcmap(length(S));
%   kmlwrite(filename,S,'Name',S.Name,'FaceColor',colors,'EdgeColor','k')
%
%   Example 5
%   ---------
%   % Write the locations of several Australian cities to a KML file, 
%   % using addresses.
%   address = {'Perth, Australia', ...
%              'Melbourne, Australia', ...
%              'Sydney, Australia'};
%   filename = 'Australian_Cities.kml';
%   kmlwrite(filename,address,'Name',address)
%
%   See also KMLWRITELINE, KMLWRITEPOINT, KMLWRITEPOLYGON, MAKEATTRIBSPEC, SHAPEWRITE

% Copyright 2007-2018 The MathWorks, Inc.

% Verify the number of varargin inputs.
narginchk(2,inf);

% Parse the input.
[varargin{:}] = convertContainedStringsToChars(varargin{:});
[filename, S, options] = map.internal.kmlparse(mfilename, 'any', varargin{:});

% Create a KML document object.
kml = map.internal.KMLDocument;

% Set the properties from the options structure.
map.internal.setProperties(kml, options);

% Add S to the document.
if isobject(S)
    addFeature(kml, S);
else
    addAddress(kml, S);
end

% Write the KML document to the file.
write(kml, filename);
