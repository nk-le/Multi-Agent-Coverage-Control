classdef DynamicShape < map.internal.DynamicVector
    
    methods
        
        function self = DynamicShape(coordinates, varargin)

            self = self@map.internal.DynamicVector(coordinates, {});
            self.Geometry = 'line';
            
            try
                % Construct the object. Use a try/catch to prevent any
                % error messages from containing references to the internal
                % class.
                [varargin{:}] = convertStringsToChars(varargin{:});
                self = constructObject(self, varargin{:});
            catch e
                throwAsCaller(e);
            end
        end
    end
     
    %----------------------- Overloaded public methods --------------------
    
    methods (Abstract)
        
         self = append(self,  varargin)
         
    end
    
    %----------------------- Overloaded protected methods -----------------
    
    methods (Access = protected, Hidden = true)
         
        %--------------------- Construction methods -----------------------

        function self = constructObject(self, varargin)
        % constructObject overloaded method.
        %
        % Construct object from varargin inputs.
            
            if length(varargin) == length(self.Coordinates) + 1
                % internal.map.DynamicShape(coord1, coord2, ... obj)
                % This syntax is not allowed when the input is an object.
                % It is only allowed when the input is a structure.
                index = length(self.Coordinates) + 1;
                if ~isstruct(varargin{index})
                    internal.map.checkNameValuePairs(varargin{index});
                end
            end
            
            % Invoke the super class method.
            self = constructObject@map.internal.DynamicVector(self, varargin{:});
        end
        
        %------------------------------------------------------------------
        
        function self = constructFromStruct(self, S)
        % constructFromSelf overloaded method.
        %
        % Assign properties to empty object self (with length 0) from
        % scalar structure, S. The value of each field of S is a vector.
        % These vectors do not need to have the same length. The length of
        % self will be the length of the longest vector.
            
            % names contains the names of the coordinates.
            names = self.Coordinates;
            
            % numCoords is the number of coordinates.
            numCoords = length(names);
            
            % structNames contains the fieldnames of S.
            structNames = fieldnames(S);
            
            % containsCoordinates is true if any coordinate name is a field
            % of S.
            containsCoordinates = any(ismember(names, structNames));
            
            % Copy the coordinate fields from S and construct object if any
            % coordinate field is present in S.
            if containsCoordinates
                c = cell(1, numCoords);
                for k=1:length(names)
                    if any(strcmp(names{k}, structNames))
                        c{k} = S.(names{k});
                        S = rmfield(S, names{k});
                    else
                        c{k} = {};
                    end
                end
                self = constructFromCoordinates(self, c);
            end
            
            % If the input structure contains any more fields, then they
            % are values for either the non-coordinate properties of the
            % class (the container properties) or they become dynamic
            % properties
            if ~isempty(S)
                % Invoke the super class method to set other non-coordinate
                % and dynamic properties.
                self = constructFromStruct@map.internal.DynamicVector(self, S);
                
                % Each coordinate array must be a cell array. It is a
                % numeric vector in the case where S does not contain any
                % coordinate values. In this case, the coordinate property
                % values need to be reset.
                if ~containsCoordinates
                    for k=1:numCoords
                        value = self.pCoordinates.(names{k});
                        if ~iscell(value) && ~isempty(value)
                            self = setProperty(self, names{k}, num2cell(value));
                        end
                    end
                end
                
                % The super class expands cell arrays with ''. These need
                % to be replaced.
                self = replaceEmptyStringInProperties(self);
                
                % Reset each dynamic vertex property, if present, in order
                % to set it to the correct length and to insert part
                % separators. In order to do this correctly, the field must
                % first be removed from the object, then reset.
                f = fieldnames(self);
                DynamicProperties = self.pDynamicProperties;
                for k=1:numel(f)
                    prop = DynamicProperties.(f{k});
                    if isVertexValue(prop)
                        self = rmfield(self, f{k});
                        type = classtype(prop);
                        if ischar(type)
                            % Cell array contains single data type.
                            % Create an index for all the values and reset.
                            index = true([1,length(prop)]);
                            self = setDynamicProperty(self, index, f{k}, prop);
                        else
                            % Cell array contains mixed type. Set each
                            % element individually. This can occur when a
                            % value is {cellstr, character vector}
                            for index = 1:length(prop)
                                values = prop(index);
                                self = setDynamicProperty(self, index, f{k}, values);
                            end
                        end
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function self = constructFromCoordinates(self, coordinates)
        % constructFromCoordinates overloaded method.
        %
        % Construct object from coordinate arrays. The cell array,
        % coordinates, contains the input coordinate arrays. The length
        % of coordinates must match the length of self.Coordinates. This
        % requirement is not validated by this method.
            
            % coordinates is a cell array with a length equal to the number
            % of coordinates as specified by self.Coordinates.
            % Set each of the elements of coordinates as a cell array.
            numCoords = length(coordinates);
            for k=1:numCoords
                coordinates{k} = validateCoordinatePropertyInput(...
                    self, coordinates{k}, self.Coordinates{k});
            end
            
            % Create a cell array which contains a logical array for each
            % element in the coordinate arrays that contain NaN values.
            % Determine if the arrays match in both length and nan
            % locations. Determine the maximum length of any coordinate
            % element.
            [nansInCell, arraysMatch, maxLength] = findNansInCells(coordinates);
            
            if ~arraysMatch
                % The coordinate arrays do not match either because the
                % length of each element does not match or because there is
                % inconsistent locations of NaN values. For each element,
                % extract a cell array of coordinate values. Match the NaN
                % locations in the extracted values. Use the superclass to
                % create an output object which contains matched NaN values
                % and matched sizes. Extract the coordinate values from
                % this object to reset the input coordinates array.
                for k = 1:maxLength
                    c = extractCoordinates(coordinates, nansInCell, k);
                    out = constructFromCoordinates@map.internal.DynamicVector( ...
                        self, c);
                    for m = 1:numCoords
                        v = out.(self.Coordinates{m});
                        if ~isempty(v)
                           coordinates{m}{k} = v{:};
                        end
                    end
                end
            end
            
            % Set the coordinate property values.
            for k = 1:numCoords
                name = self.Coordinates{k};
                self = setProperty(self, name, coordinates{k});
            end
        end
        
        %--------------------- subsasgn methods ---------------------------
        
        function self = subsasgn_impl_dot_coordinate_property( ...
                self, s, in, propname)
        % subsasgn_impl_dot_coordinate_property overloaded method.
        %
        % A coordinate property is being set.
        % s contains '.'
        % This method is invoked whenever the following operation is
        % performed:
        %   self.Coordinate = value (where Coordinate is a coordinate
        %                            property)
                  
            if isValidEmpty(in)
                % Input is [], replace it with {} to reset the object
                % to empty.
                in = {};
            else
                % Replace [] with zeros to prevent empty elements from
                % being assigned.
                in = replaceEmptyWithZeros(in);
            end
            
            % Validate the input.
            % The following inputs are not allowed:
            % self.CoordinateProperty(n) = value
            % self.CoordinateProperty{n} = value
            if ~isscalar(s)
                if strcmp(s(2).type, '{}')
                    op = '{index}';
                else
                    op = '(index)';
                end
                error(message('map:DynamicShape:invalidPropertyAssignment', ...
                    propname, op, propname, '(index)'))
            end
            
            % Invoke the super class method.
            self = subsasgn_impl_dot_coordinate_property@map.internal.DynamicVector(...
                self, s, in, propname);
            
            if iscell(in) && isempty(in)
                % IN is {} and a coordinate property is being set.
                % Set the other remaining coordinate properties to {}.
                coordinates = setdiff(self.Coordinates, propname);
                for k=1:length(coordinates)
                    self = setProperty(self, coordinates{k}, in);
                end
            else
                % Make sure the property value data type is correct since
                % the (.) referencing replaces the original values. The
                % setCoordinate method cannot determine this information
                % and casts the input based on the data type of the
                % original property values.
                %
                % If the result of the property set changes the data type
                % of the property value to not match the data type of the
                % input value, then recast the coordinate value to the data
                % type of the input value. The input class type may be
                % mixed (thus classtype returns a cell array). In this
                % case, there is nothing to change.
                v = getProperty(self, propname);
                intype = classtype(in);
                if ischar(intype) && ~isequal(classtype(v), intype)
                     v = castCoordinateInput(v, in);
                     self = setProperty(self, propname, v);
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_impl_dot_dynamic_property( ...
                self, s, in, propname)
        % subsasgn_impl_dot_dynamic_property overloaded method.
        %
        % A dynamic property is being set.
        % s contains '.'
        % This method is invoked whenever the following operation is
        % performed:
        %   self.Name = value       (where Name is a dynamic property)
                    
            isDynamicProp = isfield(self.pDynamicProperties, propname);           
            if ~isDynamicProp
                % The property is a new dynamic property.
                original = {};
                usingVertexRules = false;
            else
                % The property is already defined.
                % Save the original value.
                original = self.pDynamicProperties.(propname);
                usingVertexRules = isVertexValue(in);
                if usingVertexRules
                    % This method is invoked when obj.DynamicProperty
                    % is being set. This implies that the original
                    % value will be completely overwritten. Set the
                    % original value to {}.
                    original = {};
                end
            end
            
            % Replace [] with 0 to prevent empty elements from being
            % assigned.
            in = replaceEmptyWithZeros(in);
            
            % Validate the input.
            % The following types of inputs are not allowed:
            % self.VertexProperty(n) = value
            % self.VertexProperty{n} = value
            if ~isscalar(s) && (usingVertexRules || isVertexValue(original))
                if strcmp(s(2).type, '{}')
                    op = '{index}';
                else
                    op = '(index)';
                end
                error(message('map:DynamicShape:invalidPropertyAssignment', ...
                    propname, op, propname, op))
            end
            
            % Invoke the super class method.
            self = subsasgn_impl_dot_dynamic_property@map.internal.DynamicVector(...
                self, s, in, propname);
            
            % Determine if the property setting needs to use vertex
            % rules. If the dynamic property is already defined, and
            % the input is not following vertex rules, then check the
            % property value to see if it is following vertex rules.
            % Set the flag to the rules of the dynamic property. In
            % other words, if the input is a feature property value and
            % the new property value is for a vertex property, then the
            % vertex rules apply.
            if isfield(self.pDynamicProperties, propname) && ~usingVertexRules
                dynamic = self.pDynamicProperties.(propname);
                usingVertexRules = isVertexValue(dynamic);
            end
            
            if usingVertexRules
                % Setting a vertex property. Synchronize all the
                % properties.
                self = synchronizeProperties(self, original, propname);
            else
                % Setting a feature property. Replace empty character
                % vector values.
                self = replaceEmptyStringInProperties(self);
            end
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_property(self, s, in, propname)
        % subsasgn_property overloaded method.
        %
        % Assign value IN to property, PROPNAME, that is defined by the
        % class (a container property or a coordinate property).
        %
        % This method is only invoked from
        % subsasgn_impl_paren_two_elements. That implies that the request
        % is to reference two elements.
        %
        % Example
        % obj(n).Metadata = struct('Filename', 'name')
            
            % Determine if s is referencing a container property (defined
            % by self.ConstantProperties), or a coordinate property. This
            % method is not invoked if s is referencing a dynamic property.
            if any(strcmp(self.ConstantProperties, propname)) && isscalar(s)
                % s is referencing a container property. 
                % A container property is scalar in size, just like self.
                % Invoke the super class method to set the value. A
                % warning is issued if self is not scalar.
                self = subsasgn_property@map.internal.DynamicVector( ...
                    self, s, in, propname);
            else
                % s is referencing a coordinate property. 
                % IN must be a cell array.
                if ~iscell(in)
                    in = {in};
                end
                
                % If the input is an empty cell array, {}, then set the
                % first element to []. This prevents
                % MATLAB:subsassignnumelmismatch errors from being issued
                % later by builtin('subsasgn').
                if isempty(in)
                    in = {[]};
                end
                
                type = classtype(in);
                if ~ischar(type) || ~any(strcmp(type, {'single', 'double'}))
                    % If the input is not single or double, then use the
                    % validate method to issue an error. Since the set
                    % function also invokes this method, only validate when
                    % the input is not valid. This prevents an object that
                    % is empty from being incorrectly assigned.
                    in = validateCoordinatePropertyInput(self, in, propname);
                end

                % Set the value of the property. Use the builtin subsasgn.
                % The builtin function performs the following actions:
                % * parses s,
                % * assigns original to s (they are both cell arrays)
                % * original may be expanded (by standard MATLAB assignment)
                %
                % The value returned by subsasgn may contain [] values via
                % standard MATLAB expansion. These need to be converted to
                % 0s. The propname's set method is then invoked with the
                % adjusted value.
                original = getProperty(self, propname);
                value = builtin('subsasgn', original, s, in);
                value = replaceEmptyWithZeros(value);
                self.(propname) = value;
            end
        end
                
        %------------------------------------------------------------------
        
        function self = subsasgn_dynamic_property(self, s, in, fname)
        % subsasgn_dynamic_property overloaded method.
        %
        % Assign value IN to the field, FNAME, of the dynamic property
        % structure. s is a structure containing the assignment information
        % (from subsasgn).
        %
        % This method gets referenced with the following type of call:
        % self(2).Name = 'x'
        % self(1).X = 1:3;
        % self(n).Name = {'one'}
        %
        % This method is not invoked when assigning self.Name
        
            % Determine if input needs to expand or contract with the
            % coordinate properties (represents a vertex property).
            if  ~isscalar(in) && ...
                    (~iscell(in) && (isnumeric(in) || islogical(in))) || ...
                    (iscellstr(in) && ~isempty(in)) %#ok<ISCLSTR>
                % IN is either:
                % 1) Not a cell and not scalar and is numeric or logical. 
                % 2) A non-empty cellstr
                % Reset the input as a cell array, ONLY if referencing a
                % single element of self.
                if isscalar(s) && iscell(s(1).subs) && isscalar(s(1).subs{1})
                    in = {in};
                end
            end
            
            % Determine if the property setting needs to follow vertex
            % rules.
            if ~isfield(self.pDynamicProperties, fname)
                % The property is new and has not been set.
                original = {};
                usingVertexRules = isVertexValue(in);
            else
                % The property has been previously set. Determine if vertex
                % rules apply to the original value.
                original = self.pDynamicProperties.(fname);
                usingVertexRules = isVertexValue(original);
                
                if usingVertexRules && ischar(in)
                    in = {{in}};
                end
                
                % Determine if the original value is following vertex
                % rules and if the input value is following vertex rules.
                if ~usingVertexRules && isVertexValue(in)
                    % The original value is not following vertex rules, it
                    % is a feature property. However, the new input
                    % indicates that vertex rules are required. Reset the
                    % dynamic property to following vertex rules.
                    
                    % Set the original value to a cell with each element of
                    % original in the new cell. Use num2cell since it works
                    % correctly for any input.
                    original = num2cell(original);
                    
                    % Synchronize this value with the coordinates.
                    coords = self.Coordinates;
                    propname = coords{1};
                    value = getProperty(self, propname);
                    [~, original] = synchronizeDynamicProperty( ...
                        value, original, {});
                    
                    % Reset the dynamic property.
                    self.pDynamicProperties.(fname) = original;
                    usingVertexRules = true;
                end
            end
            
            % Test if the input is an empty cell array.
            % In order to keep the cast of the new property value
            % consistent with the class of the original property value, the
            % empty value need to be adjusted to match the class of the
            % original property value.
            %
            % When a property value is set with {} and the property name is
            % a dynamic property, the elements for those indices are set to
            % empty, then they are synchronized with the coordinate arrays
            % using the expand value (0 for numeric, false for logical, and
            % '' for scalar text) to match the length of that element.
            %
            if iscell(in) && isempty(in)
                % Recast the input to match the cast of the original
                % property value.
                type = classtype(original);
                in = recastEmptyInEmptyCell(type, usingVertexRules);
            end
            
            % Invoke the super class method.
            temp = subsasgn_dynamic_property@map.internal.DynamicVector( ...
                self, s, in, fname);
            
            % Check to see if the property has not been deleted.
            if isfield(temp.pDynamicProperties, fname)
                % If using vertex rules, then synchronize the properties,
                % otherwise, replace the empty character vector values.
                if usingVertexRules
                    temp = synchronizeProperties(temp, original, fname);
                else
                    temp = replaceEmptyStringInProperties(temp);
                end
            end
            
            % Assign self to temp for return.
            self = temp;
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_empty(self, s, in)
        % subsasgn_empty overloaded method.
        %
        % protected implementation for subsasgn_empty. self is empty.
            
            % This is for self.X = 1:n
            if numel(s) == 2 && strcmp(s(1).type, '()') && strcmp(s(2).type, '.')
                % Assigning: self(n).Name = value
                propname = s(2).subs;
            elseif isscalar(s) && strcmp(s(1).type, '.')
                % Assigning: self.Name = value
                propname = s(1).subs;
            else
                % Assigning: self = value
                propname = '';
            end
            
            % Determine if the object needs to be initialized.
            % The object needs to be initialized if in is not [] and
            % propname does not correspond to a constant property
            % (such as Metadata).
            if isEmptyString(in) || ...
                    (~isempty(in) && ~any(strcmp(propname, self.ConstantProperties)))
                % Initialize the object so that it is no longer empty.
                % This prevents self(n>1).PropName = values to cause
                % invalid assignments, where propname is not a standard
                % scalar property. However, the class must be initialized
                % with the correct class type (single 0 or double 0)
                type = classtype(in);
                if any(strcmp(propname, self.Coordinates)) ...
                        && any(strcmp(type, 'single'))
                    % Only initialize the coordinates to class single (0)
                    % if you are actually setting the coordinates and the
                    % input is of class single.
                    value = single(0);
                else
                    % Default all other values to class double (0).
                    value = 0;
                end
                
                % Initialize the object to be non-empty.
                self(end+1).(self.Coordinates{1}) = value;
                
                % Invoke the subsasgn_impl method to make the input
                % assignment.
                self = subsasgn_impl(self, s, in);
            else
                % Either the input is empty or a collection
                % (ConstantProperties) is being set. Pass the input to the
                % super class.
                self = subsasgn_empty@map.internal.DynamicVector(self, s, in);
            end
        end
        
        %--------------------- subsref methods ----------------------------
       
        function  varargout = subsref_property(self, s, numout)
        % Return a value based on the inputs to subsref, S. S contains
        % a property name.
            
            op = s(end).type;
            propname = s(1).subs;
            
            if any(strcmp(propname, self.Coordinates)) && ~strcmp(op, '{}')
                v = builtin('subsref', self, s(1));
                v = cell2mat(v);
                if ~isscalar(s)
                    v  = builtin('subsref', v, s(2:end));
                end
                [varargout{1:numout}] = v;
            else
                [varargout{1:numout}] = ...
                    subsref_property@map.internal.DynamicVector(self, s, numout);
            end
        end
        
        %------------------------------------------------------------------
        
        function varargout = subsref_dynamic_property(self, s, numout)
        % subsref_dynamic_property overloaded method.
        %
        % Use subsref to obtain the value from the DynamicProperties
        % structure. Return a value based on the inputs to subsref, s. s
        % contains reference to a field name of self.DynamicProperties.
        %
        % Examples:
        % self(n).Name
        % self.Name
        % self.Name{index}
        % self.Name(index)
            
            op = s(end).type;
            DynamicProps = self.pDynamicProperties;
            
            if any(strcmp(op, {'{}','()'}))
                % This branch is executed with the following type of
                % reference:
                %   self.Name{1}
                %   self.Name{1:end}
                %   self.Name{:}
                %   self.Name(index)
                % Note: subsref cannot create a comma-separated list of
                % values. S.Name{:} returns only the first value.
                
                % subsref the object, self(n), and the property name.
                [v{1:numout}] = builtin('subsref', DynamicProps, s(1:end-1));
                
                % Concatenate the values by converting the output from a
                % cell array to a vector (if numeric). This adds feature
                % separators if referencing multiple features.
                v = catDynamicProperty(v);
                
                % subsref the vector (or cell array).
                [varargout{1:numout}] = builtin('subsref', v{1}, s(end));
                if numout <= 1 && ~isscalar(varargout)
                    error(message('map:DynamicVector:cellIndexingNotPermitted',  ...
                        '()', '{}'))
                end
            else
                % Standard object / property reference.
                [varargout{1:numout}] = builtin('subsref', DynamicProps, s);
                if numout <= 1
                    % Concatenate the values.
                    varargout = catDynamicProperty(varargout);
                end
            end
        end

        %--------------------- validate methods ---------------------------
        
        function value = validateGeometry(self, value)
        % Validate Geometry property. VALUE is the input value to validate.
        
            if strcmpi('multipoint', value)
                value = 'point';
            end
            types =  {'point', 'line', 'polygon'};
            value = validatestring(value, types, class(self), 'Geometry');           
        end       
        
        %------------------------------------------------------------------

        function S = validatestruct(self, in)
        % validatestruct overloaded method.
        %
        % Validate input, IN to be a structure and copy valid fields to the
        % output scalar structure, S.
   
            % Validate input, IN, as a structure and convert it to a scalar
            % structure.
            S = validatestruct@map.internal.DynamicVector(self, in);
            
            % Coordinates must be cell arrays. Convert each coordinate
            % field. If the input structure is not scalar, then use
            % num2cell in order to have the correct length.
            for k=1:numel(self.Coordinates)
                name = self.Coordinates{k};
                if isfield(S, name)
                    value = S.(name);
                    if ~iscell(value)
                        if ~isscalar(in)
                            % Input structure is an array. Use num2cell to
                            % convert the numeric array to a cell array and
                            % preserver the size.
                            S.(name) = num2cell(value);
                        else
                            % The input structure is scalar. All the
                            % coordinate values are set in the first
                            % element. Convert to a cell array by
                            % concatenating the values.
                            S.(name) = {S.(name)};
                        end
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function in = validateCoordinatePropertyInput(self, in, name)
        % validateCoordinatePropertyInput overloaded method.
        %
        % Validate the property input values.
            
            % An input to a coordinate property is a cell array.
            if  ~iscell(in)
                in = {in};
            end
           
            % Validate and transpose coordinates (if they are column
            % vectors). If the input contains extra NaN values, then remove
            % them. 
            validator = @(x) validatecoordinates(x, class(self), name);
            in = cellfun(validator, in, 'UniformOutput', false);
            
            % Reshape the cell array to be a row vector.
            if ~isempty(in) && ~isrow(in)
                in = reshape(in, 1, length(in));
            end
            
            % Replace [] with 0 to prevent empty elements from being
            % assigned.
            in = replaceEmptyWithZeros(in); 
            
            % Cast the input, if required.
            propArray = getProperty(self, name);
            in = castCoordinateInput(in, propArray);

        end
        
        %------------------------------------------------------------------
        
        function in = validateDynamicPropertyInput(self, in)
        % validateDynamicPropertyInput overloaded method.
        %
        % Validate dynamic property input values.
            
            % Determine if IN is a vertex or feature property value.
            if ~isVertexValue(in)
                % IN is a feature property value.
                if iscell(in)
                    % IN is a cell array. Ensure that it does not
                    % contain any empty objects. If so, then issue a
                    % badCellTypes error rather than a badCellStr error
                    % (which is the error the super class issues).
                    testFcn = @(x)(isempty(x) && ~isValidEmpty(x));
                    notValidEmpty = cellfun(testFcn, in);
                    if any(notValidEmpty)
                        error(message('map:DynamicVector:badCellTypes'))
                    end
                end
                
                % Forward the call to the superclass method.
                in = validateDynamicPropertyInput@map.internal.DynamicVector( ...
                    self, in);
            else
                % IN is a vertex property value.
                if iscell(in)
                    % Convert all string elements to cellstr. 
                    scalarIndex = cellfun(@isStringScalar, in);
                    in = cellfun(@convertStringsToChars, in, 'UniformOutput', false);
                    if any(scalarIndex) && ~iscellstr(in) %#ok<ISCLSTR>
                        % string scalars are converted to character vectors
                        % by convertStringstoChars, but they need to be a
                        % cellstr. Use an additional cellfun to convert all
                        % string scalar to cellstr.
                        in(scalarIndex) = cellfun(@cellstr, in(scalarIndex), 'UniformOutput', false);
                    end
                    
                    % Convert valid empty values when cell array contains
                    % any char values.
                    if any(cellfun(@(x) ischar(x), in))
                        index = cellfun(@(x) isValidEmpty(x), in);
                        in(index) = {''};
                    end

                    % Determine if cell IN contains character vector or cell arrays.
                    % Allow a cell array of : cellstrs:
                    % { {'char'}, {'char'}, {'char'}}
                    % or a cell array of : char vector and cellstrs:
                    % { 'char', {cellstr}, {cellstr}}
                    containsCells = cellfun(@iscell, in);
                    containsChars = cellfun(@ischar, in);
                    containsCellsOrChars = containsCells | containsChars;
                    if any(containsCellsOrChars)
                        % Validate cells and character vector content.
                        if ~all(containsCellsOrChars)
                            % Must be cellstr or cell array of cellstrs.
                            error(message('map:DynamicVector:badCellStr'))
                        elseif any(containsCells)
                            in(containsCells) = convertStringCellsToCharCells(in(containsCells));
                            % All elements that contain cells must be cellstrs.
                            isCellStrs = cellfun(@iscellstr, in(containsCells));
                            if ~all(isCellStrs)
                                error(message('map:DynamicShape:invalidCellStrs'));
                            end
                            
                            % Vertex properties containing cells must be
                            % all cells. 
                            if any(containsChars)
                                % Error in this case of mixed cellstrs with
                                % chars. To allow this behavior, and
                                % allow a vertex property to contain a cell
                                % array of chars mixed with cellstrs,
                                % remove the error and uncomment the other
                                % two lines.
                                error(message('map:DynamicShape:invalidCellStrs'))
                                % Wrap char elements as cells.
                                %in(containsChars) = cellfun(@(x)({x}), ...
                                %    in(containsChars), 'UniformOutput', false);
                            end
                        end
                    else
                        % Validate numeric or logical elements. Ensure each
                        % element is either empty or a vector.
                        cellfun(@validateVertexValues, in, 'UniformOutput', false);
                    end
                    
                    % Ensure row vector elements.
                    % When transposing, ensure 0-by-0 does not become a
                    % 1-by-0 or 0-by-1 element.
                    isRowVector = cellfun(@isrow, in);
                    if ~all(isRowVector)
                         in(~isRowVector) = cellfun(@(x) transposeElement(x), ...
                            in(~isRowVector), 'UniformOutput', false);
                    end
                    
                    % Replace [] with 0s to prevent a dynamic property from
                    % being set to [].
                    in = replaceEmptyWithZeros(in);
                end
                
                % Reshape the array to be a row vector.
                if ~isempty(in) && ~isrow(in)
                    in = reshape(in, 1, length(in));
                end               
            end
        end
        
        %------------------------------------------------------------------
        
        function self = setCoordinate(self, name, value)
        % setCoordinate overloaded method.
        %
        % Validate and set a coordinate value.
          
           % Obtain the original value of the property.
            original = getProperty(self, name);
            
            % Check if the coordinate properties need to be initialized.
            if isempty(original) && isnumeric(original)
                % Initialize the coordinate values.               
                % Class is uninitialized. Coordinates must be held in cell
                % arrays. Reset original to: {[]} and initialize all
                % coordinate arrays.
                if all(strcmp(classtype(value), 'single'))
                    original = {single([])};
                else
                    original = {[]};
                end
                self = setCoordinates(self, original);              
            end
            
            % Validate and transpose value (if  value is a column vector).
            value = validateCoordinatePropertyInput(self, value, name);

            % Set the property value.
            self = setProperty(self, name, value);
            
            % Adjust the other properties only if the length of value does
            % not match the length of the original value of the property.
            lengthOfValue = length(value);           
            if lengthOfValue ~= length(original)
                % Adjust dynamic properties.
                self = adjustProperties(self, lengthOfValue, name);
            end
            
            % Synchronize the other coordinate arrays.
            names = setdiff(self.Coordinates, name);
            for k=1:length(names)
                coordinate = getProperty(self, names{k});
                coordinate = synchronizeVertexProperty( ...
                    coordinate, value, original);
                coordinate = synchronizeNaNLocations(coordinate, value);
                self = setProperty(self, names{k}, coordinate);
            end
            
            % Set the dynamic vertex properties.
            f = fieldnames(self.pDynamicProperties);
            dynamic = getProperty(self, name);
            self = synchronizeDynamicProperties(self, dynamic, original, f);
        end
        
        %------------------------------------------------------------------
        
        function out = vertcat_coordinates(self, inputs)
        % vertcat_coordinates overloaded method.
        %
        % Concatenate coordinates of internal.map.DynamicShape
        % object.
            
            % Remove the dynamic properties.
            out = rmfield(self, fieldnames(self));
            
            % Obtain the list of coordinates.
            c = out.Coordinates;
            
            % Loop through the list of each coordinates. Set the coordinate
            % values of out.
            for k = 1:length(c)
                % Obtain the value of the coordinate from the internal
                % structure since you cannot reference out.(p{k}) in this
                % method. p{k} is not an actual property of out.
                name = c{k};
                values = self.pCoordinates.(name);
                
                % Loop through all the inputs, beginning at the second one.
                % out and inputs{1} are equal, so start at the second
                % index. Concatenate the values and then assign to the
                % internal structure.
                for m = 2:length(inputs)
                    shape = inputs{m};
                    values = [values shape.pCoordinates.(name)]; %#ok<AGROW>
                end
                out = setCoordinate(out, name, values);
            end
        end
        
        %------------------------------------------------------------------
        
        function out = vertcat_fields(self, inputs)
        % vertcat_fields overloaded method.
        %
        % Concatenate dynamic fields of
        % internal.map.DynamicShape object.

            % Initialize the output to self.
            out = self;
            
            % Loop through all the inputs. Copy the dynamic properties from
            % the input objects, inputs, to the output object, out.
            % currentIndex is the current element of out that values are
            % being copied to. By assigning the values using the
            % setDynamicProperty method, all the part separation and
            % casting of values will automatically be assigned correctly.
            % You cannot reference out.(f{k}) since these dynamic
            % properties are not real properties of the object.
            currentIndex = 0;
            for m = 1:numel(inputs)
                shape = inputs{m};
                f = fieldnames(shape);
                for index = 1:length(shape)
                    currentIndex = currentIndex + 1;
                    for k = 1:length(f)
                        prop = shape.pDynamicProperties.(f{k});
                        values = prop(index);
                        if iscell(values) && isscalar(values) && ~isVertexValue(prop)
                            values = values{:};
                        end
                        try
                            out = setDynamicProperty(out, currentIndex, f{k}, values);
                        catch e
                            error(message('map:DynamicVector:heterogeneousAssignment', class(self)));
                        end
                    end
                end
            end
        end
        
        %--------------------- utility methods ----------------------------
        
        function count = getCount(self)
        % Return the number of elements (count) the object contains.
        
            v = self.(self.Coordinates{1});
            if iscell(v) && isscalar(v) && isempty(v{1})
                count = 0;
            else
                count = length(v);
            end
        end
        
        %------------------------------------------------------------------
        
        function [S, labels] = convertToStructure(self)
        % convertToStructure overloaded method.
        %
        % Convert object to scalar structure
            
            % Create output and labels structure by invoking the super
            % class method. Assign constant properties to output structure.
            [S, labels] = convertToStructure@map.internal.DynamicVector(self);
            
            % Assign the vertex property header. If self is not empty and
            % has a length > 1, then add delimiter information.
            p = self.Coordinates;
            numDelimiters = length(self) - 1;
            vertexHeader = ' Vertex properties:';
            if numDelimiters >= 1
                delimiter = ' delimiters';
                if numDelimiters == 1
                    delimiter = delimiter(1:end-1);
                end
                catHeader = sprintf( ...
                    '  (%d features concatenated with %d%s%s',  ...
                    length(self), numDelimiters, delimiter, ')');
                vertexHeader = sprintf('%s\n%s', ...
                    vertexHeader, catHeader);
            end
                
            featureHeader = labels.(p{1});
            labels.(p{1}) = vertexHeader;
            
            % Assign coordinate properties to output structure.            
            for k = 1:numel(p)
                v = self.(p{k});
                try
                    v = cell2mat(v);
                catch e %#ok<NASGU>
                    % An internal error occurred. Rather than not
                    % displaying anything, just return the contents. A
                    % warning could be issued.
                end
                S.(p{k}) = v;
            end
            
            % Assign dynamic properties to output structure.
            f = fieldnames(self.pDynamicProperties);
            lenClassProps = length(builtin('properties',self));
            index = [true(lenClassProps, 1);false(size(f))];
            for k=1:numel(f)
                index(k + lenClassProps) = isVertexValue( ...
                    self.pDynamicProperties.(f{k}));
                S.(f{k}) = getDynamicProperty(self, f{k});
            end
            
            % Reorder the fields. Order the fields that are defined in the
            % class first, followed by vertex properties (isVertexValue is
            % true), followed by feature properties. index is true for
            % properties defined by the class and for vertex properties.
            f = fieldnames(S);
            orderedfields = [f(index); f(~index)];
            S = orderfields(S, orderedfields);
            labels = orderfields(labels, orderedfields);
            
            firstFeatureProp = find(~index, 1);
            if ~isempty(firstFeatureProp)
                labels.(f{firstFeatureProp}) = featureHeader;
            end
        end
        
        %--------------------- protected hidden methods -------------------
        
        function value = getCoordinate(self, name)
        % Get a coordinate values.
        
            value = self.pCoordinates.(name);
            value = addFeatureSeparator(value);
        end
    end
    
    methods (Access = private, Hidden = true)
        
        %------------------------------------------------------------------
       
        function self = setDynamicProperty(self, index, name, value)
        % Set a dynamic value. INDEX is the index values of the object. For
        % example, if a single feature is being set, then index is a scalar
        % value. NAME is the name of the dynamic property and VALUE is its
        % new value.
        %
        % This is a simple wrapper around subsasgn_dynamic_property.
        %
        % Example
        % self.Name = value
        
            % Use subsasgn_dynamic_property to make the assignment.
            s = struct('type', '()', 'subs', []);
            s.subs = {index};
            self = subsasgn_dynamic_property(self, s, value, name);
        end
                
        %------------------------------------------------------------------
        
        function value = getDynamicProperty(self, name)
        % Get a dynamic property value. NAME is the name of the property
        % value to return.
        %
        % This is a simple wrapper around subsref_dynamic_property.
        %
        % Example:
        % value = self.Name
            
            s = struct('type', '.', 'subs', name);
            numout = 1;
            value = subsref_dynamic_property(self, s, numout);
        end
       
        %------------------------------------------------------------------
        
        function self = replaceEmptyStringInProperties(self)
        % Replace empty '' in property values with a feature
        % separator.
            
            % Replace values in coordinate properties.
            coordinates = self.Coordinates;
            for k=1:numel(coordinates)
                name = coordinates{k};
                value = getProperty(self, name);
                value = replaceEmptyStringInCell(value);
                self = setProperty(self, name, value);
            end
            
            % Replace values in dynamic vertex properties.
            f = fieldnames(self.pDynamicProperties);
            for k=1:numel(f)
                dynamic = self.pDynamicProperties.(f{k});
                if isVertexValue(dynamic)
                    dynamic = replaceEmptyStringInCell(dynamic);
                    self.pDynamicProperties.(f{k}) = dynamic;
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function self = synchronizeProperties(self, original, propname)
        % Synchronize properties with each other.
            
            dynamic = self.pDynamicProperties.(propname);
            dynamic = replaceEmptyStringInCell(dynamic);
            dynamic = validateclass(dynamic, original, propname);
            
            % Synchronize coordinate properties.
            coordinates = self.Coordinates;
            for k=1:numel(coordinates)
                name = coordinates{k};
                value = getProperty(self, name);
                [value, dynamic2] = synchronizeDynamicProperty( ...
                    value, dynamic, original);
                self.pDynamicProperties.(propname) = dynamic2;
                self = setProperty(self, name, value);
            end
            
            % Synchronize dynamic properties.
            f = fieldnames(self.pDynamicProperties);
            propnames = setdiff(f, propname);
            self = synchronizeDynamicProperties( ...
                self, value, original, propnames);
        end
        
        %------------------------------------------------------------------
        
        function self = synchronizeDynamicProperties( ...
                self, propvalue, original, propnames)
        % Synchronize the dynamic vertex properties.
            
            % Loop through each property name. If the property value is a
            % vertex-valued property, then synchronize it using the vertex
            % rules.
            for k=1:numel(propnames)
                % Obtain the dynamic property value from the internal
                % structure.
                name = propnames{k};
                dynamic = self.pDynamicProperties.(name);
                
                % Determine if the property value follows vertex rules.
                if isVertexValue(dynamic)
                    % The dynamic array contains vertex values. However,
                    % new features may potentially be set to '' in the
                    % array. For char-valued dynamic properties, this
                    % value must be reset to {''}. Replace elements in the
                    % dynamic array that contain '' with {''}.
                    index = cellfun(@isEmptyString, dynamic);
                    if any(index)
                        if containsStrings(dynamic)
                            dynamic{index} = {''};
                        else
                            n = find(index);
                            type = classtype(dynamic);
                            if strcmp(type, 'double')
                                separator = 0;
                            else
                                value = cast([dynamic{index(n(1))}], type);
                                separator = featureSeparator(value);
                            end
                            [dynamic{index}] = deal(separator);
                        end
                    end
                    
                    % Using the vertex rules, synchronize the dynamic
                    % property and assign it back to the internal
                    % structure.
                    dynamic2 = synchronizeVertexProperty( ...
                        dynamic, propvalue, original);
                    self.pDynamicProperties.(name) = dynamic2;
                end
            end
        end
    end
