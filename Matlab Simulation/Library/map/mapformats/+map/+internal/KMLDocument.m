%KMLDocument Construct KML document object
%
%       FOR INTERNAL USE ONLY -- This class is intentionally undocumented
%       and is intended for use only within other toolbox classes and
%       functions. Its behavior may change, or the class itself may be
%       removed in a future release.
%
%   The KMLDocument class constructs an object to represent and write KML
%   elements to a file. The documentation for KML may be found at
%   https://developers.google.com/kml/documentation/kmlreference
%
%   KMLDocument properties:
%      DocumentName - Name of document
%      FolderName   - Name of folder
%      Description  - Description for feature
%      Name         - Label for feature
%      Icon         - Icon filename for feature
%      IconScale    - Scale of icon
%      Color        - Color of icon and line
%      Width        - Width of line
%      Camera       - Virtual camera for scene
%      LookAt       - Virtual camera for feature
%      AltitudeMode - Altitude interpretation
%      Alpha        - Alpha value (0 - 1)
%      FaceColor    - Color of polygon face
%      EdgeColor    - Color of polygon edge
%      FaceAlpha    - Alpha value of polygon face
%      EdgeAlpha    - Alpha value of polygon edge
%      LineWidth    - Width of polygon edge
%      Extrude      - Specifies whether polygon connects to ground 
%      CutPolygons  - Specifies whether to cut polygon parts
%      PolygonCutMeridian - Specifies meridian where polygon parts are cut
%
%   KMLDocument methods:
%      KMLDocument   - Construct KML document object
%      addAddress    - Add address or addresses to KML document
%      addFeature    - Add feature or features to KML document
%      addMultiPartFeature - Add multi-part feature(s) to KML document
%      write         - Write KML document to disk

% Copyright 2012-2020 The MathWorks, Inc.

