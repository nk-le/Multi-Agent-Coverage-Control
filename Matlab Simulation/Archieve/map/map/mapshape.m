%MAPSHAPE Planar shape vector
%
%   A mapshape vector is an object that holds planar shape coordinates and
%   attributes. The shapes are coupled such that the size of the X and Y
%   coordinate arrays are always equal and match the size of any additional
%   attribute arrays. A mapshape vector is always a column vector.
%
%   Syntax:
%      shape = mapshape
%      shape = mapshape(x, y)
%      shape = mapshape(x, y, Name, Value)
%      shape = mapshape(S)
%      shape = mapshape(x, y, S)
%
%   mapshape properties:
%      Geometry  - Character vector defining type of geometry
%      Metadata  - Scalar structure containing metadata
%      X         - 1-by-N numeric vector of X coordinates
%      Y         - 1-by-N numeric vector of Y coordinates
%
%   Collection properties:
%      Geometry and Metadata are collection properties. These properties
%      contain only one value per class instance. The term collection is
%      used to distinguish these two properties from other properties which
%      have values associated with each feature (element in a mapshape
%      vector).
%
%   Vertex properties:
%      Vertex properties provide a scalar number or a character vector for
%      each vertex in a mapshape object. Vertex properties are suitable for
%      properties that vary spatially from point to point within a
%      multipoint object, or from vertex to vertex along a line, such as
%      elevation, speed, temperature, or time. The vertex property values
%      of an individual feature match its X and Y values in length. X and Y
%      are vertex properties since they contain a scalar number for each
%      vertex in a mapshape object.
%   
%   Feature properties:
%      Feature properties provide one value (a scalar number or a character
%      vector) for each feature in a mapshape vector. They are suitable for
%      properties, such as name, owner, serial number, age, etc., that
%      describe a given feature (an element of a mapshape vector) as a
%      whole.
%
%   Dynamic properties:
%      You can attach new dynamic vertex and feature properties to the
%      object by using the dot (.) notation. This is similar to adding
%      dynamic fields to a structure.
%
%   mapshape methods:
%      mapshape   - Construct mapshape vector
%      append     - Append features to mapshape vector
%      cat        - Concatenate mapshape vectors
%      disp       - Display mapshape vector
%      fieldnames - Dynamic properties of mapshape vector
%      isempty    - True if mapshape vector is empty
%      isfield    - True if dynamic property exists
%      isprop     - True if property exists
%      length     - Number of shapes in mapshape vector
%      properties - Properties of mapshape vector
%      rmfield    - Remove dynamic property from mapshape vector
%      rmprop     - Remove property from mapshape vector
%      size       - Size of mapshape vector
%      struct     - Convert mapshape vector to scalar structure
%      vertcat    - Vertical concatenation for mapshape vectors
%
%   Example 1
%   ---------
%   % Construct a mapshape vector from x and y coordinates.
%   x = 0:10:100;
%   y = 0:10:100;
%   shape = mapshape(x,y)
%
%   % Add a feature dynamic property.
%   shape.FeatureName = 'My Feature'
%
%   % Add a vertex dynamic property to the first feature.
%   shape(1).Temperature = 65 + rand(1,length(shape.X))
%
%   Example 2
%   ---------
%   % Construct a mapshape vector for two features.
%   x = {1:3 4:6};
%   y = {[0 0 0] [1 1 1]};
%   shape = mapshape(x,y)
%
%   % Add a two element feature dynamic property.
%   shape.FeatureName = ["Feature 1" "Feature 2"]
%
%   % Add a vertex dynamic property.
%   z = {101:103 [115 114 110]}
%   shape.Z = z
%
%   % Display the second feature.
%   shape(2)
%
%   % Add a third feature. The lengths of all the properties are
%   % synchronized.
%   shape(3).X = 5:9
%
%   % Set the values for the Z vertex property with fewer values
%   % than contained in X or Y. The Z values expand to match the 
%   % length of X and Y.
%   shape(3).Z = 1:3
%
%   % Set the values for either coordinate property (X or Y) and
%   % all properties shrink in size to match the new vertex length
%   % of that feature.
%   shape(3).Y = 1
%
%   % Set the values for the Z vertex property with more values
%   % than contained in X or Y. All properties expand in length
%   % to match Z.
%   shape(3).Z = 1:6
%
%   % Remove the FeatureName property.
%   shape.FeatureName = []
%
%   % Remove all dynamic properties and set the object to empty.
%   shape.X = []
%
%   Example 3
%   ---------
%   % Construct a mapshape vector with two features by
%   % specifying name-value pairs in the constructor.
%   x = {1:3 4:6};
%   y = {[0 0 0] [1 1 1]};
%   z = {41:43 [56 50 59]};
%   name = ["Feature 1" "Feature 2"];
%   id = [1 2];
%   shape = mapshape(x,y,'Z',z,'Name',name,'ID',id)
%
%   Example 4
%   ---------
%   % Construct a mapshape vector to hold multiple features
%   % using data from the seamount MAT-file. Add dynamic vertex
%   % properties to indicate the Z values. Add dynamic feature
%   % properties to indicate the color and level values.
%   % Include metadata information.
%
%   % Load the data and create x, y, and z arrays.
%   load seamount
%
%   % Create a level list to use to bin the z values.
%   levels = [unique(floor(z/1000)) * 1000; 0];
%
%   % Construct a mapshape object and assign the X and Y 
%   % vertex properties to the binned x and y values.
%   % Create a new Z vertex property to contain the binned
%   % z values. Add a Levels feature property to contain
%   % the lowest level value per feature.
%   shape = mapshape;
%   for k = 1:length(levels) - 1
%      index = z >= levels(k) & z < levels(k+1);
%      shape(k).X = x(index);
%      shape(k).Y = y(index);
%      shape(k).Z = z(index);
%      shape(k).Level = levels(k);
%   end
%
%   % Add a Color feature property to denote a color for 
%   % that feature.
%   shape.Color = ["red" "green" "blue" "cyan" "black"];
%
%   % The geometry of the values is 'point'.
%   shape.Geometry = 'point'
%
%   % Add metadata information. Metadata is a scalar structure 
%   % containing information for the entire set of properties. 
%   % Any type of data may be added to the structure.
%   shape.Metadata.Caption = caption;
%   shape.Metadata
%
%   % Display the point data in 2D and as a 3D scatter plot.
%   figure
%   for k=1:length(shape)
%     mapshow(shape(k).X,shape(k).Y, ...
%      'MarkerEdgeColor',shape(k).Color, ...
%      'Marker', 'o', ...
%      'DisplayType',shape.Geometry)
%   end
%   legend(num2str(shape.Level'))
%
%   figure
%   scatter3(shape.X,shape.Y,shape.Z)
% 
%   Example 5
%   ---------
%   % Construct a mapshape vector from a structure array.
%   filename = 'concord_roads.shp';
%   S = shaperead(filename);
%   shape = mapshape(S)
%
%   % Add a Filename to the Metadata structure.
%   shape.Metadata.Filename = filename;
%
%   % Construct a new shape with only CLASS 4 (major road) designation.
%   class4 = shape(shape.CLASS == 4)
%
%   Example 6
%   ---------
%   % Construct a mapshape vector and sort the dynamic properties.
%   % You can create a new mapshape vector that contains a subset 
%   % of dynamic properties by adding the name of a property or a
%   % cell array of property names to the last index in the () operator.
%   shape = mapshape(shaperead('tsunamis'))
%   shape = shape(:, sort(fieldnames(shape)))
%
%   % Modify the mapshape vector to contain only the dynamic properties,
%   % 'Year', 'Month', 'Day', 'Hour', 'Minute'.
%   shape = shape(:, ["Year" "Month" "Day" "Hour" "Minute"])
%
%   % Create a new mapshape vector in which each feature contains
%   % the points for the same year. Copy the data from a mappoint
%   % vector to ensure that NaN feature separators are not included.
%   % Create a subsection of data to include only Year and Country 
%   % dynamic properties.
%   points = mappoint(shaperead('tsunamis'));
%   points = points(:, {'Year', 'Country'});
%   years = unique(points.Year);
%   multipoint = mapshape;
%   multipoint.Geometry = 'point';
%   for k = 1:length(years)
%      index = points.Year == years(k);
%      multipoint(k).X = points(index).X;
%      multipoint(k).Y = points(index).Y;
%      multipoint(k).Year = years(k);
%      multipoint(k).Country = points(index).Country;
%   end
%
%   % Display the mapshape vector.
%   multipoint
% 
%   % Display the third from the end feature. 
%   multipoint(end-3)
%  
%   See also geopoint, geoshape, gpxread, mapshape/mapshape shaperead.

% Copyright 2012-2017 The MathWorks, Inc.

classdef mapshape < map.internal.DynamicShape
    
    properties (Access = public,  Dependent = true)
        
        %X 1-by-N numeric vector of X coordinates
        %
        %   X is a row vector of coordinates of class double or single. The
        %   values may be set as either a row or column vector but they are
        %   stored as a row vector.
        X
        
        %Y 1-by-N numeric vector of Y coordinates
        %
        %   Y is a row vector of coordinates of class double or single. The
        %   values may be set as either a row or column vector but they are
        %   stored as a row vector.
        Y
    end
    
    methods
        
        function self = mapshape(varargin)
        %MAPSHAPE Construct planar shape vector
        %
        %   SHAPE = MAPSHAPE constructs an empty mapshape vector with the
        %   following default property settings:
        %
        %        Geometry: 'line'
        %        Metadata: [1x1 struct]
        %               X: []
        %               Y: []
        %
        %   SHAPE = MAPSHAPE(X, Y) constructs a new mapshape vector and
        %   assigns the X and Y property values to the vectors, X and Y. X
        %   and Y may be either numeric vectors of class single or double
        %   or cell arrays containing numeric vectors of class single or
        %   double.
        %
        %   SHAPE = MAPSHAPE(X, Y, Name, Value) constructs a mapshape
        %   vector from the input X and Y vectors and then adds dynamic
        %   properties to the mapshape vector using the names and values
        %   specified by the name-value pairs. If a specified name is
        %   'Metadata' and the corresponding value is a scalar structure,
        %   then the value is copied to the Metadata property; otherwise,
        %   an error is issued.
        %
        %   SHAPE = MAPSHAPE(S) constructs a new mapshape vector from the
        %   fields of the structure array, S.
        %
        %   If S is a scalar structure which contains the field Metadata
        %   and the field value is a scalar structure, then the Metadata
        %   field is copied to the Metadata property. If S is a scalar
        %   structure and the Metadata field is present and is not a scalar
        %   structure, then an error is issued. If S is not scalar then the
        %   Metadata field is ignored.
        %
        %   Other fields of S are assigned to SHAPE and become dynamic
        %   properties. Field values in S that are not numeric vectors,
        %   string vectors, character vectors, or cell arrays of numeric,
        %   string, or character vectors are ignored.
        %
        %   SHAPE = MAPSHAPE(X, Y, S) constructs a new mapshape vector and
        %   assigns the X and Y property values to the numeric vectors, X
        %   and Y, and sets dynamic properties from the field values of S,
        %   a structure array. If S is a scalar structure and contains the
        %   field Metadata, and the field value is a scalar structure, then
        %   it is copied to the Metadata property. Otherwise an error is
        %   issued if the Metadata field is not a structure, or ignored if
        %   S is not scalar.
        % 
        %   Examples
        %   --------
        %   % Construct a default mapshape vector and add properties
        %   % to it.
        %   shape = mapshape;
        %   shape(1).X = 1:3
        %   shape(1).Y = 1:3
        %   shape(1).Z = [10 10 10]
        %
        %   % Construct a mapshape vector object from x and y values.
        %   x = [40, 50, 60];
        %   y = [10, 20, 30];
        %   shape = mapshape(x, y)
        %
        %   % Construct a mapshape vector from x, y, and
        %   % temperature values.
        %   x = 1:10;
        %   y = 21:30;
        %   temperature = {61:70};
        %   shape = mapshape(x, y, 'Temperature', temperature)
        %
        %   % Construct a mapshape vector from a structure array.
        %   S = shaperead('concord_roads');
        %   shape = mapshape(S)
        %
        %   % Construct a mapshape vector using arrays and a
        %   % structure as input.
        %   [S, A] = shaperead('concord_hydro_area');
        %   shape = mapshape({S.X}, {S.Y}, A);
        %   shape.Geometry = S(1).Geometry
        %
        %   See also geopoint, geoshape, gpxread, mapshape, shaperead.
        
            % Assign the names of the coordinate properties.
            coordinates = {'X', 'Y'};
            
            % Construct the object.
            self = self@map.internal.DynamicShape(coordinates, varargin{:});
        end
        
        %---------------------- set methods -------------------------------
        
        
        function self = set.X(self, value)
        % Set X.
            self = setCoordinate(self, 'X', value);
        end
            
        function self = set.Y(self, value)
        % Set Y.
            self = setCoordinate(self, 'Y', value);
        end
        
        %---------------------- get methods -------------------------------
        
        function value = get.X(self)
        % Get X.
            value = getCoordinate(self, 'X');
        end
        
        function value = get.Y(self)
        % Get Y.
            value = getCoordinate(self, 'Y');
       end
        
        %-------------------- Overloaded methods --------------------------
              
        function self = append(self, x, y, varargin)
        %APPEND Append features to mapshape vector
        %
        %   SHAPE = APPEND(SHAPE, X, Y) appends the vector, X, to the X
        %   property values of the mapshape vector, SHAPE, and the vector,
        %   Y, to the Y property values of SHAPE. X and Y are either
        %   vectors of class single or double or cell arrays containing
        %   numeric arrays of class single or double.
        %
        %   SHAPE = APPEND(..., Name, Value) appends the X and Y vectors to
        %   the X and Y property values of the mapshape vector and appends
        %   the values specified in the name-value pairs to the
        %   corresponding dynamic properties specified by the names in the
        %   name-value pairs if the properties are present in the object.
        %   Otherwise, the method adds dynamic properties to the object
        %   using the names for the dynamic property names and assigns the
        %   corresponding values.
        %
        %   Example
        %   -------
        %   shape = mapshape(42:44,30:32, 'Temperature', {65:67});
        %   shape = append(shape, 42.1, 33, 'Temperature', 65.5);
        %
        %   See also mapshape, mapshape/mapshape, mapshape/vertcat.

            if ~isempty(self)
                self = [self; mapshape(x, y, varargin{:})];
            else
                self = mapshape(x, y, varargin{:});
            end
        end
    end
    
    %----------------------------------------------------------------------
    
    methods (Static = true, Hidden = true)
        
        function obj = empty(varargin)
        %EMPTY Create empty mapshape vector
        %
        %   p = mapshape.empty creates an empty mapshape vector.
        %
        %   p = mapshape.empty(0,1) creates an empty mapshape vector.
        %
        %   Example
        %   -------
        %   p = mapshape.empty
        %
        %   See also mapshape/mapshape.
            
            if nargin > 0
                validateStaticEmptyArguments(varargin, 'mapshape vector');
            end               
            obj = mapshape;
        end
    end
end