end

%------------------------- private functions ------------------------------

function v = addFeatureSeparator(v)
% Add feature separators to the input V, if V is a non-scalar and non-empty
% cell array. Otherwise return V unchanged. In addition to a cell array, V
% can be a scalar or empty value (of any class).
%
% If V is a cell array, then append a feature separator to each element
% except the last one, according to the table listed below, and return the
% modified cell array. The size of V is unchanged; instead the length of
% each element of V, except the last, is increased by 1.
%
%    Element
%    Class          Separator
%    -----          ---------
%    single/double  NaN
%    other numeric  cast(0, class(v))
%    logical        false
%    ''             {''}
%    cellstr        {''}
%    all others     ''

if ~isscalar(v) && ~isempty(v)
    % For performance reasons, pre-determine the type of values (float,
    % integer, or logical) in the cell array. Cache the results and
    % continue only if needed. If the cell array contains chars or cell
    % arrays, then these cached logical values are all false. This
    % algorithm assumes that numeric or logical input is the most common.
    % The use of cellfun in this manner is a faster operation compared with
    % iscellstr.
    isFloatElement = cellfun(@isfloat, v);
    if ~all(isFloatElement)
        isIntegerElement = cellfun(@isinteger, v);
        tf = isFloatElement | isIntegerElement;
        if ~all(tf)
            isLogicalElement = cellfun(@islogical, v);
        else
            isLogicalElement = false(1, length(isFloatElement));
        end
    end
    
    % Loop through each element, except the last, and assign a feature
    % separator.
    for k=numel(v)-1:-1:1
        if isFloatElement(k)
            v{k} = [v{k} NaN];
        elseif isIntegerElement(k)
            n = v{k};
            v{k} = [n cast(0, class(n))];
        elseif isLogicalElement(k)
            v{k} = [v{k} false];
        elseif isempty(v{k}) && ischar(v{k})
            % The empty char needs to be converted to cell value.
            v{k} = [{''} {''}];
        elseif iscellstr(v{k})
            v{k} = [v{k} {''}];
        else
            v{k} = [v{k} ''];
        end
    end