classdef KMLDocument < handle
    
    properties (GetAccess = 'public', SetAccess = 'public', Dependent)
        %DocumentName Name of document
        %
        %   DocumentName is a string indicating the name of the document.
        %   The name appears as a text string in the viewer as the label
        %   for the document.
        DocumentName
        
        %FolderName Name of folder
        %
        %   FolderName is a string indicating the name of the folder
        %   containing the features. If unspecified, the folder is the
        %   document.
        FolderName
    end
    
    properties (Access = 'public')   
        %Description Description for feature
        %
        %   Description is a string or cell array of strings that specifies
        %   the contents to be displayed in the feature's description
        %   tag(s). The description appears in the description balloon when
        %   the user clicks on either the feature name in the Google Earth
        %   Places panel or clicks the placemark icon in the viewer window.
        Description 
        
        %Name Label for feature
        %
        %   Name is a string or cell array of strings which specifies a
        %   name displayed in the viewer as the label for the feature.
        Name
        
        %Icon Icon filename for feature
        %
        %   Icon is a string or cell array of strings which specifies a
        %   custom icon filename.  If the icon filename is not in the
        %   current folder, or in a folder on the MATLAB path, specify a
        %   full or relative pathname. The string may be an Internet URL.
        %   The URL must include the protocol type.
        Icon
        
        %IconScale Scale of icon
        %
        %   IconScale is a positive numeric scalar or vector which
        %   specifies a scaling factor for the icon.
        IconScale
        
        %Color Color of feature
        %
        %   Color is a string or cell array of strings that specify the
        %   alpha, red, green, blue color value of the icon or line. The
        %   color string is a KML color value: [alpha blue green red] in
        %   lower case hex. Color and opacity (alpha) values are expressed
        %   in hexadecimal notation. The range of values for any one color
        %   is 0 to 255 (00 to ff).
        Color
        
        %Width Width of line
        %
        %   Width is a positive numeric scalar or vector that specifies the
        %   width of the line in pixels. If unspecified, the width is 1.
        Width
        
        %LookAt Virtual camera for feature
        %
        %   A geopoint vector that defines the virtual camera that views
        %   the points or lines. The value specifies the view in terms of
        %   the point of interest that is being viewed. The view is defined
        %   by the fields of the geopoint vector, outlined in the table
        %   below. LookAt is limited to looking down at a feature, you can
        %   not tilt the virtual camera to look above the horizon into the
        %   sky.
        % 
        %   Property     
        %   Name       Description                     Data Type
        %   ---------  ---------------------------     ---------
        %   Latitude   Latitude of the point the       Scalar double
        %              camera is looking at in degrees
        % 
        %   Longitude  Longitude of the point the      Scalar double
        %              camera is looking at in degrees 
        % 
        %   Altitude   Altitude of the point the       Scalar numeric
        %              camera is looking at in meters  default: 0
        %              (optional)   
        % 
        %   Heading    Camera direction (azimuth)      Scalar numeric
        %              in degrees (optional)           [0 360], default: 0
        % 
        %   Tilt       Angle between the direction of  Scalar numeric
        %              the LookAt position and the     [0 90], default: 0
        %              normal to the surface of the
        %              Earth (optional)               
        % 
        %   Range      Distance in meters from the     Scalar numeric
        %              point to the LookAt position    
        % 
        %   AltitudeMode 
        %              Specifies how the altitude is   String with value:
        %              interpreted for the LookAt      'absolute',
        %              point (optional)                'clampToGround', 
        %                                   (default) 'relativeToGround'
        LookAt
        
        %Camera Virtual camera for scene
        %
        %   Camera is a geopoint vector that defines the virtual camera
        %   that views the scene. The value defines the position of the
        %   camera relative to the Earth's surface as well as the viewing
        %   direction of the camera. The camera position is defined by the
        %   fields of the geopoint vector, outlined in the table below. The
        %   camera value provides full six-degrees-of-freedom control over
        %   the view, so you can position the camera in space and then
        %   rotate it around the X, Y, and Z axes. Most importantly, you
        %   can tilt the camera view so that you're looking above the
        %   horizon into the sky.
        %
        %   Property     
        %   Name       Description                     Data Type
        %   ---------  ---------------------------     ---------
        %   Latitude   Latitude of the eye point       Scalar double
        %              (virtual camera) in degrees
        % 
        %   Longitude  Longitude of the eye point      Scalar double
        %              (virtual camera) in degrees 
        % 
        %   Altitude   Distance of the camera from     Scalar numeric
        %              the Earth's surface, in meters 
        % 
        %   Heading    Camera direction (azimuth)      Scalar numeric
        %              in degrees (optional)           [0 360], default 0
        % 
        %   Tilt       Camera rotation in degrees      Scalar numeric
        %              around the X axis (optional)    [0 180] default: 0
        % 
        %   Roll       Camera rotation in degrees      Scalar numeric
        %              around the Z axis (optional)    default: 0
        % 
        %   AltitudeMode 
        %              Specifies how camera altitude   String with value:
        %              is interpreted. (optional)      'absolute',
        %                                              'clampToGround',
        %                                    (default) 'relativeToGround'
        Camera
        
        %AltitudeMode Altitude interpretation
        %
        %   AltitudeMode is string or cell array of strings that specify
        %   how altitude values are interpreted. Permissible values are
        %   'absolute', 'clampToGround', and 'relativeToGround'.
        AltitudeMode
        
        %Alpha Alpha value (0 - 1)
        %
        %   Alpha is a numeric scalar or vector that specifies the alpha
        %   value of the Color property. The value range is 0 to 1.
        Alpha
        
        %FaceColor Color of polygon face
        %
        %   FaceColor is a string or cell array of strings that specify
        %   the alpha, red, green, blue color value of the polygon face.
        %   The color string is a KML color value: [alpha blue green red]
        %   in lower case hex. Color and opacity (alpha) values are
        %   expressed in hexadecimal notation. The range of values for any
        %   one color is 0 to 255 (00 to ff).
        FaceColor
        
        %EdgeColor Color of polygon edge
        %
        %   EdgeColor is a string or cell array of strings that specify
        %   the alpha, red, green, blue color value of the polygon edge.
        %   The color string is a KML color value: [alpha blue green red]
        %   in lower case hex. Color and opacity (alpha) values are
        %   expressed in hexadecimal notation. The range of values for any
        %   one color is 0 to 255 (00 to ff).
        EdgeColor
        
        %FaceAlpha Alpha value of polygon face
        %
        %   FaceAlpha is a numeric scalar or vector that specifies the
        %   alpha value which is applied to the FaceColor property. The
        %   value range is 0 to 1.
        FaceAlpha
        
        %EdgeAlpha Alpha value of polygon edge
        %
        %   EdgeAlpha is a numeric scalar or vector that specifies the
        %   alpha value which is applied to the EdgeColor property. The
        %   value range is 0 to 1.
        EdgeAlpha
         
        %LineWidth Width of polygon edge
        %
        %   LineWidth is a positive numeric scalar or vector that specifies
        %   the width of the polygon edge in pixels. If unspecified, the
        %   width is 1.
        LineWidth
                
        %Extrude Specifies whether polygon connects to ground
        %
        %   Extrude is a logical scalar or vector that specifies whether a
        %   polygon connects to the ground.
        Extrude
     
        %CutPolygons Specifies whether to cut polygon parts
        %
        %   CutPolygons is a logical scalar or numeric 0 or 1 that
        %   specifies whether to cut the polygon parts. If true, polygon
        %   parts are cut at the PolygonCutMeridian value. If true, and
        %   polygon parts require cutting, and altitude values are
        %   non-uniform, an error is issued. The default value is true.
        CutPolygons = true
        
        %PolygonCutMeridian Specifies meridian where polygon parts are cut
        %
        %   PolygonCutMeridian is a scalar numeric that specifies the
        %   meridian where polygon parts are cut. The default value is 180.
        PolygonCutMeridian = 180
    end
      
    properties (Hidden)
        %UseMultipartName Specify to use default multi-part name
        %
        %   UseMultipartName specifies whether to use an auto-generated
        %   multi-part name for multi-part features. A multi-part name
        %   consists of the following:
        %
        %       Geometry     Name
        %       --------     ----
        %       multipoint  'Multipoint number'
        %       line        'Segment number'
        %       polygon     'Part number'
        UseMultipartName = true
        
        %LatitudeLimits Latitude limits of cut polygons
        %
        %   LatitudeLimits are the latitude limits of the cut polygons.
        LatitudeLimits = [-90 90];
    end
    
    properties (Hidden, Dependent)
        %LongitudeLimits Longitude limits of cut polygons
        %
        %   LongitudeLimits are the longitude limits of the cut polygons.
        LongitudeLimits
    end
    
    properties (Access = 'private')
        DOM = []
        DocumentElement = []
        FolderElement = []
        pDocumentName = ''
        pFolderName = ''
        UseIconStyle = false
        UseLineStyle = false
        UsePolyStyle = false
        UseDefaultName = false        
    end
    

    
    methods

        function kml = KMLDocument(name)
        %KMLDocument Construct KML document object
        %
        %   kml = map.internal.KMLDocument() constructs a default KML
        %   document object.
        %
        %   kml = map.internal.KMLDocument(name) constructs a KML object
        %   and sets the DocumentName to name.

            % Create the XML DOM and the XML DocumentElement.
            [kml.DOM, kml.DocumentElement] = createDocument;
            
            % Assign name to input if supplied.
            if nargin ~= 1
                name = '';
            end
                       
            % Set the DocumentName.
            kml.pDocumentName = name;    
            
            % Add documentName to DocumentElement.
            kml.appendTextToFeature(kml.DocumentElement, 'name', name);
        end
        
        %----------------------- set/get ----------------------------------
       
        function set.DocumentName(kml, name)
        % Set DocumentName property.
            
            kml.pDocumentName = name;
            
            % Re-assign the Document name.
            item = kml.DocumentElement.getElementsByTagName('name').item(0);
            item.setTextContent(name);
        end
        
        %------------------------------------------------------------------
        
        function set.pDocumentName(kml, name)
        % Set DocumentName property.
            
            if ~ischar(name) || (~isvector(name) && ~isempty(name))
                validateattributes(name, {'char'}, {'vector'}, ...
                    mfilename, 'DocumentName');
            end
            kml.pDocumentName = name;            
        end    
       
        %------------------------------------------------------------------
        
        function name = get.DocumentName(kml)
        % Get DocumentName property.
        
            name = kml.pDocumentName;
        end
        
        %------------------------------------------------------------------
        
        function set.FolderName(kml, name)
        % Set FolderName property.
        
           kml.pFolderName = name;
           kml.FolderElement = kml.createElement('Folder');
           kml.appendTextToFeature(kml.FolderElement, 'name', name);
        end
        
        %------------------------------------------------------------------
        
        function name = get.FolderName(kml)
        % Get FolderName property.
        
            name = kml.pFolderName;
        end
        
        %------------------------------------------------------------------
        
        function lonlim = get.LongitudeLimits(kml)
        % Get Longitude limits based on PolygonCutMeridian
        
            cutMeridian = double(kml.PolygonCutMeridian);
            if cutMeridian < 180
                lonlim = [cutMeridian, cutMeridian + 360];
            else
                lonlim = [cutMeridian - 360, cutMeridian];
            end
        end
        
        %------------------------------------------------------------------
        
        function addAddress(kml, address)
        % Add address to KML document
            
            kml.UseIconStyle = true;
            kml.UseDefaultName = kml.usingDefaultName();
            
            try                               
                % Append the addresses to the KML document.
                for k = 1:length(address)
                    setNameDefaultValue(kml, 'Address', k)
                    appendAddress(kml, address{k}, k);
                end
            catch e
                throwAsCaller(e)
            end
        end
                     
        %------------------------------------------------------------------
        
        function addFeature(kml, S)
        % Add feature(s) stored in dynamic vector S to the KML document.
        
            kml.UseDefaultName = kml.usingDefaultName();
            geometry = S.Geometry;
            try
                switch geometry
                    case 'point'
                        if isa(S,'geopoint')
                            addPointFeature(kml, S)
                        else
                            addMultiPointFeature(kml, S);
                        end
                        
                    case  'line'
                        addLineFeature(kml, S);  
                        
                    case 'polygon'
                        addPolygonFeature(kml, S);
                end
                kml.FolderName = '';
            catch e
                throwAsCaller(e)
            end
        end
                
        %------------------------------------------------------------------  

        function addPointFeature(kml, S)
        % Add point data to the document.
        
            kml.UseIconStyle = true;
            altitudeName = determineAltitudeName(S);
            geometry = 'Point';
            lat = S.Latitude;
            lon = S.Longitude;
            alt = S.(altitudeName);
            for k = 1:length(lat)
                setNameDefaultValue(kml, geometry, k)
                appendPoint(kml, lat(k), lon(k), alt(k), k);
            end
        end
        
        %------------------------------------------------------------------
        
        function addMultiPointFeature(kml, S)
        % Add multi-point data to the document.
        
            kml.UseIconStyle = true;
            altitudeName = determineAltitudeName(S);
            containsParts = true;
            geometry = 'Point';
            if kml.UseDefaultName
                kml.Name = getDefaultNameCell(geometry,length(S));
            end        

            folderName = 'Multipoint';
            for k = 1:length(S)
                [lat, lon, alt] = featureCoordinates(S(k), altitudeName);
                setMultiPartFolderName(kml, folderName, containsParts, k)
                appendMultiPoint(kml, lat, lon, alt, k);
                kml.FolderName = '';
            end
        end
        
        %------------------------------------------------------------------
        
        function addLineFeature(kml, S)
        % Add line data to the document.
        
            kml.UseLineStyle = true;
            altitudeName = determineAltitudeName(S);
            geometry = 'Line';
            if kml.UseDefaultName
                kml.Name = getDefaultNameCell(geometry, length(S));
            end        

            folderName = geometry;
            for k = 1:length(S)
                [lat, lon, alt] = featureCoordinates(S(k), altitudeName);
                containsParts = any(isnan(lat));
                setMultiPartFolderName(kml, folderName, containsParts, k)
                appendMultiLineSegment(kml, lat, lon, alt, k);
                kml.FolderName = '';
            end
            kml.UseLineStyle = false;
        end
        
        %------------------------------------------------------------------
        
        function addPolygonFeature(kml, S)
        % Add polygon data to the document.
        
            kml.UsePolyStyle = true;
            altitudeName = determineAltitudeName(S);
            geometry = 'Polygon';
            if kml.UseDefaultName
                kml.Name = getDefaultNameCell(geometry, length(S));
            end        

            folderName = geometry;
            for k = 1:length(S)
                [lat, lon, alt] = featureCoordinates(S(k), altitudeName);
                containsParts = any(isnan(lat));
                setMultiPartFolderName(kml, folderName, containsParts, k)
                appendMultiPartPolygon(kml, lat, lon, alt, k);
                kml.FolderName = '';
            end
            kml.UsePolyStyle = false;
        end
        
        %------------------------------------------------------------------
        
        function write(kml, filename)
        % write Write KML document to disk
        %
        %   write(kml, filename) writes the KML document object, kml, to
        %   disk.
        
            try
                validateattributes(filename, {'char'}, {'vector'}, ...
                    mfilename, 'FILENAME')
            catch e
                throwAsCaller(e)
            end
            
            % Set DocumentName if it is empty.
            [folder, docName] = fileparts(filename);
            if isempty(kml.DocumentName)
                % Use the basename of the file for the name of the KML
                % document.
                kml.DocumentName = docName;
            end
            
            % Write the DOM to an XML file.
            try
                % Ensure folder is created.
                if ~isempty(folder) && ~exist(folder,'dir')
                    mkdir(folder)
                end
                
                % Create a writer to serialize the DOM to a character
                % array with "pretty" printing.
                writer = matlab.io.xml.dom.DOMWriter;
                writer.Configuration.FormatPrettyPrint = true;
                
                % Using the writeToFile method, as listed below,
                %     writeToFile(writer, kml.DOM, filename)
                % inserts an extra new-line between the Document tags.
                % Rather than creating an incompatibility between earlier
                % releases, convert the DOM to a character array and remove
                % the extra lines.
                xml = writeToString(writer, kml.DOM);
                sxml = string(splitlines(xml));
                sxml(sxml == "") = [];
                sxml = char(join(sxml,newline));
                
                % The character array contains encoding="UTF-16" and
                % standalone="no". We need "utf-8" and do not need the
                % standalone option. Replace those characters.
                sxml = replaceBetween(sxml,'encoding=','?>','"utf-8"');
                
                % Write the character array to the file.
                fid = fopen(filename, 'w', 'native', 'UTF-8');
                fwrite(fid, sxml, 'char');
                fclose(fid);
            catch e
                % If the file cannot be opened, issue an  error with a
                % succinct message.
                fid = fopen(filename,'w');
                if fid < 0
                    error(message('map:fileio:unableToOpenWriteFile', filename));
                else
                    % fwrite failed for other reasons.
                    % Close the newly opened file and error with a general
                    % error message.
                    fclose(fid);
                    if exist(filename, 'file')
                        try
                            delete(filename);
                        catch e %#ok<NASGU>
                            % No action required.
                        end
                    end
                    error(message('map:fileio:unableToWriteFile', filename));
                end
            end
        end        
    end
    
    methods  (Access = 'protected')
                
        function value = getProperty(kml, name, index)
        % Return the NAME property at INDEX location.
            
            default = ' ';
            if isprop(kml, name)               
                value = kml.(name);
                if any(strcmp(name, {'Camera', 'LookAt'}))
                    if iscell(value)
                        value = value{1};
                    end
                end
                if index > length(value) && ~isscalar(value)
                    % Unable to determine which value to return so set to
                    % the empty string.
                    value = default;
                elseif ~isscalar(value)
                    % Obtain value at index.
                    if ~iscell(value)
                        value = value(index);
                    else
                        value = value{index};
                    end
                elseif iscell(value)
                    % Value is scalar, return contents of cell.
                    value = value{1};
                end
                % Have already obtained value. Value is scalar and not a cell.
            else
                % name is not a property.
                value = default;
            end
        end
        
        %------------------------------------------------------------------
        
        function color = getColorProperty(kml, colorName, alphaName, index)
        % Get color property and apply alpha if supplied.
        % KML colors are : HexAlphaHexBlueHexGreenHexRed
        
            color = getProperty(kml, colorName, index);
            alpha = getProperty(kml, alphaName, index);
            
            if ~hasData(color) && ~hasData(alpha)
                % color and alpha have not been supplied.
                % Ensure color is default color and do not apply alpha.
                color = ' ';
                
            elseif ~hasData(color) && hasData(alpha)
                % color is not set but alpha is set.
                % Set color to default value: white and opaque.
                % Apply alpha.
                color = 'ffffffff';
                color(1:2) = sprintf('%02x', round(255 * alpha));
                
            elseif hasData(alpha) && ~strcmp(color,'none')
                % color and alpha are set and color is valid.
                % Apply alpha.
                color(1:2) = sprintf('%02x', round(255 * alpha));
            end
        end
        
        %------------------------------------------------------------------
        
        function color = getPolygonColorProperty(kml, colorName, alphaName, index)
        % Get polygon color property and apply alpha if supplied.
        % KML colors are : HexAlphaHexBlueHexGreenHexRed
        
            % Get Color and Alpha properties.
            color = getProperty(kml, 'Color', index);
            alpha = getProperty(kml, 'Alpha', index);
            
            % Get colorName and alphaName properties.
            colorNameValue = getProperty(kml, colorName, index);
            alphaNameValue = getProperty(kml, alphaName, index);
            
            % If colorName is set, use its value, otherwise use color.
            if hasData(colorNameValue)
                color = colorNameValue;
            end
            
            % If alphaName is set, use its value, otherwise use alpha.
            if hasData(alphaNameValue)
                alpha = alphaNameValue;
            end
            
            if ~hasData(color) && ~hasData(alpha)
                % color and alpha have not been supplied.
                % Ensure color is default color and do not apply alpha.
                color = ' ';
                
            elseif ~hasData(color) && hasData(alpha)
                % color is not set but alpha is set.
                % Set color to default value: white and opaque.
                % Apply alpha.
                color = 'ffffffff';
                color(1:2) = sprintf('%02x', round(255 * alpha));
                
            elseif hasData(alpha) && ~strcmp(color,'none')
                % color and alpha are set and color is valid.
                % Apply alpha.
                color(1:2) = sprintf('%02x', round(255 * alpha));
            end
        end
        
        function width = getWidthProperty(kml, index)
        % Get width property. Use LineWidth if supplied, otherwise use
        % Width.
        
            lineWidth = getProperty(kml, 'LineWidth', index);
            if hasData(lineWidth)
                width = lineWidth;
            else
                width = getProperty(kml, 'Width', index);
            end        
        end
        
        %------------------------------------------------------------------
        
        function setNameDefaultValue(kml, value, index)
        % Set the Name property default value.
        
            if kml.UseDefaultName
                kml.Name{1} = sprintf('%s %d', value, index);
            end        
        end
        
        %------------------------------------------------------------------
        
        function setMultiPartFolderName(kml, folderName, containsParts, index)
        % Set a multi-part folder name.
        
            % Create a Folder and assign FolderName to Name if coordinates
            % contain parts.
            if containsParts && kml.UseMultipartName
                if kml.UseDefaultName
                    kml.FolderName = sprintf('%s %d', folderName, index);
                else
                    kml.FolderName = getProperty(kml, 'Name', index);
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function appendPoint(kml, lat, lon, alt, index)
        % appendPoint Append a point or points to document model
        %
        %   appendPoint(kml, lat, lon, alt) appends a point or points to a
        %   KML Placemark element at the coordinates specified by lat, lon,
        %   alt. The coordinate arrays are numeric and may contain NaN
        %   values which are ignored. It is assumed that the coordinate
        %   arrays are validated prior to invoking the appendPoint method.
            
            nonNan = find(~isnan(lat) & ~isnan(lon));
            lon = wrapTo180(lon);
            for k = nonNan                
                coordinates = convertCoordinatesToString(lat(k), lon(k), alt(k));
                kml.appendCoordinatePlacemark('Point', coordinates,  index);
            end
        end
        
        %------------------------------------------------------------------
        
        function appendLine(kml, lat, lon, alt, index)
        % appendLine Append a line or lines to document model
        %
        %   appendLine(kml, lat, lon, alt) appends a line or lines to a KML
        %   Placemark element at the coordinates specified by lat, lon,
        %   alt. The coordinate arrays are numeric and may contain NaN
        %   values which are ignored. It is assumed that the coordinate
        %   arrays are validated prior to invoking the appendPoint method.
             
            lon = wrapTo180(lon);
            coordinates = convertCoordinatesToString(lat, lon, alt);
            kml.appendCoordinatePlacemark('LineString', coordinates,  index);
        end
        
        %------------------------------------------------------------------
        
        function appendMultiPoint(kml, lat, lon, alt, index)
        %appendMultiPoint Append multi-point data to document model
        %
        %   appendMultiPoint(kml, lat, lon, alt) appends multi-point data
        %   to KML Placemark elements at the coordinates specified by lat,
        %   lon, alt. It is assumed that the coordinate arrays are
        %   validated prior to invoking the appendMultiPoint method.
                                        
            % Append each point to the document. The NaN values are
            % filtered out and the longitude wrapping is handled by the
            % appendPoint method.
            for k = 1:length(lat)
                if ~isempty(kml.FolderName)
                    kml.Name{index} = sprintf('Point %d', k);
                end
                kml.appendPoint(lat(k), lon(k), alt(k), index);
            end
            
            % Append the folder to the document if the name has been set.
            if ~isempty(kml.FolderName)
                kml.appendChild(kml.FolderElement);
            end
        end
        
        %------------------------------------------------------------------
        
        function appendMultiLineSegment(kml, lat, lon, alt, index)
        %appendMultiLineSegment Append line segments to document model
        %
        %   appendMultiLineSegment(kml, lat, lon, alt, index) appends line
        %   segments (separated by Nans) to the document.
                    
            % Split the coordinates.
            [latCells, lonCells, altCells] = splitCoordinate(lat, lon, alt);
                                  
            % Append the lines to the KML document.
            lineNumber = index;
            for k = 1:length(latCells)
                lat = latCells{k};
                lon = lonCells{k};
                alt = altCells{k};
                if ~isempty(kml.FolderName)
                    kml.Name{lineNumber} = sprintf('Segment %d', k);
                end
                appendLine(kml, lat, lon, alt, lineNumber);
            end     
            
            % Append the folder to the document if the name has been set.
            if ~isempty(kml.FolderName)
                kml.appendChild(kml.FolderElement);
            end
        end
        
        %------------------------------------------------------------------
        
        function appendMultiPartPolygon(kml, lat, lon, alt, index)
        %appendMultiPartPolygon Append multi-part polygon data to document model
        %
        %   appendMultiPartPolygon(kml, lat, lon, alt) appends multi-part
        %   polygon data to KML Placemark elements at the coordinates
        %   specified by lat, lon, alt. It is assumed that the coordinate
        %   arrays are validated prior to invoking the
        %   appendMultiPartPolygon method.
                                   
            % Assign latlim and lonlim values.
            latlim = kml.LatitudeLimits;
            lonlim = kml.LongitudeLimits;
            cutPolygons = kml.CutPolygons;
            
            if cutPolygons
                % Cut polygons and split into outer and inner rings.
                [lat, lon, alt] = cutPolygon(lat, lon, alt, latlim, lonlim);
                [outer, inner, innerIndex] = splitPolygonIntoRings(lat, lon, alt, cutPolygons);
            else
                % Do not cut polygons, split into outer and inner rings.
                [outer, inner, innerIndex] = splitPolygonIntoRings(lat, lon, alt, cutPolygons);
                
                % If outer is empty and inner is not empty, then there is
                % no outer ring for the inner ring(s).
                noOuterRing = isempty(outer) && ~isempty(inner);
                
                % If the number of true values in innerIndex (indicating an
                % inner ring is associated with an outer ring) is less
                % than the length of inner, then there are unmatched inner
                % rings. If either are true, then we need to construct a
                % global outer boundary ring.
                unmatchedInnerRings = noOuterRing || ...
                    (~isempty(inner) && length(find(innerIndex)) < length(inner));
                if unmatchedInnerRings
                    [lat, lon, alt] = addGlobalOuterBoundaryRing(lat, lon, alt);
                    [outer, inner, innerIndex] = splitPolygonIntoRings(lat, lon, alt, cutPolygons);
                end
            end
                      
            % Add each outer and corresponding inner rings to the polygon
            % placemark.
            if ~isempty(outer)
                polygonNumber = index;
                for k = 1:length(outer)
                    if ~isempty(kml.FolderName)
                        kml.Name{polygonNumber} = sprintf('Part %d', k);
                    end
                    appendPolygonPlacemark( ...
                        kml, outer(k), inner(innerIndex(k,:)), index)
                end
            end
            
            % Append the folder to the document if the name has been set.
            if hasData(kml.FolderName)
                kml.appendChild(kml.FolderElement);
            end
        end      
        
        %------------------------------------------------------------------
        
        function appendAddress(kml, address, index)
        %appendAddress Append address to document model
        %
        %   appendAddress(kml, address) appends address data to a KML
        %   Placemark element. The cell array address contains string
        %   address data. The address is a single string per point. It is
        %   assumed that the address cell array is validated prior to
        %   invoking the appendAddress method.

            kml.appendAddressPlacemark(address, index);
        end
        
        %------------------------------------------------------------------

        function element = createElement(kml, name)
        % Create a new KML element with specified name.
        
            % The DOM createElement method requires string or character
            % input but does not accept cellstr. Convert input to string.
            name = convertCharsToStrings(name);
            element = kml.DOM.createElement(name);
        end
        
        %------------------------------------------------------------------

        function placemarkElement = createPlacemarkElement(kml, index)
        % Create a new Placemark element.
            
            % Create an element with a Placemark tag name.
            placemarkElement  = createElement(kml, 'Placemark');
            
            % Add Snippet tag to prevent description lines from being
            % displayed in the control panel.
            tagName = 'Snippet';
            attributes = {'maxLines', '0'};
            textData = ' ';
            kml.appendAttributeElementToFeature( ...
                placemarkElement, tagName, attributes, textData);
            
            % Append all the options to the Placemark element.
            kml.appendOptionsToFeature(placemarkElement, index);
        end

        %------------------------------------------------------------------
        
        function boundaryIs = createBoundaryIsElement(kml, tagName, coordinates)
        % Create a KML element to hold the outer our inner boundary.
        
            % Create the outer/innerBoundaryIs element.
            boundaryIs = kml.createElement(tagName);

            % Create the LinearRing element.
            linearRing = kml.createElement('LinearRing');

            % Add the specific feature element with coordinates to the
            % LinearRing element.
            kml.appendTextToFeature(linearRing, 'coordinates', coordinates);
            boundaryIs.appendChild(linearRing);
        end
                     
        %------------------------------------------------------------------

        function appendChild(kml, child)
        % Append a child element to the document. The child element
        % contains a new KML element.
        
            kml.DocumentElement.appendChild(child);
        end

        %------------------------------------------------------------------
        
         function appendCoordinatePlacemark(kml, elementName, coordinates, index)        
        % Append a Placemark element to the document. The Placemark element
        % contains a new KML element with name elementName. The new
        % featureElement contains a KML coordinates element containing the
        % specified coordinates.
        
            % Create an element with a Placemark tag name and append the
            % properties to the placemark element.
            placemarkElement = kml.createPlacemarkElement(index);
            
            % Create the featureElement ('Point' or 'LineString')
            featureElement = kml.createElement(elementName);
            
            % Add altitudeMode.
            mode = getProperty(kml, 'AltitudeMode', index);
            if ~isequal(mode, ' ')
                kml.appendTextToFeature( featureElement, 'altitudeMode', mode);
            end
            
            % Add the specific feature element with coordinates to the
            % Placemark element.
            tagName = 'coordinates';
            kml.appendTextToFeature(featureElement, tagName, coordinates);
            placemarkElement.appendChild(featureElement);
            if isempty(kml.FolderName)
                kml.appendChild(placemarkElement);
            else
                kml.FolderElement.appendChild(placemarkElement);
            end
        end
        
        %------------------------------------------------------------------
        
         function appendPolygonPlacemark(kml, outer, inner, index)        
         % Append a Placemark element with a Polygon element to the
         % document. The Placemark element contains a new KML element with
         % name 'Polygon'. The new Polygon contains KML coordinates element
         % containing the specified coordinates.
        
            % Create an element with a Placemark tag name and append the
            % properties to the placemark element.
            placemarkElement = kml.createPlacemarkElement(index);
            
             % Create the Polygon element.
            elementName = 'Polygon';
            featureElement = kml.createElement(elementName);
            
            % Add altitudeMode.
            mode = getProperty(kml, 'AltitudeMode', index);
            if hasData(mode)
                kml.appendTextToFeature(featureElement, 'altitudeMode', mode);
            end
            
            % Add extrude.
            extrude = getProperty(kml, 'Extrude', index);
            if hasData(extrude)
                value = num2strd(extrude);
                kml.appendTextToFeature(featureElement, 'extrude', value);
            end
                           
            % Create all outerBoundaryIs elements and append to Polygon
            % feature.
            for k = 1:length(outer)
                outerBoundaryIs = createBoundaryIsElement( ...
                    kml, 'outerBoundaryIs', outer{k});
                featureElement.appendChild(outerBoundaryIs);
            end
            
            % Create all innerBoundaryIs elements and append to Polygon
            % feature.
            for k = 1:length(inner)
                innerBoundaryIs = createBoundaryIsElement( ...
                    kml, 'innerBoundaryIs', inner{k});
                featureElement.appendChild(innerBoundaryIs);
            end
                
            placemarkElement.appendChild(featureElement);
            if isempty(kml.FolderName)
                kml.appendChild(placemarkElement);
            else
                kml.FolderElement.appendChild(placemarkElement);
            end
        end
        
        %------------------------------------------------------------------
        
        function appendAddressPlacemark(kml, address, index)
        % Append a Placemark element to the document that contains a new
        % address KML element.  The new address element contains the
        % specified address.
                    
            % Create an element with a Placemark tag name and append the
            % data from the properties to the placemark element.
            placemarkElement  = kml.createPlacemarkElement(index);
            
            % Add the address element with the address to the Placemark
            % element.
            tagName = 'address';           
            kml.appendTextToFeature(placemarkElement, tagName, address);          
            kml.appendChild(placemarkElement);
        end

        %------------------------------------------------------------------
        
        function appendOptionsToFeature(kml, featureElement,  index)
         % Append the properties to the KML element, featureElement.
            
            % Append text options to feature.
            kml.appendTextOptionsToFeature(featureElement, index);
            
            % Append any icon style options to feature.
            kml.appendStyleOptionsToFeature(featureElement, index);
            
            % Append any view point options to feature.
            kml.appendViewPointOptionsToFeature(featureElement, index);
        end
        
        %------------------------------------------------------------------
        
        function appendTextOptionsToFeature(kml, featureElement, index)
        % Append text properties to a KML element.
        %
        % Text options are simple text strings that are inserted between
        % KML tags. For example:
        %  <kmlTag> text </kmlTag>
        %
        % The property name is matched regardless of case from a list
        % of supported kmlTagNames. If found, the value in the kmlTagNames
        % is the kmlTag element.  The value of the property is the
        % text inserted between the beginning and ending kmlTags.
        
            % Supported KML element names.
            kmlTagNames = {'description','name','address'};
            
            % Corresponding KMLDocument properties. 
            documentProperties = {'Description', 'Name', 'Address'};
            
            % Is the tag name required.
            isRequired = {true, true, false};

            % Add the tag if requested.
            for k=1:numel(documentProperties)

                currentOption = documentProperties{k};
                currentValue = getProperty(kml, currentOption, index);
                tagIndex = strcmpi(currentOption, kmlTagNames);
                tagName = kmlTagNames(tagIndex);

                if isRequired{tagIndex} || ~isequal(currentValue, ' ')
                    kml.appendTextToFeature(...
                        featureElement, tagName, currentValue);
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function appendStyleOptionsToFeature(kml, featureElement, index)
        % Append IconStyle, LineStyle, and PolyStyle style options to the
        % Style element if required.
            
            % Append IconStyle element to Style element.
            appendIconStyleToStyle(kml, featureElement, index);
            
            % Append LineStyle element to Style element.
            appendLineStyleToStyle(kml, featureElement, index);
            
            % Append PolyStyle element to Style element.
            appendPolyStyleToStyle(kml, featureElement, index)
        end
                
        %------------------------------------------------------------------
        
        function appendIconStyleToStyle(kml, featureElement, index)
        % Append IconStyle options to Style element. 
        %
        % Icon options are properties that contain the partial string
        % 'Icon'. These options are inserted into a IconStyle KML tag. Two
        % 'Icon' fields are supported:
        %    IconScale, Icon
        %
        % The KML IconStyle element is composed of the following:
        % <IconStyle>
        %   <scale>1</scale>                   <!-- float -->
        %   <Icon>
        %     <href>...</href>
        %   </Icon>
        % </IconStyle>
        %
        % If an 'IconScale' field is set in properties, then the
        % KML tag <scale> is set to the field value.
        %
        % If an 'Icon' field is set in the properties, then the
        % value of the field is inserted into a <href> KML element. This
        % element is then inserted into a <Icon> KML element.
        %
        % If either 'Icon' or 'IconScale' is set in the properties,
        % then the resulting KML element is inserted into the <IconStyle>
        % element.
        %
        % If both 'Icon' and 'IconScale' are set to empty or ' ', then an
        % IconStyle element is not created.
        %
        % The IconStyle element is inserted into the KML Style
        % element. For example:
        %
        % <Style>
        %    <IconStyle>
        %       <scale> 2 </scale>
        %    </IconStyle>
        % </Style>
            
            if kml.UseIconStyle
                appendStyle = false;

                % Create elements: Style, IconStyle
                styleElement = kml.createElement('Style');
                iconStyleElement = kml.createElement('IconStyle');
                
                % Process Icon
                icon = getProperty(kml, 'Icon', index);
                if hasData(icon)
                    appendStyle = true;
                    iconElement = kml.createElement('Icon');
                    hrefElement = kml.appendTextToFeature( ...
                        iconStyleElement, 'href', icon);
                    iconElement.appendChild(hrefElement);
                    iconStyleElement.appendChild(iconElement);
                end

                % Process IconScale
                iconScale = getProperty(kml, 'IconScale', index);
                if hasData(iconScale)
                    appendStyle = true;
                    value = num2strd(iconScale);
                    kml.appendTextToFeature(iconStyleElement, 'scale', value);
                end

                % Process Color
                color = getColorProperty(kml, 'Color', 'Alpha', index);
                if hasData(color) && ~strcmp(color,'none')
                    appendStyle = true;
                    kml.appendTextToFeature(iconStyleElement, 'color', color);
                end

                % Append style element if set.
                if appendStyle
                    styleElement.appendChild(iconStyleElement);
                    featureElement.appendChild(styleElement);
                end
           end
        end
        
        %------------------------------------------------------------------
        
        function appendLineStyleToStyle(kml, featureElement,  index)
        % Append LineStyle options to Style element. 
        %
        % Line style properties modify the color or width of a line. These
        % properties are inserted into a LineStyle KML tag. Two fields are
        % supported:
        %    color, width
        %
        % The KML LineStyle element is composed of the following:
        % <LineStyle>
        %   <width>value</with>       <!-- float  -->
        %   <color>value</color>      <!-- string -->
        % </LineStyle>
        %
        % If either 'Color', 'LineWidth', or 'Width' is set in the
        % properties, and UseLineStyle is true then the KML element is
        % inserted into the <LineStyle> element.
        %
        % If both are set to empty or ' ' or UseLineStyle is false, then a
        % LineStyle element is not created.
        %
        % The LineStyle element must be inserted into the KML Style
        % element. For example:
        %
        % <Style>
        %    <LineStyle>
        %       <width>2</width>
        %       <color>ff0000ff</color>
        %    </LineStyle>
        % </Style>
            
            if kml.UseLineStyle
                appendStyle = false;
                
                % Create elements: Style, LineStyle
                styleElement = kml.createElement('Style');
                lineStyleElement = kml.createElement('LineStyle');

                % Process Width
                width = getWidthProperty(kml, index);
                if hasData(width)
                    appendStyle = true;
                    width = num2strd(width);
                    kml.appendTextToFeature(lineStyleElement, 'width', width);
                end

                % Process Color and Alpha
                color = getColorProperty(kml, 'Color', 'Alpha', index);
                if hasData(color) && ~strcmp(color,'none')
                    appendStyle = true;
                    kml.appendTextToFeature(lineStyleElement, 'color', color);
                end
                
                % Append style element if set.
                if appendStyle
                   styleElement.appendChild(lineStyleElement);
                   featureElement.appendChild(styleElement);
                end
            end
        end
       
       %------------------------------------------------------------------
        
        function appendPolyStyleToStyle(kml, featureElement,  index)
        % Append PolyStyle options to Style element.
        %
        % Polygon style properties modify the fill, outline, and color of a
        % polygon. The PolyStyle element determines whether a polygon
        % is filled and whether an outline is visible. These properties are
        % inserted into a PolyStyle KML tag. Three fields are supported:
        %   color, outline, fill
        %
        % The KML PolyStyle element is composed of the following:
        % <PolyStyle>
        %   <outline>value</outline>  <!-- logical -->
        %   <fill>value</fill>        <!-- logical -->
        %   <color>value</color>      <!-- string -->
        % </PolyStyle>
        %
        % If either 'FaceColor', 'FaceAlpha', 'Color', or 'Alpha' is set in
        % the properties then the KML element is inserted into the
        % <PolyStyle> element. Use color value 'none' to set no fill.
        %
        % The PolyStyle element is inserted into the KML Style
        % element. For example:
        %
        % <Style>
        %    <PolyStyle>
        %       <outline>1</outline>
        %       <fill>1</fill>
        %       <color>ff0000ff</color>
        %    </PolyStyle>
        % </Style>
        %
        % Line style properties modify the color or width of the outline.
        % These properties are inserted into a LineStyle KML tag. Two
        % fields are supported:
        %    color, width
        %
        % The KML LineStyle element is composed of the following:
        % <LineStyle>
        %   <width>value</width>      <!-- float  -->
        %   <color>value</color>      <!-- string -->
        % </LineStyle>
        %
        % If either 'EdgeColor', 'EdgeAlpha', or 'LineWidth' is
        % set in the properties then the KML element is inserted into the
        % <LineStyle> element.
        %
        % If both are set to empty or ' ', then a LineStyle element is not
        % created.
        %
        % The LineStyle element is inserted into the KML Style
        % element. For example:
        %
        % <Style>
        %    <LineStyle>
        %       <width>2</width>
        %       <color>ff0000ff</color>
        %    </LineStyle>
        % </Style>
                                               
            if kml.UsePolyStyle
                appendLineStyle = false;
                appendPolyStyle = false;
                
                % Create elements: Style, PolyStyle, LineStyle
                styleElement = kml.createElement('Style');
                polyStyle = kml.createElement('PolyStyle');
                lineStyleElement = kml.createElement('LineStyle');
                
                % Process Color and Alpha
                color = getPolygonColorProperty(kml, 'FaceColor', 'FaceAlpha', index);
                if hasData(color)
                    if strcmp(color,'none')
                        fill = '0';
                    else
                        fill = '1';
                        kml.appendTextToFeature(polyStyle, 'color', color);
                    end
                    appendPolyStyle = true;
                    kml.appendTextToFeature(polyStyle, 'fill', fill);
                end
                
                % Process EdgeColor and EdgeAlpha
                color = getPolygonColorProperty(kml, 'EdgeColor', 'EdgeAlpha', index);
                if hasData(color)
                    if strcmp(color,'none')
                        outline = '0';
                    else
                        outline = '1';
                        appendLineStyle = true;
                        kml.appendTextToFeature(lineStyleElement, 'color', color);
                    end
                    appendPolyStyle = true;
                    kml.appendTextToFeature(polyStyle, 'outline', outline);
                end
                
                % Process LineWidth
                width = getWidthProperty(kml, index);
                if hasData(width)
                    width = num2strd(width);
                    appendLineStyle = true;
                    kml.appendTextToFeature(lineStyleElement, 'width', width);
                end
                
                % Append style elements if set.
                if appendLineStyle
                    styleElement.appendChild(lineStyleElement);
                end
                
                if appendPolyStyle
                    styleElement.appendChild(polyStyle);
                end
                
                if appendLineStyle || appendPolyStyle
                    featureElement.appendChild(styleElement);
                end
            end
        end

       %------------------------------------------------------------------
        
       function appendViewPointOptionsToFeature(kml, featureElement, index)
       % Append view point options to a KML element.
       %
       % Camera and LookAt options are supported.
       %
       % Camera options are properties that contain
       % the string 'Camera'. These options are inserted into a Camera
       % kmlTag.
       %
       % The KML Camera element is composed of the following:
       % <Camera>
       %   <longitude>value</longitude>  <angle180>
       %   <latitude>value</latitude>    <angle90>
       %   <altitude>value</altitude>    <double>
       %   <heading>value</heading>      <angle360>
       %   <tilt>value</tilt>            <anglepos180>
       %   <roll>value</roll>            <angle180>
       %   <altitudeMode>value</altitudeMode>  <string>
       % </Camera>
       %
       % If a 'Camera' field is set properties, then the KML
       % tag <Camera> is set to the field values.
       %
       % The Camera or LookAt element are inserted into the KML Placemark
       % element, but they both cannot be inserted into the same one.
       % For example:
       %
       % <Placemark>
       %    <Camera>
       %    </Camera>
       % </Placemark>
           
           % Supported KML element names.
           kmlTagNames = {'Camera','LookAt'};
           
           % Corresponding KMLDocument properties.
           documentProperties = kmlTagNames;
                     
           % Add the tag if requested.
           for k=1:numel(documentProperties)
               
               currentOption = documentProperties{k};
               currentValue = getProperty(kml, currentOption, index);
               
               % Determine if the field value contains valid data to add
               % to the document.
               containsData = ~isempty(currentValue) ...
                   && isa(currentValue, 'geopoint');
               
               if containsData
                   % Validate that the coordinate values do not contain
                   % NaNs since they have not been validated to be
                   % NaN-coincident with the coordinates.
                   lat = currentValue.Latitude;
                   str = [currentOption '.Latitude'];
                   validateattributes(lat, {'numeric'}, {'finite'}, mfilename, str);
                   
                   lon = currentValue.Longitude;
                   str = [currentOption '.Longitude'];
                   validateattributes(lon, {'numeric'}, {'finite'}, mfilename, str);

                   tagIndex = strcmpi(currentOption, kmlTagNames);
                   tagName = kmlTagNames{tagIndex};
                   
                   topElement = kml.createElement(tagName);
                   elementNames = ...
                       ['Longitude'; 'Latitude'; fieldnames(currentValue)];
                   elementNames(strcmp('AltitudeMode', elementNames)) = [];
                   for n = 1:numel(elementNames)
                       elementName = elementNames{n};
                       value = num2strd(currentValue.(elementName));
                       kml.appendTextToFeature( ...
                           topElement, lower(elementName), value);
                   end
                   kml.appendTextToFeature( ...
                       topElement, 'altitudeMode', currentValue.AltitudeMode);
                   featureElement.appendChild(topElement);
               end
           end
       end
        
       %------------------------------------------------------------------
       
       function element = appendTextToFeature(kml, ...
               featureElement, elementName, textData)
       % Append text to a feature element.
       %
       % Create and append a new text element to a new KML element with
       % name elementName. The elementName node is appended to
       % featureElement.  The text element contains the text from the
       % string textData. The featureElement contains the new elementName
       % KML element.

           element = kml.createElement(elementName);
           textNode = kml.DOM.createTextNode(textData);
           element.appendChild(textNode);
           featureElement.appendChild(element);
       end
        
       %------------------------------------------------------------------
       
       function appendAttributeElementToFeature(kml, ...
               featureElement, elementName, elementAttributes, textData)
       % Append attribute element to a feature element.
       %
       % Create and append a new text element to a new KML element with
       % name elementName. The elementName node is appended to
       % featureElement.  The text element contains the text from the
       % string textData. The elementName node's attribute is set with the
       % values in the string cell array elementAttributes. The
       % featureElement contains the new elementName KML element.
           
           element = kml.appendTextToFeature( ...
               featureElement, elementName, textData);
           element.setAttribute(elementAttributes{:});
       end
    end
    
    methods (Access = 'private')
        
        function tf = usingDefaultName(kml)
        % Determine if the Name property is the default value.
        
           name = getProperty(kml, 'Name', 1);
           tf = isequal(name, ' ') ...
               && (isscalar(kml.Name) || isempty(kml.Name));
        end
    end
