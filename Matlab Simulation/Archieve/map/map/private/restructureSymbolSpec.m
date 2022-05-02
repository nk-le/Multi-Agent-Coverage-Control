function newspec = restructureSymbolSpec(symspec)
%RESTRUCTURESYMBOLSPEC  New representation of vector symbolization rules
%
%   newspec = restructureSymbolSpec(symspec) converts a vector
%   symbolization specification from the form returned by MAKESYMBOLSPEC
%   to a more structured form for use in function attributes2properties.

% Copyright 2006-2017 The MathWorks, Inc.

newspec.Geometry = symspec.ShapeType;
propertyNames = fields(symspec);
propertyNames(1) = [];  % Remove 'ShapeType' field (not a property name)
for k = 1:numel(propertyNames)
    % -- Name of the k-th property --
    newspec.Properties(k).Name  = propertyNames{k};

    % -- Default value (if any) for the k-th property --
    % Initialize to empty (serves as a null value)
    newspec.Properties(k).Default = {[]};

    % Extract the cell array of rules corresponding to the k-th property
    rulesCellArray = symspec.(propertyNames{k});

    % Look for rows in the rules cell array that start with 'Default'.
    % If one or more is found, use the value from the last one as the
    % default value for the k-th property.
    attributeNames = rulesCellArray(:,1);
    pDefault = find(strncmpi(attributeNames,'Default',numel('Default')));
    if ~isempty(pDefault)
        newspec.Properties(k).Default = rulesCellArray(pDefault(end),end);
    end

    % -- Rules (if any) for the k-th property --
    % Initialize to empty (serves as a null value in case there are no rules)
    newspec.Properties(k).Rules = [];

    % Remove all rows beginning with 'Default' from the rules cell array
    rulesCellArray(pDefault,:) = [];
    % Create a rule struct for row that remains.
    for j = 1:size(rulesCellArray,1)
        newspec.Properties(k).Rules(j).AttributeName ...
            = rulesCellArray{j,1};
        newspec.Properties(k).Rules(j).AttributeClass ...
            = class(rulesCellArray{j,2});
        newspec.Properties(k).Rules(j).Map ...
            = setupAttributeToPropertiesMap(...
                rulesCellArray{j,2}, rulesCellArray{j,3});
    end
end

% Build lists of attribute names and classes
attributeNames   = {};
attributeClasses = {};
for k = 1:numel(newspec.Properties)
    for j = 1:numel(newspec.Properties(k).Rules)
        rule = newspec.Properties(k).Rules(j);
        if any(strcmp(rule.AttributeName, attributeNames))
            % This attribute appears in an earlier rule, check for
            % consistency.
            n = find(strcmp(rule.AttributeName, attributeNames));
            if ~strcmp(rule.AttributeClass, attributeClasses{n})
                error('map:restructureSymbolSpec:inconsistentAttributeClasses', ...
                    'Symbolspec contains inconsistent attribute classes: %s and %s', ...
                      rule.AttributeClass, attributeClasses{n})
            end
        else
            % Add this attribute and its class to our lists.
            attributeNames{end+1}   = rule.AttributeName;
            attributeClasses{end+1} = rule.AttributeClass;
        end
    end
end

% Be sure to have an 'Attributes' name-class table, even if it's empty.
newspec.Attributes(1).Name  = '';
newspec.Attributes(1).Class = '';
newspec.Attributes(1) = [];

% Populate the attribute name-class table.
for m = 1:numel(attributeNames)
    newspec.Attributes(m).Name  = attributeNames{m};
    newspec.Attributes(m).Class = attributeClasses{m};
end

% Remove the now-redundant newspec.Properties.Rules.AttributeClass fields.
for k = 1:numel(newspec.Properties)
    if ~isempty(newspec.Properties(k).Rules)
        newspec.Properties(k).Rules ...
            = rmfield(newspec.Properties(k).Rules,'AttributeClass');
    end
end

end

%--------------------------------------------------------------------------

function map = setupAttributeToPropertiesMap(...
    attributeValueOrRange, propertyValueOrRangeOrColormap)

% Return a handle to a function, MAP.  MAP takes an array of feature
% attribute values -- either a cell array of strings or a numerical
% array -- with one array element per feature.  MAP returns two
% arguments:
%
%   - A logical index array indicating which elements of the feature
%     attribute array match the specified attribute value or range
%
%   - A cell array of property values that is either 1-by-1 (if the rule
%     specifies a unique property value) or has one element
%     corresponding to each index value of true.  Each cell will contain
%     a scalar double, a string, or a 1-by-3 double array specifying a
%     color.
%
% There are five types of maps (one for each type of rule):
%
% stringMatchMap
%    Map a specific attribute string to a specific property value
%
% scalarMatchMap
%    Map a specific numerical attribute value to a specific property value
%
% rangeMatchMap
%    Map numerical attribute values in a specified range to a specific
%    property value
%
% interpolatingMap
%    Linearly interpolate numerical attribute values for numerical
%    attributes within a specified range
%
% colorMappingMap
%    Linearly interpolate colors for numerical attributes within a
%    specified range
%
% The first three, stringMatchMap, scalarMatchMap, and rangeMatchMap,
% each return a unique value (within a 1-by-1 cell array) that is one of
% the following types:
%
%    a scalar double
%    a string
%    a [1-by-3] array of double representing a color
%
% An interpolatingMap returns a cell array with a scalar double in each
% cell. A colorMappingMap returns a cell array with a 1-by-3 array of
% double in each cell.

