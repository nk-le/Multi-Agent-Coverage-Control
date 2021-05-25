classdef DynamicVector
        
    properties (Access = public)
        %Geometry - Type of geometry
        %
        %   Geometry is a character vector or scalar string defining the
        %   type of geometry.
        Geometry = 'point'
        
        %Metadata - Scalar structure containing metadata
        %
        %   Metadata is a scalar structure containing information for the
        %   entire set of properties. Any type of data may be added to the
        %   structure.
        Metadata = struct
    end
    
    properties (Access = private,  Dependent = true, Hidden = true)
        %DynamicProperties - Structure containing dynamic fields
        %
        %   DynamicProperties is a structure containing the dynamic fields
        %   that once set, act as properties of the class.
        DynamicProperties
    end
    
    properties (Access = protected, Hidden = true)
        %Coordinates - Names of coordinate properties
        %
        %   Coordinates is a cell array containing the names of the
        %   coordinate properties.
        Coordinates
        
        %ConstantProperties - Names of non-coordinate properties
        %
        %   ConstantProperties is a cell array containing the names of the
        %   properties of the class that are not coordinate properties.
        %   These properties are scalar and do not change in size.
        ConstantProperties
        
        %NoAnsMethods - Names of non-ans methods
        %
        %    NoAnsMethods is a cell array containing the names of the
        %    methods that require either nargout to be 0 or that do not set
        %    ans.
        NoAnsMethods = {'disp'}
    end
    
    properties(Access = protected)
        % Private properties containing storage for the dependent
        % properties.
        pCoordinates = struct()
        pDynamicProperties = struct()
    end
    
    methods  
        
        function self = DynamicVector(coordinates, varargin)
       
            self.Coordinates = coordinates;
            self = setCoordinates(self, []);
            
            % Assign the constant properties, those properties of self that
            % are not coordinate properties.
            self.ConstantProperties = setdiff( ...
                properties(class(self)), self.Coordinates,'legacy');
            
            % Construct the object.
            try
                [varargin{:}] = convertStringsToChars(varargin{:});
                self = constructObject(self, varargin{:});
            catch e
                 % throw the exception as the caller in order to have it
                 % issue Error using classname rather than 
                 % Error using struct or 
                 % Error using map.internal.DynamicVector
                throwAsCaller(e);
            end            
        end
        
        %---------------------- set methods -------------------------------
        
        function self = set.Geometry(self, value)
        % Set Geometry property value.
            
            if iscell(value)
                if isscalar(unique(value,'legacy'))
                    value = value{1};
                end
            end
            
            value = validateGeometry(self, value);
            self.Geometry = value;          
        end
    
        %------------------------------------------------------------------
        
        function self = set.Metadata(self, value)
        % Set Metadata property.
        
            validateattributes(value, {'struct'}, {'scalar'}, class(self),'Metadata');
            self.Metadata = value;           
        end
        
        %------------------------------------------------------------------
        
        function self = set.DynamicProperties(self, value)
        % Assign the private property, pDynamicProperty, to value.
        % value is validated by the constructor and does not need to be
        % validated since DynamicProperty is not a public property.
            
            % Assign the private property to the value.
            self.pDynamicProperties = value;
            
            % Determine if the properties need to be adjusted so that all
            % lengths match. First determine the length of all fields.
            % Find the maximum number of elements by calculating the
            % maximum number of values in each field of the structure with
            % the maximum number of elements in the first coordinate
            % property (obtained from self.getCount).
            fieldlen = structfun(@(x)(length(x)), self.pDynamicProperties);
            lengths = [self.getCount(), fieldlen(:)'];
            if ~all(lengths(1) == lengths)
                % All the lengths do not match, adjust the properties.
                kmax = max(lengths);
                self = adjustProperty(self,   kmax, 'pDynamicProperties');
                self = adjustProperties(self, kmax, 'DynamicProperties');
            end
        end
        
        %---------------------- get methods -------------------------------
        
        function value = get.DynamicProperties(self)
        % Return DynamicProperties structure.
            value = self.pDynamicProperties;
        end
        
        %-------------------- Overloaded methods --------------------------
        
        function disp(self)
        %DISP Display dynamic vector
        %
        %   disp(V) prints the size of the dynamic vector, V, and its
        %   properties and dynamic properties (if present). If the command
        %   window is large enough, the values of the properties are also
        %   shown, otherwise only their size is shown. You can control the
        %   display of the numeric values by using the format command.
        %
        %   See also format, map.internal.DynamicVector.
            
            % Construct the display and label structures.
            [S, labels] = convertToStructure(self);
                      
            % If the desktop is in use, then add a clickable hyperlink 
            % in the first line.
            firstLine = getFirstLine(class(self), length(self));
            
            % Print the lines.
            printLines(S, labels, firstLine);
        end
        
        %------------------------------------------------------------------
        
        function out = length(self)
        %LENGTH Number of elements in dynamic vector
        %
        %   N = length(V) returns the number of elements contained in the
        %   dynamic vector, V. The result is equivalent to size(V, 1).
        %
        %   See also map.internal.DynamicVector/size.
            
            out = self.getCount();
        end
        
        %------------------------------------------------------------------
        
        function out = isempty(self)
        %ISEMPTY True if dynamic vector is empty
        %
        %   TF = isempty(V) returns true if the dynamic vector, V, is
        %   empty and false otherwise.
           
            out = self.getCount() == 0;
        end
        
        %------------------------------------------------------------------ 
        
        function varargout = size(self, varargin)
        %SIZE Size of dynamic vector
        %
        %   SZ = size(V) returns the vector [length(V), 1].
        %
        %   SZ = size(V, 1) returns the length of V.
        %
        %   SZ = size(V, N), for N >= 2, returns 1.
        %
        %   [M, N] = size(V) returns length(V) for M and 1 for N.
        %
        %   See also map.internal.DynamicVector/length, size.
            
             try
                 % Use the builtin function to validate the inputs and
                 % outputs.
                 switch nargout
                     case 0
                         % size(obj)       :  ans = [self.getCount 1]
                         % size(obj, 1)    :  ans = self.getCount
                         % size(obj, 2)    :  ans = 1
                         % size(obj, d > 2):  ans = 1                         
                         [varargout{1:nargout}] = ...
                             builtin('size', self, varargin{:});
                         if isempty(varargin)
                             % size(obj)
                             varargout{1}(1) = self.getCount();
                         elseif numel(varargin) == 1 && varargin{1} ~= 1
                             % size(obj, 2), size(obj,n) n~=1 = 1
                             varargout{1} = 1;                             
                         else
                             % size(obj, 1)
                             varargout{1} = self.getCount();
                         end

                     case 1
                         % D = size(obj)       :  D = [self.getCount, 1]
                         % n = size(obj, 1)    :  n = self.getCount
                         % m = size(obj, 2)    :  m = 1
                         % p = size(obj, d > 2):  p = 1
                         n = builtin('size', self, varargin{:});
                         if isempty(varargin)
                             % D = size(obj);
                             varargout{1} = [self.getCount, 1];                             
                         elseif numel(varargin) == 1 && varargin{1} ~= 1
                             % m = size(obj, 2);                            
                             % p = size(obj, d > 3);
                            varargout{1} = n;
                         else
                             % n = size(obj, 1);
                              varargout{1} = self.getCount;                             
                         end
                         
                     case 2
                         % [n, m] = size(obj);
                         % [n, m] = size(obj, d) --> issues error
                         [n, ~] = builtin('size', self, varargin{:});
                         varargout{1} = self.getCount();
                         varargout{2} = n;
                         
                     otherwise
                         % [n, m, p, ...] = size(obj)
                         % [n, m, p, ...] = size(obj, d) ---> issues error
                         %  p, ... are always 1
                         [n, ~, varargout{3:nargout}] = ...
                             builtin('size', self, varargin{:});
                         varargout{1} = self.getCount();
                         varargout{2} = n; 
                 end                 
             catch e
                 % throwAsCaller(e) in order to prevent the line:
                 % Error using map.internal.DynamicVector/size. Issue only
                 % the error message.
                 throwAsCaller(e);
             end
        end
        
        %------------------------------------------------------------------
        
        function S = struct(self, varargin)
        %STRUCT Convert dynamic vector to scalar structure
        %
        %   S = struct(V) converts the dynamic vector, V, to a scalar
        %   structure, S.
        %
        %   See also map.internal.DynamicVector/properties.
            
            if ~isempty(varargin)
                % struct('name', value, 'name2', map.internal.DynamicVector)
                S = builtin('struct',self, varargin{:});
            else
                % Convert dynamic vector to a structure.
                S = convertToStructure(self);
            end
        end
        
        %------------------------------------------------------------------
        
        function self = rmfield(self, names)
        %RMFIELD Remove dynamic properties from dynamic vector
        %
        %   V = rmfield(V, FIELDNAME) removes the field specified by the
        %   character vector or scalar string, FIELDNAME, from the dynamic
        %   vector, V.
        %
        %   V = rmfield(V, FIELDS) removes all the fields specified in the
        %   string or cell array, FIELDS.
        %
        %   See also map.internal.DynamicVector/fieldnames, map.internal.DynamicVector/rmprop.
        
            % Only remove fields, ignore other values.
            names = convertStringsToCellstr(names);
            names = unique(names,'legacy');
            names(~isfield(self, names)) = [];
            self = rmprop(self, names);     
        end
 
        %------------------------------------------------------------------
        
        function self = rmprop(self, names)
        %RMPROP Remove properties from dynamic vector
        %
        %   V = rmprop(V, PROPNAME) removes the property specified by the
        %   character vector or scalar string, PROPNAME, from the dynamic
        %   vector, V.
        %
        %   V = rmprop(V, PROPNAMES) removes all the properties specified
        %   in the string or cell array, PROPNAMES, from the dynamic
        %   vector, V. If PROPNAMES contains a coordinate property an error
        %   is issued.
        %
        %   See also map.internal.DynamicVector/fieldnames, map.internal.DynamicVector/rmprop.
   
            try
                validateattributes(names, {'char', 'cell', 'string'}, {},  ...
                    'rmprop', 'PROPNAME');
            catch e
                throwAsCaller(e);
            end
                        
            % Remove entries that are not string or character vector and
            % not unique.
            names = convertStringsToCellstr(names);
            names = unique(names,'legacy');
            names(~cellfun(@ischar, names)) = [];
            
            % Remove entries that are not properties.
            names(~cellfun(@(x) isprop(self, x), names)) = [];
            
            % Issue error if requesting any standard property name. 
            standardProps = setdiff(properties(self), fieldnames(self),'legacy');
            members = cellcmp(standardProps, names);
            if any(members)
                % Issue error.
                propnames = sprintf('''%s'', ', standardProps{1:end-1});
                p = sprintf('%s''%s''', propnames, standardProps{end});
                try
                    error(message('map:DynamicVector:propertyRemovalNotPermitted', p))
                catch e
                    throwAsCaller(e);
                end
            else
                % Remove the names from the dynamic properties structure.
                self.pDynamicProperties = ...
                    rmfield(self.pDynamicProperties, names);
            end
        end
        
        %------------------------------------------------------------------
        
        function out = cat(dim,varargin)
        %CAT Concatenate dynamic vectors
        %
        %   V = cat(DIM, V1, V2, ...) concatenates the dynamic vectors, V1,
        %   V2, ... along dimension DIM. DIM must be 1.
        %
        %   See also map.internal.DynamicVector/vertcat.
            
            try
                narginchk(2, inf)
                validateattributes(dim, {'numeric'}, ...
                    {'nonempty', 'finite', 'integer'}, ...
                    class(varargin{1}), 'DIM');
                if dim ~= 1
                    error(message('map:DynamicVector:badCatDim'));
                end
            catch e
                throwAsCaller(e);
            end
            out = vertcat(varargin{:});
        end
               
        %------------------------------------------------------------------
        
        function out = vertcat(self, varargin)
        %VERTCAT Vertical concatenation for dynamic vectors
        %
        %   V = vertcat(V1, V2, ...) vertically concatenates the dynamic
        %   vector, V1, V2, ... . If the class type of any property is a
        %   cell array, then the resultant field in the output V will also
        %   be a cell array.
        %
        %   See also map.internal.DynamicVector/cat.
            
            try
                if ~all(cellfun(@(x) isa(x, class(self)), varargin))
                    error(message('map:DynamicVector:badCatTypes',  ...
                        class(self)));
                end
                
                % Eliminate empty values.
                inputs = [{self} varargin];
                inputs(cellfun(@isempty, inputs)) = [];
                if isempty(inputs)
                    out = self;
                elseif isscalar(inputs)
                    out = inputs{1};
                else
                    % inputs has been updated, update self.
                    self = inputs{1};
                    % cat the coordinates.
                    out = vertcat_coordinates(self, inputs);
                    
                    % cat the fields.
                    out = vertcat_fields(out, inputs);
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        %------------------------------------------------------------------
        
        function varargout = properties(self)
        %PROPERTIES Properties of dynamic vector
        %
        %   P = properties(V) returns a cell of the property names of the
        %   dynamic vector, V.
        %
        %   properties(V) displays the names of the properties of V.
        %
        %   See also map.internal.DynamicVector/fieldnames.
        
            p = [self.ConstantProperties'; self.Coordinates'; ...
                fieldnames(self.DynamicProperties)];
            if nargout == 0
                fprintf('\nProperties for class %s:\n\n', class(self))
                for k = 1:numel(p)
                    fprintf('    %s\n', p{k});
                end
                fprintf('\n');
            else
                varargout{1} = p;
            end
        end
        
        %------------------------------------------------------------------
        
        function names = fieldnames(self)
        %FIELDNAMES Dynamic properties of dynamic vector
        %
        %   NAMES = fieldnames(V) returns the names of the dynamic
        %   properties of the dynamic vector, V.
        %
        %   See also map.internal.DynamicVector/properties.
        
            names = fieldnames(self.DynamicProperties);
        end

        %------------------------------------------------------------------
        
        function tf = isprop(self, name)
        %ISPROP Returns true if property exists
        %
        %   TF = isprop(V, NAME) returns true if the value specified by the
        %   character vector or scalar string, NAME, is a property of the
        %   dynamic vector, V.
        %
        %   TF = isprop(V, NAMES) returns true for each element of the cell
        %   or string array, NAMES, that is a property of V. TF is a
        %   logical array the same size as NAMES.
        %
        %   See also map.internal.DynamicVector/isfield, map.internal.DynamicVector/properties.
        
            p = self.properties();
            tf = cellcmp(name, p);
        end

        %------------------------------------------------------------------
        
        function tf = isfield(self, name)
        %ISFIELD Returns true if dynamic property exists
        %
        %   TF = isfield(V, NAME) returns true if the value specified by
        %   the character vector or scalar string, NAME, is a dynamic
        %   property of the dynamic vector, V.
        %
        %   TF = isfield(V, NAME) returns true for each element of the cell
        %   or string array, NAMES, that is a dynamic property of V. TF is
        %   a logical array the same size as NAMES.
        %
        %   See also map.internal.DynamicVector/isprop, map.internal.DynamicVector/fieldnames.
        
            p = self.fieldnames();
            tf = cellcmp(name, p);
        end
        
    end
    
    %----------------------- Public Hidden methods ------------------------
    
    methods (Hidden = true)
        
        function n = numel(varargin)
        %NUMEL Returns "numel" value for dynamic vector
        %
        %   N = numel(V) returns 1 for any dynamic vector V, since a
        %   dynamic vector is always a scalar object. To find the number of
        %   elements in V, use length(V).
        %
        %   See also map.internal.DynamicVector/length.
        
           % numel must be overloaded to prevent errors from being issued
           % when MATLAB calls subsref given incorrect inputs. For
           % example: obj{1,{'NAME'}} issues a numel error if it is not
           % overloaded. The object is scalar and always contains only one
           % element.
            n = 1;
        end
        
        %------------------------------------------------------------------
        
        function ind = end(self, varargin)
        %END Last index in indexing expression for dynamic vector
        %
        %   end(V,K,N) is called for indexing expressions involving the
        %   dynamic vector V when END is part of the K-th index out of N
        %   indices. For example, the expression V(end-1,:) calls the
        %   dynamic vector's END method with END(V,1,2).
        %
        %   See also end, map.internal.DynamicVector/isempty, map.internal.DynamicVector/size.
        
            if isempty(varargin) || varargin{1} == 1
                ind = self.getCount();
            else
                ind = 1;
            end                
        end
        
        %------------------------------------------------------------------
        
        function varargout = subsref(self,s)
        %SUBSREF Subscripted reference for dynamic vector
        %
        %   B = subsref(V, S) is called for the syntax V(k), or
        %   V.PropertyName, where V is a dynamic vector. S is a structure
        %   with the fields:
        %
        %      type -- character vector containing '()', '{}', or '.'
        %              specifying the subscript type.
        %      subs -- cell array or string containing actual subscripts.
        %
        %   V2 = V(K) returns a copy, V2, of the K-th element of V.
        %   V2 itself is a dynamic vector.
        %
        %   VALUES = V.PropertyName returns the values in the property
        %   'PropertyName'.
        %
        %   VALUES = V(N:M).PropertyName returns the N:M values of
        %   V.PropertyName.
        %
        %   See also map.internal.DynamicVector/subsasgn.

            try
                % Validate inputs.
                if isscalar(s) && iscell(s.subs)
                    s.subs = convertStringCellToChars(s.subs);
                else
                    for k = 1:length(s)
                        s(k).subs = convertStringsToChars(s(k).subs);
                    end
                end
                validatesubsref(self, s);
                
                % Adjust self if using multi-element subscripting:
                % self(1,:), self(1,{'PropertyName'}) etc.
                [self, s] = adjustMultiElementSubsIndex(self, s, 'subsref');
                
                if length(s) == 2 && isempty(s(2).subs)
                    % s has length 2, so we are referencing either
                    % self.method() or self.PropertyName(). Since there are
                    % no inputs (s(2).subs is empty), remove the second
                    % element. This isn't needed for the self.method()
                    % reference but in the future, MATLAB may issue either
                    % a warning or error when referencing self.PropertyName().
                    % See g847170 and g847173.
                    s(2) = [];
                end
                
                % Determine if referencing a NoAnsMethod (such as disp)
                % Special handling is needed to process varargout.
                dotname = s(1).subs;
                referencingNoAnsMethod = any(strcmp(dotname, self.NoAnsMethods)) ...
                    && ~isprop(self, dotname);
                
                if referencingNoAnsMethod
                    % A method such as disp is being requested and we are
                    % referencing it as self.disp or self.disp(). We expect
                    % no inputs.
                    map.internal.assert(isscalar(s), 'MATLAB:TooManyInputs');
                    
                    if nargout > 0 && strcmp(dotname, 'disp')
                        % Use evalc to evaluate the method. In most cases,
                        % an error is issued since the disp method does not
                        % have outputs. However, in the future, MATLAB may
                        % set nargout to 1 for cases when it used to be 0.
                        % Using evalc works in this case but ans is set to
                        % the evaluation of disp(self), i.e.
                        % varargout = "ans = ..." 
                        % See g886314
                        varargout = {evalc('disp(self)')};
                    else
                        % Do not supply the ; after the method call
                        % in order to display the output of the call.
                        subsref_impl_dot(self, s, nargout)
                    end
                else
                    % A '.', '()', or '{}' referencing is requested.
                    % Pass nargout into subsref_impl since nargout from
                    % this call is always 1.
                    [varargout{1:nargout}] = subsref_impl(self, s, nargout);
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        %------------------------------------------------------------------
        
        function out = subsasgn(self,s,in)
        %SUBSASGN Subscripted assignment to dynamic vector
        %
        %   V2 = subsasgn(V, S, IN) is called for the syntax V(k) = IN or
        %   V.PropertyName = IN where V is a dynamic vector.
        %
        %   S is a structure array with the fields:
        %      type -- character vector containing '()', '{}', or '.'
        %              specifying the subscript type.
        %      subs -- cell array, character vector or scalar string
        %              containing actual subscripts.
        %
        %   V(k) = IN, where IN is a dynamic vector, assigns the contents
        %   of IN to a subset of the dynamic vector, V.
        %
        %   V(1:n) = IN, where V has P coordinate properties and IN is a
        %   P-by-N numeric array, assigns the K-th row of IN to the K-th
        %   coordinate property of V. If N ~= P and IN is N-by-P, then the
        %   K-th column of IN is assigned to the K-th coordinate property
        %   instead. If IN is a vector, then all coordinate values are
        %   assigned to the values of IN.
        %
        %   V.PropertyName = IN, V(N:M).PropertyName = IN assigns IN to the
        %   'PropertyName' property of the dynamic vector, V. If the
        %   dynamic vector property already exists and the V.PropertyName
        %   syntax is used, the assignment completely replaces the values
        %   in that property. If the property is not previously defined, a
        %   new dynamic property is added to the class, otherwise values
        %   are replaced.
        %
        %   IN may be a numeric, logical, or string array, a character
        %   vector, or a cell array of numeric, logical, character, or
        %   string values.
        %
        %   See also map.internal.DynamicVector/subsref.
                       
            try
                scalarExpansionFromEmpty =  ...
                    ~isa(self, 'map.internal.DynamicVector') ...
                    && isa(in, 'map.internal.DynamicVector') ...
                    && isempty(self);
                if scalarExpansionFromEmpty
                    % Assigning from: self(n) = DynamicVector(...) where
                    % self is uninitialized and set to [] by MATLAB.
                    % subsasgn method invoked since IN is a DynamicVector.
                    % When IN is empty, set self to a default empty
                    % DynamicVector value rather than the empty numeric
                    % value to allow methods of self to be invoked.
                    % Otherwise, set self to the first element of IN, but
                    % with each dynamic property value set to a default
                    % value, in order to allow copy of structures.
                    % (Otherwise, when the assignment is made, an error
                    % would be issued indicating attempting to copy
                    % dissimilar structures).
                    self = emptyDefaultElement(in);
                 end
                in = validatesubsasgn(self, s, in);
                [self, s] = adjustMultiElementSubsIndex(self, s, 'subsasgn');
                if isempty(self)
                    out = subsasgn_empty(self, s, in);
                else
                    out = subsasgn_impl(self, s, in);
                end
            catch e
                throwAsCaller(e);
            end
        end
        
        %------------------------------------------------------------------
        
        function out = horzcat(self, varargin)
        %HORZCAT Horizontal concatenation for dynamic vectors
        %
        %   horzcat(V1, V2, ...) where V1, V2, ... are dynamic vectors,
        %   issues an error. A dynamic vector is always a column vector.
        %   Use vertcat instead.
        %
        %   See also map.internal.DynamicVector/vertcat.

            try
                if isempty(varargin)
                    out = self;
                else
                    error(message('map:DynamicVector:horzcatIsNotPermitted', class(self)));
                end
            catch e
                throwAsCaller(e);
            end 
        end
         
    end
    
    %----------------------- Abstract methods -----------------------------

    methods (Abstract)     
        
        self = append(self, varargin)
       
    end
    
    %----------------------- protected methods ----------------------------
    
    methods (Access = protected, Hidden = true)
        
        %--------------------- Construction methods -----------------------
        
        function self = constructObject(self, varargin)
        %constructObject Object constructor method
        
            if ~isempty(varargin)
                switch numel(varargin)
                    
                    case 1
                        % DynamicVector(S) (object)
                        if isa(varargin{1}, class(self))
                            self = varargin{1};
                        else
                            % DynamicVector(S) (structure)
                            S = validatestruct(self, varargin{1});
                            self = constructFromStruct(self, S);
                        end
                        
                    case numel(self.Coordinates)
                        % DynamicVector(coordinates)
                        self = constructFromCoordinates(self, varargin);
                        
                    case numel(self.Coordinates) + 1
                        % DynamicVector(coordinate1, ..., S)
                        n = numel(self.Coordinates) + 1;
                        if isa(varargin{n}, class(self))
                            % Reset coordinates.
                            self = varargin{n};
                            coordinates = varargin(1:n-1);
                            self = constructFromCoordinates(self, coordinates);
                        else
                            S = validatestruct(self, varargin{n});
                            for k = 1:numel(self.Coordinates)
                                S.(self.Coordinates{k}) = varargin{k};
                            end
                            self = constructFromStruct(self, S);
                        end
                        
                    otherwise
                        % DynamicVector(coordinate1, ..., 'Name', value, ...)
                        n = numel(self.Coordinates) + 1;
                        pairs = varargin(n:end);
                        internal.map.checkNameValuePairs(pairs{:});
                        S = validatestruct(self, makestruct(pairs));
                        for k = 1:numel(self.Coordinates)
                            S.(self.Coordinates{k}) = varargin{k};
                        end
                        self = constructFromStruct(self, S);
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function self = constructFromCoordinates(self, coordinates)
        % Construct object from coordinate arrays. The cell array,
        % coordinates, contains the input coordinate arrays. The length
        % of coordinates must match the length of self.Coordinates. This
        % requirement is not validated by this method.
            
            % Find the lengths of the coordinate arrays.
            arrayLengths = cellfun(@length, coordinates);
            
            % Sort the lengths from small to large.
            [~, sortedIndex] = sort(arrayLengths);
            
            % Set the coordinate properties starting from the shortest
            % length and progressing to the longest length. This prevents
            % the coordinate with the shortest length array from truncating
            % the previous coordinates since the lengths are synchronized.
            for k = 1:length(sortedIndex)
                index = sortedIndex(k);
                self.(self.Coordinates{index}) = coordinates{index};
            end
                      
        end
        
        %------------------------------------------------------------------
        
        function self = constructFromStruct(self, S)
        % Assign properties to empty object self (with length 0) from
        % scalar structure, S. The value of each field of S is a vector.
        % These vectors do not need to have the same length. The length of
        % self will be the length of the longest vector.
                               
            % Obtain a cell array of all the properties of self.
            p = properties(self);
            
            % Copy the fields of S that correspond to property names of
            % self using the set method of each property (implemented in a
            % subclass except for Metadata). The length of self dynamically
            % grows depending on the length of each coordinate property.
            for k = 1:numel(p)
                if isfield(S, p{k})
                    self.(p{k}) = S.(p{k});
                    S = rmfield(S, p{k});
                end
            end
            
            % Assign the remaining fields of S to the DynamicProperties
            % structure using set.DynamicProperties. The length of self may
            % grow further.
            self.DynamicProperties = S;
        end
        
        %------------------------------------------------------------------
        
        function self = constructEmptyObject(self)
        % Construct an empty object, based on the class name of the input
        % object. This method is appropriate for derived classes.
        
            fcn = str2func(class(self));
            self = fcn();
        end  
        
        %--------------------- Property methods ---------------------------
        
        function value = getProperty(self, name)
        % getProperty returns the value of the property, NAME. It is
        % required for derived classes to be able to utilize the subsref,
        % subsasgn, and adjustProperty methods within this class. Derived
        % classes do not need to overload this method.
        
            if any(strcmp(self.Coordinates, name))
                value = self.pCoordinates.(name);
            else
                value = self.(name);
            end
        end
        
        %------------------------------------------------------------------
        
        function self = setProperty(self, name, value)
        % setProperty sets the value of property, NAME, with the value,
        % VALUE. It is required for derived classes to be able to utilize
        % the subsref, subsasgn, and adjustProperty methods within this
        % class. Derived classes do not need to overload this method.
        
            if any(strcmp(self.Coordinates, name))
                if isempty(value) && isnumeric(value)
                    % Make sure empty is always 0-by-0
                    value = [];
                end
                self.pCoordinates.(name) = value;
            else
                self.(name) = value;
            end
        end
      
        %------------------------------------------------------------------
         
        function self = setCoordinate(self, name, value)
        % Set a coordinate property value.
            
            % Validate and transpose value (if value is a column vector).
            value = validateCoordinatePropertyInput(self, value, name);
            
            % Save lengths of input value and coordinate.
            lengthOfValue = length(value);
            lengthOfOriginal = length(self.(name));
                       
            % Set the property.
            self = setProperty(self, name, value);
            
            % Adjust the other properties only if the length of value does
            % not match the length of the original value of the property.
            if lengthOfValue ~= lengthOfOriginal
                self = adjustProperties(self, lengthOfValue, name);
            end
        end    
        
        %------------------------------------------------------------------
        
        function self = setCoordinates(self, value)
        % Set all coordinate property values to value.

            names = self.Coordinates;
            for k=1:numel(names)
                self = setProperty(self,  names{k},  value);
            end
        end
        
        %--------------------- Validate methods ---------------------------
        
        function value = validateGeometry(self, value)
        % Validate Geometry property. VALUE is the input value to validate.
        
            types = {'point'};
            value = validatestring(value, types, class(self), 'Geometry');           
        end       
        
        %------------------------------------------------------------------
        
        function in = validatesubsasgn(self, s, in)
        % Validate input to subsasgn.
            
            % Validate the input to ensure data type and shape.
            for k = 1:length(s)
                s(k).subs = convertStringsToChars(s(k).subs);
            end
            in = validateinput(self, s, in);
            
            if numel(find(strcmp({s.type}, '.'))) >= 2
                % Referencing: self.X.X
                if (ischar(s(1).subs) && ~isprop(self, s(1).subs) ...
                        || ~ischar(s(1).subs))
                    % Do not permit: obj(1).DynamicProperties.PropName = value
                    % Do permit derived classes to have properties that contain
                    % structure or objects.
                    index = find(strcmp({s.type}, '.'));
                    propname = s(index(1)).subs;
                    if ~isprop(self, propname)
                        error(message('map:DynamicVector:unexpectedInput'));
                    end
                elseif ischar(s(1).subs) ...
                        && isfield(self.pDynamicProperties, s(1).subs)
                    % Do not permit:
                    % self = geopoint(1,1);
                    % self.X = 1; self.X.x = 1
                    error(message('map:DynamicVector:unexpectedInput'))
                end
            end
            
            % Validate the subs index.
            for k=1:numel(s)
                validatesubsindex(self, s, k);
            end            
        end
        
        %------------------------------------------------------------------
        
        function validatesubsref(self, s)
        % Validate input to subsref.
            
            if numel(find(strcmp({s.type}, '.'))) >= 2 ...
                    && (ischar(s(1).subs) && ~isprop(self, s(1).subs) ...
                    || ~ischar(s(1).subs))
                % Do not permit: obj(1).DynamicProperties.PropName
                % Do permit derived classes to have properties that contain
                % structure or objects.
                index = find(strcmp({s.type}, '.'));
                propname = s(index(1)).subs;
                if ~isprop(self, propname)
                    error(message('map:DynamicVector:nonExistentProperty', ...
                        propname));
                end
            end
            
            % Validate the subs index.
            for k=1:numel(s)
                validatesubsindex(self, s, k);
            end
        end
        
        %------------------------------------------------------------------
        
        function validatesubsindex(self, s, k)
         % Validate subs index values: s.subs
            
            switch(s(k).type)
                case '.'
                    % obj.(s(1).subs) must contain a character vector. A
                    % cell array is not permitted.
                    if ~ischar(s(k).subs), ...
                            error(message('map:DynamicVector:invalidDynamicReference', ...
                            class(self)));
                    end
                    
                case '{}'
                    if k == 1
                        % Error with any reference of obj{...}. Let builtin
                        % issue the error.
                        builtin('subsref', self, s(k));
                    else
                        if length(s(k).subs) > 1
                            % Matrix indexing is not permitted when using
                            % the {} operator on the property.
                            error(message('map:DynamicVector:matrixIndexingNotPermitted', s(k).type));
                        else
                            validateindices(s(k));
                        end                        
                    end
                    
                case '()'
                    % Check if a method is being referenced:
                    % obj(k).methodname(inputs)
                    % If so, then this is a valid reference.
                    if ischar(s(1).subs) && any(strcmp(s(1).subs, methods(self)))
                        % Referencing a method. No need to validate.
                    elseif k == 2 && length(s(k).subs) > 1
                        % Matrix indexing is not permitted when using the
                        % () operator on the property.
                        error(message('map:DynamicVector:matrixIndexingNotPermitted', s(k).type));
                    else
                        % Validate the indices.
                        validateindices(s(k));
                    end
            end
        end

        %------------------------------------------------------------------

        function in = validateinput(self, s, in)
        % Validate the input, IN, to subsasgn.
            
            % Early conversion to prevent issues with string.empty or
            % string(missing)
            in = convertStringsToChars(in);
            
            % Ignore numeric and logical index values.
            subs = {s.subs};
            stringOnly = cellfun(@ischar, subs);
            subs(~stringOnly) = [];
            
            % self.ConstantProperties contains any standard property that
            % is not a coordinate property. The constant properties may
            % contain any type. Their set method will validate input, so
            % these properties can be ignored.
            usingDotNotation = any(strcmp('.',{s.type}));
            if usingDotNotation && ~isValidEmpty(in) ...
                    && ~any(cellcmp(subs, self.ConstantProperties))
                if ~any(cellcmp(subs, self.Coordinates)) || isempty(subs)
                    % A dynamic property is being set. Validate the input.
                    in = validateDynamicPropertyInput(self, in);
                else
                    % A coordinate is being set. No need to validate at
                    % this time. Allow the set function to validate.
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function S = validatestruct(self, in)
        % Validate input, IN to be a structure and copy valid fields to the
        % output structure, S.
            
            if isempty(in)
                % Make sure input is a valid empty structure.
                in = struct();
            else
                % Make sure input is a structure.
                validateattributes(in, {'struct'}, {}, class(self));
            end
            
            % Copy the values from the input structure, IN, to the output
            % structure, S.
            S = struct();
            f = fieldnames(in);
            for k=1:numel(f)
                % Return a vector for all scalar numeric and logical
                % values; otherwise, return a cell array.
                v = fieldvalues(in, f{k});
                try
                    if strcmp(f{k}, 'Metadata') && ~isscalar(in)
                        % Ignore setting the Metadata property when the
                        % input is not scalar. This happens when the input
                        % is a structure array with a Metadata field.
                    elseif any(strcmp(f{k}, self.ConstantProperties))
                        % Allow the Metadata property to be set if the
                        % input, IN, is a scalar structure; otherwise, this
                        % field is ignored. The set.Metadata method
                        % validates the input, v, as a structure.
                        %
                        % Other constant (container) properties are
                        % validated with their set method.
                        S.(f{k}) = v;
                    else
                        % Determine if v contains valid values. Valid
                        % values are values that can be set via subsasgn.
                        % If the field values are not valid, then do not
                        % include them in the output structure.
                        v = validateDynamicPropertyInput(self, v);
                        S.(f{k}) = v;
                    end
                catch e %#ok<NASGU>
                    % Ignore any errors. The data is not added to the
                    % output structure.
                end
            end
            
            % For naming standards, replace any instance of 'Lat' or 'Lon'
            % field names with 'Latitude' and 'Longitude' only if all of
            % the following conditions are true:
            % 1) the short field name exists
            % 2) the longer field name does not exist
            % 3) and the longer field name is a member of Coordinates
            shortNames = {'Lat', 'Lon'};
            longNames  = {'Latitude', 'Longitude'};
            S = replaceFieldnames(S, self.Coordinates, longNames, shortNames);
        end
        
        %------------------------------------------------------------------
        
        function in = validateDynamicPropertyInput(self, in)
        % Validate the property input values. 
        
            % Forward the call to the validatevalues function which is used
            % by the constructor to validate input values.
            in = validatevalues(in, class(self));
        end
        
        %------------------------------------------------------------------
        
        function in = validateCoordinatePropertyInput(self, in, name)
        % Validate the property input values.
            
            % Validate value as numeric and a vector or [].
            if isempty(in)
                % [] is a valid value and isvector([]) is false.
                % Assign {} for the attributes.
                attributes = {};
            else
                % in is not empty and must be a vector.
                attributes = {'vector'};
            end            
            validateattributes( ...
                in, {'single', 'double'}, attributes, class(self), name); 
            
            % Reshape the input to be a row vector.
            if ~isempty(in)
                in = reshape(in, 1, length(in));
            end
        end
                
        %--------------------- Adjust methods -----------------------------
        
        function self = adjustProperty(self, newlen, name)
        % Adjust the length of the property, NAME, to the value, NEWLEN.
        
            if ~strcmp(name, 'pDynamicProperties')
                % Adjust standard property.
                value = getProperty(self, name);
                self  = setProperty(self, name, adjustValue(value, newlen));
            else
                % Adjust dynamic property.
                self.pDynamicProperties = structfun( ...
                    @(x) adjustValue(x, newlen), ...
                    self.pDynamicProperties, ...
                    'UniformOutput', false);
            end
        end
                
        %------------------------------------------------------------------
        
        function self = adjustProperties(self, proplen, name)
        % Reset the length of all properties, excluding the NAME property.
        % PROPLEN is the new length for all properties.
            
            % Adjust the length of all coordinate properties to match the
            % length (PROPLEN) of property, NAME. Since these properties
            % are all numeric, use 0 as the value for expansion. The
            % property, NAME, does not need to be adjusted.
            p = self.Coordinates;
            p(cellcmp(p,  name)) = [];
            for k=1:numel(p)
                self = adjustProperty(self, proplen, p{k});
            end
            
            % Adjust the length of all existing non-coordinate and
            % non-empty properties. Do not adjust the NAME property.
            p = [self.Coordinates 'pDynamicProperties'];
            p(cellcmp(p, unique([self.Coordinates {name}],'legacy'))) = [];
            for k=1:numel(p)
                if ~isempty(self.(p{k}))
                    self = adjustProperty(self, proplen, p{k});
                end
            end
        end
        
        %------------------------------------------------------------------        
        
        function [self, s] = adjustMultiElementSubsIndex(self, s, fcnname)
        % Adjust the object, self, and the structure, s, if s contains
        % multi-element indexing. If s.subs{2} is 1 or ':', then it can be
        % replaced with standard linear indexing. If s.subs{2} is a
        % character vector or cell array, then remove all other fields from
        % self.
            
            if all(strcmp(s(1).type, '()'))  && length(s(1).subs) >= 2
                % self(n,m)  
                [self, s] = adjustObjectUsingMatrixIndexing(self, s, fcnname);
            end
                
            subs = s(1).subs;
            if iscell(subs) && isscalar(subs) && all(strcmp(subs{1}, ':'))
                % Referencing: self(:)
                if ~isempty(self)
                    % Prevent transposing all data.
                    % Change self(:) to self(true(1,length(self))
                    s(1).subs{1} = true(1, self.getCount());
                else
                    % Referencing self(:) but self is empty.
                    % Prevent properties from becoming size
                    % 0-by-N or N-by-0.
                    s(1).subs = {[]};
                end
            end
            
            if iscell(s(1).subs) &&  any(cellfun(@isempty, s(1).subs))
                % Change self(n,[]) or self([],m), or self(...,[],...)
                % to an empty object.
                self = constructEmptyObject(self);
                s(1).subs = {[]};
            end
        end
        
        %------------------------------------------------------------------
        
        function [self, s] = adjustObjectUsingMatrixIndexing(self, s, fcnname)
        % Adjust the object, self, and the structure, s, if s contains any
        % matrix indexing elements. Convert s to use linear indexing.
            
            subs2 = s(1).subs{end};
            if isequal(subs2, 1) || all(strcmp(subs2, ':'))
                % self(n,1), self(n,:): remove last argument
                s(1).subs = s(1).subs(1:end-1);
                
                % Remove all ones in dimensions > 1. They are legal
                % but will cause errors in the subsref implementation.
                % For example: self(n,1,1,1,1)
                s(1).subs = removeSingletonsFromSubs(s(1).subs);
                
            elseif ischar(subs2) || iscell(subs2)
                % self(n,'propertyname')
                % self(n, {'propname1', 'propname2', ...})
                [self, s] = adjustObjectUsingPropertyIndex(self, s, fcnname);
                
            else
                % No need to manage any other input
            end
        end
        
        %------------------------------------------------------------------
        
        function [self, s] = adjustObjectUsingPropertyIndex(self, s, fcnname)
        % Adjust the object when using property indexing. For example:
        % self(2,1,'Propname') or self(2,1,{'Prop1','Prop2'})
            
            subs2 = s(1).subs{end};
            if ~iscell(subs2)
                subs2 = {subs2};
            end
            
            if isequal(fcnname, 'subsref')
                % Create new self object using cell array indexing.
                self = adjustObjectUsingCellArrayIndex(self, subs2);
                
                % Remove the cell array index. Remove all extra
                % singletons from subs. They are legal but cause errors
                % in subsref implementation.
                s(1).subs = s(1).subs(1:end-1);
                s(1).subs = removeSingletonsFromSubs(s(1).subs);
            else
                % Assignment. Do not adjust self, but remove the
                % singletons from the index.
                s(1).subs = ...
                    [removeSingletonsFromSubs(s(1).subs(1:end-1)) ...
                    s(1).subs(end)];
            end
        end
        
        %------------------------------------------------------------------
        
        function self = adjustObjectUsingCellArrayIndex(self, subs)
        % Given a subs index (a cell array of dynamic property names),
        % create a new object with only the dynamic properties specified in
        % subs.
                        
            % Make sure subs is unique and not sorted.
            subs = unique(subs, 'stable');
            
            % Remove the fields from the object self, that are not 
            % specified in subs.
            self = rmfield(self, setdiff(fieldnames(self), subs,'legacy'));
            
            % Order the fields, and make sure that each field specified in
            % subs is a member of fieldnames (to prevent any error in
            % orderfields).  
            index = cellcmp(subs, fieldnames(self));
            self.pDynamicProperties = ...
                orderfields(self.pDynamicProperties, subs(index));
        end
        
        %--------------------- subsref methods ----------------------------
        
        function  varargout = subsref_impl(self,s, numout)
        % Protected implementation of subsref.
            
            switch s(1).type
                case {'{}', '()'}
                    [varargout{1:numout}] = subsref_impl_paren(self, s);
                    
                case {'.'}
                    [varargout{1:numout}] = subsref_impl_dot(self, s, numout);                  
            end
        end
        
        %------------------------------------------------------------------
        
        function varargout = subsref_impl_paren(self, s)
        % Protected implementation of subsref. 
        % s(1).type contains either () or {}.
            
            % Adjust the size of self to match inputs in s.
            if isempty(s(1).subs)
                % User is attempting to reference all of the object by
                % referencing self(). In the future, MATLAB may throw a
                % warning or may error when referencing self() (Example:
                % d = [1:3], d()). However, the message may indicate class
                % "double" since the warning or error would be thrown when
                % attempting to subrefs a property value. 
                % See g847170 and g847173.
                % Supply all index values to subs.
                s(1).subs = {true(1, length(self))};
            end
            p = self.Coordinates;
            for k=1:numel(p)
                propk = p{k};
                value = getProperty(self, propk);
                self  = setProperty(self, propk, subsref(value, s(1)));
            end
            
            props = properties_private(self);
            index = cellcmp(props, p);
            props(index) = [];
            p = props;
            
            for k=1:numel(p)
                propk = p{k};
                if ~isempty(self.(propk))
                    if ~strcmp('DynamicProperties', propk)
                        % This if block will not be executed with the
                        % current implementation. However, if additional
                        % properties are defined via subclassing, then this
                        % if block will be executed. Since the property is
                        % not a coordinate property, expect it always to be
                        % scalar. There is no need to expand or contract
                        % the property, so nothing needs to be done. The
                        % property is still defined in self.
                    else
                        % Update the fields of pDynamicProperties.
                        propk = 'pDynamicProperties';
                        e = struct();
                        f = fieldnames(self.(propk));
                        for l=1:numel(f)
                            e.(f{l}) = subsref(self.(propk).(f{l}), s(1));
                        end
                        self.(propk) = e;
                    end
                end
            end
            
            n = numel(s);
            switch n
                case {0,1}
                    % Referencing self(n)
                    [varargout{1:nargout}] = self;
                    
                case 2
                    % Referencing:
                    % self(n).DynamicPropertyName or
                    % self(n).Coordinate 
                    f = fieldnames(self.pDynamicProperties);
                    if any(strcmp(s(2).subs, f))
                        c = subsref_dynamic_property(self, s(2), 1);
                    else
                        % Do not use builtin('subsref', ...) here. builtin
                        % returns the values for private and hidden properties.
                        % For example: self(1).Coordinates or
                        % self(1).DynamicProperties are returned using builtin.
                        c = subsref(self,s(2));
                    end
                    [varargout{1:nargout}] = c;
                    
                otherwise
                    % numel(s) >= 3
                    % self.Metadata.Fieldname
                    % Do not use builtin('subsref', ...) here. builtin returns
                    % the values for private and hidden properties.
                    [varargout{1:nargout}] =  subsref(self, s(2:end));
            end
        end
        
        %------------------------------------------------------------------
        
        function varargout = subsref_impl_dot(self, s, numout)
        % Protected implementation of subsref. s(1).type contains '.'
            
            propname = s(1).subs;
            if isfield(self, propname)
                % Referencing a dynamic property.
                [varargout{1:numout}] = subsref_dynamic_property(self, s, numout);
                           
            elseif all(cellcmp(propname, properties(class(self)))) 
                % Referencing a standard property.
                [varargout{1:numout}] = subsref_property(self, s, numout);
                
            elseif any(strcmp(propname, methods(self)))
                % Referencing a method.
                [varargout{1:numout}] = builtin('subsref',self, s);                                
            else
                error(message('map:DynamicVector:nonExistentProperty', propname));
            end
        end
        
        %------------------------------------------------------------------
        
        function  varargout = subsref_property(self, s, numout)
        % Return a value based on the inputs to subsref, S. S contains
        % a property name.
            
            nargoutchk(0,1)
            if strcmp(s(end).type, '{}')
                % Convert to () to return a cell array from subsref.
                % Return a scalar cell array. subsref cannot create a
                % comma-separated list of values. This branch is executed
                % with the following type of reference:
                % self.Metadata.Name{1} or self.Metadata.Name{:}
                if any(strcmp(s(1).subs, self.Coordinates))
                    % Coordinates are not cells.
                    error(message('MATLAB:cellRefFromNonCell'))
                end

                varargout{1:numout} = builtin('subsref', self, s);
                if numout <= 1 && ~isscalar(varargout)
                    error(message('map:DynamicVector:cellIndexingNotPermitted',  ...
                        '()', '{}'))
                end
            else
                [varargout{1:numout}] = builtin('subsref', self, s);
            end
            
            if numout <= 1 && ~isempty(varargout) && iscell(varargout{1}) ...
                    && any(strcmp(s(1).subs, self.Coordinates))
                % Extract the contents of the cell array if the values
                % are all logical or numeric or character vector.
                varargout{1} = cell2values(varargout{1}, numel(s));
            end
        end
        
        %------------------------------------------------------------------
        
        function varargout = subsref_dynamic_property(self, s, numout)
        % Return a value based on the inputs to subsref, S. S contains
        % a field name of self.DynamicProperties.
        
            % Use subsref to obtain the value from the DynamicProperties
            % structure.
            if strcmp(s(end).type, '{}')
                % Convert to () to return a cell array from subsref.
                % Return a scalar cell array. subsref cannot create a
                % comma-separated list of values. This branch is executed
                % with the following type of reference: 
                % self.Name{1} or self.Name{:}
                s(end).type = '()';
                varargout = builtin('subsref', self.DynamicProperties, s);
                if numout <= 1 && ~isscalar(varargout)
                    error(message('map:DynamicVector:cellIndexingNotPermitted',  ...
                        '()', '{}'))
                end
            else
                [varargout{1:numout}] = builtin('subsref', self.DynamicProperties, s);
            end
            
            if numout <= 1 && ~isempty(varargout) && iscell(varargout{1})
                % Extract the contents of the cell array if the values
                % are all logical or numeric or a character vector.
                varargout{1} = cell2values(varargout{1}, numel(s));
            end
        end
        
        %--------------------- subsasgn methods ---------------------------
        
        function self = subsasgn_impl_paren_numeric(self, s, in)
        % Protected implementation for subsasgn. s(1) contains () or {}
        % and IN is asserted to be either an map.internal.DynamicVector
        % object, empty, or numeric 2d array.
            
            numCoords = numel(self.Coordinates);
            validInput = isa(in, class(self)) ...
                || (isnumeric(in) && ismatrix(in));
            if ~validInput
                error(message('map:DynamicVector:badAssignmentInput', ...
                    class(self)));
            end
            
            if isnumeric(in) && ~isempty(in)
                % Adjust the shape of the input IN to match the number of
                % coordinates.
                in = adjustNumericInput(in, numCoords);
                
                c = self.Coordinates;
                S = struct();
                for k=1:numel(c)
                    S.(c{k}) = in(k,:);
                end
                temp = constructFromStruct(self, S);
                self = subsasgn(self, s, temp);
            else
                self = subsasgn_impl_paren_multiple_elements(self, s, in);
            end
        end
        
        %------------------------------------------------------------------
        
        function out = subsasgn_empty(self, s, in)
        % Protected implementation for subsasgn. self is empty.
            
            % Assign values using standard implementation.
            out = subsasgn_impl(self, s, in);
        end
        
        %------------------------------------------------------------------
        
        function out = subsasgn_impl(self, s, in)
        % Protected implementation for subsasgn.
            
            switch s(1).type
                case {'{}', '()'}
                    out = subsasgn_impl_paren(self, s, in);
                    
                case '.'
                    out = subsasgn_impl_dot(self, s, in);
            end
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_impl_paren(self, s, in)
        % Protected implementation for subsasgn. s(1).type is () or {}.
            
            if numel(s) == 2
                % Example: self(k).PropertyName = in.
                self = subsasgn_impl_paren_two_elements(self, s, in);
            else
                if isscalar(s) && length(s(1).subs) == 2 ...
                        && (ischar(s.subs(1)) || iscell(s.subs(1)))
                    % Example: 
                    %   self(k, 'NAME') = in 
                    %   self(k,{'NAME1','NAME2',...})
                    self = subsasgn_impl_paren_string_index(self, s, in);
                    
                elseif isa(in, class(self))
                    % Example: self(k) = in,
                    % where in is an map.internal.DynamicVector object.
                    self = subsasgn_impl_paren_object(self, s, in);
                    
                else
                    if isscalar(s)
                        % Example: self(k) = in where in is a number.
                        self = subsasgn_impl_paren_numeric(self, s, in);
                    else
                        % Examples:
                        % self(k).StandardProperty.A.B, etc
                        % self(k).Coordinate(n) = 1
                        % self(k).Metadata.X = 1
                        % self(k).Name{1} = 'a'
                        self = subsasgn_property_indexing(self, s, in);                          
                    end
                end               
            end
        end
        
        %------------------------------------------------------------------
        
        function out = subsasgn_impl_paren_string_index(self, s, in)
        % Protected implementation for subsasgn. s contains a character
        % vector for property indexing. For example: self(2,'Name') =
        % self(1,'Name')
            
            % Make sure RHS is an map.internal.DynamicVector object or empty.
            if ~isa(in, class(self))
                error(message('map:DynamicVector:invalidRHS', class(self)));
            end
            
            % Adjust the input object to make sure all fields match and
            % validate.
            adjustedSelf = adjustMultiElementSubsIndex(self, s, 'subsref');
            if ~isequal(unique(properties(in),'legacy'), unique(properties(adjustedSelf),'legacy'))
                error(message('map:DynamicVector:heterogeneousAssignment', class(self)));
            end
            
            % Save the property name(s).
            propname = s.subs{2};
            
            % Remove the property name(s)
            s.subs = s.subs(1);
            
            % Create a new subs index in order to reference the properties
            % via: self(index).PROPNAME
            s(2).type = '.';
            
            if ~iscell(propname)
                propname = {propname};
            end
            
            if any(cellcmp(self.Coordinates, propname))
                error(message('map:DynamicVector:invalidLHS'))
            end
            
            % Loop through all the properties and re-assign. 
            % subsref and subsasgn must be used since the properties cannot
            % be referenced with self.(propname) here. IN is already
            % conditioned. All propname properties of IN need to be copied
            % to the correct elements of OUT. Therefore, s(1).subs must be
            % set to true for all values of a property of IN, but must be
            % reset to the requested elements of OUT.
            out = self;
            subs1 = s(1).subs;
            
            for k=1:numel(propname)
                s(2).subs = propname{k};
                s(1).subs{1} = true(1, length(in));
                value = subsref_impl(in, s, 1);
                s(1).subs = subs1;
                out = subsasgn(out, s, value);
            end
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_impl_paren_two_elements(self, s, in)
        % Protected implementation for subsasgn: s contains two elements.
            
            if isnumeric(in) && isempty(in) && numel(s) >= 2
                if isscalar(s(1).subs) && isscalar(s(1).subs{1})
                    index = num2str(s(1).subs{:});
                else
                    index = 'index';
                end
                error(message('map:DynamicVector:operationNotPermitted', ...
                    s(2).subs, index));
            end
            
            propname = s(2).subs;
            if any(strcmp(propname, fieldnames(self.DynamicProperties))) ...
                    || ~isprop(self, propname)
                % If propname is a field of self.DynamicProperties then the
                % request is to assign a value to the dynamic property:
                % self(n).X = value;
                %
                % If propname is not a property of self, then the request
                % is to add a new dynamic property to self.
                % self(n).NewProp = value;
                self = subsasgn_dynamic_property(self, s(1), in, propname);
            else
                % propname is a property of self.
                self = subsasgn_property(self, s(1), in, propname);
            end
        end
                
        %------------------------------------------------------------------
        
        function self = subsasgn_impl_paren_object(self, s, in)
        % Protected implementation for subsasgn. s contains () and IN is an
        % map.internal.DynamicVector object.
            
            p = properties_private(self);
            [outfields, sorted] = sort(fieldnames(self.pDynamicProperties));
            outcells = structfun(@iscell, self.pDynamicProperties);
            outcells = outcells(sorted);
            
            for k=1:numel(p)
                if ~strcmp('DynamicProperties', p{k})
                    % Processing standard property.
                    propk = p{k};
                    if cellcmp(p{k}, self.Coordinates)
                        % Processing a coordinate property.
                        value   = getProperty(self, propk);
                        invalue = getProperty(in, propk);
                        if isempty(value) && isempty(invalue)
                            % subsasgn errors in this case.
                            % Allow self(1) = self; where self is empty.
                            outvalue = [];
                        else
                            outvalue = builtinSubsasgn(value, s(1), invalue);
                        end
                        self = setProperty(self, propk, outvalue);
                    else
                        % Processing non-coordinate and non-dynamic
                        % property. The remaining properties are container
                        % properties (scalar). However, they are not
                        % obtained with properties_private and they are not
                        % copied when referencing: self(n) = other_self(n).
                        % If this needs to change in the future, for
                        % example to copy the Metadata, then uncomment this
                        % line and change p = properties_private(self) to
                        % include the container properties.
                        % self.(propk) = in.(propk);
                    end
                else
                    % Processing dynamic properties. 
                    % These are contained in 'pDynamicProperties'.
                    propk = 'pDynamicProperties';
                    [infields, sorted] = sort(fieldnames(in.(propk)));
                    incells = structfun(@iscell, in.pDynamicProperties);
                    incells = incells(sorted);
                    if ~(isequal(infields, outfields) ...
                            && isequal(incells, outcells))
                        error(message('map:DynamicVector:heterogeneousAssignment', class(self)));
                    end
                    for l = 1:numel(incells)
                        self.(propk).(infields{l}) = builtinSubsasgn( ...
                            self.(propk).(infields{l}), s(1), in.(propk).(infields{l}));
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_impl_paren_multiple_elements(self, s, in)
        % Protected implementation for subsasgn. s contains () or {} and '.'.
            
            p = properties_private(self);
            
            for k=1:numel(p)
                propk = p{k};
                value = getProperty(self, propk);
                if ~isempty(value)
                    if ~strcmp(propk, 'DynamicProperties')
                        self = setProperty(self, propk, ...
                            builtinSubsasgn(value, s(1), in));
                    else
                        if numel(s) == 3
                            % No action is need for this branch. It would
                            % be used if a structure is added to this
                            % class.
                        else
                            f = fieldnames(self.DynamicProperties);
                            if isempty(in)
                                % Do not scalar expand the structure
                                for l=1:numel(f)
                                    self.pDynamicProperties.(f{l}) = builtinSubsasgn( ...
                                        self.pDynamicProperties.(f{l}), s, in);
                                end
                            else
                                % This block should be processed earlier:
                                % obj(1) = 0; Currently, only the
                                % coordinates are set when a numeric
                                % value is on the RHS. However, to set all
                                % dynamic properties, uncomment the
                                % following:
                                % for l=1:numel(f)
                                %  self.DynamicProperties.(f{l}) = ...
                                %    builtin('subsasgn', ...
                                %     self.DynamicProperties.(f{l}), s, in);
                                % end
                            end
                        end
                    end
                end
            end
            
            % If output object is empty, remove any remaining 1-by-0 values.
            if isempty(self)
                self = constructEmptyObject(self);
            end
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_impl_dot(self, s, in)
        % Protected implementation for subsasgn. s contains '.'
            
            % Obtain the property name.
            propname = s(1).subs;
            
            % Determine the type of property.
            isContainerProperty  = any(strcmp(propname, self.ConstantProperties));
            isCoordinateProperty = any(strcmp(propname, self.Coordinates));

            if isContainerProperty
                % Setting a container property.
                self = builtinSubsasgn( self, s ,in);
                
            elseif isCoordinateProperty
                % Setting a coordinate property.
                self = subsasgn_impl_dot_coordinate_property( ...
                    self, s, in, propname);
                
            else
                % Setting a dynamic property.
                self = subsasgn_impl_dot_dynamic_property( ...
                    self, s, in, propname);              
            end
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_impl_dot_coordinate_property( ...
                self, s, in, propname)
            
            % Validate the input.
            validateEmptyAssignment(s, in, propname)
            
            % Assign the input values.
            self = builtinSubsasgn( self, s ,in);
            
            % Clear properties if self is empty.
            if isempty(self)
                self.pDynamicProperties = struct();
            end
        end
        
        %------------------------------------------------------------------
        
        function out = subsasgn_impl_dot_dynamic_property(self, s, in, propname)
                
            % Validate the input.
            validateEmptyAssignment(s, in, propname)
            
            % Assigning dynamic property.
            out = self;
            if ~isempty(in) || ischar(in)  % permit ''
                % Check cell notation: obj.PropertyName{index} = value
                usingCellNotation = any(strcmp('{}',{s.type}));
                if usingCellNotation
                    % obj.PropertyName{index} = value
                    if ~ischar(in)
                        % When using cell notation, input must be char.
                        validateattributes(in, {'char'}, {});
                    else
                        % Input is a char, but syntax may be such that a
                        % new cell array is being created at any index. For
                        % example: obj.PropertyName{5} = 'char', where
                        % PropertyName is a new dynamic property.
                        % Therefore, use builtin to create the cell array
                        % and then validate the value. The output of
                        % builtin returns a structure since s references a
                        % field of a structure. The last value of s (the
                        % structure array defining the subsasgn) contains
                        % {} and can now be discarded.
                        if ~isfield(self.DynamicProperties, propname)
                            c = {};
                            v = builtinSubsasgn( c, s, in);
                            in = validatevalues(v.(propname), class(self));
                            s(end) = [];
                        end
                    end
                end
                                
                if ~iscell(in) && ischar(in) && ~any(strcmp('{}', {s.type}))
                    in = {in};
                end
                
                % Assign the new value to the field of the
                % DynamicProperties structure, as specified in s. An output
                % structure is created in v. Assign each field of
                % out.DynamicProperties to the field values in v in order
                % to adjust the lengths of the dynamic properties (the
                % field values) correctly or to set a new field.
                v = builtinSubsasgn( self.DynamicProperties, s, in);
                f = fieldnames(v);
                for l = 1:numel(f)
                    out.DynamicProperties.(f{l}) = v.(f{l});
                end
            else
                % Delete a field
                if isfield(out.pDynamicProperties, propname)
                    S = rmfield(out.pDynamicProperties, propname);
                    out.pDynamicProperties = S;
                else
                    % This block will only execute in derived classes
                    % that have additional properties.
                    error(message('map:DynamicVector:nonExistentProperty', ...
                        propname))
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_property(self, s, in, propname)
        % Assign value IN to property, PROPNAME.
            
            if isContainerProperty(self, propname)
                % Assign a container property.
                            
                % subref the object to obtain its length and to determine
                % if s is value.
                v = subsref(self, s);
                
                % Assign the property value by using obj.PropertyName
                % syntax.
                s.type = '.';
                s.subs = propname;
                self = builtinSubsasgn( self, s, in);
                
                % Issue a warning if the subs reference is not scalar.
                if length(v) > 1 || length(self) ~= 1
                    issueSingleInstanceWarning(propname);
                end
            else
                % Assign a coordinate property.
                if ~isnumeric(in)
                    % builtin errors if the value is not numeric since
                    % self.(propname) is a numeric value. Use
                    % validateCoordinatePropertyInput to generate the error
                    % message. Since the set function also invokes this
                    % method, only validate when the input is not numeric.
                    in = validateCoordinatePropertyInput(self, in, propname);
                end
                
                % Assign the value to the property.
                self.(propname) = builtinSubsasgn( self.(propname), s, in);
            end
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_dynamic_property(self, subs, in, fname)
        % Assign value IN to the field, FNAME, of S. S is a structure.
        %
        % This method gets referenced with the following type of call:
        % self(2).Name = 'x'
        % or self.X = 1
            
            % Obtain the length of the object.
            count = self.getCount();
            
            S = self.DynamicProperties;
            if ~isfield(S, fname)|| isempty(S.(fname))
                % Field is not set or is empty. Initialize the field to the
                % correct type and length.
                if isnumeric(in)
                    c = zeros(1, count);
                elseif islogical(in)
                    c = false(1, count);
                else
                    c = cell(1, count);
                end
                v = c;
            else
                v = S.(fname);               
            end
            
            % If the field is a cell array, then the input, IN, must be a
            % cell array for subsref to work correctly. In addition, the
            % input must be re-validated since valid values for cell array
            % input is different than non-cell input.
            if iscell(v) && ~iscell(in)
                in = {in};
                in = validateDynamicPropertyInput(self, in);
                if iscellstr(v) && ~(isempty(in) || iscellstr(in))
                    error(message('map:DynamicVector:badCellStr'))
                end
            end
            
            % If the input is an empty cell array, {}, then set the first
            % element to ''. This prevents MATLAB:subsassignnumelmismatch
            % errors from being issued by builtin('subsasgn').
            if isempty(in) && iscell(in)
                in = {''};
            end

            % Assign the value IN to the field name.
            v = builtinSubsasgn( v, subs, in);
            
            % Replace numeric [] with character vector ''.
            S.(fname) = replaceNumericEmptyInCell(v);
            
            % Assign S to DynamicProperties.
            self.DynamicProperties = S;
        end
        
        %------------------------------------------------------------------
        
        function self = subsasgn_property_indexing(self, s, in)
        % Assign value IN to self based on values in subsref input, s.
        % s contains a property name and multiple elements.
        %    Examples:
        %       self(k).StandardProperty.A.B = in
        %       self(k).DynamicProperty = in
            
            propname = s(2).subs;
            if isContainerProperty(self, propname)
                % The property name refers to a container property. s
                % contains indices which may be a scalar number, an array
                % of doubles, or an array of logical values. Rather than
                % parsing this information, use the builtin subsasgn
                % function to assign the scalar container property value.
                %
                % The output, self, must always be scalar. The standard
                % properties are always scalar. However, builtin may return
                % an array of DynamicVector objects. For example:
                % self(n).Metadata.X = value, where n is greater than the
                % length of self.
                v = builtinSubsasgn( self, s, in);
                
                % If v is  scalar, then the assignment is correct. If the
                % number of elements of v is greater than the length of
                % self, then an indexOutOfBounds error occurred. Otherwise,
                % a valid assignment was made on the scalar object, but v
                % is non-scalar. Replace the index in s with the value 1
                % and use builtin again.
                n = builtin('numel', v);
                if n == 1
                    self = v;
                elseif n > length(self)
                    error(message('map:DynamicVector:indexOutOfBounds'))
                else
                    s(1).subs = {1};
                    self = builtinSubsasgn( self, s, in);
                end
                
                % Issue a warning if self is not scalar.
                if length(self) > 1 
                    issueSingleInstanceWarning(propname);
                end

            else
                % Obtain the element or elements of self, referenced by
                % s(1). s(1) equals () with an index value.
                v = subsref(self, s(1));
                
                for k=1:length(v)
                    s_one = s(1);
                    s_one.subs = {k};
                    v2 = subsref(v, s_one);
                    
                    % Obtain the property of v2. s(2) references a property
                    % name.
                    propvalue = subsref(v2, s(2));
                    
                    % subsasgn the value, in, to the property value to
                    % create a new property value.
                    propvalue = builtinSubsasgn(propvalue, s(3:end), in);
                    
                    % Assign back to v2. 
                    % Reference using v2(1).PropertyName
                    s_ref = s(1:2);
                    s_ref(1).subs = {1};
                    v2 = subsasgn(v2, s_ref, propvalue);
                    
                    % Assign v2 back to v.
                    v = subsasgn(v, s_one, v2);
                end
                
                % Assign v to self.
                self = subsasgn(self, s(1), v);
                
            end       
        end
        
        %--------------------- concatenate methods ------------------------
              
        function out = vertcat_coordinates(self, inputs)
            % Concatenate coordinates of map.internal.DynamicVector object.
            
            out = self;
            c = out.Coordinates;
            values = zeros(numel(c), length(out));
            for k = 1:numel(c)
                values(k,:) = out.(c{k});
            end
            
            for k = 2:numel(inputs)
                v = inputs{k};
                count = size(values,2);
                values(1, end+1:end+length(v)) = 0;
                for n = 1:numel(c)
                    values(n, count+1:end)  = v.(c{n});
                end
            end
            
            for k = 1:numel(c)
                out.(c{k}) = values(k,:);
            end
        end
        
        %------------------------------------------------------------------
        
        function out = vertcat_fields(self, inputs)
        % Concatenate dynamic fields of map.internal.DynamicVector object.
            
            % Find all common fieldnames.
            out = self;
            f = fieldnames(inputs{1});
            for k = 2:numel(inputs)
                v = inputs{k};
                f(end+1:end+numel(fieldnames(v))) = fieldnames(v);
            end
            f = unique(f,'legacy');
            
            % Determine if property requires cell values
            needCell = false(size(f));
            for k = 1:numel(inputs)
                v = inputs{k};
                for n = 1:numel(f)
                    if isfield(v, f{n})
                        if iscell(v.DynamicProperties.(f{n}))
                            needCell(n) = true;
                        end
                    end
                end
            end
            
            % Make sure all properties exist and are consistent.
            for k = 1:numel(inputs)
                v = inputs{k};
                for n = 1:numel(f)
                    if ~isfield(v, f{n})
                        if needCell(n)
                            inputs{k}.DynamicProperties.(f{n}) = {''};
                        else
                            inputs{k}.DynamicProperties.(f{n}) = 0;
                        end
                    elseif needCell(n) && ~iscell( inputs{k}.DynamicProperties.(f{n}))
                        inputs{k}.DynamicProperties.(f{n}) = ...
                            { inputs{k}.DynamicProperties.(f{n})};
                    end
                end
            end
            
            % All properties exist and are consistent in class type.
            % Concatenate values.
            for n = 1:numel(f)
                value = inputs{1}.pDynamicProperties.(f{n});
                for k = 2:numel(inputs)
                    v = inputs{k};
                    propval = v.pDynamicProperties.(f{n});
                    value(end+1:end+numel(propval)) = propval;
                end
                out.pDynamicProperties.(f{n}) = value;
            end
        end
        
        %--------------------- utility methods ----------------------------
        
        function count = getCount(self)
        % Return the number of elements (count) the object contains.
        
            count = length(self.(self.Coordinates{1}));
        end
        
        %------------------------------------------------------------------
        
        function p = properties_private(self)
        % Return list of properties of self and the character vector,
        % 'DynamicProperties'. Exclude the container properties, defined by
        % the ConstantProperties property value since they are scalar
        % properties.
            
            p = [properties(class(self)); 'DynamicProperties'];
            p(cellcmp(p, self.ConstantProperties)) = [];
        end
        
        %------------------------------------------------------------------
        
        function [S, labels] = convertToStructure(self)
        % Convert self to a scalar structure, S. LABELS is a scalar
        % structure containing field names that match the field names in S.
        % The fields of LABELS contains either a character vector value or
        % empty, depending on whether a label is present for that field
        % name.
            
            headers = cell(2,1);
            headers{1} = ' Collection properties:';
            headers{2} = ' Feature properties:';
            
            names = properties(self);
            labels = cell2struct(cell(1,length(names)), names, 2);
            S = labels;
            
            % Assign constant properties to output structure.           
            p = self.ConstantProperties;
            for k = 1:numel(p)
                S.(p{k}) = self.(p{k});
            end
            labels.(p{1}) = headers{1};
            
            % Assign coordinate properties to output structure.
            p = self.Coordinates;
            for k = 1:numel(p)
                S.(p{k}) = self.(p{k});
            end
            labels.(p{1}) = headers{2};
            
            % Assign dynamic properties to output structure.
            f = fieldnames(self.DynamicProperties);
            for k=1:numel(f)
                value = self.DynamicProperties.(f{k});
                if  isscalar(value) && iscellstr(value)
                    S.(f{k}) = value{:};
                else
                    S.(f{k}) = value;
                end
            end           
        end    
        
        %------------------------------------------------------------------
        
        function tf = isContainerProperty(self, propname)
        % Return true if propname is a container property of self.
        
            tf = any(cellcmp(propname, self.ConstantProperties));
        end
        
        %------------------------------------------------------------------
        
        function self = emptyDefaultElement(self)
        % Construct an empty dynamic vector element that includes setting
        % the coordinates to empty and initializes each dynamic property to
        % the default value depending on the class.
        
            dynamicProperties = self.DynamicProperties;
            names = fieldnames(dynamicProperties);
            self = self.empty;
            if ~isempty(names)
                % Set all the fieldnames to their default values.
                for k = 1:length(names)
                    value = dynamicProperties.(names{k});
                    if iscell(value) && ~isempty(value)
                        v = value{1};
                        if isnumeric(v)
                            value = {[]};
                        elseif ischar(v)
                            value = {''};
                        else
                            value = {false(0)};
                        end
                    elseif ischar(value)
                        value = '';
                    elseif islogical(value)
                        value = false(0);
                    else
                        value = [];
                    end
                    dynamicProperties.(names{k}) = value;
                end
                self.pDynamicProperties = dynamicProperties;
            end
        end
    end
end

%------------------ private functions -------------------------------------

function S = makestruct(pairs)
% Create a structure from input pairs. The pairs need to be validated prior
% to calling this function.

S = struct();
names  = pairs(1:2:end);
values = pairs(2:2:end);
for k = 1:numel(names)
    S.(names{k}) = values{k};
end
end

%--------------------------------------------------------------------------

function values = fieldvalues(S, name)
% Obtain field values from structure

if isscalar(S)
    values = S.(name);
    if ischar(values)
        values = {values};
    end
elseif isCellType(S,name)
    % The elements in the field are character vectors or mixed type or
    % non-scalar. If the elements are column vectors, then transpose them.
    values = {S(:).(name)};
else
    values = [S(:).(name)];
end

if iscell(values)
    % Transpose all column vectors.
    for k=1:length(values)
        v = values{k};
        if iscolumn(v)
            values{k} = v';
        end
    end
end
end

%--------------------------------------------------------------------------

function returnCell = isCellType(S, name)
% Return true if field values of NAME are mixed type,  non-scalar,
% non-numeric or non-logical.

% Determine if the field values require a cell output.
classType = class(S(1).(name));
fcn = @(x)(isscalar(x) && ~issparse(x) && ...
    (islogical(x) || isnumeric(x)) && isequal(classType, class(x)));

returnCell = false;
for k = 1:length(S)
    if ~fcn(S(k).(name))
        returnCell = true;
        break
    end
end
end

%--------------------------------------------------------------------------

function S = replaceFieldnames(S, replaceableFields, new, old)
% Replace old fields of structure S with new fields. replaceableFields is a
% cell array of character vectors containing a list of field names that may
% be replaced. NEW is a cell array of character vectors containing new
% field names. OLD is a cell array of character vectors containing old
% field names. NEW and OLD must match in size.
%
% Replace old fields with new fields under the following conditions:
% 1) old field exists and new field does not exist
% 2) new field is a member of replaceableFields