end
end

%--------------------------------------------------------------------------

function vout = catDynamicProperty(values)

if ~isempty(values) && iscell(values) && iscell(values{1})
    v = values{1};
    if ~ischar(v{1})
        % Extract the contents of the cell array if the values are all
        % logical or numeric or a character vector.
        v = addFeatureSeparator(v);
        type = classtype(v);
        if strcmp('cell',type)
            % cat the cell contents.
            vout{1} = cat(2,v{:});
        else
            % Convert the numeric or logical contents of the cell array to
            % a vector.
            vout{1} = cell2mat(v);
        end
    elseif isscalar(v)
        % v{1} is a char, return char rather than a cell.
        vout{1} = v{1};
    else
        % v{1} is a cellstr, return values
        vout = values;
    end
else
    vout = values;
end
end

%--------------------------------------------------------------------------

function c =  synchronizeVertexProperty(c, template, original)
% Synchronize cell contents, c, with the template. Use original to
% determine how the template has changed from the original. It is assumed
% that c and template match in size and that all inputs are cell arrays.

lenC = length(c);
lenT = length(template);
lenO = length(original);
classname = classtype(c);

if lenC == lenT && iscell(c) && iscell(template) && iscell(original)
    if isempty(template)
        c = {};
        indices = [];
        
    elseif isempty(original)
        indices = 1:lenT;
        
    elseif lenT > lenO
        if isequal(template(1:lenO), original)
            % Case 1: length template > length original and template
            % matches original
            % In this case, there is no reason to examine the elements that
            % are less than or equal to the length of template.
            indices = lenO + 1:lenT;
        else
            % Case 2: length template > length original and template does
            % not match original
            indices = findNonMatchingElements(template(1:lenO), original);
            indices = [indices lenO+1:lenT];
        end
        
    else 
        % lenT <= lenO
        % Case 2: length template <= length original
        % In this case, only examine the elements that have changed.
        indices = findNonMatchingElements(template, original(1:lenT));
    end
    
    for k=1:numel(indices)
        index = indices(k);
        value = synchronizeElement(c{index}, template{index});
        if ischar(classname) && ~any(strcmp(classname, {'cell','char'}))
            c{index} = cast(value, classname);
        else
            c{index} = value;
        end
    end
