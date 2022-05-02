function properties = attributes2properties(symspec, S)
%attributes2properties Rule-based graphic properties for vector features
%
%   PROPERTIES = attributes2properties(SYMSPEC, S) applies the
%   symbolization rules in SYMSPEC to the attribute values in S. S may be
%   either a dynamic vector or a geographic data structure array.  SYMSPEC
%   is a symbol specification structure returned by MAKESYMBOLSPEC. The
%   return value, PROPERTIES, is a structure that can be passed to the
%   function EXTRACTPROPS, such that
%
%        props = extractprops(properties,k)
%
%   returns a cell array containing pairs of graphics property names and
%   values for the k-th elements of S.
%
%   Note
%   ----
%   If a rule is applied to a numeric-valued attribute that has a value
%   of NaN, then the resulting property value will the default, if one
%   exists in the symbolspec, or else will remain unassigned.
%
%   Example
%   -------
%   symspec = makesymbolspec('Line',...
%       {'CLASS',2,'Color','r','LineWidth',3},...
%       {'CLASS',3,'LineWidth',2},...
%       {'CLASS',6,'Color',[0 0 1],'LineStyle','-.'},...
%       {'Default','Color','k'},...
%       {'CLASS',5,'Color','g'},...
%       {'STREETNAME','FULKERSON STREET','Color','magenta'});
%   S = shaperead('boston_roads');
%   properties = attributes2properties(symspec, S);
%   figure
%   for k = 1:length(S)
%       props = extractprops(properties,k);
%       line(S(k).X, S(k).Y, props{:})
%   end
%   axis equal
%
%   See also EXTRACTPROPS, MAKESYMBOLSPEC.

% Copyright 2006-2012 The MathWorks, Inc.

% Internal definition of the PROPERTIES structure:
%
%   A scalar structure with fields 'Names' and 'Values'.  Let M be the
%   number of features (elements) in S and N be the number of graphics
%   properties controlled by SYMSPEC.  The 'Names' field of PROPERTIES
%   contains a 1-by-N cell array of strings, with one element for each
%   graphics property controlled by SYMSPEC. The 'Values' field contains an
%   M-by-N cell array of graphics property values, with one row per feature
%   in S and one column per graphic property.  If the j-th property of the
%   k-th element of S is not specified by SYMSPEC, then
%   properties.Values(k,j) contains [].

% Check geometry fields for consistency and validity
if ~isobject(S)
   geometry = checkGeostructGeometry(S);
else
    % S is an object. Convert lower case Geometry value to expected case.
    geometry = validatestring(S.Geometry, {'Point','Line','Polygon'});
end
checkGeometryStringMatch(geometry, symspec.ShapeType)

% Convert symbol spec to a more useful form based on MATLAB structures.
symspec = restructureSymbolSpec(symspec);

% Every attribute in symspec must be present in S, except for 'INDEX'.
missingAttributes = setdiff({symspec.Attributes.Name}, fieldnames(S));
if ~isempty(missingAttributes) && ~isequal(missingAttributes,{'INDEX'})
    error('map:attributes2properties:missingAttributes', ...
        'SYMSPEC specifies attributes that are missing from input.')
end

% For each attribute used in the symbol spec, put all the corresponding
% values from S into either a 1-by-N cell vector (for character-valued)
% attributes) or a 1-by-N numeric vector (for numeric-value attributes),
% where N is the number of elements in S.  Make each attribute vector a
% field in a scalar structure (attributeValues) and use the attributeName
% for the corresponding field name.  
for m = 1:numel(symspec.Attributes)
    attributeName = symspec.Attributes(m).Name;
    if strcmp(attributeName,'INDEX')
        % Construct an index array -- a special, "implicit" attribute
        attributeValues.INDEX = 1:numel(S);
    else
        % Build an array of attribute values
        if isobject(S)
            % dynamic vector object.
            value = S.(attributeName);       
        elseif strcmp(symspec.Attributes(m).Class,'char')
            % String-valued attributes
             value = getStringValues(S, attributeName);
        else
            % Numeric scalar-valued attributes
            value = getNumericValues(S, attributeName);
        end
        attributeValues.(attributeName) = value;
    end
end

