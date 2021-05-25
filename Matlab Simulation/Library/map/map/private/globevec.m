function h = globevec(mstruct, lat, lon, ~, objectType, varargin)
%GLOBEVEC Display point, multipoint, line, or polygon on globe
%
%   h = globevec(mstruct, lat, lon, height, objectType, Name, Value)
%   displays a point, multipoint, line, or polygon on a globe, and returns
%   a line or patch handle.
%
%   Inputs
%   ------
%   LAT and LON are NaN-delimited vertex arrays.
%
%   The HEIGHT input is currently ignored.
%
%   objectType is one of the following strings:
%       'geopoint', 'geomultipoint', 'geoline', or 'geopolygon'.
%
%   Name, Value indicates optional name-value pairs corresponding to
%      graphics properties of line ('geopoint', 'geomultipoint' or
%      'geoline' objectTypes) or patch ('geopolygon' objectType).
%
%   Defaults
%   --------
%   For 'geopoint' and 'geomultipoint' objects, red '+' markers are
%   displayed by default.
%
%   For 'geoline' objects, blue lines are displayed by default.
%
%   For 'geopolygon objects', patches with black edges and light yellow
%   fill are displayed by default.

% Copyright 2009-2019 The MathWorks, Inc.

% Verify NaN locations are equal.
assert(isequal(isnan(lat), isnan(lon)), ...
    'map:globevec:inconsistentLatLon', ...
    '%s and %s mismatch in size or NaN locations.','LAT','LON')

spheroid = map.internal.mstruct2spheroid(mstruct);
[lat, lon] = toDegrees(mstruct.angleunits, lat, lon);
height = 0;

if ~isempty(lat) || ~isempty(lon)
    switch(objectType)
        case {'geopoint','geomultipoint'}
            % Construct a line but show only the markers.
            [x, y, z] = geodetic2ecef(spheroid, lat, lon, height);
            h = line(x, y, z, 'Marker', '+', ...
                'MarkerEdgeColor', 'red', varargin{:}, 'LineStyle', 'none');
            
        case 'geoline'
            % Construct a line with a default color of 'blue'.
            [x, y, z] = geodetic2ecef(spheroid, lat, lon, height);
            h = line(x, y, z, 'Color', 'blue', varargin{:});
            
        case 'geopolygon'
            h = map.graphics.internal.globepolygon( ...
                spheroid, lat, lon, height, varargin{:});
    end
else
    % Either xdata or ydata are empty.
    h = reshape([],[0 1]);
end