end
end

%--------------------------------------------------------------------------

function [coordinate, dynamic] =  synchronizeDynamicProperty( ...
    coordinate, dynamic, original)
% Synchronize cell contents, c, with the template. Use original to
% determine how the template has changed from the original. It is assumed
% that c and template match in size and that all inputs are cell arrays.

lenC = length(coordinate);
lenD = length(dynamic);
lenO = length(original);

if lenC == lenD && iscell(coordinate) && iscell(dynamic) && ~isempty(dynamic)
    
    dynamic = replaceEmptyStringWithEmptyCellStr(dynamic);
    
    if isempty(coordinate)
        for k=1:lenD
            coordinate{k} = synchronizeElement(coordinate{k}, dynamic{k});
        end
    elseif isempty(original)
        for k=1:lenD
            if length(dynamic{k}) <= length(coordinate{k})
                dynamic{k} = synchronizeElement(dynamic{k}, coordinate{k});
            else
                coordinate{k} = synchronizeElement(coordinate{k}, dynamic{k});
            end
        end
        
    elseif lenD > lenO
        if isequal(dynamic(1:lenO), original)
            % length template > length original and template matches
            % original
            %
            % In this case, there is no reason to examine the elements that
            % are less than or equal to the length of template.
            for k = lenO + 1:lenD
                coordinate{k} = synchronizeElement(coordinate{k}, dynamic{k});
            end
        else
            % length template > length original and template does
            % not match original
            indices = findNonMatchingElements(dynamic(1:lenO), original);
            for k=1:numel(indices)
                index = indices(k);
                coordinate{index} = ...
                    synchronizeElement(coordinate{index}, dynamic{index});
            end
            for k = lenO + 1:lenD
                coordinate{k} = synchronizeElement(coordinate{k}, dynamic{k});
            end
        end
        
    else 
        % lenT <= lenO (length template <= length original).
        % In this case, only examine the elements that have changed.
        indices = findNonMatchingElements(dynamic, original(1:lenD));
        for k=1:numel(indices)
            index = indices(k);
            if (length(coordinate{index}) > length(dynamic{index}))
                dynamic{index} = ...
                    synchronizeElement(dynamic{index}, coordinate{index});
            else
                coordinate{index} = ...
                    synchronizeElement(coordinate{index}, dynamic{index});
            end
        end
    end
