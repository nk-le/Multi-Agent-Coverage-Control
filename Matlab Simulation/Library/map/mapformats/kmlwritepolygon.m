function kmlwritepolygon(varargin)
%KMLWRITEPOLYGON Write geographic polygon to KML file
%
%   KMLWRITEPOLYGON(FILENAME, LAT, LON) writes the latitude and longitude
%   values specified by LAT and LON to disk in KML format as a polygon. The
%   altitude values in the KML file are set to 0 and the interpretation is
%   'clampToGround'.
%
%   KMLWRITEPOLYGON(FILENAME, LAT, LON, ALT) writes the latitude,
%   longitude, and altitude values specified by LAT, LON, and ALT, to disk
%   in KML format as a polygon. The altitude values are interpreted as
%   'relativeToSeaLevel'.
%
%   KMLWRITEPOLYGON(__, Name, Value) specifies name-value pairs that set
%   additional KML feature properties. Parameter names can be abbreviated
%   and are case-insensitive.
%
%   Input Arguments
%   ---------------
%   FILENAME  - String scalar or character vector specifying the output 
%               file name and location. If an extension is included, it
%               must be '.kml'.
%
%   LAT       - Vector of class single or double specifying latitudes in 
%               the range [-90 90].
%
%   LON       - Vector of class single or double specifying longitudes.  
%               All longitudes are cut and wrapped to the range [-180 180].
%
%   ALT       - Numeric vector or scalar. If ALT is a scalar, the value is
%               applied to each point, otherwise it has the same length as
%               LAT and LON. The altitude values are in units of meter. The
%               altitude interpretation is 'relativeToSeaLevel'.
%
%   The name-value pairs are listed below:
%
%     Name
%          A string scalar or character vector which specifies a name
%          displayed in the viewer as the label for the polygon. If the
%          vertex list contains multiple outer rings, a folder is created
%          with the value of Name and each outer ring is labeled 'Part N'
%          where N varies from 1 to the number of outer rings. The default
%          value is 'Polygon 1'.
%
%     Description
%          A string scalar or character vector which specifies the contents
%          to be displayed in the polygon's description tag(s). The
%          description appears in the description balloon when the user
%          clicks on either the feature name in the Google Earth Places
%          panel or clicks the polygon in the viewer window.
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
%     FaceColor
%          A MATLAB Color Specification (ColorSpec) (char, string, scalar
%          cellstr, or a 1-by-3 numeric vector with values between 0 and 1)
%          that specifies the color of the polygon face. The value 'none'
%          indicates that the polygon is not filled. If unspecified, a
%          value is not included in the file and the face color is
%          determined by the viewer.
%
%     FaceAlpha
%          A numeric scalar with value between 0 and 1 that specifies the
%          transparency of the polygon face. If unspecified, the value is
%          1 (fully opaque).
%
%     EdgeColor
%          A MATLAB Color Specification (ColorSpec) (char, string, scalar
%          cellstr, or 1-by-3 numeric vector with values between 0 and 1)
%          that specifies the color of the polygon edge. The value 'none'
%          indicates that the polygon has no outline. If unspecified, a
%          value is not included in the file and the edge color is
%          determined by the viewer.
%
%     EdgeAlpha
%          A numeric scalar with value between 0 and 1 that specifies the
%          transparency of the polygon edge. If unspecified, the value is
%          1 (fully opaque).
%
%     LineWidth
%          A positive numeric scalar that specifies the width of the
%          polygon edge in pixels. If unspecified, a value is not included
%          in the file and the width of the edge is determined by the
%          viewer.
%
%     Extrude
%          A logical scalar or numeric 0 or 1 that specifies whether to
%          connect the polygon to the ground. If unspecified, a value is
%          not included in the file and the polygon is not extruded.
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
%          polygon. The value specifies the view in terms of the point of
%          interest that is being viewed. The view is defined by the fields
%          of the geopoint vector, outlined in the table below. LookAt is
%          limited to looking down at a feature, you cannot tilt the
%          virtual camera to look above the horizon into the sky.
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
%          A scalar geopoint vector that defines the virtual camera that
%          views the scene. The value defines the position of the camera
%          relative to the Earth's surface as well as the viewing direction
%          of the camera. The camera position is defined by the fields of
%          the geopoint vector, outlined in the table below. The camera
%          value provides full six-degrees-of-freedom control over the
%          view, so you can position the camera in space and then rotate it
%          around the X, Y, and Z axes. Most importantly, you can tilt the
%          camera view so that you're looking above the horizon into the
%          sky.
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
%   % Write coastlines to a KML file as a polygon.
%   load coastlines
%   filename = 'coastlines.kml';
%   kmlwritepolygon(filename,coastlat,coastlon)
%
%   Example 2
%   ---------
%   % Create a polygon with an inner ring around the Eiffel Tower.
%   lat0 = 48.858288;
%   lon0 = 2.294548;
%   outerRadius = .02;
%   innerRadius = .01;
%   [lat1,lon1] = scircle1(lat0,lon0,outerRadius);
%   [lat2,lon2] = scircle1(lat0,lon0,innerRadius);
%   [lon2,lat2] = poly2ccw(lon2,lat2);
%   lat = [lat1; NaN; lat2];
%   lon = [lon1; NaN; lon2];
%   alt = 500;
%   filename = 'EiffelTower.kml';
%   kmlwritepolygon(filename,lat,lon,alt, ...
%     'EdgeColor','g','FaceColor','c','FaceAlpha',.5)
%
%   Example 3
%   ---------
%   % Create a polygon that spans the 180 meridian. The polygon
%   % is automatically cut and a seam is visible in the polygon.
%   lat = [0 1 1 0 0];
%   lon = [179.5 179.5 -179.5 -179.5 179.5];
%   h = 5000;
%   alt = ones(1,length(lat)) * h;
%   filename = 'cross180.kml';
%   kmlwritepolygon(filename,lat,lon,alt,'EdgeColor','r','FaceColor','w')
%
%   % To remove the seam, set PolygonCutMeridian to 0.
%   filename = 'noseam.kml';
%   kmlwritepolygon(filename,lat,lon,alt,'EdgeColor','r', ...
%      'FaceColor','w','PolygonCutMeridian',0);
%
%   % To display a ramp without a seam, wrap the longitude values to the
%   % range [0 360] and set CutPolygon to false. Extrude the polygon to 
%   % the ground for better visibility.
%   filename = 'ramp.kml';
%   lon360 = wrapTo360(lon);
%   altramp = [0 0 h h 0];
%   kmlwritepolygon(filename,lat,lon360,altramp,'EdgeColor','r', ...
%      'FaceColor','w','CutPolygons',false,'Extrude',true);
%
%   See also KMLWRITE, KMLWRITEPOINT, KMLWRITELINE, SHAPEWRITE

% Copyright 2015-2017 The MathWorks, Inc.

% Verify the number of varargin inputs.
narginchk(3,inf);

% Parse the input.
[varargin{:}] = convertStringsToChars(varargin{:});
[filename, S, options] = map.internal.kmlparse(mfilename, 'polygon', varargin{:});

% Create a KML document object.
kml = map.internal.KMLDocument;

% Set the properties from the options structure.
map.internal.setProperties(kml, options);

% Add S to the document.
addFeature(kml, S);

% Write the KML document to the file.
write(kml, filename);
