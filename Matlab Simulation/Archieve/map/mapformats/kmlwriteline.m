function kmlwriteline(varargin)
%KMLWRITELINE Write geographic line to KML file
%
%   KMLWRITELINE(FILENAME, LAT, LON) writes the latitude and longitude
%   values specified by LAT and LON to disk in KML format as a line. The
%   altitude values in the KML file are set to 0 and the interpretation is
%   'clampToGround'.
%
%   KMLWRITELINE(FILENAME, LAT, LON, ALT) writes the latitude, longitude,
%   and altitude values specified by LAT, LON, and ALT, to disk in KML
%   format as a line. The altitude values are interpreted as
%   'relativeToSeaLevel'.
%
%   KMLWRITELINE(__, Name, Value) specifies name-value pairs that set
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
%          A string scalar or character vector which specifies a name
%          displayed in the viewer as the label for the line. If
%          unspecified, Name is set to 'Line 1'. If the line contains NaN
%          values, the line segments are placed in a folder labeled with
%          'Line 1' and the line segments are labeled 'Segment N', where N
%          varies from 1 to the number of segments.
%
%     Description
%          A string scalar or character vector which specifies the contents
%          to be displayed in the line's description tag. The description
%          appears in the description balloon when the user clicks on
%          either the feature name in the Google Earth Places panel or
%          clicks the line in the viewer window.
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
%     Color
%          A MATLAB Color Specification (ColorSpec) (char string, cellstr,
%          or numeric vector with values between 0 and 1) that specifies
%          the color of the line. If the value is a cell array, it is
%          scalar. If the value is a numeric vector, it is size 1-by-3. The
%          value 'none' indicates that a color value is not included in the
%          file. If unspecified, a value is not included in the file and
%          the color of the line is determined by the viewer.
%
%     Alpha
%          A numeric scalar with value between 0 and 1 that specifies the
%          transparency of the line. If unspecified, the value is 1 (fully
%          opaque).
%
%     LineWidth
%          A positive numeric scalar which specifies the width of the line
%          in pixels. If unspecified, a value is not included in the file
%          and the width of the line is determined by the viewer.
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
%          A scalar geopoint vector that defines the virtual camera that
%          views the line. The value specifies the view in terms of the
%          line of interest that is being viewed. The view is defined by
%          the fields of the geopoint vector, outlined in the table below.
%          LookAt is limited to looking down at a feature, you cannot tilt
%          the virtual camera to look above the horizon into the sky.
%           
%          Property     
%          Name       Description                     Data Type
%          ---------  ---------------------------     ---------
%          Latitude   Latitude of the line the       Scalar double
%                     camera is looking at in degrees
%            
%          Longitude  Longitude of the line the      Scalar double
%                     camera is looking at in degrees 
%
%          Altitude   Altitude of the line the       Scalar numeric
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
%                     line to the LookAt position    
%
%          AltitudeMode 
%                     Specifies how the altitude is   Permissible values:
%                     interpreted for the LookAt      'relativeToSeaLevel',
%                     line (optional)                'clampToGround', 
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
%          Latitude   Latitude of the eye line       Scalar double
%                     (virtual camera) in degrees
%            
%          Longitude  Longitude of the eye line      Scalar double
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
%   % Write coast lines to a KML file as a black line.
%   load('coastlines');
%   filename = 'coastlines.kml';
%   kmlwriteline(filename,coastlat,coastlon,'Color','k','LineWidth',3)
%
%   Example 2
%   ---------
%   % Write a single GPS track log to a KML file.
%   points = gpxread('sample_tracks');
%   lat = points.Latitude;
%   lon = points.Longitude;
%   alt = points.Elevation;
%   filename = 'track.kml';
%   kmlwriteline(filename,lat,lon,alt,'Name','Track Log', ...
%      'Description',points.Metadata.Name)
%
%   Example 3
%   ---------
%   % Display equally spaced waypoints along a great circle track
%   % from London to New York with altitude values and the same
%   % track clamped to the ground. Use a LookAt virtual camera
%   % to view the two lines.
%   cities = geopoint(shaperead('worldcities','UseGeoCoords',true));
%   city1 = 'London';
%   city2 = 'New York';
%   pt1 = cities(strcmp(city1,cities.Name));
%   pt2 = cities(strcmp(city2,cities.Name));
%   lat1 = pt1.Latitude;
%   lon1 = pt1.Longitude;
%   lat2 = pt2.Latitude;
%   lon2 = pt2.Longitude;
%   nlegs = 20;
%   [lat,lon] = gcwaypts(lat1,lon1,lat2,lon2,nlegs);
%   midpoint = nlegs/2;
%   altscale = 5000;
%   alt = [0:midpoint midpoint-1:-1:0] * altscale;
%   lookLat = 49.155804;
%   lookLon = -56.698494;
%   lookAt = geopoint(lookLat, lookLon);
%   lookAt.Range = 2060400;
%   lookAt.Heading = 10;
%   lookAt.Tilt = 70;
%   width = 4;
%   filename1 = 'altitudetrack.kml';
%   kmlwriteline(filename1,lat,lon,alt,'Color','k','LineWidth',width)
%   filename2 = 'groundtrack.kml';
%   kmlwriteline(filename2,lat,lon,alt,'Color','w','LineWidth',width, ...
%      'LookAt',lookAt,'AltitudeMode','clampToGround')
%
%   See also KMLWRITE, KMLWRITEPOINT, KMLWRITEPOLYGON, SHAPEWRITE

% Copyright 2012-2017 The MathWorks, Inc.

% Verify the number of varargin inputs.
narginchk(3, inf);

% Parse the input.
[varargin{:}] = convertStringsToChars(varargin{:});
[filename, S, options] = map.internal.kmlparse(mfilename, 'line', varargin{:});

% Create a KML document object.
kml = map.internal.KMLDocument;

% Set the properties from the options structure.
map.internal.setProperties(kml, options);

% Add S to the document.
addFeature(kml, S);
 
% Write the KML document to the file.
write(kml, filename);