end
end

%--------------------------------------------------------------------------

function indices = findNonMatchingElements(c1, c2)
% Find non matching elements in cell arrays, c1 and c2. The inputs, c1, and
% c2, are expected to be cell arrays.

indices = find(~cellfun(@isequal, c1, c2));
end

%--------------------------------------------------------------------------

function c = synchronizeElement(c, template)
% Synchronize the cell array, c, with the template, template.

c = adjustCellValue(c, length(template));
end

%--------------------------------------------------------------------------

function c = synchronizeNaNLocations(c, template)
% Synchronize the NaN locations in the input arrays. The locations of the
% NaN values in the template are synchronized to the locations in c. If c
% has NaN values, they are initially reset to 0s. The return value contains
% NaN locations at the same location as template.
%
% It is assumed that the input arrays are numeric and match in size and
% each element matches in length. This function is used to synchronize NaN
% locations in coordinate arrays, not dynamic property arrays.

for k=1:length(c)
    % Unset NaN locations in input c.
    element = c{k};
    element(isnan(element)) = 0;
    
    % Set NaN locations in input c to match NaN locations in template.
    element(isnan(template{k})) = NaN;
    c{k} = element;
end
end

%--------------------------------------------------------------------------

function value = adjustCellValue(value, newlen)
% Adjust VALUE to be length NEWLEN. If NEWLEN is greater than the length of
% VALUE, then expand it using the expansion value, EXPANDVAL.