for k = 1:numel(new)
    if isfield(S,old{k}) && ~isfield(S, new{k}) ...
            && cellcmp(new{k}, replaceableFields)
        S.(new{k}) = S.(old{k});
        S = rmfield(S, old{k});
    end
end
end

%--------------------------------------------------------------------------

function  in = validatevalues(in, classname)
% Validate IN to be valid input for a property.

in = convertStringsToChars(in);
if iscell(in)
    % Validate cell array input.
    % Cell input must be a vector and all inputs must be character vectors
    % or strings. Inputs in the cell array must be row vectors.
    validateattributes(in, {'cell'}, {'vector'}, classname);
    in = convertStringCellToChars(in);
    validFcn = @(x) isValidEmpty(x) || (ischar(x) && (isrow(x) && isvector(x)));
    if ~all(cellfun(validFcn, in))
       error(message('map:DynamicVector:badCellStr'))
    end
    
    % Replace all numeric [] with ''. This prevents a dynamic property from
    % being set to [].
    in = replaceNumericEmptyInCell(in);
else
    % The input IN must be a string (scalar), character, numeric, or
    % logical vector. Note: string input is converted to character vector
    % prior to this branch, but include it in the validateattributes for
    % the error message. Do not use 'scalartext' because the input may also
    % be numeric or logical.
    validateattributes(in, {'numeric','logical','char','string'}, ...
        {'vector'}, classname);
