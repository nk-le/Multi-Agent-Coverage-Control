function v = struct2DynamicVector(S)
%STRUCT2DYNAMICVECTOR Convert geostruct or mapstruct to dynamic vector
%
%   V = struct2DynamicVector(S) validates S to be either a mapstruct or
%   geostruct and converts S to a dynamic vector object based on the
%   Geometry value of S.

% Copyright 2012-2013 The MathWorks, Inc.

% Validate Geometry field of S.
S = validateGeometry(S);

% Validate attributes of S.
[S, vertexProperties] = validateAttributes(S);

% Validate coordinates of S. Return true if S is a mapstruct.
isMap = validateCoordinates(S);

% Convert S to either a geopoint, mappoint, geoshape, or mapshape vector.
v = convert2DynamicVector(S, isMap, vertexProperties);

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
            if ~any(strcmp(attributeName, {'Height', 'Elevation', 'Altitude'}))
                % Dynamic vertex properties are not permitted unless named:
                % 'Height', 'Elevation', or 'Altitude'.
                error(message('map:validate:attributeNotScalar', attributeName))
            else
                vertexProperties{end+1} = attributeName; %#ok<AGROW>
            end
        end

        % Validate values.
        map.internal.assert(all(~isinf(v) & isreal(v)), ...
            'map:validate:attributeNotFiniteReal', attributeName)
        
    elseif ischar(value)
        % Validate that the field contains only char characters.
        try
            char(v);
        catch exception
            % Issue our own error.
            if strcmp(exception.identifier,'MATLAB:character:CellsMustContainChars')
                error(message('map:geostruct:attributeMustContainChars', attributeName, 'S'))
            else
                rethrow(exception)
            end
        end
        fcn = @(x) (isvector(x) || isempty(x));
        if ~all(cellfun(fcn, v))
            % The attribute field is not a vector or empty. Issue an
            % appropriate error message using validateattributes.
            for n = 1:length(S)
                name = ['S('  num2str(n) ').' attributeName];
                validateattributes(S(n).(attributeName),  ...
                    {'char'}, {'vector'}, mfilename, name)
            end
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
% Validate coordinates fields of S.

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

% Return true if S is a mapstruct.
isMap = hasXY;

%--------------------------------------------------------------------------

function v = convert2DynamicVector(S, isMap, vertexProperties)
% Convert S to a dynamic vector object.

switch S(1).Geometry
    case 'Point'
        if isMap
            v = mappoint(S);
        else
            v = geopoint(S);
        end
        
    case 'MultiPoint'
        if isMap
            v = convert2DynamicShape(@mapshape, S, vertexProperties);
        else
            v = convert2DynamicShape(@geoshape, S, vertexProperties);
        end
        v.Geometry = 'point';
        
    case 'Line'
        if isMap
            v = convert2DynamicShape(@mapshape, S, vertexProperties);
        else
            v = convert2DynamicShape(@geoshape, S, vertexProperties);
        end
        % v.Geometry defaults to 'line'.
        
    case 'Polygon'
        if isMap
            v = convert2DynamicShape(@mapshape, S, vertexProperties);
        else
            v = convert2DynamicShape(@geoshape, S, vertexProperties);
        end
        v.Geometry = 'polygon';
end

%--------------------------------------------------------------------------

function v = convert2DynamicShape(dynamicShape, S, vertexProperties)
% Convert a structure array to a dynamicShape. Assign the names in
% vertexProperties as dynamic vertex properties.
            
if isempty(vertexProperties)
    v = dynamicShape(S);
else
    v = dynamicShape(rmfield(S, vertexProperties));
    for k = 1:numel(vertexProperties)
        for n = 1:length(S)
            name = vertexProperties{k};
            v(n).(name) = S(n).(name);
        end
    end
end