if isempty(value)
    if ischar(value)
        value = 0;
    elseif isnumeric(value)
        value = cast(0, class(value));
    end
end

expandval = expandCellValue(value);
oldlen = numel(value);
if newlen == 0
    value = [];
elseif newlen < oldlen
    value(newlen+1:end) = [];
elseif newlen > oldlen
    value(end+1:end+newlen-oldlen) = expandval;
end
end

%--------------------------------------------------------------------------

function value = expandCellValue(in)
% Create a value, based on class type of IN, to be used for expanding
% arrays.

if isnumeric(in)
    value = cast(0, class(in));
elseif islogical(in)
    value = false;
else
    value = {''};
end
end

%--------------------------------------------------------------------------

function v = replaceEmptyStringInCell(v)
% If V is a cell array containing '' values, then replace them with numeric
% [] values.

if iscell(v)
    % Replace '' with numeric [].
    index = cellfun(@(x) (ischar(x) && isempty(x)),v);
    v(index) = featureExpander(v);
end
end

%--------------------------------------------------------------------------

function c  = replaceEmptyStringWithEmptyCellStr(c)
% Replace empty '' in cell array with empty cellstr:
% replace { ...'' ... } with { ... {''} ...}

if iscell(c) && any(cellfun(@iscellstr, c))
    % Replace  '' with  {''}.
    index = cellfun(@(x) (ischar(x) && isempty(x)), c);
    c(index) = {{''}};
