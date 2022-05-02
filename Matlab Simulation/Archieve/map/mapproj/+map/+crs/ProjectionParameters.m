classdef (Sealed) ProjectionParameters < matlab.mixin.CustomDisplay
% map.crs.ProjectionParameters provides an interface for inspecting and
% modifying projection parameter values in a projcrs object.

% Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Hidden, SetAccess = private)
        ParameterData struct = struct.empty(0,1)
    end
    
    
    properties (Access = private)
        Names string = string.empty(0,1)
    end
    
    
    methods  % Construction & properties
        function obj = ProjectionParameters(data)
            if nargin > 0
                if ~isstruct(data)
                    error(message('map:crs:MustBeStructure'))
                end
                if ~isempty(data)
                    % The data struct must have 'name' and 'value' fields. It
                    % may have others. If so, they will be carried along but
                    % otherwise ignored.
                    if ~isfield(data,'name')
                        error(message('map:crs:MissingFieldInParameterStructure','name'))
                    end
                    if ~isfield(data,'value')
                        error(message('map:crs:MissingFieldInParameterStructure','value'))
                    end
                    
                    % Remove any extra fields, except for 'unit' and 'id'.
                    fieldsInput = string(fields(data))';
                    fieldsToKeep = ["name", "value", "unit", "id"];
                    for f = fieldsInput
                        if ~any(strcmp(f,fieldsToKeep))
                            data = rmfield(data,f);
                        end
                    end
                    
                    for k = 1:numel(data)
                        parameterName = makeMixedCaseParameterName(data(k).name);
                        value = validateParameterValue(data(k).value, parameterName);
                        data(k).value = value;
                        obj.Names(k,1) = parameterName;
                    end
                    obj.ParameterData = data;
                end
            end
        end
    end
    
    
    methods (Hidden)        
        function parameters = properties(obj)
        % properties(obj) displays a list of parameter names
        % parameters = properties(obj) returns a cellstr of parameter names
            names = parameterNames(obj);
            if nargout > 0
                parameters = convertStringsToChars(names);
            else
                if isempty(names)
                    if isscalar(obj)
                        noPropertiesMessage = getString(message('map:crs:NoPropertiesForObject'));
                    else
                        noPropertiesMessage = getString(message('map:crs:NoPropertiesForArray'));
                    end
                    displayNoPropertiesMessage(noPropertiesMessage)
                else
                    displayParameterNames(names)
                end
            end
        end
        
        
        function tf = isprop(obj, name)
        % Returns true if name is an exact, case-sensitive match for one of
        % the parameter names in obj.
            parameters = parameterNames(obj);
            if isempty(parameters)
                tf = false;
            else
                tf = any(strcmp(name, parameters));
            end
        end
    end
    
    
    methods (Access = protected)  % Custom display
        function header = getHeader(obj)
            % Get default header. It may include a matlab:helpPopup link.
            defaultHeader = getHeader@matlab.mixin.CustomDisplay(obj);
            
            % Request a default header again, but ensure there's no link. 
            hotlinks = feature('hotlinks');
            clean = onCleanup(@() feature('hotlinks', hotlinks));
            feature('hotlinks',false)
            linkFreeHeader = getHeader@matlab.mixin.CustomDisplay(obj);
            
            % Obtain the descriptive text (e.g., " with properties:")that
            % follows the class type. It's easier to do this using the
            % "link free header" because we don't have to check for the
            % possibility of a trailing "</a>" following the type string.
            defaultDescription = extractAfter(linkFreeHeader, "ProjectionParameters");
            
            % Going back to the actual default header (which may include a
            % link), use the default description to extract the first part
            % of the default header. Note the description will depend on
            % the locale. We can't just replace it with a string literal
            % like "with" because that would work only on English machines.
            sizeAndTypeString = extractBefore(defaultHeader, defaultDescription);
            
            % Combine the first part of the default header (size, if
            % present + class type, possibly including help popup link)
            % with custom description text (e.g., "object with
            % parameters:") to create a custom header.
            header = sizeAndTypeString + " " + customDescription(obj);
        end
        
        
        function description = customDescription(obj)
            % Descriptive string to follow class type in display header
            if isempty(obj)
                description = string(getString(message('map:crs:Array')));
            elseif isscalar(obj)
                if isempty(obj.ParameterData)
                    description = string(getString(message('map:crs:ObjectWithNoParameters')));
                else
                    description = getString(message('map:crs:ObjectWithParameters')) + string(newline);
                end
            else
                names = parameterNames(obj);
                if isempty(names)
                    description = string(getString(message('map:crs:ArrayWithNoParameters')));
                else
                    description = getString(message('map:crs:ArrayWithParameters')) + string(newline);
                end
            end
        end
        
        
        function displayEmptyObject(obj)
            header = getHeader(obj);
            disp(header);
            if looseSpacing()
                fprintf('\n')
            end
            % No footer
        end
        
        
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            if ~isempty(obj.ParameterData)
                fmt = get(0,'format');
                clean = onCleanup(@() format(fmt));
                format('longG')
                s = cell2struct({obj.ParameterData.value}, obj.Names', 2);
                disp(s)
            else
                if looseSpacing()
                    fprintf('\n')
                end
            end
            % No footer
        end
        
        
        function displayNonScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            names = parameterNames(obj);
            if ~isempty(names)
                fprintf('    %s\n', names)
            end
            if looseSpacing()
                fprintf('\n')
            end
            % No footer
        end
    end
    
    
    methods (Hidden)  % subsref / subsasgn
        function varargout = subsref(obj, s)
            try
                switch(s(1).type)
                    case '.'
                        % value = obj.<parameter name>
                        % value = obj.ParameterData  <== Hidden property
                        % value obj.<invalid name>   <== Errors
                        % etc.
                        varargout = subsrefDot(obj, s);
                        
                    case '()'
                        % obj(indices)
                        % obj(indices).<parameter name>
                        % obj(indices).ParameterData   <== Hidden property
                        % obj(indices).<invalid name>  <== Errors 
                        % etc.
                        varargout = subsrefIndex(obj, s);
                        
                    case '{}'
                        % All cases error:
                        %  obj{indices}
                        %  obj{indices}
                        %  obj{indices}.<parameter name>
                        %  etc.
                        error(message('map:crs:NoProjectionParametersBraceIndexing'))
                end
            catch e
                throwAsCaller(e)
            end
        end
        
        
        function obj = subsasgn(obj, s, varargin)
            % Allow subscripted assignment to uninitialized variable.
            if isequal(obj,[])
                obj = map.crs.ProjectionParameters.empty;
            end
            
            try
                switch(s(1).type)
                    case '.'
                        % obj.<parameter name> = value
                        % [obj.<parameter name>] = deal(value1, value2, ...)
                        % obj.ParameterData = struct(...) <== Errors: hidden & read-only
                        % obj.<invalid name> = value      <== Errors
                        % etc.
                        obj = subsasgnDot(obj, s, varargin);
                        
                    case '()'
                        % obj1(indices) = obj2
                        % obj(indices).<parameter name> = value
                        % obj(indices).ParameterData = value
                        % obj(indices).<invalid name> = value
                        % etc.
                        obj = subsasgnIndex(obj, s, varargin);
                        
                    case '{}'
                        % All cases error:
                        %  obj{indices} = newObj
                        %  obj{indices}.<parameter name> = value
                        %  etc.
                        error(message('map:crs:NoProjectionParametersBraceIndexing'))
                end
            catch e
                throwAsCaller(e)
            end
        end
    end
    
    
    methods (Access = private)
        function names = parameterNames(obj)
        % Return a string vector of parameter names. If numel(obj) > 1,
        % include only the parameter names comment to all elements of obj.
            if isempty(obj)
                names = string.empty;
            elseif isscalar(obj)
                names = obj.Names;
            else
                names = obj(1).Names;
                for k = 2:numel(obj)
                    names = intersect(names, obj(k).Names);
                end
            end
        end
        
        
        function returnArgs = subsrefDot(obj, s)
        % The essential purpose of this method is to take an indexing
        % structure that represents obj.<parameter name> or
        % obj.<parameter name>(indices) -- where the only valid value for
        % indices is 1 because all parameter values are scalar -- and
        % convert it to index into obj.ParameterData, as in
        % obj.ParameterData(idx).value, where obj.ParameterData(idx).name
        % corresponds to <parameter name>. In addition, the method needs to
        % allow obj.ParameterData to return the value of the hidden
        % ParameterData property, for use by the ProjectionParameter
        % object's client object (e.g., the projcrs object whose
        % ProjectionParameters property value equals obj).
        
            % Assume s(1).type is '.'
            name = s(1).subs;
            dotParameterNameCase = any(strcmpi(name, properties(obj)));
            if dotParameterNameCase
                if isscalar(s)
                    if isscalar(obj)
                        % value = obj.<parameter name>
                        snew = convertDotParameterName(obj, s);
                        returnArgs{1} = builtin('subsref', obj.ParameterData, snew);
                    else
                        % [v1, v2, ..., vn] = obj.<parameter name>
                        % v = [obj.<parameter name>]
                        n = numel(obj);
                        returnArgs = cell(1,n);
                        for k = 1:n
                            returnArgs{k} = subsref(obj(k), s);
                        end
                    end
                else
                    % This is OK: value = obj.<parameter name>(1)
                    % These result in a standard MATLAB error:
                    %     obj.<parameter name>(n) for n > 1
                    %     obj.<parameter name>.___
                    %     obj.<parameter name>{n} for any n
                    snew = convertDotParameterName(obj, s);
                    returnArgs{1} = builtin('subsref', obj.ParameterData, snew);
                end
            elseif strcmp(name,"ParameterData")
                n = numel(obj);
                returnArgs = cell(1,n);
                for k = 1:n
                    returnArgs{k} = builtin('subsref', obj(k), s);
                end
            else
                % obj.<invalid name>
                throwDoesNotHaveParameter(obj, name)
            end
        end
        
        
        function obj = subsasgnDot(obj, s, args)
        % The essential purpose of this method is to take an indexing
        % structure that represents obj.<parameter name> = value or
        % obj.<parameter name>(indices) = value -- where the only valid
        % value for indices is 1 because all parameter values are scalar --
        % and convert it to index into obj.ParameterData, as in value =
        % obj.ParameterData(idx).value where obj.ParameterData(idx).name
        % corresponds to <parameter name>. In addition, the method needs to
        % help validate the input parameter value and indicate that the
        % value of the hidden ParameterData property cannot be changed.
        
            % Assume s(1).type is '.'
            name = s(1).subs;
            dotParameterNameCase = any(strcmpi(name, properties(obj)));
            if dotParameterNameCase
                if isscalar(obj)
                    % obj.<parameter name> = value
                    value = args{1};  % args should be scalar in this case.
                    [snew, parameterName] = convertDotParameterName(obj, s);
                    currentValue = builtin('subsref', obj.ParameterData, snew);
                    value = validateParameterValue(value, parameterName, currentValue);
                    obj.ParameterData = builtin('subsasgn', obj.ParameterData, snew, value);
                else
                    % [obj.<parameter name>] = deal(value1, value2, ...)
                    n = numel(obj);
                    for k = 1:n
                        obj(k) = subsasgn(obj(k), s, args{k});
                    end
                end
            elseif strcmp(name,"ParameterData")
                % obj.ParameterData = value;
                error(message('map:crs:SetProhibitedOnParameterData'))
            else
                % obj.<invalid parameter name> = value
                throwDoesNotHaveParameter(obj, name)
            end
        end
        
        
        function [s, name] = convertDotParameterName(obj, s)
        % Convert an indexing structure, s, in which s(1) has the form:
        %
        %    substruct('.', <parameter name>)
        %
        % to the form:
        %
        %    s = [substruct('()', {idx}, '.', 'value') s(2:end)]
        %
        % where idx is the index of the specified parameter in the
        % ParameterData structure array (such that
        % obj.ParameterData(idx).name corresponds to <parameter name>).
            
            name = "";
            subs1 = convertCharsToStrings(s(1).subs);
            if isscalar(subs1) && isstring(subs1)
                name = subs1;
                names = obj.Names;
                if ~isempty(names)
                    idx = find(name == names,1);
                    if ~isempty(idx)
                        s = [substruct('()', {idx}, '.', 'value'), s(2:end)];
                    end
                end
            end
        end
        
        
        function throwDoesNotHaveParameter(obj, name)
        % Throw error in the case of obj.<invalid name>, where
        % <invalid name> is neither "ParameterData" nor the name of a
        % parameter of obj.
        
            if isscalar(obj)
                error(message('map:crs:NotParameterOfObject',name))
            else
                error(message('map:crs:NotParameterOfArray',name))
            end
        end
        
        
        function returnArgs = subsrefIndex(obj, s)
            if isscalar(s)
                % obj(indices)
                returnArgs{1} = builtin('subsref', obj, s);
            else
                % obj(indices).<parameter name>
                % obj(indices).ParameterData
                % obj(indices).<invalid name>
                % etc.
                t = builtin('subsref', obj, s(1));
                n = numel(t);
                returnArgs = cell(1,n);
                for k = 1:n
                    returnArgs{k} = subsref(t(k), s(2:end));
                end
            end
        end
        
        
        function obj = subsasgnIndex(obj, s, args)
            % Assume s(1).type is '()'
            if isscalar(s)
                % obj(indices) = newObjects (scalar or size-matched array)
                obj = builtin('subsasgn', obj, s, args{:});
            else
                % [obj(indices).<parameter name>] = deal(v1, v2, ..., vn)
                % Copy ProjectionParameters objects referenced by s(1),
                % modify the copies, then assign them back into the
                % proper places in the input array, obj.
                subs1 = s(1).subs;
                indexedObjects = obj(subs1{:});
                indexedObjects = subsasgn(indexedObjects, s(2:end), args{:});
                obj(subs1{:}) = indexedObjects;
            end
        end
    end
end


function mixedCaseName = makeMixedCaseParameterName(name)
    % Include converting first letter in each word to upper case and
    % removing white space to generate a valid MATLAB variable name
    % formatted in mixed case.
    name = convertCharsToStrings(name);
    if ~isscalar(name) || ~isstring(name)
        error(message('map:crs:InvalidParameterName'))
    end
    mixedCaseName = regexprep(name,'(\<\w)','${upper($1)}');
    mixedCaseName = matlab.lang.makeValidName(mixedCaseName);
end


function displayNoPropertiesMessage(messageString)
% Formatted command-line display of "no properties" message string
    if looseSpacing()
        fprintf('\n%s\n\n', messageString)
    else
        fprintf('%s\n', messageString)
    end
end


function displayParameterNames(names)
% Formatted command-line display of parameter names
% (The names input is an N-by-1 string vector.)
    if looseSpacing()
        fprintf('\n')
        fprintf('    %s\n', names)
        fprintf('\n')
    else
        fprintf('    %s\n', names)
    end
end


function tf = looseSpacing()
    tf = strcmp(get(0,'FormatSpacing'),'loose');
end


function value = validateParameterValue(value, parameterName, currentValue)
% Validate parameter values, converting valid numeric input to double and
% valid char vector or string input to string. To be valid, input must be
% scalar numeric, char vector, or string scalar. In addition, input must be
% numeric if the current type is double and char or string if the current
% type is string. Assumption: currentValue is assumed to be either a scalar
% double or a string scalar, which should be established by invoking this
% function (without a currentValue input) at construction time.

    if isnumeric(value)
        if nargin > 2 && isstring(currentValue)
            error(message('map:crs:ParameterMustRemainString', parameterName))
        elseif ~isscalar(value)
            error(message('map:crs:ParameterMustBeScalar', parameterName))
        elseif ~isreal(value)
            error(message('map:crs:ParameterMustBeReal', parameterName))
        elseif ~isfinite(value)
            error(message('map:crs:ParameterMustBeFinite', parameterName))
        else
            value = double(value);
        end
    elseif ischar(value) || isstring(value)
        value = convertCharsToStrings(value);
        if nargin > 2 && isnumeric(currentValue)
            error(message('map:crs:ParameterMustRemainNumeric', parameterName))
        elseif ~isscalar(value)
            error(message('map:crs:ParameterMustBeString', parameterName))
        % else
            % value was specified as a string scalar or was
            % successfully converted to a string scalar.
        end
    else
        error(message('map:crs:ParameterMustBeNumericOrString', parameterName))
    end
end
