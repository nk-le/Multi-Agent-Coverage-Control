function varargout = geostructshow(S, varargin)
%GEOSTRUCTSHOW Display map latitude and longitude data
%
%   GEOSTRUCTSHOW(S) displays the vector geographic features stored in the
%   geographic data structure S as points, lines, or polygons according to
%   the Geometry field of the geostruct.  If S includes Lat and Lon fields
%   then the coordinate values are projected to map coordinates using the
%   projection stored in the axes if available; otherwise the values are
%   projected using the Plate Carree default projection. If S includes X
%   and Y fields the coordinate values are plotted as map coordinates.
%
%   GEOSTRUCTSHOW(..., PARAM1, VAL1, PARAM2, VAL2, ...) specifies
%   parameter/value pairs that modify the type of display or set MATLAB
%   graphics properties. Parameter names can be abbreviated and are
%   case-insensitive.
%
%   Parameters include:
%
%   'DisplayType'  The DisplayType parameter specifies the type of graphic
%                  display for the data.  The value must be consistent with
%                  the type of data in the geostruct as shown in the
%                  following table:
%
%                  Data type      Value
%                  ---------      -----
%                  vector         'point', 'multipoint', 'line', or 'polygon'
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
%   SymbolSpec     In  the case where both SymbolSpec and one or more
%   Override       graphics properties are specified, the graphics
%                  properties last specified will override any settings in 
%                  the symbol spec structure. 
%
%   H = GEOSTRUCTSHOW(...) returns the handle to an hggroup object with one
%   child per feature in the geostruct, excluding any features that are
%   completely trimmed away.  In the case of a polygon geostruct, each
%   child is a modified patch object; otherwise it is a line object.
%
%   Example 1 
%   ---------
%   % Display world land areas, using the Plate Carree projection.
%   figure
%   land = shaperead('landareas.shp','UseGeocoords',true);
%   geostructshow(land, 'FaceColor', [0.5 1.0 0.5]);
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
%   states = shaperead('usastatehi', 'UseGeoCoords', true);
%
%   % Create a SymbolSpec to display Alaska and Hawaii as red polygons.
%   symbols = makesymbolspec('Polygon', ...
%                            {'Name', 'Alaska', 'FaceColor', 'red'}, ...
%                            {'Name', 'Hawaii', 'FaceColor', 'red'});
%
%   % Display all the other states in blue.
%   geostructshow(states, 'SymbolSpec', symbols, ...
%                         'DefaultFaceColor', 'blue', ...
%                         'DefaultEdgeColor', 'black');
%
%   Example 3
%   ---------
%   % Worldmap with land areas, major lakes and rivers, and cities and
%   % populated places
%   ax = worldmap('World');
%   setm(ax, 'Origin', [0 180 0])
%   land = shaperead('landareas', 'UseGeoCoords', true);
%   geostructshow(land, 'FaceColor', [0.5 0.7 0.5],'Parent',ax)
%   lakes = shaperead('worldlakes', 'UseGeoCoords', true);
%   geostructshow(lakes, 'FaceColor', 'blue')
%   rivers = shaperead('worldrivers', 'UseGeoCoords', true);
%   geostructshow(rivers, 'Color', 'blue')
%   cities = shaperead('worldcities', 'UseGeoCoords', true);
%   geostructshow(cities, 'Marker', '.', 'Color', 'red')
%
%   See also GEOSHOW, GEOVECSHOW.

% Copyright 2006-2012 The MathWorks, Inc.

% Convert line or patch display structure to geostruct.
[S, updateSymspec] = updategeostruct(S);

% Set fcnName.
fcnName = 'geoshow';

% Obtain the Geometry value.
geometry = lower(S(1).Geometry);

% Parse the properties from varargin.
[symspec, defaultProps, otherProps] = parseShowParameters( ...
    geometry, fcnName, varargin);

% Determine if structure is a geostruct or mapstruct.
if isfield(S,'Lat') && isfield(S,'Lon')
    
   % Find or construct the projection mstruct.
   mstruct = getProjection(varargin{:});
      
   % Switch display and projection operations based on Geometry   
   objectType = ['geo' geometry ];

   % If symspec is empty and the updateSymspec is not empty then a V1
   % geostruct is present. In this case, use updateSymspec as the symspec.
   if isempty(symspec) && ~isempty(updateSymspec)
      symspec = updateSymspec;
   end
   
   % Trim and forward project the geostruct S, using function
   % symbolizeMapVectors. For its third argument use an anonymous
   % function, defined via geovec or globevec, with the prequisite
   % signature:
   %
   %    plotfcn(s, prop1, val1, pro2, val2, ...)
   %
   % where s is a scalar geostruct, prop1, prop2, ... are graphics
   % property names, and val1, val2, ... are the corresponding property
   % values.
   
   if strcmpi(mstruct.mapprojection,'globe')
       % Treat globe axes separately because of the third dimension.
       height = [];
       fcn = @(s, varargin) globevec(mstruct, s.Lat, s.Lon, height, ...
           objectType, varargin{:});
   else
       % Project and display in 2-D map coordinates.
       mapfcn = mapvecfcn(geometry, fcnName);
       fcn = @(s, varargin) geovec(mstruct, s.Lat, s.Lon, ...
           objectType, mapfcn, varargin{:});
   end
    h = symbolizeMapVectors(S, symspec, fcn, defaultProps, otherProps);
else
   % Display the X and Y coordinates using mapstructshow.
   fcnName = upper(fcnName);
   warning(message('map:geoshow:usingMAPSHOW', fcnName, fcnName,'MAPSHOW'))
   h = mapstructshow(S, varargin{:});
end

% Allow usage without ; to suppress output.
if nargout > 0
   varargout{1} = h;
end