end
end

%--------------------------------------------------------------------------

function c = replaceEmptyWithZeros(c)
% If c is a non-scalar cell array, with at least one non-char value,
% and it contains empty values, then replace those values with 0s.

if iscell(c) && ~isscalar(c) && ~iscellstr(c) %#ok<ISCLSTR>
    % Replace empty with 0s.
    index = cellfun(@isValidEmpty, c);
    c(index) = {0};
end
end

%--------------------------------------------------------------------------

function c = recastEmptyInEmptyCell(type, usingVertexRules)
% Create an output value that matches the input class type, specified by
% the character vector, TYPE.

if strcmp(type, 'char') || strcmp(type, 'cell') || iscell(type)
    if usingVertexRules
        c = {{''}};
    else
        c = {''};
    end
else
    % Cast 0 to the input type.
    % Use a numeric 0 rather than [] since the super class
    % method replaces [] with '' and the new value needs to
    % be synchronized.
    c = {cast(0, type)};
end
end
            
%--------------------------------------------------------------------------

function value = featureExpander(in)
% Create a value, based on class type of IN, to be used for expanding
% arrays.

type = classtype(in);
if ischar(type) && ~any(strcmp(type, {'cell', 'char'}))
    value = {cast(0, type)};
else
    value = {''};
end
end

%--------------------------------------------------------------------------

function value = featureSeparator(value)
% Determine the feature separator.

if isnumeric(value)
    if isinteger(value)
        value = cast(0,class(value));
    else
        value = NaN;
    end
elseif islogical(value)
    value = false;
else
    value = '';
end
end

%--------------------------------------------------------------------------

function tf = isVertexValue(value)
% Return true if value is a vertex value.

% True if value:
%  value = {numeric values}
%  value = {logical values}
%  value = { {values} {values} }  
%  value = {string values}
tf = iscell(value) && ~isempty(value) && ...
    (isnumeric(value{1}) || islogical(value{1}) || iscell(value{1}) ...
    || isstring(value{1}));
end

%--------------------------------------------------------------------------

function value = validateclass(value, original, propname)
% Validate the class type of value.

valueType = classtype(value);
if iscell(valueType) && ~isscalar(unique(valueType)) 
    % Obtain the class type of the original values.
    originalType = classtype(original);

    % Find the class types that are not the same.
    valueTypes = setdiff(valueType, originalType);
    
    % Cast the values, using standard MATLAB rules.
    s = struct('type','()', 'subs', []);
    typeIndex = find(strcmp(originalType, {'logical', 'char', 'cell'}));
    for k = 1:length(valueTypes)
        index = find(cellfun(@(x)(isa(x, valueTypes{k})), value));
        for m = 1:length(index)
            v = value{index(m)};
            if isempty(typeIndex)
                subsValue = zeros(size(v), originalType);
            elseif typeIndex == 1
                subsValue = false(size(v));
            else
                subsValue = char(zeros(size(v)));
                if typeIndex == 3
                    if ~isempty(original)
                        error(message('map:DynamicShape:mixedDataTypes', propname))
                    else
                        % original is empty, but value is of mixed type
                        % (cell)
                        % subsValue = v; (this causes mixed type in cell)
                        % Make sure value contains all numeric values
                        type = lowestType(valueTypes);
                        if isempty(type)
                            error(message('map:DynamicShape:mixedDataTypes', propname))
                        else
                            subsValue = zeros(size(v), type);
                        end
                        
                    end
                end
            end
            s.subs = {1:length(subsValue)};
            v = builtin('subsasgn', subsValue, s, v);
            value{index(m)} = v;
            value = replaceEmptyStringInCell(value);
        end
    end
end
end

%--------------------------------------------------------------------------

function x = validatecoordinates(x, classname, propname)
% Validate X as a single or double vector. If X is not a row vector, then
% transpose it.

% Input X must be class single or double, and either empty or a vector.
% For speed and efficiency, use logicals to validate input.
attributes = {'single','double'};
if any(strcmp(class(x), attributes)) && (isempty(x) || isvector(x))
    if ~isrow(x)
        x = x';
    end
else
    % The input is not valid. Issue an error using validateattributes.
    validateattributes(x, attributes, {'vector'}, classname, propname)
end
end

%--------------------------------------------------------------------------

function x = validateVertexValues(x)
% Validate X as numeric or logical vector or an empty scalar. 

% Input X must be numeric or logical and either empty or a vector.
isValid = (isnumeric(x) || islogical(x)) && (isempty(x) || isvector(x));
if ~isValid
    % The input is not valid. Issue an error.
    error(message('map:DynamicVector:badCellTypes'))
end

end

%--------------------------------------------------------------------------

function type = classtype(value)
% Return the class type of value.

if ~iscell(value) || iscell(value) && isempty(value)
    type = class(value);
else
    
    type = unique(cellfun(@class, value, 'UniformOutput',false));
    if ~isscalar(type)
        % Ignore empty
        v = cellfun(@isValidEmpty, value, 'UniformOutput', false);
        value(cell2mat(v)) = [];
        if ~isempty(value)
            type = unique(cellfun(@class, value, 'UniformOutput',false));
        else
            type = class([]);
        end
    end
    
    if iscell(type) && isscalar(type)
        type = type{:};
    end
