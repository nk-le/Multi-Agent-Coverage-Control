%SurfaceAdapter Adapt surface handle for use within map data objects
%
%       FOR INTERNAL USE ONLY -- This class is intentionally undocumented
%       and is intended for use only within other toolbox classes and
%       functions. Its behavior may change, or the class itself may be
%       removed in a future release.

% Copyright 2010-2020 The MathWorks, Inc.

classdef SurfaceAdapter < matlab.mixin.SetGetExactNames
    
    properties (Access = protected, Hidden = true, Transient = true)
        %SurfaceHandle Handle(s) to MATLAB surface object
        %
        %   SurfaceHandle is an array containing a handle or handles to an
        %   associated MATLAB surface object or objects.
        SurfaceHandle
    end
    
    properties (Access = protected, Hidden = true, Dependent = true)
        
        %NamesOfSurfaceProps Surface property Names 
        %
        %   NamesOfSurfaceProps is a cell array of strings containing all
        %   the property names of a MATLAB surface object.
        NamesOfSurfaceProps
    end
    
    methods
        function h = SurfaceAdapter(ax, varargin)
        % Constructor
        
            % Obtain and validate the first input.
            if nargin == 0
                ax = gca;
            else
                assert(isscalar(ax) && ishghandle(ax, 'axes'), ...
                    'map:SurfaceAdapter:invalidAxesHandle', ...
                    'The AXES input must be a valid axes handle.');
            end
            
            % Obtain the surface properties from varargin inputs and assign
            % them to the scalar structure, S.
            validNames = [properties(h)' h.getDefaultSurfacePropNames()]; 
            S = parseProperties(ax, validNames, varargin);
            
            % Update the properties of the class based on values in S.
            S = h.updateProperties(S);
             
            % Display the surface defined by the values in the scalar 
            % structure, S.
            h.refresh(S);
            
            % Use appdata to establish a link back from the surface handle.
            if hasValidSurfaceHandle(h)
               setappdata(h.SurfaceHandle(1), 'mapgraph', h)  
            end
        end
                
        %------------------------------------------------------------------
        
        function refresh(h, varargin)
        % Create or update the object's SurfaceHandle to be consistent with
        % the current properties of h. VARARGIN, if supplied must contain a
        % scalar structure containing fields whose names are property names
        % of a MATLAB surface object.
            
            if numel(varargin) == 1
                surfaceProps = varargin{1};
            else
                % A derived class may have properties associated with a
                % MATLAB surface object. Obtain the properties of h that
                % match the properties of a MATLAB surface object.
                % surfaceProps is returned as a scalar structure.
                surfaceProps = h.getSurfaceProperties();
                
                % Remove empty properties.
                index = structfun(@isempty, surfaceProps);
                names = fieldnames(surfaceProps);
                surfaceProps = rmfield(surfaceProps, names(index));
            end
            
            % Display the surface.
            h.displaySurface(surfaceProps);            
        end
        
        %------------------------------------------------------------------
        
        function s = getPrimarySurfaceHandle(h)
        % Return the handle to the primary MATLAB surface object. 
        
            s = h.SurfaceHandle;
            s(2:end) = [];
            % Eliminate any deleted surface handles.
            s(~ishghandle(s, 'surface')) = [];           
        end
        
        %------------------------------------------------------------------

        function obj = saveobj(obj)
        % Create an object suitable for saving to a MAT-file or FIG-file by
        % removing the reference to the SurfaceHandle create function.
        % Setting CreateFcn to '' prevents load errors from openfig.

            if hasValidSurfaceHandle(obj)
                % Remove reference to CreateFcn.
                sh = obj.SurfaceHandle(1);
                set(sh,'CreateFcn', '')
            end
       end
                        
        %--------------------- set/get methods ----------------------------       
        
        function names = get.NamesOfSurfaceProps(h)
        % Obtain the names of surface properties from the object's surface
        % handle.            
            if hasValidSurfaceHandle(h)
                surfaceProps = get(h.SurfaceHandle(1));
                names = fieldnames(surfaceProps);
            else
                names = {};
            end
        end
    end
    
    methods (Static = true, Hidden = true, Access = protected)
        
        function v = getDefaultSurfacePropNames() 
        % Return a cell array of default surface property names. Derived
        % classes may overload this method.
            v = {'LineStyle', 'ButtonDownFcn'};
        end
    end
    
    methods (Access = protected, Hidden = true)
        
        function S = updateProperties(h, S) %#ok<INUSL>
        % Update the properties of the class based on values in
        % S. (Placeholder for derived classes).
        end
        
        %------------------------------------------------------------------
        
        function surfaceProperties = getSurfaceProperties(h)
        % A list of the property names of the object h that match surface
        % property names.
                        
            S = get(h);
            names = properties(h);
            index = ismember(names, h.NamesOfSurfaceProps,'legacy');
            surfaceProperties = rmfield(S, names(~index));
        end
        
        %------------------------------------------------------------------
        
        function tf = hasValidSurfaceHandle(h)
        % Return true if the object's SurfaceHandle property is valid.
            tf = ~isempty(h.SurfaceHandle) ...
                && all(ishghandle(h.SurfaceHandle, 'surface'));
        end
    end
    
    methods (Access = private)
        
        function displaySurface(h, surfaceProps)
        % Display the scalar structure, surfaceProps, in a MATLAB surface
        % object. If the surface has been already created, then set the new
        % properties; otherwise create a new surface object.
            
            if hasValidSurfaceHandle(h)
                set(h.SurfaceHandle(1), surfaceProps)
            else
                h.SurfaceHandle = surface(surfaceProps);
                
                % Set a DeleteFcn callback such that when the primary
                % surface handle is deleted, any additional surfaces are
                % also deleted.
                set(h.SurfaceHandle,  ...
                    'DeleteFcn', ...
                    {@internal.mapgraph.surfaceAdapterCallback,'delete'}, ...
                    'CreateFcn', ...
                    {@internal.mapgraph.surfaceAdapterCallback,'create'});
                
                % Insert the surface handle into appdata.
                setappdata(h.SurfaceHandle, 'mapgraph_handle', h.SurfaceHandle);
            end
            
            function deleteFunction(~,~) %#ok<DEFNU>
                % This anonymous function is required for backward
                % compatibility with releases prior to R2014a. Prior to
                % R2014a, a function by this name was used as the DeleteFcn
                % callback for the primary surface object. Now that object
                % uses a separate function (see code above) for its
                % DeleteFcn.
            end
        end
    end
end

%--------------------------------------------------------------------------

function S = parseProperties(ax, validNames, props)
% Validate the parameter/value pairs and create a structure S whose
% fields match the parameter names. Adjust the case of the
% fieldnames to match the property names, if required.

% Validate props to contain parameter/value pairs.
internal.map.checkNameValuePairs(props{:});

% The interface to surface allows partial and case-insensitive
% name match. Match the case of the inputs with the proper
% case for properties of h and for the default surface
% properties that any derived class uses.
names = standardizeCasing(props(1:2:end), validNames);

% Remove empty names.
index = cellfun(@isempty, names);
values = props(2:2:end);
names(index)  = [];
values(index) = [];

% Only use the last value if duplicates are found.
% Unique returns last occurrence.
[names, index] = unique(names,'legacy');
if ~isempty(names)
    % Convert the cell parameter/values to a scalar structure.
    values = values(index);
    S = cell2struct(values, names, 2);
    
    % Add the Parent surface property.
    S.Parent = ax;
else
    % Add the Parent surface property.
    S = struct('Parent', ax);
end
end

%--------------------------------------------------------------------------

function names = standardizeCasing(names, validNames)
% Standardize the case of the values in the cell array, NAMES, with the 
% proper case defined by the values in the cell array, VALIDNAMES. Entries
% in NAMES that do not match an entry in VALIDNAMES are ignored.

id = 'standardizeCasing';
for k=1:numel(names)
    try
        names{k} = validatestring(names{k}, validNames, id);
    catch e
        if ~isequal(e.identifier, ...
                ['MATLAB:' id ':unrecognizedStringChoice'])
            rethrow(e)
        end
    end
end
end
