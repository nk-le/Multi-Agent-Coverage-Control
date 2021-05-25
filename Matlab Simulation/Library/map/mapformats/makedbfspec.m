function dbfspec = makedbfspec(S)
%MAKEDBFSPEC DBF specification structure
%  
%   DBFSPEC = MAKEDBFSPEC(S) analyzes S and constructs a DBF specification
%   suitable for use with SHAPEWRITE.  S is either a geopoint vector, a
%   geoshape vector, or a geostruct (with 'Lat' and 'Lon' coordinate
%   fields) or a mappoint vector, mapshape vector, or a mapstruct (with 'X'
%   and 'Y fields).  You can modify DBFSPEC, then pass it to SHAPEWRITE to
%   exert control over which attribute fields are written to the DBF
%   component of the shapefile, the field-widths, and the precision used
%   for numerical values.
%
%   DBFSPEC is a scalar MATLAB structure with two levels.  The top level
%   consists of a field for each attribute in S.  Each of these fields,
%   in turn, contains a scalar structure with a fixed set of four fields:
%
%   FieldName          The field name to be used within the DBF file.  This
%                      will be identical to the name of the corresponding
%                      attribute, but may modified prior to calling
%                      SHAPEWRITE.  This might be necessary, for example,
%                      because you want to use spaces your DBF field names,
%                      but the attribute fieldnames in S must be valid
%                      MATLAB variable names and cannot have spaces
%                      themselves.
%
%   FieldType          The field type to be used in the file, either 'N'
%                      (numeric) or 'C' (character).
%
%   FieldLength        The number of bytes that each instance of the field
%                      will occupy in the file.
%
%   FieldDecimalCount  The number of digits to the right of the decimal
%                      place that are kept in a numeric field. Zero for
%                      integer-valued fields and character fields. The
%                      default value for non-integer numeric fields is 6.
%
%   Example
%   -------
%   % Import a shapefile representing a small network of road segments,
%   % and construct a DBF specification.
%   s = shaperead('concord_roads')
%   dbfspec = makedbfspec(s)
%
%   % Modify the DBF spec to (a) eliminate the 'ADMIN_TYPE' attribute, (b)
%   % rename the 'STREETNAME' field to 'Street Name', and (c) reduce the
%   % number of decimal places used to store road lengths.
%   dbfspec = rmfield(dbfspec,'ADMIN_TYPE')
%   dbfspec.STREETNAME.FieldName = 'Street Name';
%   dbfspec.LENGTH.FieldDecimalCount = 1;
%
%   % Export the road network back to a modified shapefile.  (Actually,
%   % only the DBF component will be different.)
%   shapewrite(s, 'concord_roads_modified', 'DbfSpec', dbfspec)
%
%   % Verify the changes you made.  Notice the appearance of
%   % 'Street Name' in the field names reported by SHAPEINFO, the absence
%   %  of the 'ADMIN_TYPE' field, and the reduction in the precision of the
%   %  road lengths.
%   info = shapeinfo('concord_roads_modified')
%   {info.Attributes.Name}
%   r = shaperead('concord_roads_modified')
%   s(33).LENGTH
%   r(33).LENGTH
%
%   See also: SHAPEINFO, SHAPEWRITE.

% Copyright 2003-2018 The MathWorks, Inc.  

% Validate input.
types = {'struct','mappoint','geopoint','mapshape','geoshape'};
validateattributes(S, types, {'nonempty', 'vector'}, 'makedbfspec', 'S', 1)

if isstruct(S)
    S = convertContainedStringsToChars(S);
    S = validateGeographicDataStructure(S);
    attributeNames = fields(S);
    nonAttributeNames = {'Geometry', 'BoundingBox', 'X', 'Y', 'Lat', 'Lon'};
    dbfspecForSingleAttribute = @dbfspecForStructAttribute;
else
    attributeNames = fieldnames(S);
    nonAttributeNames = {...
        'Geometry', 'Metadata', 'X', 'Y', 'Latitude', 'Longitude'};
    dbfspecForSingleAttribute = @dbfspecForDynamicVectorAttribute;
end

[~,fIndex] = setxor(attributeNames, nonAttributeNames);
attributeNames = attributeNames(sort(fIndex));

% In this version we support only types 'N' and 'C'.
for k = 1:numel(attributeNames)
    spec = dbfspecForSingleAttribute(S, attributeNames{k});
    if ~isempty(spec)
        dbfspec.(attributeNames{k}) = spec;
    end
end

if ~exist('dbfspec','var')
    % Return a 0x0 struct with no fields in these cases:
    %    (1) a geostruct or mapstruct without an attributes and
    %    (2) a geostruct or mapstruct in which every attribute contains
    %        an unsupported data class.
    dbfspec = struct([]);
end

%--------------------------------------------------------------------------

function s = dbfspecForStructAttribute(S, attributeName)

dataClass = class(S(1).(attributeName));
switch(dataClass)    
    case 'double'
        s.FieldName = attributeName;
        s.FieldType = 'N';
        v = [S.(attributeName)];
        [s.FieldLength, s.FieldDecimalCount] = numericalFieldLayout(v);
       
    case 'char'
        s.FieldName = attributeName;
        s.FieldType = 'C';
        
        values = {S.(attributeName)};
        
        maxFieldLength = calculateMaxFieldLength(values, attributeName);
        minCharFieldLength = 2;
        s.FieldLength = max(maxFieldLength, minCharFieldLength);
        s.FieldDecimalCount = 0;
        
    otherwise
        warning(message('map:validate:unsupportedDataClass', dataClass));
        s = [];
end

%--------------------------------------------------------------------------

function s = dbfspecForDynamicVectorAttribute(S, attributeName)

v = S.(attributeName);

% Typically v is a cell array. However, if S is a dynamic vector with
% only one feature and the attribute value is a string, then v is a
% string. In this case, convert v to a cell array for proper processing
% by calculateMaxFieldLength.
if ischar(v)
    v = {v};
end
dataClass = class(v);

% Determine if attributeName is a dynamic vertex property.
if length(v) ~= length(S)
    % Issue a warning for the dynamic vertex property, attributeName.
    % Do not add it to the output structure.
    warning(message('map:validate:ignoringAttribute', attributeName))
    s = [];
    return
end

switch(dataClass)
    case 'double'
        s.FieldName = attributeName;
        s.FieldType = 'N';
        
        % Attributes must be real and finite.
        map.internal.assert(all(~isinf(v) & isreal(v)), ...
            'map:validate:attributeNotFiniteReal', attributeName)
        
        [s.FieldLength, s.FieldDecimalCount] = numericalFieldLayout(v);
        
    case 'cell'
        s.FieldName = attributeName;
        s.FieldType = 'C';
        
        maxFieldLength = calculateMaxFieldLength(v);
        minCharFieldLength = 2;
        
        s.FieldLength = max(maxFieldLength, minCharFieldLength);
        s.FieldDecimalCount = 0;
        
    otherwise
        warning(message('map:validate:unsupportedDataClass', dataClass));
        s = [];
end

%--------------------------------------------------------------------------

function [fieldLength, numRightOfDecimal] = numericalFieldLayout(v)

% Default to six digits to the right of the decimal point.
defaultDecimalPrecision = 6;

if all(v == 0)
    numRightOfDecimal = 0;
    fieldLength = 2;
else
    numLeftOfDecimal = max(1, 1 + floor(log10(max(abs(v)))));
    if all(v == floor(v))
        numRightOfDecimal = 0;
        fieldLength = 1 + numLeftOfDecimal;
    else
        numRightOfDecimal = defaultDecimalPrecision;
        fieldLength = 1 + numLeftOfDecimal + 1 + numRightOfDecimal;
    end
end

minNumericalFieldLength = 3;  % Large enough to hold 'NaN'
fieldLength = max(fieldLength, minNumericalFieldLength);

%--------------------------------------------------------------------------

function maxFieldLength = calculateMaxFieldLength(values, attributeName)
% Calculate a safe upper bound on the number of bytes per field required to
% contain the characters in the cell array, VALUES.

% Convert cell to a char array. Dynamic vectors are validated to contain
% only string values in cell arrays.
if nargin < 2
    charValues = char(values);
else
    % Validate that the cell array, VALUES, contains only char characters.
    try
        charValues = char(values);
    catch exception
        % Issue our own error.
        if strcmp(exception.identifier,'MATLAB:character:CellsMustContainChars')
            error(message('map:geostruct:attributeMustContainChars', attributeName, 'S'))
        else
            rethrow(exception)
        end
    end
end

% Determine a safe upper bound for the number of bytes per field required
% to contain the number of characters. For efficiency, use charValues to
% determine if the input, VALUES, is a cell array containing all ASCII
% characters. 
if isASCII(charValues)
    % charValues contains all ASCII characters. A safe upper bound is the
    % size of the rows.
    maxFieldLength = size(charValues, 2);
else
    % The array contains non-ASCII unicode characters. Calculate
    % maxFieldLength as the maximum number of bytes required to hold any
    % element in VALUES. For each element of the cell array, convert the
    % element to native representation and count the resultant number of
    % bytes. Set maxFieldLength as the maximum number of bytes of any
    % element in the cell array.
    numNativeBytesFcn = @(x)numel(unicode2native(x));
    numelCell = cellfun(numNativeBytesFcn, values, 'UniformOutput', false);
    maxFieldLength = max(cell2mat(numelCell));
end

%--------------------------------------------------------------------------

function tf = isASCII(c)
% Return true if the character array, C, contains all ASCII characters.

tf = all(c < 128);

%--------------------------------------------------------------------------

function [S, isMap] = validateGeographicDataStructure(S)
% Validate a geostruct or mapstruct
%
%   Input
%   -----
%   S -- Geographic or map structure array (geostruct or mapstruct)
%
%   Output
%   ------
%   S -- Version of S with consistent values in its Geometry field from
%       which attributes with unsupported types (neither double nor char)
%       have been removed.
%
%   isMap -- True if S is a mapstruct, false if S is a geostruct.

% The following three functions are identical, or nearly identical, to
% subfunctions in map.internal.struct2DynamicVector:
S = validateGeometry(S);
S = validateAttributes(S);
isMap = validateCoordinates(S);

%--------------------------------------------------------------------------

function S = validateGeometry(S)
% Validate Geometry field of S.

% Make sure there's a geometry field.
map.internal.assert(isfield(S, 'Geometry'), 'map:geostruct:expectedGeometryField');

% Make sure the Geometry field of the first feature is a string and has a
% valid value. Ignore case in the validation but make sure on return that
% all Geometry entries are MixedCase.
validGeometries =  {'Point', 'MultiPoint', 'Line', 'PolyLine', 'Polygon'};
geometryIndex = strcmpi(S(1).Geometry, validGeometries);
if ~any(geometryIndex)
    error(message('map:geostruct:invalidGeometryString'))
else
    geometry = validGeometries{geometryIndex};
    if strcmp(geometry, 'PolyLine')
        geometry = 'Line';
    end
end

% Make sure all the Geometry values are strings and expect only one unique
% value.
geometries = {S.Geometry};
map.internal.assert(iscellstr(geometries) && isscalar(unique(geometries)), ...
    'map:geostruct:inconsistentGeometry');

% Make sure all Geometry values are MixedCase.
[S.Geometry] = deal(geometry);

%--------------------------------------------------------------------------

function [S, vertexProperties] = validateAttributes(S)
% Validate attributes of S.

% Determine what types of fields to write for each attribute.
attributeNames = fieldnames(S);
nonAttributeNames = {'Geometry', 'BoundingBox', 'X', 'Y', 'Lat', 'Lon'};
[~,fIndex] = setxor(attributeNames, nonAttributeNames);
attributeNames = attributeNames(sort(fIndex));

% Cell array containing valid vertex properties.
vertexProperties = {};

% Validate each attribute.
for k = 1:numel(attributeNames)
    attributeName = attributeNames{k};
    v = {S.(attributeName)};
    
    % Validate class type.
    classType = validateClassType(v, attributeName);
    
    % Validate values.
    value = v{1};    
    if isnumeric(value)       
        % Validate dimensions.
        try
            v = [S.(attributeName)];
        catch exception
            % Issue our own error, unless MATLAB has run out of memory.
            if strcmp(exception.identifier,'MATLAB:nomem')
                rethrow(exception)
            else
                error(message('map:validate:inconsistentAttributeData', attributeName))
            end
        end
        
        % Validate vertex properties.
        if numel(v) ~= length(S)
            error(message('map:validate:attributeNotScalar', attributeName))
        end

        % Validate values.
        map.internal.assert(all(~isinf(v) & isreal(v)), ...
            'map:validate:attributeNotFiniteReal', attributeName)
        
    elseif ischar(value)
        % Validate that the field contains only strings.
        if ~all(cellfun(@(x) ischar(x) && (isrow(x) || isempty(x)), v))
            error(message('map:geostruct:attributeMustContainChars', attributeName, 'S'))
        end
    else
        % Remove fields containing unsupported class types.
        warning(message('map:validate:unsupportedDataClass', classType));
        S = rmfield(S, attributeName);
    end
end

%--------------------------------------------------------------------------

function classType = validateClassType(v, attributeName)
% Validate class type of values in cell array, v, and return a string
% denoting the class type of the values. attributeName is a string denoting
% a field name and is used in constructing an error message.

classType = unique(cellfun(@class, v, 'UniformOutput', false));
if ~isscalar(classType)
    % Non-uniform class type in input cell array. Issue an error.
    if any(strcmp('char', classType))
        error(message('map:geostruct:attributeMustContainChars', attributeName, 'S'))
    elseif any(strcmp('double', classType))
        error(message('map:geostruct:nonDoubleNumericAttribute', attributeName))
    else
        error(message('map:validate:inconsistentAttributeData', attributeName))
    end
end

% classType is a scalar cell array. Return the first element.
classType = classType{1};

%--------------------------------------------------------------------------

function isMap = validateCoordinates(S)
% Validate coordinates fields of S. Return true if S is a mapstruct and
% false if S is a geostruct.

% Check the coordinate field names.
hasXY     = (isfield(S,'X')   && isfield(S,'Y'));
hasLatLon = (isfield(S,'Lon') && isfield(S,'Lat'));
map.internal.assert(hasXY || hasLatLon, 'map:geostruct:missingCoordinateFields')

if (hasXY && hasLatLon)...
        || (hasXY     && (isfield(S,'Lat') || isfield(S,'Lon')))...
        || (hasLatLon && (isfield(S,'X')   || isfield(S,'Y')))
    error(message('map:geostruct:redundantCoordinateFields'))
end

% Check the coordinate values on a per-feature basis.
if hasXY
    cfield1 = 'X';
    cfield2 = 'Y';
else
    cfield1 = 'Lon';
    cfield2 = 'Lat';
end

isPointGeometry = strcmp(S(1).Geometry, 'Point');
for k = 1:length(S)
    % Obtain coordinates.
    c1 = S(k).(cfield1);
    c2 = S(k).(cfield2);
    
    % Shape does not matter.
    c1 = c1(:)';
    c2 = c2(:)';
    
    % Make sure they're doubles.
    map.internal.assert(isa(c1,'double') && isa(c2,'double'), ...
        'map:geostruct:nonDoubleCoordinate')
    
    % Make sure they match in length.
    map.internal.assert(isequal(size(c1),size(c2)), ...
        'map:geostruct:coordinateSizeMismatch')
    
    % Make sure they have matching NaNs, in any.
    map.internal.assert(isequal(isnan(c1),isnan(c2)), ...
        'map:geostruct:coordinateNanMismatch')
    
    % Make sure they're real and finite.
    if ~all(isreal(c1)) || ~all(isreal(c2))...
            || ~all(isfinite(c1(~isnan(c1))))...
            || ~all(isfinite(c2(~isnan(c2))))
        error(message('map:geostruct:coordinateNanMismatch'))
    end
    
    % For 'Point' geometry only, make sure all coordinate values are scalar
    if isPointGeometry
        map.internal.assert(isscalar(c1) && isscalar(c2), 'map:geostruct:nonScalarPoint');
    end
end

isMap = hasXY;
