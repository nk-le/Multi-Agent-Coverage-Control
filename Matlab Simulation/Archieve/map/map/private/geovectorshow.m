function varargout = geovectorshow(S, varargin)
%GEOVECTORSHOW Display geographic vector data with projection
%
%   GEOVECTORSHOW(S) displays the vector geographic features stored in the
%   geopoint or geoshape vector S as points, lines, or polygons according
%   to the Geometry property of the object. If S is a geopoint or geoshape
%   vector then the coordinate values are projected to map coordinates
%   using the projection stored in the axes if available; otherwise the
%   values are projected using the Plate Carree default projection. If S is
%   a mappoint or mapshape vector a warning is issued and the coordinate
%   values are plotted as map coordinates.
%
%   GEOVECTORSHOW(..., Name, Value) specifies name-value pairs that modify
%   the type of display or set MATLAB graphics properties. Parameter names
%   can be abbreviated and are case-insensitive.
%
%   Parameters include:
%
%   'DisplayType'  The DisplayType parameter specifies the type of graphic
%                  display for the data.  The value must be consistent with
%                  the Geometry field in the dynamic vector.
%
%   Graphics       In addition to specifying a parent axes, the graphics
%   Properties     properties may be set for line, point, and polygon.
%                  Refer to the MATLAB Graphics documentation on line,
%                  and patch for a complete description of these properties 
%                  and their values.
%
%   'SymbolSpec'   The SymbolSpec parameter specifies the symbolization
%                  rules used for vector data through a structure returned
%                  by MAKESYMBOLSPEC. 
%
%                  In  the case where both SymbolSpec and one or more
%                  graphics properties are specified, the graphics
%                  properties last specified will override any settings in 
%                  the symbol spec structure. 
%
%   H = GEOVECTORSHOW(...) returns the handle to an hggroup object with one
%   child per feature in the geostruct, excluding any features that are
%   completely trimmed away.  In the case of polygon Geometry, each
%   child is a modified patch object; otherwise it is a line object.
%
%   Example 1 
%   ---------
%   % Display world land areas, using the Plate Carree projection.
%   figure
%   land = geoshape(shaperead('landareas.shp','UseGeocoords',true));
%   geovectorshow(land, 'FaceColor', [0.5 1.0 0.5]);
%
%   Example 2 
%   ---------
%   % Override the SymbolSpec default rule.
%
%   % Create a worldmap of North America
%   figure
%   worldmap('na');
%
%   % Read the USA high resolution data
%   states = geoshape(shaperead('usastatehi', 'UseGeoCoords', true));
%
%   % Create a SymbolSpec to display Alaska and Hawaii as red polygons.
%   symbols = makesymbolspec('Polygon', ...
%                            {'Name', 'Alaska', 'FaceColor', 'red'}, ...
%                            {'Name', 'Hawaii', 'FaceColor', 'red'});
%
%   % Display all the other states in blue.
%   geovectorshow(states, 'SymbolSpec', symbols, ...
%                         'DefaultFaceColor', 'blue', ...
%                         'DefaultEdgeColor', 'black');
%
%   Example 3
%   ---------
%   % Worldmap with land areas, major lakes and rivers, and cities and
%   % populated places
%   land = geoshape(shaperead('landareas', 'UseGeoCoords', true));
%   lakes = geoshape(shaperead('worldlakes', 'UseGeoCoords', true));
%   rivers = geoshape(shaperead('worldrivers', 'UseGeoCoords', true));
%   cities = geopoint(shaperead('worldcities', 'UseGeoCoords', true));
%   ax = worldmap('World');
%   setm(ax, 'Origin', [0 180 0])
%   geovectorshow(land,  'FaceColor', [0.5 0.7 0.5],'Parent',ax)
%   geovectorshow(lakes, 'FaceColor', 'blue')
%   geovectorshow(rivers, 'Color', 'blue')
%   geovectorshow(cities, 'Marker', '.', 'Color', 'red')
%
%   See also GEOSHOW, GEOSTRUCTSHOW, GEOVECSHOW

% Copyright 2012-2014 The MathWorks, Inc.

% Validate S.
fcnName = 'geoshow';
validateattributes(S, {'geopoint', 'mappoint', 'geoshape','mapshape'}, ...
   {}, fcnName, 'S')

% Obtain the Geometry value.
geometry = S.Geometry;

% Parse the properties from varargin.
[symspec, defaultProps, otherProps] = parseShowParameters( ...
    geometry, fcnName, varargin);

% Determine if using geovectorshow or mapvectorshow.
if any(strcmp(class(S), {'geopoint','geoshape'}))   
    % Find or construct the projection mstruct.
    mstruct = getProjection(varargin{:});
    
    % Switch display and projection operations based on Geometry
    objectType = ['geo' geometry ];
    
    % Trim and forward project the dynamic vector S, using function
    % symbolizeMapVectors. For its third argument use an anonymous
    % function, defined via geovec or globevec, with the prequisite
    % signature:
    %
    %    plotfcn(s, prop1, val1, pro2, val2, ...)
    %
    % where s is a single feature, prop1, prop2, ... are graphics
    % property names, and val1, val2, ... are the corresponding property
    % values.
    if strcmpi(mstruct.mapprojection,'globe')
        % Treat globe axes separately because of the third dimension.
        height = [];
        fcn = @(s, varargin) globevec(mstruct, s.Latitude, s.Longitude, ...
            height, objectType, varargin{:});
    else
        % Project and display in 2-D map coordinates.
        mapfcn = mapvecfcn(geometry, fcnName);
        fcn = @(s, varargin) geovec(mstruct, s.Latitude, s.Longitude,  ...
            objectType, mapfcn, varargin{:});
    end
    h = symbolizeMapVectors(S, symspec, fcn, defaultProps, otherProps);
else    
    % Display the X and Y coordinates using mapvectorshow
    fcnName = upper(fcnName);
    warning(message('map:geoshow:usingMAPSHOW', fcnName, fcnName, 'MAPSHOW'))
    h = mapvectorshow(S, varargin{:});
end

%  Restack to ensure standard child order in the map axes.
map.graphics.internal.restackMapAxes(h)

% Allow usage without ; to suppress output.
if nargout > 0
    varargout{1} = h;
end