end
end

%--------------------------------------------------------------------------

function tf = containsStrings(c)
% Return true if the cell array, c, contains cell arrays of cellstr, or
% character vector.

fcn = @(x) (iscellstr(x) || ischar(x)); %#ok<ISCLSTR>
tf = all(cellfun(fcn, c));
end

%--------------------------------------------------------------------------

function tf = isEmptyString(x)
% Return true if x is ''.

tf = ischar(x) && isempty(x);
end

%--------------------------------------------------------------------------

function x = castCoordinateInput(x, propArray)
% Cast the input array, X, based on the class type of the inputs.
%
% Up-cast X to class double if the class of X is single and the class of
% propArray is double. This is equivalent to how MATLAB behaves when
% inserting a value of class single into an array of class double.
%    propArray = 1:3; 
%    x = single(2);
%    propArray(2) = x; 
%    class(propArray) returns double
% 
% Downcast X to class single if the class of X is double and the class of
% propArray is single. This is equivalent to how MATLAB behaves when
% inserting a value of class double into an array of class single.
%    propArray = single(1:3); 
%    x = 2; % (double)
%    propArray(2) = x; 
%    class(propArray) returns single

propClass = classtype(propArray);
inputClass = classtype(x);

if isempty(propArray) && ischar(inputClass)
    propClass = inputClass;
end
if iscell(inputClass)
    % input is mixed single and double, cast to class of
    % property array.
    if strcmp(propClass, 'single')
        fcn = @single;
    elseif strcmp(propClass, 'double')
        fcn = @double;
    else
        % Property array is not defined yet. When MATLAB
        % concatenates an array with mixed type:
        % [single(1:3) double(1:3)], the class type is single.
        fcn = @single;
    end
    x = cellfun(fcn, x, 'UniformOutput', false);
    
elseif strcmp(inputClass, 'single') && strcmp(propClass, 'double')
    % propArray is class double:
    % d = 1:3; d(2) = single(2); class(d) returns double
    x = cellfun(@double, x, 'UniformOutput', false);
    
elseif strcmp(inputClass, 'double') && strcmp(propClass, 'single')
    % propArray is class single:
    % s = single(1:3); s(2) = 2; class(s) returns single
    x = cellfun(@single, x, 'UniformOutput', false);
end
end

%--------------------------------------------------------------------------

function type = lowestType(types)
% Return the lowest class type.

datatypes = { ...
    'uint8',  'int8', ...
    'uint16', 'int16', ...
    'uint32', 'int32', ...
    'uint64', 'int64', ...
    'single', 'double'};
index = length(datatypes);
for k=1:numel(types)
    newIndex = find(strcmp(types{k}, datatypes));
    index = min(index, newIndex);
end

if ~isempty(index)
    type = datatypes{index};
else
    type = '';
end 
end

%--------------------------------------------------------------------------

function [nansInCell, arraysMatch, maxLength] = findNansInCells(coordinates)
% Create a logical index indicating the locations of the NaN values in the
% coordinates cell array. Return true for arraysMatch if the NaN locations
% match and if the length of each element in the coordinate cell arrays
% match. maxLength is the maximum length of any element in coordinates.

coordLength = zeros(size(coordinates));
numCoords = length(coordinates);
cellLength = cell(1, numCoords);
lengthsMatch = true;
nansInCell = cell(1, numCoords);
nansMatch = true;

for k=1:length(coordinates)
    coordLength(k) = length(coordinates{k});
    cellLength{k} = cellfun(@length,  coordinates{k});
    nansInCell{k} = cellfun(@isNanIndex, coordinates{k}, ...
        'UniformOutput', false);
    if k > 1
        if ~isequal(cellLength{k}, cellLength{k-1})
            lengthsMatch = false;
        end
        
        if ~isequal(nansInCell{k}, nansInCell{k-1})
            nansMatch  = false;
        end
    end
end

maxLength = max(coordLength);
arraysMatch = lengthsMatch && nansMatch;
end

%--------------------------------------------------------------------------

function c = extractCoordinates(coordinates, nansInCell, k)
% Extract the k'th coordinates from the cell array, coordinates. Match the
% NaN locations if they do not match.

numCoords = length(coordinates);
nansMatch = true;

c = cell(1, numCoords);
for m = 1:numCoords
    if length(coordinates{m}) >= k
        values = coordinates{m};
        c{m} = values{k};
    else
        c{m} = {};
        nansInCell{m}{k} = false;
    end
    if m > 1 && ~isequal(nansInCell{m}{k}, nansInCell{m-1}{k})
        nansMatch = false;
    end
end

if ~nansMatch
    c = matchNansInCells(c);
end
end
                    
%--------------------------------------------------------------------------

function index = isNanIndex(value)
% Return a logical array the same size as VALUE and assign true to each
% element that contains a NaN. VALUE may be a non-numeric array.

index = false(size(value));
if all(isnumeric(value))
    index = isnan(value);
end
end

%--------------------------------------------------------------------------

function c = matchNansInCells(c)
% Match the NaN values in the cell array, C. C is a cell array with a
% length that matches the number of coordinates of the class. Each element
% may contain a vector of numbers. In addition, the cell array is not
% validated, so it may contain non-numeric values.
%
% The longest element is matched in NaN locations with all the other
% shorter elements. If each element is of equal length, then the last one
% is adjusted. This is because the last coordinate, when set, overrides the
% NaN locations of the other coordinates.

% Find all the NaN locations in the input cell array. 
nansInCell = cellfun(@isNanIndex, c, 'UniformOutput', false);

% Find the length of each element.
cellLength = cellfun(@length,  c);

% Use the longest element. Make sure to use the last one found if the
% lengths are equal, since it is set last and will override the NaN
% locations of other coordinates.
maxIndex = find(max(cellLength) == cellLength, 1, 'last');

% Set the locations in the longest element to NaN if the other elements
% contain a NaN value. Guard against setting non-numeric values by wrapping
% the set with if ~isempty.
v = c{maxIndex};
for k=1:length(c)
    if ~isempty(v(nansInCell{k}))
        v(nansInCell{k}) = NaN;
    end
end

% Reset the longest element.
c{maxIndex} = v;
end

%--------------------------------------------------------------------------

function tf = isValidEmpty(v)
% return true if V is empty and is numeric, char, or a cell.

tf = isempty(v) && (isnumeric(v) || ischar(v) || iscell(v) || isstring(v));
end

%--------------------------------------------------------------------------

function in = convertStringCellsToCharCells(in)
% Convert string-valued elements in cell array to char vector.

for k = 1:length(in)
    if iscell(in(k))
        out = cellfun(@convertStringsToChars, in{k}, 'UniformOutput', false);
        in(k) = {out};
    end
end
end

%--------------------------------------------------------------------------

function out = transposeElement(in)
% Transpose element ensuring that empty does not become 0-by-1 or 1-by-0.

if ~isempty(in)
    out = in(:)';
else
    out = in;
end
end

%  In order for method help to work properly for subclasses, this classdef
%  file cannot have a comment block at the top, so the following remark and
%  copyright/version information are provided here at the end. Please do
%  not move them.

%  FOR INTERNAL USE ONLY -- This class is intentionally undocumented
%  and is intended for use only within other toolbox classes and
%  functions. Its behavior may change, or the class itself may be
%  removed in a future release.

% Copyright 2012-2017 The MathWorks, Inc.