end

% Ensure a row vector for input. If in is not a row vector,
% then transpose it.
if ~isrow(in)
    in = in';
end             
end

%--------------------------------------------------------------------------

function validateindices(s)
% Validate indices. An index may be a logical or positive integer number.
% The last index may be a character vector or cell array of character vectors.

subs = s(1).subs;
if ~isempty(subs)
    % Determine if the first 1:N indices are valid. indices must be real,
    % positive, integer-valued numbers, logicals, or ':'
    index = cellfun(@isIndex, subs(1:end-1));
    if ~(all(index) || isempty(index))
        error(message('map:DynamicVector:invalidSubscript'))
    end
    
    % Validate the last index.
    % This index may be numeric or logical (as above) and may also be a
    % character vector or cell array of character vectors, but only if it
    % is referenced as the last index and not the first and only index.
    subs = subs(end);
    v = subs{:};
    if ~(isIndex(v) || ...
        (numel(s(1).subs) > 1) && (ischar(v) || iscell(v)))
        error(message('map:DynamicVector:invalidSubscript'))
    end
    
    if iscell(v)
        % Last index must be a cell array of character vectors.
        if ~iscellstr(v), ...
            error(message('map:DynamicVector:expectedCellArrayOfStrings'))
        end
    end
    
    % If matrix indexing is being used, then the numeric indices in the
    % dimensions > 1 need to be validated. These indices cannot exceed the
    % value 1. If these values are not validated, then it becomes possible
    % to reference the wrong property elements since they are stored as
    % rows and the object is a column vector. For example, if obj contained
    % 3 elements, then obj(1,2).X would reference the second element of X
    % if not validated. Or obj(1,3,1,'X') would reference the third
    % element.
    if length(s(1).subs) >= 2
        % Find all numeric indices after the first one.
        subs2 = s(1).subs(2:end);
        index = cellfun(@(x) (~isempty(x) && isnumeric(x)), subs2);
        
        % Validate that these values are equal to 1.
        indices = cell2mat(subs2(index));
        if ~all(indices == 1)
            error(message('map:DynamicVector:indexOutOfBounds'));
        end
    end