end

%---------------------- Utility Functions ---------------------------------

function  [DOM, documentElement] = createDocument()
% Create the XML DOM and Document element.

DOM = matlab.io.xml.dom.Document('kml');

rootNode = DOM.getDocumentElement;
namespace = 'http://www.opengis.net/kml/2.2';
rootNode.setAttribute('xmlns', namespace);

documentElement = DOM.createElement('Document');
rootNode.appendChild(documentElement);

end

%--------------------------------------------------------------------------

function coordinates = convertCoordinatesToString(lat, lon, alt)
% Convert coordinates to a string.

if isscalar(lat)
    coordinates = sprintf('%.15g,%.15g,%.15g', lon, lat, alt);
else
    coordinates = [' ' sprintf('%.15g,%.15g,%.15g ',[lon;lat;alt])];
    coordinates(end) = [];
end
end

%--------------------------------------------------------------------------

function altitudeName = determineAltitudeName(S)
% Determine the altitude name from the input dynamic vector, S.

% Find altitude names in S.
altitudeNames = {'Altitude', 'Elevation', 'Height'};
names = fieldnames(S);
index = ismember(altitudeNames, names);
altitudeName = altitudeNames{index};
if isempty(altitudeName)
    % This condition cannot be met unless the class is constructed outside
    % of the KML functions. The class expects an altitude name. Since it is
    % an internal class and this condition cannot be met, rather than error
    % here, let the code error when attempting to access the data.
    altitudeName = altitudeNames{1};
