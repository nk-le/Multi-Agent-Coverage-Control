function kmlwritepoint(varargin)
%KMLWRITEPOINT Write geographic points to KML file
%
%   KMLWRITEPOINT(FILENAME, LAT, LON) writes the latitude and longitude
%   points specified by LAT and LON to disk in KML format. The altitude
%   values in the KML file are set to 0 and the interpretation is
%   'clampToGround'.
%
%   KMLWRITEPOINT(FILENAME, LAT, LON, ALT) writes the latitude, longitude,
%   and altitude points specified by LAT, LON, and ALT, to disk in KML
%   format. The altitude values are interpreted as 'relativeToSeaLevel'.
%
%   KMLWRITEPOINT(__, Name, Value) specifies name-value pairs that set
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
%          A string, character vector or cell array of character vectors
%          which specifies a name displayed in the viewer as the label for
%          the points. If the value is a string scalar or character vector,
%          the name is applied to all points. If the value is a string
%          vector or cell array, it is the same size as LAT and LON. If
%          unspecified, Name is set to 'Point N' where N is the point
%          number.
%
%     Description
%          A string, character vector or cell array of character vectors,
%          which specifies the contents to be displayed in the point's
%          description tag(s). The description appears in the description
%          balloon when the user clicks on either the point name in the
%          Google Earth Places panel or clicks the placemark icon in the
%          viewer window. If the value is a string scalar or character
%          vector, the description is applied to all points. If the value
%          is a string vector or cell array, it is the same size as LAT and
%          LON. Use a string vector or cell array to customize descriptive
%          tags for different placemarks.
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
%     Icon
%          A string, character vector or cell array of character vectors
%          which specifies a custom icon filename. If the value is a string
%          scalar or character vector, the value is applied to all points.
%          If the value is a string vector or cell array, it is the same
%          length as LAT and LON.  If the icon filename is not in the
%          current folder, or in a folder on the MATLAB path, specify a
%          full or relative pathname. The string may be an Internet URL.
%          The URL must include the protocol type.
%
%     IconScale
%          A positive numeric scalar or vector which specifies a scaling
%          factor for the icon. If the value is a scalar, the value is
%          applied to all points. If the value is a vector, it is the same
%          length as LAT and LON.
%
%     Color
%          A MATLAB Color Specification (ColorSpec) (char, string, cellstr,
%          or numeric array with values between 0 and 1) that specifies the
%          color of the icons. If the value is a cell array, it is scalar
%          or the same length as LAT and LON. If the value is a numeric
%          array, it is size M-by-3 where M is the length of LAT or LON.
%          The value 'none' indicates that a color value is not included in
%          the file. If unspecified, a value is not included in the file
%          and the color is determined by the viewer.
%
%     Alpha
%          A numeric scalar or vector with values between 0 and 1 that
%          specifies the transparency of the icons. If the value is not
%          scalar, it is the same length as LAT and LON. If unspecified,
%          the value is 1.
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
%          points. If the value is a scalar, the value is applied to all
%          the points; otherwise, the length of the value is the same
%          length as LAT and LON. The value specifies the view in terms of
%          the point of interest that is being viewed. The view is defined
%          by the fields of the geopoint vector, outlined in the table
%          below. LookAt is limited to looking down at a feature, you
%          cannot tilt the virtual camera to look above the horizon into
%          the sky.
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
%          as LAT and LON. The value defines the position of the camera
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
%   % Write a single point to a KML file.
%   % Add a description containing HTML, a name and an icon.
%   lat =  42.299827;
%   lon = -71.350273;
%   description = sprintf('%s<br>%s</br><br>%s</br>', ...
%      '3 Apple Hill Drive', 'Natick, MA. 01760', ...
%      'https://www.mathworks.com');
%   name = 'The MathWorks, Inc.';
%   iconDir = fullfile(matlabroot,'toolbox','matlab','icons');
%   iconFilename = fullfile(iconDir,'matlabicon.gif');
%   filename = 'MathWorks.kml';
%   kmlwritepoint(filename,lat,lon,'Name',name,'Icon',iconFilename, ...
%      'Description',description);
%
%   Example 2
%   ---------
%   % Write the locations of major European cities to a KML file,  
%   % including the names of the cities.
%   latlim = [30; 75];
%   lonlim = [-25; 45];
%   cities = shaperead('worldcities.shp','UseGeoCoords',true, ...
%      'BoundingBox',[lonlim, latlim]);
%   filename = 'European_Cities.kml';
%   lat = [cities.Lat];
%   lon = [cities.Lon];
%   name = {cities.Name};
%   kmlwritepoint(filename,lat,lon,'Name',name,'IconScale',2)
%
%   Example 3
%   ---------
%   % View the Washington Monument in Washington D.C. with a camera.
%   % Place a marker at the ground location of the camera.
%   filename = 'WashingtonMonument.kml';
%   camlat = 38.889301;
%   camlon = -77.039731;
%   camera = geopoint(camlat,camlon);
%   camera.Altitude = 500;
%   camera.Heading = 90;
%   camera.Tilt = 45;
%   camera.Roll = 0;
%   name = 'Camera ground location';
%   lat = camera.Latitude;
%   lon = camera.Longitude;
%   kmlwritepoint(filename,lat,lon,'Camera',camera,'Name',name)
%
%   Example 4
%   ---------
%   % Create a placemark for Machu Picchu, Peru with a LookAt virtual
%   % camera.
%   filename = 'Machu_Picchu.kml';
%   lat = -13.163111;
%   lon = -72.544945;
%   alt = 2430;
%   name = 'Machu Picchu';
%   lookAt = geopoint(lat,lon);
%   lookAt.Range = 1500;
%   lookAt.Heading = 260;
%   lookAt.Tilt = 67;
%   kmlwritepoint(filename,lat,lon,alt,'Name',name,'LookAt',lookAt)
%
%   See also KMLWRITE, KMLWRITELINE, KMLWRITEPOLYGON, SHAPEWRITE

% Copyright 2012-2017 The MathWorks, Inc.

% Verify the number of varargin inputs.
narginchk(3, inf);

% Parse the input.
[varargin{:}] = convertStringsToChars(varargin{:});
[filename, S, options] = map.internal.kmlparse(mfilename, 'point', varargin{:});

% Create a KML document object.
kml = map.internal.KMLDocument;

% Set the properties from the options structure.
map.internal.setProperties(kml, options);

% Add S to the document.
addFeature(kml, S);
 
% Write the KML document to the file.
write(kml, filename);