end
end

%--------------------------------------------------------------------------

function validateEmptyAssignment(s, in, propname)
% Validate whether IN can be assigned to a property.

isNumericEmpty = isnumeric(in) && isempty(in);
if isNumericEmpty && numel(s) >= 2
    % You are not permitted to delete the property using:
    % self.Property(n) = []
    % self.Property{n} = []
    if isscalar(s(2).subs) && isscalar(s(2).subs{1})
        index = num2str(s(2).subs{:});
    else
        index = 'index';
    end
    error(message('map:DynamicVector:operationNotPermitted', ...
        propname, index));
end
end

%--------------------------------------------------------------------------

function tf = isIndex(x)
% Return true if the input X conforms to a valid index value. An index may
% be a logical or positive finite integer number. In addition, a valid
% index may contain the character ':'.

tf = (islogical(x) || all(strcmp(x,':')) || (isreal(x) && all(isfinite(x)) ...
        && isnumeric(x) && all(x > 0)) && isequal(x,fix(x)));
end

%--------------------------------------------------------------------------

function value = adjustValue(value, newlen)
% Adjust VALUE to be length NEWLEN. If NEWLEN is greater than the length of
% VALUE, then expand it using the expansion value, EXPANDVAL.

expandval = expandValue(value);
oldlen = numel(value);
if newlen == 0
    value = [];