end
end

%--------------------------------------------------------------------------

function [latCells, lonCells, altCells] = splitCoordinate(lat, lon, alt)
% Split latitude, longitude, and altitude coordinates into cells. It is
% assumed that lat, lon, and alt are the same length.

if isempty(lat) || isempty(lon)
    latCells = reshape({}, [0 1]);
    lonCells = latCells;
    altCells = latCells;    
else    
    % Ensure NaN locations are consistent. The KML functions already ensure
    % this. 
    n = isnan(lat(:));
    
    % Locate extra NaNs.   
    firstOrPrecededByNaN = [true; n(1:end-1)];
    extraNaN = n & firstOrPrecededByNaN;
    
    % Remove extra NaNs.
    lat(extraNaN) = [];
    lon(extraNaN) = [];
    alt(extraNaN) = [];
    
    % Find NaN locations.
    [first, last] = internal.map.findFirstLastNonNan(lat);
    
    % Extract each segment into pre-allocated n-by-1 cell arrays, where n
    % is the number of segments.
    n = numel(first);
    latCells = cell(n,1);
    lonCells = latCells;
    altCells = latCells;
    for k = 1:n
        latCells{k} = lat(first(k):last(k));
        lonCells{k} = lon(first(k):last(k));
        altCells{k} = alt(first(k):last(k));
    end
