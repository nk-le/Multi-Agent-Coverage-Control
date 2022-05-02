function varargout = mapvectorshow(S, varargin)
%MAPVECTORSHOW Display map vector data without projection
%
%   MAPVECTORSHOW(S) displays the vector geographic features stored in the
%   mappoint or mapshape vector S as points, lines, or polygons according
%   to the Geometry property of the object. If S is a mappoint or mapshape
%   vector, then they are used directly to plot features in map
%   coordinates; otherwise, the coordinates will be projected using the
%   Plate Carree projection.
%
%   MAPVECTORSHOW(..., Name, Value) specifies name-value pairs that modify
%   the type of display or set MATLAB graphics properties. Parameter names
%   can be abbreviated and are case-insensitive.
%
%   Parameters include:
%
%   'DisplayType'  The DisplayType parameter specifies the type of graphic
%                  display for the data.  The value must be consistent with
%                  the type of data in the dynamic vector.
%
%   Graphics       In addition to specifying a parent axes, the graphics
%   Properties     properties may be set for line, point, and polygon
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
%                  the symbol spec structure. See example 5 below.
%
%   H = MAPVECTORSHOW(...) returns the handle to an hggroup object with one
%   child per feature in the geostruct. In the case of a polygon Geometry,
%   each child is a modified patch object;  otherwise it is a line object.
%
%   Example 1 
%   ---------
%   % Display the roads geographic data structure.
%   roads = mapshape(shaperead('boston_roads.shp'));
%   figure
%   mapvectorshow(roads);
%  
%   Example 2
%   ---------
%   % Display the roads shape and change the LineStyle.
%   roads = mapshape(shaperead('boston_roads.shp'));
%   figure
%   mapvectorshow(roads,'LineStyle',':');
%
%   Example 3 
%   ---------
%   % Display the roads shape, and render using a SymbolSpec.
%   roads = mapshape(shaperead('boston_roads.shp'));
%   roadspec = makesymbolspec('Line',...
%                             {'ADMIN_TYPE',0,'Color','c'}, ...
%                             {'ADMIN_TYPE',3,'Color','r'},...
%                             {'CLASS',6,'Visible','off'},...
%                             {'CLASS',[1 4],'LineWidth',2});
%   figure
%   mapvectorshow(roads,'SymbolSpec',roadspec);
%
%   Example 4 
%   ---------
%   % Override default properties of the SymbolSpec.
%   roadspec = makesymbolspec('Line',...
%                             {'ADMIN_TYPE',0,'Color','c'}, ...
%                             {'ADMIN_TYPE',3,'Color','r'},...
%                             {'CLASS',6,'Visible','off'},...
%                             {'CLASS',[1 4],'LineWidth',2});
%   figure
%   roads = mapshape(shaperead('concord_roads.shp'));
%   mapvectorshow(roads,'SymbolSpec',roadspec,'DefaultColor','b', ...
%           'DefaultLineStyle','-.');
%
%   Example 5 
%   ---------
%   % Override a graphics property of the SymbolSpec.
%   roadspec = makesymbolspec('Line',...
%                             {'ADMIN_TYPE',0,'Color','c'}, ...
%                             {'ADMIN_TYPE',3,'Color','r'},...
%                             {'CLASS',6,'Visible','off'},...
%                             {'CLASS',[1 4],'LineWidth',2});
%   figure
%   roads = mapshape(shaperead('concord_roads.shp'));
%   mapvectorshow(roads,'SymbolSpec',roadspec,'Color','b');
%
%   Example 6 
%   ---------
%   % Display a pond with three large islands (feature 14 in the
%   % concord_hydro_area shapefile).  Note that islands are visible through 
%   % three "holes" in the pond polygon. 
%
%   pond = mapshape(shaperead('concord_hydro_area.shp', 'RecordNumbers', 14));
%   figure
%   hold on
%   mapvectorshow(pond, 'FaceColor', [0.3 0.5 1], 'EdgeColor', 'black')
%
%   See also MAPSTRUCTSHOW, MAPVECSHOW, MAPSHOW.

% Copyright 2012 The MathWorks, Inc.

% Validate S.
fcnName = 'mapshow';
validateattributes(S, {'geopoint', 'mappoint', 'geoshape','mapshape'}, ...
   {}, fcnName, 'S')

% Obtain the Geometry value.
geometry = S.Geometry;

% Parse the properties from varargin.
[symspec, defaultProps, otherProps] = parseShowParameters( ...
    geometry, fcnName, varargin);

if any(strcmp(class(S), {'mappoint','mapshape'}) ) 
   % Switch display type based on geometry.
   fcn = mapstructfcn(geometry, 'mapshow');

   % Via symbolizeMapVectors call the appropriate display function:
   % mappointshow, line, or mappolygon.
   % The third argument passed to symbolizeMapVectors is an
   % anonymous function with the prerequisite signature:
   %    plotfcn(s, prop1, val1, pro2, val2, ...)
   % where s is a scalar geostruct, prop1, prop2, ... are graphics
   % property names, and val1, val2, are the corresponding property values.
   % The anonymous function uses the fcn variables from this workspace.
   h = symbolizeMapVectors( ...
      S, symspec, @(s, varargin) fcn(s.X, s.Y, varargin{:}), ...
      defaultProps, otherProps);
else
   % Display the geographic coordinates using geovectorshow.
   fcnName = upper(fcnName);
   warning(message('map:mapshow:usingGEOSHOW', fcnName, fcnName, 'GEOSHOW'))
   h = geovectorshow(S, varargin{:});   
end

% Allow usage without ; to suppress output.
if nargout > 0
   varargout{1} = h;
end