elseif newlen < oldlen
    value(newlen+1:end) = [];
elseif newlen > oldlen
    if iscell(expandval) && (newlen - oldlen == 1)
        value{end+1:end+newlen-oldlen} = expandval{:};
    else
        value(end+1:end+newlen-oldlen) = expandval;
    end
end
end

%--------------------------------------------------------------------------

function value = expandValue(in)
% Create a value, based on class type of IN, to be used for expanding
% arrays.

if isnumeric(in)
    value = 0;
elseif islogical(in)
    value = false;
else
    value = {''};
end
end
 
%--------------------------------------------------------------------------

function subs = removeSingletonsFromSubs(subs)
% Remove all ones in dimensions > 1, provided that only ones exists. These
% indices are legal but will cause errors in subsref. SUBS is the subsindex
% provided to subsref.

index = cellfun(@(x)(isequal(x, 1)), subs, 'UniformOutput',false);
if iscell(index)
    index = cell2mat(index);
end

if islogical(index) && all(index(2:end))
    index(1) = false;
    subs(index) = [];
end
end

%--------------------------------------------------------------------------

function in = adjustNumericInput(in, numCoords)
% Adjust the shape of the input IN to match the number of coordinates.

if isscalar(in)
    in = repmat(in, [numCoords, 1]);
