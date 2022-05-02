function h = geovec(mstruct, lat, lon, objectType, fcn, varargin)
%GEOVEC Trim, project, and display lat-lon points, lines, or polygons
%
%   Trims lat-lon features and projects them to map x-y by calling the
%   appropriate map projection function.  objectType should be one of the
%   following strings: 'geopoint', 'geomultipoint', 'geoline', or
%   'geopolygon' (case-insensitive).  FCN should be a handle to
%   MAPPOINT, MAPLINE, or MAPPOLYGON.  mstruct.mapprojection can be any
%   valid projection name other than 'globe'.

% Copyright 2006-2009 The MathWorks, Inc.

assert(~strcmpi(mstruct.mapprojection,'globe'), ...
    'map:geovec:globeNotSupported', ...
    'Attempted to use ''%s'' with function %s. Use %s instead.', ...
    'globe', 'geovec', 'globevec')

[x, y] = feval(mstruct.mapprojection, ...
    mstruct, lat, lon, objectType, 'forward');

h = fcn(x, y, varargin{:});
