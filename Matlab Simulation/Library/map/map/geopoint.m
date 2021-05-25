%GEOPOINT Geographic point vector
%
%   A geopoint vector is an object that holds geographic point coordinates
%   and attributes. The points are coupled such that the size of the
%   latitude and longitude coordinate arrays are always equal and match the
%   size of any additional attribute arrays. A geopoint vector is always a
%   column vector.
%
%   Syntax:
%      p = geopoint()
%      p = geopoint(lat, lon)
%      p = geopoint(lat, lon, Name, Value)
%      p = geopoint(S)
%      p = geopoint(lat, lon, S)
%
%   geopoint properties:
%      Geometry  - Character vector defining type of geometry
%      Metadata  - Scalar structure containing metadata
%      Latitude  - 1-by-N numeric vector of latitude coordinates
%      Longitude - 1-by-N numeric vector of longitude coordinates
%
%   Collection properties:
%      Geometry and Metadata are collection properties. These properties
%      contain only one value per class instance. The term collection is
%      used to distinguish these two properties from other feature
%      properties which have values associated with each feature (element
%      in a geopoint vector).
%
%   Feature properties:
%      Feature properties provide one value (scalar number, scalar string,
%      or character vector) for each feature in the geopoint vector. They
%      are suitable for properties that describe a single element of a
%      geopoint vector. The Latitude and Longitude properties are feature
%      properties since they contain one value for each feature.
%
%   Dynamic feature properties:
%      You can attach new dynamic feature properties to the object by using
%      the dot (.) notation. This is similar to adding dynamic fields to a
%      structure. Dynamic feature properties are suitable for such
%      attributes as name, owner, serial number, age, etc., that describe a
%      given feature.
%
%   geopoint methods:
%      geopoint   - Construct geopoint vector
%      append     - Append points to geopoint vector
%      cat        - Concatenate geopoint vectors
%      disp       - Display geopoint vector
%      fieldnames - Dynamic properties of geopoint vector
%      isempty    - True if geopoint vector is empty
%      isfield    - True if dynamic property exists
%      isprop     - True if property exists
%      length     - Number of points in geopoint vector
%      properties - Properties of geopoint vector
%      rmfield    - Remove dynamic property from geopoint vector
%      rmprop     - Remove property from geopoint vector
%      size       - Size of geopoint vector
%      struct     - Convert geopoint vector to scalar structure
%      vertcat    - Vertical concatenation for geopoint vectors
%
%   Example 1
%   ---------
%   % Construct a geopoint vector for one feature.
%   lat = 51.519;
%   lon = -.13;
%   p = geopoint(lat,lon);
%
%   % Add a feature dynamic property with a character vector value.
%   p.Name = 'London'
%
%   Example 2
%   ---------
%   % Construct a geopoint vector for two features.
%   lat = [51.519 48.871];
%   lon = [-.13 2.4131];
%   p = geopoint(lat,lon);
%
%   % Add a feature dynamic property.
%   p.Name = ["London" "Paris"]
%
%   % Add a numeric feature dynamic property.
%   p.ID = [1 2]
%
%   % Add the coordinates for a third feature. The lengths of all
%   % the properties are synchronized.
%   p(3).Latitude = 45.472
%   p(3).Longitude = 9.184
%
%   % Set the values for the ID feature dynamic property with
%   % more values than contained in Latitude or Longitude. 
%   % All properties are expanded to match in size.
%   p.ID = 1:4
%
%   % Set the values for the ID feature dynamic property with
%   % less values than contained in Latitude or Longitude. 
%   % The ID property values expand to match the length of the
%   % Latitude and Longitude property values.
%   p.ID = 1:2
%
%   % Set the value of either coordinate property (Latitude or Longitude)
%   % with fewer values. All properties shrink in size to match 
%   % the new length.
%   p.Latitude = [51.519 48.871]
%
%   % Remove the ID property by setting its value to [].
%   p.ID = []
%
%   % Remove all dynamic properties and set the object to
%   % empty by setting a coordinate property value to [].
%   p.Latitude = []
%
%   Example 3
%   ---------
%   % Construct a geopoint vector for two features by 
%   % specifying name-value pairs in the constructor.
%   p = geopoint([51.519 48.871],[-.13 2.4131],'Name',["London" "Paris"]) 
%
%   Example 4
%   ---------
%   % Construct a geopoint vector from a structure array.
%   S = shaperead('worldcities.shp','UseGeoCoords',true);
%   p = geopoint(S);
%
%   % Add a Filename field to the Metadata structure.
%   p.Metadata.Filename = 'worldcities.shp';
%
%   % Display the first 5 points.
%   p(1:5)
%
%   % Display the Metadata structure.
%   p.Metadata
%   
%   Example 5
%   ---------
%   % Append Paderborn Germany to the vector of world cities.
%   p = geopoint(shaperead('worldcities.shp','UseGeoCoords',true));
%   lat = 51.715254;
%   lon = 8.75213;
%   p = append(p,lat,lon,'Name','Paderborn');
%   p(end)
%
%   % You can also add a point to the end of the vector using linear
%   % indexing. Add Arlington, Virginia to the end of the vector.
%   p(end+1).Latitude = 38.880043;
%   p(end).Longitude = -77.196676;
%   p(end).Name = 'Arlington';
%   p(end-1:end)
%
%   % Plot the points.
%   figure
%   worldmap('world')
%   geoshow('landareas.shp')
%   geoshow(p)
%
%   Example 6
%   ---------
%   % Construct a geopoint vector with the dynamic properties sorted.
%   p = geopoint(shaperead('tsunamis','UseGeoCoords',true));
%   p = p(:,sort(fieldnames(p)))
%
%   % Modify the geopoint vector to contain only the dynamic properties,
%   % 'Year', 'Month', 'Day', 'Hour', 'Minute'.
%   p = p(:, ["Year" "Month" "Day" "Hour" "Minute"])
%
%   % Display the first 5 elements.
%   p(1:5)
%
%   Example 7
%   ---------
%   % If you typically store latitude and longitude coordinate values 
%   % in a N-by-2 or 2-by-M array, you can assign a geopoint vector to 
%   % these numeric values. If the values are stored in a N-by-2 array, 
%   % then the Latitude property values are assigned to the first column 
%   % and the Longitude property values are assigned to the second column.
%   coast = load('coast');
%   pts = [coast.lat coast.long];
%   p = geopoint;
%   p(1:length(pts)) = pts
%
%   % If the values are stored in a 2-by-M array, then the 
%   % Latitude property values are assigned to the first row and
%   % the Longitude property values are assigned to the second row.
%   pts = [coast.lat'; coast.long'];
%   p = geopoint;
%   p(1:length(pts)) = pts
%
%   See also geopoint/geopoint geoshape, gpxread, mappoint, mapshape,
%   shaperead.