elseif numel(in) == 2
    in = in(:);
    for k = 3:numCoords
        in(k, :) = 0;
    end
elseif isvector(in)
    in = in(:)';
    for k = 2:numCoords
        in(k,:) = in(1,:);
    end
elseif isequal(size(in), [2,2])
    for k = 3:numCoords
        in(k,:) = 0;
    end
else
    sz1 = size(in,1);
    sz2 = size(in,2);
    map.internal.assert(sz1 == numCoords || sz2 == numCoords, ...
        'map:DynamicVector:sizeMismatch', numCoords,numCoords);
    if sz2 == numCoords && sz1 ~= sz2
        in = in';
    end
end
end

%--------------------------------------------------------------------------

function v = replaceNumericEmptyInCell(v)
% If V is a cell array containing [] values, then replace them with ''
% values.

if iscell(v)
    % Replace numeric [] with ''.
    index = cellfun(@(x) (isnumeric(x) && isempty(x)),v);
    v(index) = {''};
end
end

%--------------------------------------------------------------------------

function v = cell2values(v, numsubs)
% Extract the cell's contents if they are all numeric, logical, or a
% character vector value. Otherwise return the cell array.
 
if isscalar(v) && numsubs == 1
    % numsubs is 1 which indicates referencing via the object and not the
    % property. v is a cell array and is scalar. In that case, return the
    % contents of the cell array.
    v = v{:};
    