end
end
       
%--------------------------------------------------------------------------

function str = num2strd(value)
% Convert a scalar number to a string representation with a maximum of 15
% digits of precision.

% Use sprintf to convert a number to a string representation with 15 digits
% of precision. (You can use num2str(value, 15) but sprintf is more
% efficient).
str = sprintf('%.15g', value);
end

%--------------------------------------------------------------------------

function [lat, lon, alt] = featureCoordinates(S, altitudeName)
% Obtain latitude, longitude, and altitude values from dynamic vector S.

lat = S.Latitude;
lon = S.Longitude;
alt = S.(altitudeName);

% Remove trailing NaN from all non-scalar arrays.
if length(lat) > 1 && isnan(lat(end))
    lat(end) = [];
    lon(end) = [];
    alt(end) = [];
end
end

%--------------------------------------------------------------------------

function tf = hasData(value)
% Return true if value is not empty or contain a single space (the default
% value).

tf = ~isempty(value) && ~isequal(value, ' ');
end

%--------------------------------------------------------------------------

function [lat, lon, alt] = cutPolygon(lat, lon, alt, latlim, lonlim)
% Cut the polygon to latlim and lonlim limits.

% maptrimp returns empty if coordinates have length < 2.
if length(lat) > 2
    % Get a scalar value for alt. If the input array is not uniform in
    % value (excluding NaN) issue an error.
    alt = getScalarArrayValue(alt);
    if isempty(alt)
        error(message('map:kml:expectedUniformValues'));
    end
    
    % Cut the polygon.
    [lat, lon] = maptrimp(lat, lon, latlim, lonlim);
    
    % Ensure lon is between -180 and 360.
    if any(lon < -180) 
        lon = wrapTo360(lon);
    end
    
    % Create a new alt array the same length as lat and assign all elements
    % the value of scalar alt. Ensure NaN values are consistent. If lat and
    % lon are empty (from all vertices being cut), then set alt to be empty
    % too.
    if ~isempty(lat)
        alt(1,1:length(lat)) = alt;
        index = isnan(lat);
        alt(index) = NaN;
    else
        alt = [];
    end