if ischar(attributeValueOrRange)
    % Map a specific attribute string to a specific graphics property value
    specifiedString = attributeValueOrRange;
    specifiedPropertyValue = propertyValueOrRangeOrColormap;
    map = setupStringMatchMap(specifiedString, specifiedPropertyValue);
else
    matchScalar = (numel(attributeValueOrRange) == 1);
    matchRange  = (numel(attributeValueOrRange) == 2);
    if matchScalar
        % Map a specific numerical attribute value to a specific property value
        specifiedScalar = attributeValueOrRange;
        specifiedPropertyValue = propertyValueOrRangeOrColormap;
        map = setupScalarMatchMap(specifiedScalar, specifiedPropertyValue);
    elseif matchRange
        specifiedAttributeRange = attributeValueOrRange;
        scalarPropertyValue = ...
            ischar(propertyValueOrRangeOrColormap) || ...
            (numel(propertyValueOrRangeOrColormap) == 1);
        singleColorProperty = isequal(size(propertyValueOrRangeOrColormap),[1 3]);
        if scalarPropertyValue || singleColorProperty
            specifiedPropertyValue = propertyValueOrRangeOrColormap;
            map = setupRangeMatchMap(...
                specifiedAttributeRange, specifiedPropertyValue);
        elseif isColormap(propertyValueOrRangeOrColormap)
            colormap = propertyValueOrRangeOrColormap;
            map = @(attributeValues) colorMappingMap(...
                specifiedAttributeRange, colormap, attributeValues);
        elseif (numel(propertyValueOrRangeOrColormap) == 2)
            specifiedPropertyRange = propertyValueOrRangeOrColormap;
            map = setupInterpolatingMap(...
                specifiedAttributeRange, specifiedPropertyRange);
        else
            % Note: We should never reach this line because
            % makesymbolspec should error first.
            error('map:restructureSymbolSpec:invalidPropertyValueOrRange', ...
                'Symbol spec property specification had %d elements; it must be a one or two-element vector, a 1-by-3 color, or a colormap array.', ...
                numel(propertyValueOrRangeOrColormap))
        end
    else
        % Note: We should never reach this line because makesymbolspec
        % should error first.
        error('map:restructureSymbolSpec:invalidAttributeSpecification', ...
            'Symbol spec attribute specification had %d elements; it must be a one or two-element vector.', ...
            numel(attributeValueOrRange))
    end
end
end

%--------------------------------------------------------------------------

function map = setupStringMatchMap(specifiedString, specifiedPropertyValue)

map = @stringMatchMap;

    function [index, propertyValues] = stringMatchMap(attributeStrings)
        index = strcmp(attributeStrings, specifiedString);
        propertyValues = {specifiedPropertyValue};
    end

end

%--------------------------------------------------------------------------

function map = setupScalarMatchMap(specifiedScalar, specifiedPropertyValue)

map = @scalarMatchMap;

    function [index, propertyValues] = scalarMatchMap(attributeValues)
        index = (attributeValues == specifiedScalar);
        propertyValues = {specifiedPropertyValue};
    end

end

%--------------------------------------------------------------------------

function map = setupRangeMatchMap(attributeRange, specifiedPropertyValue)

% All features with whose attribute value is in range correspond to the
% same property value

map = @rangeMatchMap;

    function [index, propertyValues] = rangeMatchMap(attributeValues)
        index = (attributeValues >= attributeRange(1)) ...
              & (attributeValues <= attributeRange(2));
        propertyValues = {specifiedPropertyValue};
    end

end

%--------------------------------------------------------------------------

function map = setupInterpolatingMap(attributeRange, propertyRange)

map = @interpolatingMap;

    function [index, propertyValues] = interpolatingMap(attributeValues)
        index = (attributeValues >= attributeRange(1)) ...
              & (attributeValues <= attributeRange(2));
        if any(index)
            p = interp1(attributeRange, ...
                        propertyRange, attributeValues(index));
        else
            p = [];
        end
        propertyValues = cell(numel(p),1);
        for k = 1:numel(p)
            propertyValues{k,1} = p(k);
        end
    end
end

%--------------------------------------------------------------------------

function [index, propertyValues] = colorMappingMap(...
    attributeRange, colormap, attributeValues)

    index = (attributeValues >= attributeRange(1)) ...
        & (attributeValues <= attributeRange(2));
    % Bin the attributeValues so that they are represented by the expected
    % color in the colormap
    bins = discretize(attributeValues, ...
        linspace(attributeRange(1), attributeRange(2), size(colormap,1) + 1));
    bins = bins(~isnan(bins));
    propertyValues = cell(numel(bins),1);
    for k = 1:numel(bins)
        propertyValues{k,1} = colormap(bins(k),:);
    end
end

%--------------------------------------------------------------------------

function tf = isColormap(cmap)

% True if cmap is M-by-3 with M > 1.  Returns false for a single color
% (1-by-3 cmap).

tf = isnumeric(cmap) && (size(cmap,2) == 3) && (size(cmap,1) > 1);
end