% Initialize the properties (output) structure using the property names and
% default values from the symbol spec.
properties.Names  = {symspec.Properties.Name};
properties.Values = cell(length(S), numel(properties.Names));
for k = 1:numel(symspec.Properties)
    properties.Values(:,k) = symspec.Properties(k).Default;
end

% Iterate over each property, applying each of its rules in the order
% given to override the defaults in the properties.Values cell array.
for k = 1:numel(symspec.Properties)
    for j = 1:numel(symspec.Properties(k).Rules)
        rule = symspec.Properties(k).Rules(j);
        [index, propertyValues] ...
            = rule.Map(attributeValues.(rule.AttributeName));
        properties.Values(index,k) = propertyValues;
    end
end

%-----------------------------------------------------------------------

function geometry = checkGeostructGeometry(S)
% Check geostruct/mapstruct 'Geometry' fields for consistency and validity

% See also SHAPEWRITE.

% Make sure there's a geometry field
if ~isfield(S, 'Geometry')
    error('map:attributes2properties:noGeometry', ...
        'Geographic data structure S must have a ''Geometry'' field.')
end

% Make sure that, for all features, the Geometry field contains a string
geometryArray = {S.Geometry};
if any(~cellfun(@ischar,geometryArray))
    error('map:attributes2properties:nonStrGeometry', ...
        'An element of geographic data structure S has a non-string ''Geometry'' field.')
end

% Make sure the geometry of the first feature has a valid value
geometry = S(1).Geometry;
validGeometries = {'Point', 'MultiPoint', 'Line', 'Polygon'};
if ~any(strcmp(geometry,validGeometries))
    error('map:attributes2properties:invalidGeometryString', ...
        'The ''Geometry'' field of geographic data structure S must contain one of the following strings: %s, %s, %s, %s.',...
        validGeometries{:})
end

% Make sure that all the geometry strings match the first one
if any(~strcmp(geometryArray,geometry))
    error('map:attributes2properties:inconsistentGeometry', ...
        'All features in geographic data structure S must have the same geometry.')
end

%-----------------------------------------------------------------------

function checkGeometryStringMatch(geometry, shapeType)

pointMatch = strcmp(shapeType,'Point') ...
    && ismember(geometry,{'Point','MultiPoint'});

lineMatch = ismember(shapeType,{'Line','PolyLine'}) ...
    && strcmp(geometry,'Line');

polygonMatch = ismember(shapeType,{'Polygon','Patch'}) ...
    && strcmp(geometry,'Polygon');

if ~(pointMatch || lineMatch || polygonMatch)
    error('map:attributes2properties:mismatchedGeometry', ...
        'Geometry value %s is inconsistent with SymbolSpec geometry %s.', ...
        geometry, shapeType);
end

%-----------------------------------------------------------------------

function v = getNumericValues(S, attributeName)

% See also MAKEDBFSPEC.

try
    v = [S.(attributeName)];
catch exception
    % Issue our own error, unless MATLAB has run out of memory.
    if strcmp(exception.identifier,'MATLAB:nomem')
        rethrow(exception)
    else
        error('map:attributes2properties:inconsistentAttributeData', ...
            'Inconsistent data in attribute field: %s.', attributeName)
    end
end

if ~isa(v,'double')
    error('map:attributes2properties:nondoubleNumericAttribute', ...
        'Attribute field %s of geographic data structure S contains at least one non-double value.', ...
        attributeName)

end

if numel(v) ~= numel(S)
    error('map:attributes2properties:nonscalarAttributeValue', ...
        'Attribute field %s of geographic data structure S contains at least one value that is not a scalar double.', ...
        attributeName)
end

if any(isinf(v)) || any(~isreal(v))
    error('map:attributes2properties:attributeNotFiniteReal', ...
        'Numerical attributes of geographic data structure S must be finite and real.')
end

%-----------------------------------------------------------------------

function v = getStringValues(S, attributeName)

% See also MAKEDBFSPEC.

v = {S.(attributeName)};
if any(~cellfun(@ischar,v))
    error('map:attributes2properties:inconsistentCharacterClass',...
        'Attribute field %s of geographic data structure S contains at least one value that is not a character string.',...
        attributeName)
end
