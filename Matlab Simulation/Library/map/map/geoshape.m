%GEOSHAPE Geographic shape vector
%
%   A geoshape vector is an object that holds geographic shape coordinates
%   and attributes. The shapes are coupled such that the size of the
%   latitude and longitude coordinate arrays are always equal and match the
%   size of any additional attribute arrays. A geoshape vector is always a
%   column vector.
%
%   Syntax:
%      shape = geoshape
%      shape = geoshape(lat, lon)
%      shape = geoshape(lat, lon, Name, Value)
%      shape = geoshape(S)
%      shape = geoshape(lat, lon, S)
%
%   geoshape properties:
%      Geometry  - Character vector defining type of geometry
%      Metadata  - Scalar structure containing metadata
%      Latitude  - 1-by-N numeric vector of latitude coordinates
%      Longitude - 1-by-N numeric vector of longitude coordinates
%
%   Collection properties:
%      Geometry and Metadata are collection properties. These properties
%      contain only one value per class instance. The term collection is
%      used to distinguish these two properties from other properties which
%      have values associated with each feature (element in a geoshape
%      vector).
%
%   Vertex properties:
%      Vertex properties provide a scalar number or a character vector for
%      each vertex in a geoshape object. Vertex properties are suitable for
%      properties that vary spatially from point to point within a
%      multipoint object, or from vertex to vertex along a line, such as
%      elevation, speed, temperature, or time. The vertex property values
%      of an individual feature match its Latitude and Longitude values in
%      length. Latitude and Longitude are vertex properties since they
%      contain a scalar number for each vertex in a geoshape object.
%   
%   Feature properties:
%      Feature properties provide one value (a scalar number or a character
%      vector) for each feature in a geoshape vector. They are suitable for
%      properties, such as name, owner, serial number, age, etc., that
%      describe a given feature (an element of a geoshape vector) as a
%      whole.
%
%   Dynamic properties:
%      You can attach new dynamic vertex and feature properties to the
%      object by using the dot (.) notation. This is similar to adding
%      dynamic fields to a structure.
%
%   geoshape methods:
%      geoshape   - Construct geoshape vector
%      append     - Append features to geoshape vector
%      cat        - Concatenate geoshape vectors
%      disp       - Display geoshape vector
%      fieldnames - Dynamic properties of geoshape vector
%      isempty    - True if geoshape vector is empty
%      isfield    - True if dynamic property exists
%      isprop     - True if property exists
%      length     - Number of shapes in geoshape vector
%      properties - Properties of geoshape vector
%      rmfield    - Remove dynamic property from geoshape vector
%      rmprop     - Remove property from geoshape vector
%      size       - Size of geoshape vector
%      struct     - Convert geoshape vector to scalar structure
%      vertcat    - Vertical concatenation for geoshape vectors
%
%   Example 1
%   ---------
%   % Construct a geoshape vector with one feature from
%   % latitude and longitude coordinates.
%   load coastlines
%   shape = geoshape(coastlat, coastlon);
%
%   % Add a feature dynamic property with a character vector value.
%   shape.Name = 'coastline'
%
%   % Display the coordinates as a single line.
%   worldmap world
%   geoshow(shape)
%
%   Example 2
%   ---------
%   % Construct a scalar geoshape vector for two point features from
%   % latitude, longitude, and temperature values.
%   lat = [42 42.3];
%   lon = [-72 -72.85];
%   temperature = {[89 87.5]};
%   point = geoshape(lat,lon,'Temperature',temperature);
%   point.Geometry = 'point'
%
%   Example 3
%   ---------
%   % Construct a geoshape vector by setting Latitude and Longitude
%   % property values and by adding a new feature dynamic property.
%   S = shaperead('worldrivers','UseGeoCoords',true);
%   shape = geoshape;
%   for k=1:length(S)
%      shape(k).Latitude  = S(k).Lat;
%      shape(k).Longitude = S(k).Lon;
%   end
%   shape.Name = {S.Name}
% 
%   Example 4
%   ---------
%   % Construct a geoshape vector from a structure array.
%   S = shaperead('worldrivers.shp','UseGeoCoords',true);
%   shape = geoshape(S)
%
%   % Add a Filename field to the Metadata structure.
%   shape.Metadata.Filename = 'worldcities.shp';
%
%   % Display the first 5 points.
%   shape(1:5)
%
%   % Display the Metadata structure.
%   shape.Metadata
%
%   Example 5
%   ---------
%   % Append a single point and a shape to a geoshape vector.
%   % Create a geoshape vector containing a single feature
%   % of the locations of world cities. 
%   S = shaperead('worldcities.shp','UseGeoCoords',true);
%   cities = geoshape([S.Lat],[S.Lon],'Name',{{S.Name}});
%   cities.Geometry = 'point';
%
%   % Append Paderborn Germany to the geoshape vector.
%   % The length of each vertex property grows by 1 when 
%   % Latitude(end+1) is set. The remaining properties are
%   % indexed with end.
%   lat = 51.715254;
%   lon = 8.75213;
%   cities(1).Latitude(end+1) = lat;
%   cities(1).Longitude(end) = lon;
%   cities(1).Name{end} = 'Paderborn'
%
%   % You can display the last point by constructing a
%   % a geopoint vector.
%   paderborn = geopoint(cities.Latitude(end),cities.Longitude(end), ...
%      'Name',cities.Name{end})
%
%   % Create a new geoshape vector with two new features containing 
%   % the cities in the northern and southern hemispheres. 
%   % Add a Location dynamic feature property to distinguish the 
%   % different classifications.
%   northern = cities(1).Latitude >= 0;
%   southern = cities(1).Latitude < 0;
%   index = {northern; southern};
%   location = {'Northern Hemisphere','Southern Hemisphere'};
%   hemispheres = geoshape;
%   for k = 1:length(index)
%      hemispheres = append(hemispheres, ...
%         cities.Latitude(index{k}),cities.Longitude(index{k}), ...
%         'Name',{cities.Name(index{k})},'Location',location{k});
%   end
%   hemispheres.Geometry = 'point'
%   
%   % Plot the northern cities in red and the southern cities in blue.
%   hemispheres.Color = ["red" "blue"];
%   worldmap('world')
%   geoshow('landareas.shp')
%   for k=1:2
%      geoshow(hemispheres(k).Latitude,hemispheres(k).Longitude, ...
%         'DisplayType',hemispheres.Geometry, ...
%         'MarkerEdgeColor',hemispheres(k).Color)
%   end
%
%   Example 6
%   ---------
%   % Construct a geoshape vector with the dynamic properties sorted.
%   shape = geoshape(shaperead('tsunamis','UseGeoCoords',true));
%   shape.Geometry = 'point';
%   shape = shape(:, sort(fieldnames(shape)))
%
%   % Modify the geoshape vector to contain only the dynamic properties,
%   % 'Year', 'Month', 'Day', 'Hour', 'Minute'.
%   shape = shape(:, ["Year" "Month" "Day" "Hour" "Minute"])
%
%   % Display the first 5 elements.
%   shape(1:5)
%
%   Example 7
%   ---------
%   % If you typically store latitude and longitude coordinate values 
%   % in a N-by-2 or 2-by-M array, you can assign a geoshape vector to 
%   % these numeric values. If the values are stored in a N-by-2 array, 
%   % then the Latitude property values are assigned to the first column 
%   % and the Longitude property values are assigned to the second column.
%   load coastlines
%   pts = [coastlat coastlon];
%   shape = geoshape;
%   shape(1) = pts
%
%   % If the values are stored in a 2-by-M array, then the 
%   % Latitude property values are assigned to the first row and
%   % the Longitude property values are assigned to the second row.
%   pts = [coastlat'; coastlon'];
%   shape = geoshape;
%   shape(1) = pts
%
%   See also geopoint, geoshape/geoshape, gpxread, mappoint, mapshape, 
%   shaperead.

