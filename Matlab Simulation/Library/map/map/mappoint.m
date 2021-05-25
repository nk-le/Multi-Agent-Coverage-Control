%MAPPOINT Planar point vector
%
%   A mappoint vector is an object that holds planar point coordinates and
%   attributes. The points are coupled such that the size of the X and Y
%   coordinate arrays are always equal and match the size of any additional
%   attribute arrays. A mappoint vector is always a column vector.
%
%   Syntax:
%      p = mappoint()
%      p = mappoint(x, y)
%      p = mappoint(x, y, Name, Value)
%      p = mappoint(S)
%      p = mappoint(x, y, S)
%
%   mappoint properties:
%      Geometry  - Character vector defining type of geometry
%      Metadata  - Scalar structure containing metadata
%      X         - 1-by-N numeric vector of X coordinates
%      Y         - 1-by-N numeric vector of Y coordinates
%
%   Collection properties:
%      Geometry and Metadata are collection properties. These properties
%      contain only one value per class instance. The term collection is
%      used to distinguish these two properties from other feature
%      properties which have values associated with each feature (element
%      in a mappoint vector).
%
%   Feature properties:
%      Feature properties provide one value (scalar number, scalar string,
%      or character vector) for each feature in the mappoint vector. They
%      are suitable for properties that describe a single element of a
%      mappoint vector. The X and Y properties are feature properties since
%      they contain one value for each feature.
%
%   Dynamic feature properties:
%      You can attach new dynamic feature properties to the object by using
%      the dot (.) notation. This is similar to adding dynamic fields to a
%      structure. Dynamic feature properties are suitable for such
%      attributes as name, owner, serial number, age, etc., that describe a
%      given feature.
%
%   mappoint methods:
%      mappoint   - Construct mappoint vector
%      append     - Append points to mappoint vector
%      cat        - Concatenate mappoint vectors
%      disp       - Display mappoint vector
%      fieldnames - Dynamic properties of mappoint vector
%      isempty    - True if mappoint vector is empty
%      isfield    - True if dynamic property exists
%      isprop     - True if property exists
%      length     - Number of points in mappoint vector
%      properties - Properties of mappoint vector
%      rmfield    - Remove dynamic property from mappoint vector
%      rmprop     - Remove property from mappoint vector
%      size       - Size of mappoint vector
%      struct     - Convert mappoint vector to scalar structure
%      vertcat    - Vertical concatenation for mappoint vectors
%
%   Example 1
%   ---------
%   % Construct a mappoint vector for one feature.
%   x = 1;
%   y = 1;
%   p = mappoint(x,y)
%
%   % Add a feature dynamic property with a character vector value.
%   p.FeatureName = 'My Feature'
%
%   Example 2
%   ---------
%   % Construct a mappoint vector for two features.
%   x = [1 2];
%   y = [10 10];
%   p = mappoint(x,y)
%
%   % Add a feature dynamic property.
%   p.FeatureName = {'Feature 1','Feature 2'}
%
%   % Add a numeric feature dynamic property.
%   p.ID = [1 2]
%
%   % Add a third feature. The lengths of all the properties are
%   % synchronized.
%   p(3).X = 3
%   p(3).Y = 10
%
%   % Set the values for the ID feature dynamic property with
%   % more values than contained in X or Y. All properties
%   % are expanded to match in size.
%   p.ID = 1:4
%
%   % Set the values for the ID feature dynamic property with
%   % less values than contained in X or Y. The ID property 
%   % values expand to match the length of X and Y.
%   p.ID = 1:2
%
%   % Set the values of either coordinate property (X or Y)
%   % with fewer values. All properties shrink in size to match 
%   % the new length.
%   p.X = 1:2
%
%   % Remove the FeatureName (or ID) property by setting
%   % its value to [].
%   p.FeatureName = []
%
%   % Remove all dynamic properties and set the object to
%   % empty by setting a coordinate property value to [].
%   p.X = []
%
%   Example 3
%   ---------
%   % Construct a mappoint vector for two features
%   % by specifying name-value pairs in the constructor.
%   point = mappoint([42 44],[10, 11],'Temperature',[63 65])
%
%   Example 4
%   ---------
%   % Load the data and create a mappoint vector using
%   % the coordinate values.
%   seamount = load('seamount');
%   p = mappoint(seamount.x,seamount.y,'Z',seamount.z);
% 
%   % Create a level list to use to bin the z values.
%   levels = [unique(floor(seamount.z/1000)) * 1000; 0];
% 
%   % Create a list of color values for each level.
%   colors = ["red" "green" "blue" "cyan" "black"];
% 
%   % Add a MinLevel and MaxLevel feature property 
%   % to indicate the lowest and highest binned level.
%   for k = 1:length(levels) - 1
%      n = levels(k) <= p.Z & p.Z < levels(k+1);
%      p(n).MinLevel = levels(k);
%      p(n).MaxLevel = levels(k+1) - 1;
%      p(n).Color = colors(k);
%   end
% 
%   % Add metadata information. Metadata is a scalar structure 
%   % containing information for the entire set of properties. 
%   % Any type of data may be added to the structure.
%   p.Metadata.Caption = seamount.caption;
%   p.Metadata
% 
%   % Display the point data in 2D and as a 3D scatter plot.
%   figure
%   minLevels = unique(p.MinLevel);
%   for k=1:length(minLevels)
%       minLevel = p.MinLevel == minLevels(k);
%       points = p(minLevel);
%       mapshow(points.X,points.Y,'ZData',points.Z, ...
%           'MarkerEdgeColor',points(1).Color, ...
%           'Marker','o','DisplayType','point')
%   end
%   legend(num2str(minLevels'))
% 
%   figure
%   scatter3(p.X,p.Y,p.Z)
%
%   Example 5
%   ---------
%   % Construct a mappoint vector from a structure array
%   % by assigning property values to the structure fields.
%   S = shaperead('boston_placenames');
%   p = mappoint;
%   p.X = [S.X];
%   p.Y = [S.Y];
%   p.Name = {S.NAME}
%
%   % Construct a mappoint vector from a structure array using
%   % the constructor syntax.
%   filename = 'boston_placenames.shp';
%   S = shaperead(filename);
%   p = mappoint(S)
%
%   % Add a Filename field to the Metadata structure.
%   p.Metadata.Filename = filename;
%
%   % Display the first 5 points.
%   p(1:5)
%
%   % Display the Metadata structure.
%   p.Metadata
%
%   Example 6
%   ---------
%   % Append Paderborn Germany to the vector of world cities.
%   p = mappoint(shaperead('worldcities.shp'));
%   x = 51.715254;
%   y = 8.75213;
%   p = append(p,x,y,'Name','Paderborn');
%   p(end)
%
%   % You can also add a point to the end of the vector using linear
%   % indexing. Add Arlington, Virginia to the end of the vector.
%   p(end+1).X = 38.880043;
%   p(end).Y = -77.196676;
%   p(end).Name = 'Arlington';
%   p(end-1:end)
%
%   % Plot the points.
%   figure
%   mapshow(p)
%
%   Example 7
%   ---------
%   % Construct a mappoint vector and sort the dynamic properties.
%   p = mappoint(shaperead('tsunamis'));
%   p = p(:,sort(fieldnames(p)))
%
%   % Modify the mappoint vector to contain only the dynamic properties,
%   % 'Year', 'Month', 'Day', 'Hour', 'Minute'.
%   p = p(:,["Year" "Month" "Day" "Hour" "Minute"])
%
%   % Display the first 5 elements.
%   p(1:5)
%
%   Example 8
%   ---------
%   % If you typically store x and y coordinate values in a N-by-2
%   % or 2-by-M array, you can assign a mappoint object to these 
%   % numeric values. If the values are stored in a N-by-2 array, 
%   % then the X property values are assigned to the first column 
%   % and the Y property values are assigned to the second column.
%   x = 1:10;
%   y = 21:30;
%   pts = [x' y'];
%   p = mappoint;
%   p(1:length(pts)) = pts
%
%   % If the values are stored in a 2-by-M array, then the X property 
%   % values are assigned to the first row and the Y property values 
%   % are assigned to the second row.
%   pts = [x; y];
%   p(1:length(pts)) = pts
%
%   See also geopoint, geoshape, gpxread, mappoint/mappoint, mapshape, 
%   shaperead.

% Copyright 2012-2017 The MathWorks, Inc.

classdef mappoint < map.internal.DynamicVector 
    
    properties (Access = public,  Dependent = true)
        
        %X 1-by-N numeric vector of X coordinates
        %
        %   X is a row vector of coordinates of class single or double. The
        %   values may be set as either a row or column vector, but they
        %   are stored as a row vector.
        X
        
        %Y 1-by-N numeric vector of Y coordinates
        %
        %   Y is a row vector of coordinates of class single or double. The
        %   values may be set as either a row or column vector, but they
        %   are stored as a row vector.
        Y
    end
    
    methods
        
        function self = mappoint(varargin)
        %MAPPOINT Construct mappoint vector
        %
        %   P = MAPPOINT() constructs an empty mappoint vector with the
        %   following default property settings:
        %
        %        Geometry: 'point'
        %        Metadata: [1x1 struct]
        %               X: []
        %               Y: []
        %
        %   P = MAPPOINT(X, Y) constructs a new mappoint vector and assigns
        %   the X and Y property values to the numeric vectors, X and Y. X
        %   and Y are vectors of class single or double.
        % 
        %   P = MAPPOINT(X, Y, Name, Value) constructs a mappoint vector
        %   from the input X and Y vectors and then adds dynamic properties
        %   to the mappoint vector using the names and values specified by
        %   the name-value pairs. If a specified name is 'Metadata' and the
        %   corresponding value is a scalar structure, then the value is
        %   copied to the Metadata property; otherwise, an error is issued.
        %
        %   P = MAPPOINT(S) constructs a new mappoint vector from the
        %   fields of the structure, S. The X and Y fields of S, if
        %   present, become the X and Y property values of P.
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
        %   P = MAPPOINT(X, Y, S) constructs a new mappoint vector and
        %   assigns the X and Y property values to the numeric vectors, X
        %   and Y, and sets dynamic properties from the field values of S,
        %   a structure array. If X or Y are fields of S, the values are
        %   overwritten by the X and Y input vectors. If S is a scalar
        %   structure and contains the field Metadata, and the field value
        %   is a scalar structure, then it is copied to the Metadata
        %   property. Otherwise an error is issued if the Metadata field is
        %   not a structure, or ignored if S is not scalar.
        %
        %   Examples
        %   --------
        %   % Construct a default mappoint vector, set the X and Y
        %   % property values, and add a dynamic property.
        %   p = mappoint();
        %   p.X = 1:3;
        %   p.Y = 1:3;
        %   p.Z = [10 10 10]
        %
        %   % Construct a mappoint vector from x and y values.
        %   x = [40 50 60];
        %   y = [10, 11, 12];
        %   p = mappoint(x, y)
        %
        %   % Construct a mappoint vector from x, y, and
        %   % temperature values.
        %   x = 41:43;
        %   y = 1:3;
        %   temperature = 61:63;
        %   p = mappoint(x, y, 'Temperature', temperature)
        %
        %   % Construct a mappoint vector from a structure array.
        %   S = shaperead('boston_placenames');
        %   p = mappoint(S)
        %
        %   % Construct a mappoint vector from x and y numeric arrays 
        %   % and a structure array.
        %   [S, A] = shaperead('boston_placenames');
        %   x = [S.X];
        %   y = [S.Y];
        %   p = mappoint(x, y, A)
        %
        %   See also geopoint, geoshape, gpxread, mappoint, mapshape, 
        %   shaperead.
       
            % Assign the names of the coordinate properties.
            coordinates = {'X', 'Y'};
            self = self@map.internal.DynamicVector(coordinates, varargin{:});
            
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
            value = self.pCoordinates.X;
        end
        
        function value = get.Y(self)
        % Get Y.
            value = self.pCoordinates.Y;
       end
        
        %-------------------- Overloaded methods --------------------------
        
        function self = append(self, x, y, varargin)
        %APPEND Append points to mappoint vector
        %
        %   P = APPEND(P, X, Y) appends the vector, X, to the X property
        %   values of the mappoint vector, P, and the vector, Y, to the Y
        %   property values of P. X and Y are vectors of class single or
        %   double.
        %
        %   P = APPEND(..., Name, Value) appends the X and Y vectors to the
        %   X and Y property values of the mappoint vector and appends the
        %   values specified in the name-value pairs to the corresponding
        %   dynamic properties specified by the names in the name-value
        %   pairs if the properties are present in the object. Otherwise,
        %   the method adds dynamic properties to the object using the
        %   names for the dynamic property names and assigns the
        %   corresponding values.
        %
        %   Example
        %   -------
        %   p = mappoint(42,-110, 'Temperature', 65);
        %   p = append(p, 42.1, -110.4, 'Temperature', 65.5)
        %
        %   See also mappoint, mappoint/mappoint, mappoint/vertcat.

            if ~isempty(self)
                self = [self; mappoint(x, y, varargin{:})];
            else
                self = mappoint(x, y, varargin{:});
            end
        end        
    end
    
    %----------------------------------------------------------------------
    
    methods (Static = true, Hidden = true)
        
        function obj = empty(varargin)
        %EMPTY Create empty mappoint vector
        %
        %   p = mappoint.empty() creates an empty mappoint vector.
        %
        %   p = mappoint.empty(0,1) creates an empty mappoint vector.
        %
        %   Example
        %   -------
        %   p = mappoint.empty()
        %
        %   See also mappoint/mappoint.
            
            if nargin > 0
                validateStaticEmptyArguments(varargin, 'mappoint vector');
            end               
            obj = mappoint();
        end
    end
end