end
end

%--------------------------------------------------------------------------

function [lat, lon, alt] = addGlobalOuterBoundaryRing(lat, lon, alt)
% Add a global outer boundary ring to the lat, lon, alt coordinate arrays.

% Construct vertex list for the global boundary ring.
globalLat = [90 -90 -90 -90 90 90 90 NaN];
globalLon = [180 180 0 -180 -180 0 180 NaN];

% Get the scalar value for alt. If the array is not uniform (excluding
% NaN) issue a warning and set altp to 0.
altp = getScalarArrayValue(alt);
if isempty(altp)
    warning(message('map:kml:settingNonUniformAltitudeToZero'))
    altp = 0;
end

% Create a new alt array the same length as globalLat and assign all elements
% the value of altp. Ensure NaN values are consistent.
globalAlt = ones(1,length(globalLat))*altp;
index = isnan(globalLat);
globalAlt(index) = NaN;

% Add global boundary ring to coordinate arrays.
lat = [globalLat lat];
lon = [globalLon lon];
alt = [globalAlt alt];
end

%--------------------------------------------------------------------------

function [outer, inner, index] = splitPolygonIntoRings(lat, lon, alt, cutPolygons)
% Split the polygon vertex list into outer and inner rings. Return OUTER
% and INNER cell arrays containing coordinates as strings. INDEX is a
% logical matrix that indicates which inner ring corresponds to which outer
% ring.