% Copyright 2012-2017 The MathWorks, Inc.

classdef geoshape < map.internal.DynamicShape
    
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
        
        function self = geoshape(varargin)
        %GEOSHAPE Construct geoshape vector
        %
        %   SHAPE = GEOSHAPE() constructs an empty geoshape vector with the
        %   following default property settings:
        %
        %        Geometry: 'line'
        %        Metadata: [1x1 struct]
        %        Latitude: []
        %       Longitude: []
        %
        %   SHAPE = GEOSHAPE(LAT, LON) constructs a new geoshape vector and
        %   assigns the Latitude and Longitude property values to the
        %   vectors, LAT and LON. LAT and LON may be either numeric vectors
        %   of class single or double or cell arrays containing numeric
        %   vectors of class single or double.
        %
        %   SHAPE = GEOSHAPE(LAT, LON, Name, Value) constructs a geoshape
        %   vector from the input LAT and LON vectors and then adds dynamic
        %   properties to the geoshape vector using the names and values
        %   specified by the name-value pairs. If a specified name is
        %   'Metadata' and the corresponding value is a scalar structure,
        %   then the value is copied to the Metadata property; otherwise,
        %   an error is issued.
        %
        %   SHAPE = GEOSHAPE(S) constructs a new geoshape vector from the
        %   fields of the structure array, S.
        %
        %   If S contains the field Lat, and does not contain a field
        %   Latitude, then the Latitude property values are assigned to the
        %   Lat field values. If S contains the field Lon, and does not
        %   contain a field Longitude, then the Longitude property values
        %   are assigned to the Lon field values.
        %
        %   If S contains both Lat and Latitude fields, then the Latitude
        %   property values are assigned to the Latitude field values and a
        %   Lat dynamic property is created whose values are assigned to
        %   the Lat field values. If S contains both Lon and Longitude
        %   fields, then the Longitude property values are assigned to the
        %   Longitude field values and a Lon dynamic property is created
        %   whose values are assigned to the Lon field values.
        %
        %   If S is a scalar structure which contains the field Metadata
        %   and the field value is a scalar structure, then the Metadata
        %   field is copied to the Metadata property. If S is a scalar
        %   structure and the Metadata field is present and is not a scalar
        %   structure, then an error is issued. If S is not scalar then the
        %   Metadata field is ignored.
        %
        %   Other fields of S are assigned to SHAPE and become dynamic
        %   properties. Field values in S that are not numeric, string, or
        %   character vectors, or cell arrays of numeric, string, or
        %   character vectors are ignored.
        %
        %   SHAPE = GEOSHAPE(LAT, LON, S) constructs a new geoshape vector
        %   and assigns the Latitude and Longitude property values to the
        %   numeric vectors, LAT and LON, and sets dynamic properties from
        %   the field values of S, a structure array. If S contains the
        %   fields Lat, Latitude, Lon, or Longitude, then those field
        %   values are ignored since the Latitude and Longitude property
        %   values are set by the LAT and LON input vectors. If S is a
        %   scalar structure and contains the field Metadata, and the field
        %   value is a scalar structure, then it is copied to the Metadata
        %   property value. Otherwise an error is issued if the Metadata
        %   field is not a scalar structure, or ignored if S is not scalar.
        %
        %   Examples
        %   --------
        %   % Construct a default geoshape vector, set the Latitude and
        %   % Longitude  property values, and add a dynamic property.
        %   shape = geoshape;
        %   shape(1).Latitude = 0:45:90;
        %   shape(1).Longitude = [10 10 10];
        %   shape(1).Z = [10 20 30]
        %
        %   % Construct a geoshape vector from latitude and longitude 
        %   % values.
        %   shape = geoshape([42 43 45],[10 11 15]);
        %
        %   % Construct a geoshape vector from a latitude, longitude, and
        %   % temperature value.
        %   point = geoshape(42,-72,'Temperature',89);
        %   point.Geometry = 'point'
        %
        %   % Construct a geoshape vector from a structure array.
        %   S = shaperead('worldrivers','UseGeoCoords',true);
        %   shape = geoshape(S)
        %
        %   % Construct a geoshape vector using cell arrays and a
        %   % structure array as input.
        %   [S,A] = shaperead('worldrivers','UseGeoCoords',true);
        %   shape = geoshape({S.Lat},{S.Lon},A)
        %
        %   See also geopoint, geoshape, gpxread, mappoint, mapshape,
        %   shaperead.
        
            % Assign the names of the coordinate properties.
            coordinates = {'Latitude', 'Longitude'};
           
            % Construct the object.
            self = self@map.internal.DynamicShape(coordinates, varargin{:});
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
        % Get Latitude.
            value = getCoordinate(self, 'Latitude');
        end
        
        function value = get.Longitude(self)
        % Get Longitude.
            value = getCoordinate(self, 'Longitude');
       end
        
        %-------------------- Overloaded methods --------------------------
              
        function self = append(self, lat, lon, varargin)
        %APPEND Append features to geoshape vector
        %
        %   SHAPE = APPEND(SHAPE, LAT, LON) appends the vector, LAT, to the
        %   Latitude property values of the geoshape vector, SHAPE, and the
        %   vector, LON, to the Longitude property values of SHAPE. LAT and
        %   LON are either vectors of class single or double or cell arrays
        %   containing numeric arrays of class single or double.
        %
        %   SHAPE = APPEND(..., Name, Value) appends the LAT and LON
        %   vectors to the Latitude and Longitude property values of the
        %   geoshape vector, SHAPE, and appends the values specified in the
        %   name-value pairs to the corresponding dynamic properties
        %   specified by the names in the name-value pairs if the
        %   properties are present in the object. Otherwise, the method
        %   adds dynamic properties to the object using the names for the
        %   dynamic property names and assigns the corresponding values.
        %
        %   Example
        %   -------
        %   lat1 = [42 42.2 43];
        %   lon1 = [-110 -110.3 -110.5];
        %   temp1 = [65 65.1 68];
        %   shape = geoshape(lat1,lon1,'Temperature',{temp1});
        %
        %   lat2 = [43 43.1 44 44.1];
        %   lon2 = [-110.1 -111 -111.12 -110.8];
        %   temp2 = [66 66.1 68.3 69];
        %   shape = append(shape,lat2,lon2,'Temperature',{temp2});
        %
        %   See also geoshape, geoshape/geoshape, geoshape/vertcat.

            if ~isempty(self)
                self = [self; geoshape(lat, lon, varargin{:})];
            else
                self = geoshape(lat, lon, varargin{:});
            end
        end
    end
    
    %----------------------------------------------------------------------
    
    methods (Static = true, Hidden = true)
        
        function obj = empty(varargin)
        %EMPTY Create empty geoshape vector
        %
        %   p = geoshape.empty() creates an empty geoshape vector.
        %
        %   p = geoshape.empty(0,1) creates an empty geoshape vector.
        %
        %   Example
        %   -------
        %   p = geoshape.empty()
        %
        %   See also geoshape/geoshape.
            
            if nargin > 0
                validateStaticEmptyArguments(varargin, 'geoshape vector');
            end               
            obj = geoshape();
        end
    end
end
