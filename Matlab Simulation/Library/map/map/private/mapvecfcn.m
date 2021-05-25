function fcn = mapvecfcn(geometry, fcnname)
%MAPVECFCN Get map vector display function for given geometry
%
%   FCN = MAPVECVCN(GEOMETRY, FCNNAME) returns a function handle in FCN
%   based on the GEOMETRY string. Valid GEOMETRY strings are 'point',
%   'multipoint', 'line', or 'polygon'. If the geometry is not determined,
%   an error message is constructed using the name of the calling function,
%   FCNNAME.
%
%   See also MAPSHOW, MAPSTRUCTFCN, MAPSTRUCTSHOW, MAPVECSHOW.

% Copyright 2006-2012 The MathWorks, Inc.

switch (lower(geometry))

   case {'point', 'multipoint'}
      fcn = @mappointshow;

   case 'line'
      fcn = @mapline;

   case 'polygon'
      fcn = @map.graphics.internal.mappolygon;

   otherwise
      error(['map:' fcnname ':invalidGeometry'], ...
          'Function %s expected ''DisplayType'' to be ''Point'', ''MultiPoint'', ''Line'', or ''Polygon''; instead it was ''%s''.', ...
          upper(fcnname), geometry)

end