% Copyright 2011-2017 The MathWorks, Inc.

classdef geopoint < map.internal.DynamicVector 
    
    properties (Access = public,  Dependent = true)
        %Latitude - 1-by-N numeric vector of latitude coordinates
        %
        %   Latitude is a row vector of latitude coordinates of class
        %   single or double. The values may be set as either a row or
        %   column vector but they are stored as a row vector.
        Latitude
        
        %Longitude - 1-by-N numeric vector of longitude coordinates
        %
        %   Longitude is a row vector of longitude coordinates of class
        %   single or double. The values may be set as either a row or
        %   column vector but they are stored as a row vector.
        Longitude
    end
    
    methods
        
        function self = geopoint(varargin)
        %GEOPOINT Construct geopoint vector
        %
        %   P = GEOPOINT() constructs an empty geopoint vector with the
        %   following default property settings:
        %
        %        Geometry: 'point'
        %        Metadata: [1x1 struct]
        %        Latitude: []
        %       Longitude: []
        %
        %   P = GEOPOINT(LAT, LON) constructs a new geopoint vector and
        %   assigns the Latitude and Longitude property values to the
        %   numeric vectors, LAT and LON. LAT and LON are vectors of class
        %   single or double.
        %
        %   P = GEOPOINT(LAT, LON, Name, Value) constructs a geopoint
        %   vector from the input LAT and LON vectors and then adds dynamic
        %   properties to the geopoint vector using the names and values
        %   specified by the name-value pairs. If a specified name is
        %   'Metadata' and the corresponding value is a scalar structure,
        %   then the value is copied to the Metadata property; otherwise,
        %   an error is issued.
        %
        %   P = GEOPOINT(S) constructs a new geopoint vector from the
        %   fields of the structure, S. The Latitude and Longitude fields
        %   of S, if present, become the Latitude and Longitude property
        %   values of P.
        %
        %   If S contains the field Lat, and does not contain a field
        %   Latitude, then the Lat values are assigned to the Latitude
        %   property value. If S contains both Lat and Latitude fields,
        %   then both field values are assigned to P. If S contains the
        %   field, Lon, and does not contain a field, Longitude, then the
        %   Lon values are assigned to the Longitude property value. If S
        %   contains both Lon and Longitude fields, then both field values
        %   are assigned to P.
        %
        %   If S is a scalar structure which contains the field Metadata
        %   and the field value is a scalar structure, then the Metadata
        %   field is copied to the Metadata property. Otherwise an error is
        %   issued if the Metadata field is not a structure, or ignored if
        %   S is not scalar.
        %
        %   The remaining fields of S are assigned to P and become dynamic
        %   properties. Field values in S that are not numeric, string,
        %   character vector, or cell arrays of numeric, character
        %   vector, or string values are ignored.
        %
        %   P = GEOPOINT(LAT, LON, S) constructs a new geopoint vector and
        %   assigns the Latitude and Longitude property values to the
        %   numeric vectors, LAT and LON, and sets dynamic properties from
        %   the field values of S, a structure array. If S contains the
        %   fields Lat, Latitude, Lon, or Longitude, then those field
        %   values are ignored since the Latitude and Longitude property
        %   values are set by the LAT and LON input vectors. If S is a
        %   scalar structure and contains the field Metadata, and the field
        %   value is a scalar structure, then it is copied to the Metadata
        %   property. Otherwise an error is issued if the Metadata field is
        %   not a structure, or ignored if S is not scalar.
        %
        %   Examples
        %   --------
        %   % Construct a default geopoint vector, set the Latitude
        %   % and Longitude property values, and add a dynamic property.
        %   p = geopoint;
        %   p.Latitude = 10;
        %   p.Longitude = 30;
        %   p.Z = 1
        %
        %   % Construct a geopoint vector from latitude and longitude
        %   % values.
        %   p = geopoint(42,-72)
        %
        %   % Construct a geopoint vector from a latitude, longitude, and
        %   % temperature value.
        %   point = geopoint(42,-72,'Temperature',89)
        %
        %   % Construct a geopoint vector from a structure array.
        %   S = shaperead('worldcities','UseGeoCoords',true);
        %   p = geopoint(S)
        %
        %   % Construct a geopoint vector from numeric arrays and a
        %   % structure array.
        %   [S,A] = shaperead('worldcities','UseGeoCoords',true);
        %   p = geopoint([S.Lat],[S.Lon],A)
        %
        %   See also geopoint, geoshape, gpxread, mappoint, mapshape,
        %   shaperead.
       
            % Assign the names of the coordinate properties.
            coordinates = {'Latitude', 'Longitude'};
            self = self@map.internal.DynamicVector(coordinates, varargin{:});
            
        end
        
        %---------------------- set methods -------------------------------
        
        function self = set.Latitude(self, value)
        % Set Latitude.
            self = setCoordinate(self, 'Latitude', value);
        end
            
        function self = set.Longitude(self, value)
        % Set Longitude.
            self = setCoordinate(self, 'Longitude', value);
        end
        
        %---------------------- get methods -------------------------------
        
        function value = get.Latitude(self)
            value = self.pCoordinates.Latitude;
        end
        
        function value = get.Longitude(self)
            value = self.pCoordinates.Longitude;
        end
        
        %-------------------- Overloaded methods --------------------------
        
        function self = append(self, lat, lon, varargin)
        %APPEND Append points to geopoint vector
        %
        %   P = APPEND(P, LAT, LON) appends the vector, LAT, to the
        %   Latitude property values of the geopoint vector, P, and the
        %   vector, LON, to the Longitude property values of P. LAT and LON
        %   are vectors of class single or double.
        %
        %   P = APPEND(..., Name, Value) appends the LAT and LON vectors to
        %   the Latitude and Longitude property values of the geopoint
        %   vector and appends the values specified in the name-value pairs
        %   to the corresponding dynamic properties specified by the names
        %   in the name-value pairs if the properties are present in the
        %   object. Otherwise, the method adds dynamic properties to the
        %   object using the names for the dynamic property names and
        %   assigns the corresponding values.
        %
        %   Example
        %   -------
        %   p = geopoint(42,-110, 'Temperature', 65);
        %   p = append(p, 42.1, -110.4, 'Temperature', 65.5);
        %
        %   See also geopoint, geopoint/geopoint, geopoint/vertcat.

            if ~isempty(self)
                self = [self; geopoint(lat, lon, varargin{:})];
            else
                self = geopoint(lat, lon, varargin{:});
            end
        end        
    end
    
    %----------------------------------------------------------------------
    
    methods (Static = true, Hidden = true)
        
        function obj = loadobj(S)
        % Update properties when the object is loaded from a MAT-file.
           
            % In R2012b, a new Geometry property was added to geopoint. To
            % load an object correctly from previous versions, recreate the
            % object from the fields of S, if S is a structure.
            if isstruct(S)
                obj = geopoint;
                obj.pCoordinates = S.pCoordinates;
                obj.pDynamicProperties = S.pDynamicProperties;
                if isfield(S, 'Metadata') && ~isempty(S.Metadata)
                    obj.Metadata = S.Metadata;
                end
            else
                obj = S;
            end                
        end
        
        %------------------------------------------------------------------
        
        function obj = empty(varargin)
        %EMPTY Create empty geopoint vector
        %
        %   p = geopoint.empty() creates an empty geopoint vector.
        %
        %   p = geopoint.empty(0,1) creates an empty geopoint vector.
        %
        %   Example
        %   -------
        %   p = geopoint.empty()
        %
        %   See also geopoint/geopoint.
            
            if nargin > 0
                validateStaticEmptyArguments(varargin, 'geopoint vector');
            end               
            obj = geopoint();
        end
    end
end
