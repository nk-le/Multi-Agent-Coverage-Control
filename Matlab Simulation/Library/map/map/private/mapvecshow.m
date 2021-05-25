function varargout = mapvecshow(x, y, varargin)
%MAPVECSHOW Display x-y map vectors with given geometry
%
%   MAPVECSHOW(X,Y) or 
%   MAPVECSHOW(X,Y, ..., 'DisplayType', DISPLAYTYPE, ...) displays the
%   equal length coordinate vectors, X and Y.  X and Y may contain embedded
%   NaNs, delimiting coordinates of points, lines or polygons. DISPLAYTYPE
%   can be 'point', 'multipoint', 'line', or 'polygon' and defaults to
%   'line'.
%
%   MAPVECSHOW(..., Name, Value) specifies name-value pairs that set MATLAB
%   graphics properties. Property names can be abbreviated and are
%   case-insensitive.
%
%   H = MAPVECSHOW(...) returns a handle to a MATLAB graphics object.
%
%   Example 
%   -------
%   % Display the Boston roads as black lines.
%   roads = shaperead('boston_roads.shp');
%   figure
%   mapvecshow([roads.X], [roads.Y], 'Color', 'black');
%
%   See also GEOVECSHOW, MAPSHOW, MAPSTRUCTSHOW.

% Copyright 2006-2015 The MathWorks, Inc.

% Verify the coordinate arrays.
checkxy(x, y, 'MAPSHOW', 'X', 'Y', 1, 2);

internal.map.checkNameValuePairs(varargin{:})

% Find the geometry.
% Delete 'DisplayType' parameter/value pair from varargin (if present).
% If DisplayType is not set, then draw a line.
default = 'line';
[geometry, varargin] = ...
   map.internal.findNameValuePair('DisplayType', default, varargin{:});

% Split HG property value pairs into two groups, depending on whether or
% not a (case-insensitive) prefix of 'Default' is included in the
% property name.
[defaultProps, otherProps] = separateDefaults(varargin);
   
% Determine the display function based on the geometry.
fcn = mapvecfcn(geometry, 'mapshow');

% Display the x, y vectors.
h = fcn(x, y, defaultProps{:}, otherProps{:});

%  Restack to ensure standard child order in the map axes.
map.graphics.internal.restackMapAxes(h)

% Allow usage without ; to suppress output.
if nargout > 0
   varargout{1} = h;
end
