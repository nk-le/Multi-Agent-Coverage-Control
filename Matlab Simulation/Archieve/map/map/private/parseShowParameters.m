function [symspec, defaultProps, otherProps] = parseShowParameters( ...
    geometry, fcnName, inputs)
%parseShowParameters Parse parameters for show functions
%
%   [SYMSPEC, defaultProps, otherProps] = parseShowParameters(GEOMETRY,
%   fcnName, INPUTS) parses the cell array, INPUTS, and returns a symbol
%   spec in SYMSPEC, and a cell array of 'Default' and other HG options in
%   the cell array defaultProps and otherProps. GEOMETRY is a string and is
%   either 'point', 'multipoint', 'line', or 'polygon'. fcnName is a string
%   denoting the calling function and is either 'geoshow' or 'mapshow'.
%
%   See also GEOSTRUCTSHOW, GEOVECTORSHOW, MAPSTRUCTSHOW, MAPVECTORSHOW.

% Copyright 2012-2015 The MathWorks, Inc.

internal.map.checkNameValuePairs(inputs{:})

% Find SymbolSpec and remove name-value pair from inputs (if present).
defaultSymspec = [];
[symspec, inputs] = ...
   map.internal.findNameValuePair('SymbolSpec', defaultSymspec, inputs{:});

% Verify the symspec.
if ~isempty(symspec) && ~map.graphics.internal.isValidSymbolSpec(symspec)
    error(message('map:validate:invalidSymbolSpec'))
end

% Split HG property value pairs into two groups, depending on whether or
% not a (case-insensitive) prefix of 'Default' is included in the
% property name.
[defaultProps, otherProps] = separateDefaults(inputs);

% Verify the DisplayType and remove name-value pair from inputs (if present).
[displayGeometry, otherProps] = map.internal.findNameValuePair( ...
    'DisplayType', geometry, otherProps{:});

% Verify geometry.
if ~strcmpi(displayGeometry,  geometry)
    id = ['map:' fcnName ':ignoringDisplayType'];
    fcnName = upper(fcnName);
    warning(message(id, fcnName, displayGeometry, geometry, fcnName))
end
