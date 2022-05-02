function S = checkgeostruct(S, argument_position, function_name)
%CHECKGEOSTRUCT Check geostruct for validity
%
%   CHECKGEOSTRUCT(S, ARGUMENT_POSITION, FUNCTION_NAME) checks the
%   validity of the geostruct S and issues a formatted error message if
%   it is invalid.  If S is a display structure, then it is converted to
%   a geostruct.
%
%   ARGUMENT_POSITION is a positive integer indicating which input argument
%   is being checked; it is also used in the formatted error message.
%
%   FUNCTION_NAME is a string containing the function name to be used in
%   the formatted error message.

% Copyright 2007-2011 The MathWorks, Inc.

% Verify the input is a non-empty structure.
validateattributes(S, {'struct'}, {'vector','nonempty'}, ...
    function_name, 'S', argument_position);

% Support version1 geostruct.
if isfield(S,'lat') && isfield(S,'long')
   S = updategeostruct(S);
end

% Verify the geometry of the geostruct.
verifyGeometry(S, function_name);

% Verify the geostruct coordinate field names.
assert(isfield(S,'Lat') && isfield(S,'Lon'), ...
    ['map:' function_name ':needLatLon'], ...
    'Function %s expected a geostruct with ''Lat'' and ''Lon'' fields.', ...
    upper(function_name));

%--------------------------------------------------------------------------

function verifyGeometry(S, function_name)
% Verify and validate the Geometry field of the geostruct S.

% Setup an anonymous function for use with constructing error IDs and
% message.
eid = @(x) sprintf('map:%s:%s',function_name, x);
function_name = upper(function_name);

% Verify Geometry field exists.
assert(isfield(S,'Geometry'), ...
    eid('noGeometry'), ...
    'Function %s expected a geostruct with a ''Geometry'' field.', ...
    function_name);

% Verify Geometry contains string values.
geometry = extractfield(S,'Geometry');
assert(iscell(geometry), ...
    eid('nonStrGeometry1'), ...
    'Function %s expected a geostruct where the ''Geometry'' field contains a string for all elements.', ...
    function_name)
  
assert(all(cellfun(@ischar, geometry)), ...
    eid('nonStrGeometry2'), ...
     'Function %s expected a geostruct where the ''Geometry'' field contains a string for all elements.', ...
     function_name);

% Verify Geometry contains uniform values.
geometry = unique(lower(geometry));
assert(numel(geometry)==1, ...
    eid('inconsistentGeometry'), ...
    'Function %s expected a geostruct with uniform geometry.', ...
    function_name);