% Split the coordinates.
[latCells, lonCells, altCells] = splitCoordinate(lat, lon, alt);

% Split the vertex cells into outer and inner cells.
if ~isempty(latCells)
    n = numel(latCells);
    outer = cell(n,1);
    inner = cell(n,1);
    outerIndex = zeros(n,1);
    innerIndex = zeros(n,1);
    outk = 0;
    ink = 0;
    for k = 1:n
        lat = latCells{k};
        lon = lonCells{k};
        alt = altCells{k};
        if isPolygonClockwise(lat, lon, cutPolygons)
            outk = outk + 1;
            outer{outk} = convertCoordinatesToString( ...
                fliplr(lat), fliplr(lon), fliplr(alt));
            outerIndex(k) = k;
        else
            ink = ink + 1;
            inner{ink} = convertCoordinatesToString(lat, lon, alt);
            innerIndex(k) = k;
        end
    end
    
    % Compute inner ring index.
    outer(cellfun(@isempty, outer)) = [];
    inner(cellfun(@isempty, inner)) = [];
    index = assignInnerToOuterRings( ...
        latCells, lonCells, outerIndex, innerIndex, outer, inner, cutPolygons);
else
    outer = {};
    inner = {};
    index = false;
end
end

%--------------------------------------------------------------------------

