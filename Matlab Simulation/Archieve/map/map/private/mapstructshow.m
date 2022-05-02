function varargout = mapstructshow(S, varargin)
%MAPSTRUCTSHOW Display map vector data without projection
%
%   MAPSTRUCTSHOW(S) displays the vector geographic features stored in the
%   map data structure S as points, lines, or polygons according to the 
%   Geometry field of the mapstruct. If S includes X and Y fields, then
%   they are used directly to plot features in map coordinates. If Lat and
%   Lon fields are present instead, the coordinates will be projected using
%   the Plate Carree projection.
%
%   MAPSTRUCTSHOW(..., PARAM1, VAL1, PARAM2, VAL2, ...) specifies
%   parameter/value pairs that modify the type of display or set MATLAB
%   graphics properties. Parameter names can be abbreviated and are
%   case-insensitive.
%
%   Parameters include:
%
%   'DisplayType'  The DisplayType parameter specifies the type of graphic
%                  display for the data.  The value must be consistent with
%                  the type of data in the mapstruct as shown in the
%                  following table:
%
%                  Data type    Value
%                  ---------    -----
%                  vector       'point', 'multipoint', 'line', or 'polygon'
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
%   SymbolSpec     In  the case where both SymbolSpec and one or more
%   Override       graphics properties are specified, the graphics
%                  properties last specified will override any settings in 
%                  the symbol spec structure. See example 5 below.
%
%   H = MAPSTRUCTSHOW(...) returns the handle to an hggroup object with one
%   child per feature in the geostruct.  In the case of a polygon
%   geostruct, each child is a modified patch object;  otherwise it is a
%   line object.
%
%   Example 1 
%   ---------
%   % Display the roads geographic data structure.
%   roads = shaperead('boston_roads.shp');
%   figure
%   mapstructshow(roads);
%  
%   Example 2
%   ---------
%   % Display the roads shape and change the LineStyle.
%   roads = shaperead('boston_roads.shp');
%   figure
%   mapstructshow(roads,'LineStyle',':');
%
%   Example 3 
%   ---------
%   % Display the roads shape, and render using a SymbolSpec.
%   roads = shaperead('boston_roads.shp');
%   roadspec = makesymbolspec('Line',...
%                             {'ADMIN_TYPE',0,'Color','c'}, ...
%                             {'ADMIN_TYPE',3,'Color','r'},...
%                             {'CLASS',6,'Visible','off'},...
%                             {'CLASS',[1 4],'LineWidth',2});
%   figure
%   mapstructshow(roads,'SymbolSpec',roadspec);
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
%   roads = shaperead('concord_roads.shp');
%   mapstructshow(roads,'SymbolSpec',roadspec,'DefaultColor','b', ...
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
%   roads = shaperead('concord_roads.shp');
%   mapstructshow(roads,'SymbolSpec',roadspec,'Color','b');
%
%   Example 6 
%   ---------
%   % Display a pond with three large islands (feature 14 in the
%   % concord_hydro_area shapefile).  Note that islands are visible through 
%   % three "holes" in the pond polygon. 
%
%   pond = shaperead('concord_hydro_area.shp', 'RecordNumbers', 14);
%   figure
%   hold on
%   mapstructshow(pond, 'FaceColor', [0.3 0.5 1], 'EdgeColor', 'black')
%
%   See also GEOSTRUCTSHOW, MAPVECSHOW, MAPSHOW.

% Copyright 2006-2012 The MathWorks, Inc.

% Convert line or patch display structure to geostruct.
[S, updateSymspec] = updategeostruct(S);

% Obtain the Geometry value.
geometry = S(1).Geometry;

% Set fcnName.
fcnName = 'mapshow';

% Parse the properties from varargin.
[symspec, defaultProps, otherProps] = parseShowParameters( ...
    geometry, fcnName, varargin);

% Determine if structure is a geostruct or mapstruct.
if isfield(S,'X') && isfield(S,'Y')
   % Switch display type based on geometry.
   fcn = mapstructfcn(geometry, 'mapshow');

   % Via symbolizeMapVectors call the appropriate display function:
   % mappointshow, line, or mappolygon.
   % The third argument passed to symbolizeMapVectors is an
   % anonymous function with the prequisite signature:
   %    plotfcn(s, prop1, val1, pro2, val2, ...)
   % where s is a scalar geostruct, prop1, prop2, ... are graphics
   % property names, and val1, val2, are the corresponding property values.
   % The anonymous function uses the fcn variables from this workspace.
   h = symbolizeMapVectors( ...
      S, symspec, @(s, varargin) fcn(s.X, s.Y, varargin{:}), ...
      defaultProps, otherProps);
else
   % Display the Lat and Lon coordinates using geostructshow.
   fcnName = upper(fcnName);
   warning(message('map:mapshow:usingGEOSHOW', fcnName, fcnName,'GEOSHOW'))
   
   % If symspec is empty and the updateSymspec is not empty then a V1
   % geostruct is present. In this case, use updateSymspec as the symspec.
   % This is needed only for geostructshow since V1 mapstructs do not exist.
   if isempty(symspec) && ~isempty(updateSymspec)
       h = geostructshow(S, 'SymbolSpec', updateSymspec, varargin{:});
   else
       h = geostructshow(S,  varargin{:});
   end  
end

% Allow usage without ; to suppress output.
if nargout > 0
   varargout{1} = h;
end