elseif all(cellfun(@(x) (isnumeric(x) || islogical(x)), v))
    % v is a cell array and contains all numeric or logical values.
    % Convert the cell array to a matrix.
    try
        v = cell2mat(v);
    catch e %#ok<NASGU>
        % The cell array could contain mixed numeric types or mixed
        % numeric/logical types, so just return the cell array. There is
        % no need to issue an error.
    end
end
end
                    
%--------------------------------------------------------------------------

function outvalue = builtinSubsasgn(value, s, invalue)
% Use the builtin subsasgn function to make assignment operations. Use
% direct assignment when deleting data members.

if isempty(invalue) && strcmp(s(1).type, '()')
    % Delete indices of outvalue by using assignment. See g778268.
    outvalue = value;
    outvalue(s(1).subs{:}) = [];    
else
    % Use the builtin version of subsasgn to make the assignment.
    outvalue = builtin('subsasgn', value, s, invalue);   
end
end

%--------------------------------------------------------------------------

function fieldStr = builtinDisp(S, fieldname)
% Obtain character vectors for display of map.internal.DynamicVector object
% using builtin. FIELDNAME is the field of S to convert to a character
% vector. FIELDSTR is the FIELDNAME of S converted to a character vector.

% Create a structure containing only the fieldname of S
printS = struct();
printS.(fieldname) = S.(fieldname); %#ok<STRNU>