function index = assignInnerToOuterRings( ...
    latCells, lonCells, outerIndex, innerIndex, outer, inner, cutPolygons)
% Assign inner rings to outer rings. INDEX is a logical array that is size
% (length(outer),length(inner)). For each row, a value is true if the
% corresponding inner ring is attached to the outer ring. Inner rings vary
% by column, outer rings by row. For example if there are two inner rings
% and three outer rings with index:
%
%   1 0 
%   0 0
%   0 1
%
% then the first inner ring is contained in the first outer ring
% and the second inner ring is contained in the third outer ring.

if isempty(inner)
    index = false(length(outer),1);
else
    % Determine which inner ring is inside which outer ring by using
    % inpolygon. If all polygon points are inside, then set INDEX to true.
    % An inner ring may be inside more than one outer ring.
    index = false(length(outer),length(inner));
    outerIndex(~outerIndex) = [];
    innerIndex(~innerIndex) = [];
    for j = 1:length(outer)
        for k = 1:length(inner)
            outk = outerIndex(j);
            ink = innerIndex(k);
            in = inSphericalPolygon( ...
                lonCells{ink}, latCells{ink},  ...
                lonCells{outk},latCells{outk}, ...
                cutPolygons); 
            if all(in)
                index(j,k) = true;
            end
        end
    end
    
    % Determine whether an inner ring is attached to more than one outer
    % ring. This condition is true if a column in index contains more than
    % one true value. For example:
    %  1 0 1
    %  0 0 1
    % in this case, column two denotes that more than one outer ring (outer
    % ring 1 and outer ring 2) contain the same inner ring (3). Find which
    % of the outer rings are contained by another outer ring. If an outer
    % ring is inside another outer ring, then set the INDEX value of the
    % true outer ring (outk) to false.
    for k = 1:size(index,2)
        j = find(index(:,k));
        if length(j) > 1
           for n = 1:length(j)
               ink = j(n);
               for m = 1:length(j)
                   outk = j(m);
                   if ink ~= outk
                       in = inSphericalPolygon( ....
                           lonCells{ink}, latCells{ink}, ...
                           lonCells{outk}, latCells{outk},cutPolygons);
                       if all(in)
                           index(outk,ink) = 0;
                       end
                   end
               end
           end              
        end
    end
end
end

%--------------------------------------------------------------------------

function value = getScalarArrayValue(array)
% Return a scalar value from the numeric array ARRAY. ARRAY is assumed
% uniform in value and may contain NaNs. ARRAY is assumed to contain at
% least one non-NaN value. If the array is not uniform or contains all NaN
% values return [].

array(isnan(array)) = [];
if all(array == array(1))
    value = array(1);
else
    value = [];
end
end

%--------------------------------------------------------------------------

function tf = isPolygonClockwise(lat, lon, cutPolygons)
% Return true if polygon is clockwise. LAT and LON are polygon parts and do
% not contain NaN values.

if cutPolygons
    tf = all(ispolycw(lon, lat));
else
    % Trim the polygon. Use maptriml to prevent a global polygon from
    % being created.
    [tlat,tlon] = maptriml(lat, lon, [-90 90], [-180 180]);
    
    % If everything is cut (tlat is empty), then ensure this polygon part
    % is treated as an outer-boundary. maptriml may create extra parts
    % because of the cutting. If any part is not clockwise, then the input
    % polygon is counter-clockwise.
    if isempty(tlat) || all(ispolycw(tlon, tlat))
        tf = true;
    else
        tf = false;
    end
end
end

%--------------------------------------------------------------------------

function tf = inSphericalPolygon(lon,lat,lonv,latv,cutPolygons)
% Return true if LON and LAT are inside LONV and LATV.

if cutPolygons
    tf = all(inpolygon(lon,lat,lonv,latv));
else
    % The polygon is not cut. Cut both inputs to global grid.
    latlim = [-90 90];
    lonlim = [-180 180];
    [lat,lon] = maptriml(lat, lon, latlim, lonlim);
    [latv,lonv] = maptriml(latv, lonv, latlim, lonlim);
    
    if isempty(latv) || isempty(lat)
        % empty is returned, which occurs if one of the inputs is a global
        % polygon. All vertices are inside the global polygon.
        tf = true;
    else
       % The polygon is now cut. Determine if lat and lon are inside the
       % latv and lonv polygon.
       tf = inpolygon(lon,lat,lonv,latv);
        
        % Inputs to this function are polygon parts and do not contain NaN
        % values. maptriml adds NaN to the end of the arrays, thus tf(end)
        % is always NaN. If there are NaN values in the arrays, then the
        % input is cut and return true if any points are inside.
        tf = tf(1:end-1);
        if any(isnan(lat(1:end-1))) || any(isnan(latv(1:end-1)))
            % Polygon is cut, return true if any part is inside.
            tf = any(tf);
        else
            % If all points are inside the polygon, then return true (as in
            % the cut case).
            tf = all(tf);
        end
    end
end
end

%--------------------------------------------------------------------------

function c = getDefaultNameCell(name, n)
% Construct a cell array containing elements of [name %d'] where %d ranges
% from 1:n

c = num2cell(1:n);
c = cellfun(@(x)(sprintf([name ' %d'],x)),c,'UniformOutput',false);
end