% Obtain a character vector representation using builtin.
fieldStr = evalc('builtin(''disp'', printS)');

% Remove header added for structs
fieldStr = regexprep(fieldStr,'\s*.<a.*?/a>.*?\n\n','');

% Remove beginning and trailing white space.
% Add a new line character since strtrim removes it.
fieldStr = sprintf('%s\n', strtrim(fieldStr));

end

%--------------------------------------------------------------------------

function  printLine(line, numSpaces, label)
% Print a line.

c = strfind(line,':');
numIndentSpaces = numSpaces - c(1) + 1;
fprintf('%s%s', label(1:numIndentSpaces), line);
end

%--------------------------------------------------------------------------

function printLines(S, info, firstLine)
% Print scalar structure S. INFO is a structure with fieldnames matching S.
% Each fieldname in INFO is either [] or contains a label character vector.
% FIRSTLINE is a character vector containing the first line to print.

% Create label array containing all spaces.
f = fieldnames(info);
m = cellfun(@numel, f);
numIndentSpaces = 4;
numSpaces = max(m) + numIndentSpaces;
label(1:numSpaces) = ' ';

% Print the first line.
fprintf('%s\n\n', firstLine);

% Print each line of the structure. Use MATLAB's builtin disp function to
% convert a field to a character vector.
for n = 1:length(f)
    fieldname = f{n};
    line = builtinDisp(S, fieldname);
    if isfield(info, fieldname) && ~isempty(info.(fieldname))
        fprintf('%s\n', info.(fieldname));
    end
    printLine(line, numSpaces, label);
end
fprintf('\n');
end

%--------------------------------------------------------------------------

function firstLine = getFirstLine(classType, count)
% Determine if a desktop is in use and create the first line of the display
% output.

usingDesktop = desktop('-inuse') && feature('hotlinks');
count = sprintf([' %d' matlab.internal.display.getDimensionSpecifier '1 '], count);
vectorString = ' vector with properties:';
if usingDesktop
    helpString   = '<a href="matlab:helpPopup ';
    firstLine = ...
        [count  helpString classType '">' classType '</a>' vectorString];
else
    firstLine = [count  classType vectorString];
end             
end

%--------------------------------------------------------------------------

function tf = cellcmp(a,b)
% Compare cell, string, or character vector arrays. A and B are either a
% cellstr, character vector, or string array. If A is a character vector,
% then TF is a scalar logical and is true if any member of B matches A. If
% A is a cell or string array, then TF is the same size as A and is true
% for each member of A that is in B. cellcmp returns the same values as
% ismember but is significantly faster.

% Note: if a is a string array, a{k} returns a character vector.
% No need to convert string values.
if ischar(a)
    tf = any(strcmp(a,b));
else
    tf = false(size(a));
    for k=1:length(a)
        tf(k) = any(strcmp(a{k}, b));
    end
end
end

%--------------------------------------------------------------------------

function issueSingleInstanceWarning(propname)
% Issue a warning that signifies a single instance is being set.

w = warning('query','backtrace');
warning('off','backtrace')
warning(message('map:DynamicVector:expectedScalarReference', propname, propname))
warning(w.state, 'backtrace')
end

%--------------------------------------------------------------------------

function tf = isValidEmpty(v)
% return true if V is empty and is numeric, char, or a cell.

tf = isempty(v) && (isnumeric(v) || ischar(v) || iscell(v));
end

%--------------------------------------------------------------------------

function in = convertStringCellToChars(in)
% Convert string values in cell array to character vectors.
% Ensure that string.empty is set to ''.

in = cellfun(@convertStringsToChars, in, 'UniformOutput', false);
index = cellfun(@(x) (iscell(x) && isempty(x)), in);
in(index) = {''};
end

%--------------------------------------------------------------------------

function in = convertStringsToCellstr(in)
% Convert string array or cell input with string values to cellstr output.

if iscell(in)
    in = convertStringCellToChars(in);
else
    in = convertStringsToChars(in);
    if ~iscell(in)
        in = {in};
    end
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

% Copyright 2012-2020 The MathWorks, Inc.
