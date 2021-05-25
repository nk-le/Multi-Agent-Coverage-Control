%GeoRaster Surface in latitude-longitude
%
%       FOR INTERNAL USE ONLY -- This class is intentionally undocumented
%       and is intended for use only within other toolbox classes and
%       functions. Its behavior may change, or the class itself may be
%       removed in a future release.
%
%   GeoRaster properties:
%      DisplayType - Type of display for surface
%      SpatialRef  - Geographic referencing object or structure
%      FaceColor - Color of the surface face
%      XData - X data of surface
%      YData - Y data of surface
%      ZData - Z data of surface
%      CData - C data of surface
%      VertexNormals - Vertex normals  of surface

% Copyright 2010-2020 The MathWorks, Inc.

classdef GeoRaster < internal.mapgraph.SurfaceAdapter
    
    properties (Dependent = true)
        %DisplayType Type of display for surface
        %
        %  DisplayType is a string and indicates the type of display for
        %  the surface. A value of '2D' specifies that the surface is set
        %  to the Z = 0 plane and the FaceColor is set to 'texturemap'. A
        %  value of '3D' results in a surface that can be viewed in
        %  three-dimensions and the FaceColor is set to 'interp'.
        DisplayType  
        
        %SpatialRef Geographic referencing object or structure
        %
        %   SpatialRef is either a geographic referencing object or a
        %   scalar structure containing fields, LatMesh, LonMesh.
        SpatialRef
        
        % Surface properties
        FaceAlpha
        FaceColor
        AlphaData
        CData
        XData
        YData
        ZData
        VertexNormals
        
        % Full list of surface properties; the ones that are commented out
        % are not to be accessed from within mapgraph classes. The others
        % (which are declared Dependent) can be accessed via set and get
        % methods.)
        
        % The following surface properties do not have a corresponding
        % class property. 
        %  AlphaDataMapping
        %  Annotation
        %  BeingDeleted
        %  BusyAction
        %  CDataMapping
        %  EdgeAlpha
        %  EdgeColor
        %  LineStyle
        %  LineWidth
        %  Marker
        %  MarkerEdgeColor
        %  MarkerFaceColor
        %  MarkerSize
        %  MeshStyle
        %  FaceLighting
        %  EdgeLighting
        %  BackFaceLighting
        %  AmbientStrength
        %  DiffuseStrength
        %  SpecularStrength
        %  SpecularExponent
        %  SpecularColorReflectance
        %  Children
        %  CreateFcn
        %  DeleteFcn
        %  DisplayName
        %  NormalMode
        %  Selected
        %  SelectionHighlight
        %  Tag
        %  Type
        %  UserData
        %  ButtonDownFcn
        %  Clipping
        %  HandleVisibility
        %  HitTest
        %  Interruptible
        %  UIContextMenu
        %  Visible
    end
    
    properties (GetAccess = private, Hidden = true, Constant = true)
        %PropertiesToListenFor Surface properties that may be listened for
        %
        %   PropertiesToListenFor is a fixed cell array of surface property
        %   names that are associated with a listener when the additional
        %   edge surface is required.
        PropertiesToListenFor = { ...
            'AlphaData', ...
            'AlphaDataMapping', ...
            'CData', ...
            'CDataMapping', ...
            'EdgeAlpha', ...
            'EdgeColor', ...
            'FaceAlpha', ...
            'FaceColor', ...
            'LineStyle', ...
            'LineWidth', ...
            'Marker', ...
            'MarkerEdgeColor', ...
            'MarkerFaceColor', ...
            'MarkerSize', ...
            'MeshStyle', ...
            'XData', ...
            'YData', ...
            'ZData', ...
            'FaceLighting', ...
            'EdgeLighting', ...
            'BackFaceLighting', ...
            'AmbientStrength', ...
            'DiffuseStrength', ...
            'SpecularStrength', ...
            'SpecularExponent', ...
            'SpecularColorReflectance', ...
            'VertexNormals', ...
            'ButtonDownFcn', ...
            'Clipping', ...
            'Visible', ...
            'Parent'}
        
        %NonSurfacePropertyNames Non-surface properties names
        %
        %   NonSurfacePropertyNames is a fixed cell array of non-surface
        %   property names that are associated with this class.
        NonSurfacePropertyNames = ...
                {'DisplayType', ...
                'SpatialRef', ...
                'EdgeSurfaceEnabled', ...
                'ModifiedValues'}
    end

    properties (Hidden, GetAccess = public, SetAccess = private, Transient)
        ObjectIsLoaded = false
    end
    
    properties (Access = private)
        %ModifiedValues Structure of modified Z and C data
        %
        %  ModifiedValues is a structure if the values of ZData and CData
        %  are modified by the class when eliminating northern or southern
        %  NaN values in the coordinate arrays. The structure contains the
        %  following fields:
        %     ZDataTop    - Modified values in first few rows of ZData
        %     ZDataBottom - Modified values in last few rows of ZData
        %     CDataTop    - Modified values in first few rows of CData
        %     CDataBottom - Modified values in last few rows of CData
        %  If the Z and C data are not modified, then ModifiedValues is
        %  empty.        
        ModifiedValues = []
    end
    
    properties (Access = private, Hidden = true)        
        pDisplayType = ''
        pSpatialRef
    end
    
    properties (Access = private, Hidden = true)
        %ListenersEnabled Logical flag
        %
        %   ListenersEnabled is a logical and determines if a surface
        %   property listener is enabled or disabled.
        ListenersEnabled = true
        
        %EdgeSurfaceEnabled Logical flag
        % 
        %   EdgeSurfaceEnabled is a logical and determines if the edge
        %   surface is enabled or disabled.
        EdgeSurfaceEnabled = false        
    end
    
    properties (Access = private, Hidden = true, Dependent = true)
        %EdgeSurfaceVisible Visibility of edge surface
        %
        %   EdgeSurfaceVisible is a string with value 'on' or 'off' and
        %   determines the visibility of the edge surface.
        EdgeSurfaceVisible 
    end
    
    %------------------------ public methods ------------------------------
    
    methods
        
        function h = GeoRaster(ax, Z, R, varargin)
        % Construct a GeoRaster object and an associated surface
        % object.          
            
            % Use base class to initialize new object.  Pass in varargin,
            % default surface properties values, and Z and R values as
            % parameter/value pairs. The base object's parseProperties
            % function parses the values into a structure. The object's
            % updateProperties overloaded method uses these values to
            % create the surface parameter/value pairs. The surface is
            % constructed by the refresh method.
            h = h@internal.mapgraph.SurfaceAdapter(ax, ...
                'ZData',  Z,  'SpatialRef',  R,  ...
                'LineStyle',  'none',  'ButtonDownFcn',  @uimaptbx,  ...
                varargin{:});

            if h.EdgeSurfaceEnabled
                 % Create listeners in order to update properties on the
                 % edge surface.
                 h.addListeners; 
            else
                % An edge surface has not been created. Create a single
                % listener for the CData property in order to update it and
                % the FaceColor property (if required) when the property is
                % set by the user.
                h.addListeners('CData');               
            end
            h.ListenersEnabled = true;
            
            % Set the mapgraph ID.
            setMapGraphID(h.SurfaceHandle);
        end
                
        function reproject(h)
        % Reproject and display the raster.
            h.geosurface()
        end
        
        function refresh(h, varargin)
        % Create or update the surface handle(s) to be consistent with
        % the current properties of h.
        
            % Update the primary surface. Disable the listeners to prevent
            % multiple updates when the primary surface handle is updated.
            cleanObj = onCleanup(@() setObjectProperty(h, 'ListenersEnabled', true));
            h.ListenersEnabled = false;
            refresh@internal.mapgraph.SurfaceAdapter(h, varargin{:}); 
            h.ListenersEnabled = true;
            
            if h.EdgeSurfaceEnabled
                % The edges of the raster meet. Create or update the edge
                % surface.
                h.edgesurface();
            end
            
        end
        
        %--------------------- set methods --------------------------------
        
        function set.DisplayType(h, v)
            validatestring(v, {'2D','3D'}, 'set', 'DisplayType');
            if ~isequal(v, h.DisplayType)
                switch h.DisplayType
                    case '3D'
                        % Convert to 2D
                        zData = h.CData;
                        cData = h.ZData;  
                        faceColor = 'texturemap';
                    case '2D'
                        % Convert to 3D
                        zData = h.CData;
                        cData = h.CData;
                        faceColor = 'interp';
                    case ''
                        % Initial value of DisplayType
                end
                h.pDisplayType = v;
                if h.hasValidSurfaceHandle()
                    cleanObj = onCleanup( ...
                        @() setObjectProperty(h, 'ListenersEnabled', true));
                    h.ListenersEnabled = false;
                    set(h.SurfaceHandle(1), 'ZData', zData, ...
                        'CData', cData, 'FaceColor', faceColor);
                    h.reproject();
                    h.ListenersEnabled = true;
                end
            end
            
        end
        
        function v = get.DisplayType(h)
            v = h.pDisplayType;
        end
        
        function set.SpatialRef(h, v)
            h.pSpatialRef = v;
            if hasValidSurfaceHandle(h)
               h.reproject();
            end
        end
               
        function v = get.SpatialRef(h)
            v = h.pSpatialRef;
        end

        function set.FaceColor(h, v)
            h.setSurfaceProperty('FaceColor', v);
        end
        
        function v = get.FaceColor(h)
            v = h.getSurfaceProperty('FaceColor');
        end
        
        function set.FaceAlpha(h, v)
            h.setSurfaceProperty('FaceAlpha', v);
        end
        
        function v = get.FaceAlpha(h)
            v = h.getSurfaceProperty('FaceAlpha');
        end
        
        function set.AlphaData(h, v)
            h.setSurfaceProperty('AlphaData', v)
        end
        
        function v = get.AlphaData(h)
            v = h.getSurfaceProperty('AlphaData');
        end
        
        function set.CData(h,v)
            h.ModifiedValues = [];
            if hasValidSurfaceHandle(h)
                if ~strcmp(h.FaceColor, 'texturemap')
                    h.FaceColor = 'texturemap';
                end
            end
            h.setSurfaceProperty('CData', v)
        end
        
        function v = get.CData(h)
            v = h.getSurfaceProperty('CData');
        end
        
        function set.XData(h, v)
            h.setSurfaceProperty('XData', v)
        end
        
        function v = get.XData(h)
            v = h.getSurfaceProperty('XData');
        end
        
        function set.YData(h, v)
            h.setSurfaceProperty('YData', v)
        end
        
        function v = get.YData(h)
            v = h.getSurfaceProperty('YData');
        end
        
        function set.ZData(h, v)
            h.ModifiedValues = [];
            if hasValidSurfaceHandle(h)
                set(h.SurfaceHandle(1), 'ZData', v);
             end
        end
        
        function v = get.ZData(h)
            v = h.getSurfaceProperty('ZData');
        end
        
        function set.VertexNormals(h,v)
            if h.hasValidSurfaceHandle()
               set(h.SurfaceHandle(1), 'VertexNormals', v)
               % Split the normals to include only the last and first
               % column for the edge surface.              
               if h.EdgeSurfaceEnabled && ...
                       ishghandle(h.SurfaceHandle(2), 'surface')
                   vData = v(:,[end 1],:);
                   set(h.SurfaceHandle(2), 'VertexNormals', vData);
               end
            end
        end
        
        function v = get.VertexNormals(h)
            v = h.getSurfaceProperty('VertexNormals');
        end
           
        function v = get.EdgeSurfaceVisible(h)
        % Set the EdgeSurfaceVisible property. The edge surface is hidden
        % when the following conditions are true:
        %    1) displaying a 3D surface, and
        %    2) origin of latitude is non-zero 
        %    3) or there exists only one surface handle.
            
            % Obtain the parent.
            parent = getParent(h);
            
            % Obtain the projection structure.
            mstruct = getProjection('Parent', parent);
            
            % Set the value to 'on' or 'off' depending on the conditions.
            if (isequal(h.DisplayType, '3D') ...
                    && ~isempty(mstruct.origin)  ...
                    && mstruct.origin(1) ~= 0) ...
                    || numel(h.SurfaceHandle) == 1
                v = 'off';
            else
                v = 'on';
            end
        end
    end
    
    methods (Static = true)
        
        function obj = loadobj(obj)
        % Update properties when the object is loaded from a MAT-file
        % or from a FIG-file.
        
            % Update ObjectIsLoaded property to true.
            obj.ObjectIsLoaded = true;
            
            % Set the SurfaceHandle property to [] since its Parent
            % property is no longer valid for this object.
            obj.SurfaceHandle = [];
        end
    end
    
    methods (Hidden = true)
        
        function updateMapGraphHandle(h, surfaceHandle)
        % Update the SurfaceHandle property of H to surfaceHandle.
        % Reproject the data to make the object current and add listeners,
        % if the edge surface is present, in order to update surface
        % properties. This method is only intended for use after the
        % object is loaded from a file.
            
            if h.ObjectIsLoaded
                h.SurfaceHandle = surfaceHandle;               
                if numel(h.SurfaceHandle) > 1
                    h.addListeners;
                    h.EdgeSurfaceEnabled = ...
                        strcmpi(get(h.SurfaceHandle(2), 'Visible'), 'on');
                    h.ListenersEnabled = true;
                end
                h.reproject();
            end
        end
    end
    
    methods (Access = protected, Hidden = true)
        
        function setSurfaceProperty(h, propertyName, propertyValue)
        % Set a property/value pair value on the surface object(s).
        
            % Verify that the handles are valid
            if h.hasValidSurfaceHandle() && h.ListenersEnabled
                % If the edges of the surface meet and the property
                % requires refresh, then set the value on the primary
                % surface handle (which validates the property) then
                % refresh the view in order to update additional surface
                % handles.
                if h.EdgeSurfaceEnabled && propertyRequiresRefresh(propertyName)
                    set(h.SurfaceHandle(1), propertyName, propertyValue);
                    S.(propertyName) = propertyValue;
                    h.refresh(S);
                else
                    % Update all surface handles with the new property.
                    for k=1:numel(h.SurfaceHandle)
                        set(h.SurfaceHandle(k), propertyName, propertyValue);
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        
        function v = getSurfaceProperty(h, propertyName)
        % Return a surface object property value.
        
           if h.hasValidSurfaceHandle()
               v = get(h.SurfaceHandle(1), propertyName);
           else
               v = [];
           end
        end
        
        %------------------------------------------------------------------

        function S = updateProperties(h, S)
        % Project the Z data and update the properties of h based on values 
        % in the scalar structure, S. 
        
            % Project the raster surface and put the results (XData, YData,
            % ZData, FaceColor) into fields of S. These field names match
            % surface property names.
            S = projectGeoRaster(S);
            
            % Assign the properties of h from the fields of S that
            % correspond to non-surface properties. Then remove those
            % fields of S that do not correspond to a surface object. The
            % remaining fields of S contain only field names that can be
            % supplied to the surface function.
            S = h.assignNonSurfaceProperties(S);
        end      
    end
     
    %------------------------ private methods -----------------------------
    
    methods (Access = private)
        
        function S = assignNonSurfaceProperties(h, S)
        % S is a scalar structure containing values for both a surface
        % object and h. Assign the properties of h from the fields of S
        % that do not correspond to a surface object and then remove those
        % fields from S. Allow the non-surface fields of S to be
        % case-insensitive and allow a partial match.
        
            names = fieldnames(S);
            id = 'assignNonSurfaceProperties';
            for k=1:numel(names)
                try
                    structName = names{k};
                    names{k} = validatestring( ...
                        names{k},  h.NonSurfacePropertyNames, id);
                    h.(names{k}) = S.(structName);
                    S = rmfield(S, structName);
                catch e
                    if ~isequal(e.identifier, ...
                            ['MATLAB:', id, ':unrecognizedStringChoice'])
                        rethrow(e)
                    end
                end
            end                
        end
        
        %------------------------------------------------------------------
        
        function geosurface(h)
        % Project and display the surface.

            % Convert the properties of h to a scalar structure.
            S = get(h);
            
            % Add the private ModifiedValues property as a field in S,
            % which is necessary because it's not public.
            S.ModifiedValues = h.ModifiedValues;
            
            % Obtain the Parent.
            if ~isfield(S,'Parent')
                S.Parent = getParent(h);
            end
            
            % Project the raster.
            S = projectGeoRaster(S);
            
            % Set non-surface properties from values of S.
            h.EdgeSurfaceEnabled = S.EdgeSurfaceEnabled; 
            h.ModifiedValues = S.ModifiedValues;
            
            % Remove properties that either are not surface properties or
            % should not be set.
            S = rmfield(S, [h.NonSurfacePropertyNames {'VertexNormals'}]);
            
            % Display the surface.
            h.refresh(S);            
        end
        
        %------------------------------------------------------------------
        
        function edgesurface(h)
        % Create and display an edge surface.
        
            % Obtain the surface properties that can be copied from the
            % primary surface handle. edgeProps is a scalar structure.
            edgeProps = getEdgeSurfaceProps(h.SurfaceHandle(1));
            
            % The edges of the surface meet. Create the additional edge
            % surface, overriding the fields in edgeProps.
            surfaceProps = get(h.SurfaceHandle(1));
            edgeProps = createEdgeSurface(surfaceProps, edgeProps);
          
            % If the additional surface already exists, then set the
            % new properties; otherwise, create a new one.
            if numel(h.SurfaceHandle) > 1 && ...
                    ishghandle(h.SurfaceHandle(2), 'surface')
                set(h.SurfaceHandle(2), edgeProps)
            else
                % Create a new surface based on the values in the cell
                % array, edgeProps. Make sure the handle is always
                % invisible and the surface cannot be selected.
                edgeProps.HandleVisibility = 'off';
                edgeProps.SelectionHighlight = 'off';
                edgeProps.Selected = 'off';
                surfaceHandle = surface(edgeProps);
                
                % Add the new surface handle to the property value.
                h.SurfaceHandle(end+1) = surfaceHandle;
                
                % Add surface handles to app data.
                setappdata(h.SurfaceHandle(1), 'mapgraph_handle', h.SurfaceHandle);
            end
            
            % Set the visibility of the edge surface.
            set(h.SurfaceHandle(2), 'Visible', h.EdgeSurfaceVisible);                
        end
        
        %------------------------------------------------------------------
         
        function addListeners(h, varargin)
        % Add property listeners on the object's surface handle. If
        % varargin is empty, then add listeners to all the properties that
        % require it (obtained from the hidden and constant property,
        % PropertiesToListenFor). Otherwise, set listeners on the
        % properties listed in varargin.
            
            % Names of properties to add listeners.
            if isempty(varargin)
                names = internal.mapgraph.GeoRaster.PropertiesToListenFor';
            else
                names = varargin;
            end
            
            % Make sure these names are actually property names of a
            % surface.
            surfaceHandle = h.SurfaceHandle(1);
            names = names(ismember(names, fieldnames(surfaceHandle)));
            
            % Create a structure with field names matching the entries in
            % names. Each field has the value of true.
            tfcell = cellfun(@(x)({true}), names);
            update = cell2struct(tfcell, names);
            
            % Add a listener for each of the properties defined in names.            
            addlistener(surfaceHandle, names, 'PostSet', @setProperty); 
            
            function setProperty(hSrc, evnt)
            % Set the other surface handles held by the object, h, based on
            % the value in the event structure. If the surface property
            % being set corresponds to property of h, then set the property
            % via the set method of h. Otherwise, set the property value on
            % the other surface handle(s). This function is nested and has
            % access to the object, h, and the variable, update.
            
                propName = hSrc.Name;
                if update.(propName)
                    update.(propName) = false;
                    propValue = evnt.AffectedObject.(propName);
                    if h.ListenersEnabled
                        % Only update when the listeners are enabled.
                        if ~isempty(findprop(h, propName))
                            % Use the set method of the object.
                            set(h, propName, propValue);
                            
                            % Refresh the surface objects if the property
                            % requires refresh and an edge surface has been
                            % constructed. This is required in order to
                            % update all the edge surface properties.
                            if propertyRequiresRefresh(propName) ...
                                    && numel(h.SurfaceHandle) > 1
                                S.(propName) = propValue;
                                h.refresh(S);
                            end
                        else
                            % Set the value on the other surface handles.
                            for k=2:numel(h.SurfaceHandle)
                                set(h.SurfaceHandle(k), propName, propValue);
                            end
                        end
                    end
                end
                update.(propName) = true;
            end
        end
        
        %------------------------------------------------------------------
        
        function parent = getParent(h)
        % Obtain parent of the object's surface handle.
            if h.hasValidSurfaceHandle()
                parent = get(h.SurfaceHandle(1), 'Parent');
            else
                parent = gca;
            end
        end
        
        %------------------------------------------------------------------
        
        function setObjectProperty(h, propertyName, propertyValue)
        % Set the property, propertyName, with the value, propertyValue, on
        % the object, h. h is a handle object so the handle does not need
        % to be returned.
        
           h.(propertyName) = propertyValue;
        end
 
    end
    
end

%--------------------------------------------------------------------------

function [lat, lon, edgesMeet, lonlim] = ...
    createLatLonMesh(Z, R, displayType)
% Create a latitude and longitude mesh based on R and the display type.

if isstruct(R)
    lat = R.LatMesh;
    lon = R.LonMesh;
    edgesMeet = false;
    lonlim = [min(lon(:)) max(lon(:))];
else
    [lat, lon, edgesMeet, lonlim] = ...
        createGeoReferencedMesh(Z, R, displayType);
end
end

%--------------------------------------------------------------------------

function [lat, lon, edgesMeet, lonlim] = ...
        createGeoReferencedMesh(Z, R, displayType)
% Create a georeferenced mesh based on R and the display type.

R = map.internal.referencingVectorToMatrix(R, size(Z));

% Calculate the longitude (X) limits.
zWidth = size(Z,2);
lonlim(1) = R(3,1) + R(2,1)/2;
lonlim(2) = R(3,1) + R(2,1) * zWidth +  R(2,1)/2;
lonlim = [min(lonlim) max(lonlim)];

% Determine if the edges meet.
if R(1,1) ~= 0 || R(2,2) ~= 0
    edgesMeet = false;  % R is rotational
else
    edgesMeet = wrapTo360(diff(lonlim)) == 360;
end

% Create the mesh based on the display type. If it is a texture-map
% surface ('2d'), then use cell edges; otherwise if it is a 3D surface,
% then use cell centers.
if strcmpi(displayType, '2d')
    [lon, lat] = celledges(R, size(Z));
else
    [lon, lat] = cellcenters(R, size(Z));
end
end

%--------------------------------------------------------------------------

function [zData, cData, faceColor] = ...
    getZDataAndCData(zData, cData, displayType, meshSize)
% Return zData, cData, and faceColor based on the display type. Update the
% data type of zData and cData if required for either a texture-mapped
% surface or a 3D surface.

needTextureMap = ~isequal(meshSize,size(zData)) || isequal(displayType, '2D');
if needTextureMap
    if isempty(cData)
        cData = zData;
    end
    zData = zeros(meshSize);
    isDoubleOrUint8 = isa(cData, 'double') || isa(cData, 'uint8');
    if ~isDoubleOrUint8
        cData = double(cData);
    end
else
    if isempty(cData)
        cData = zData;
    end
    isDoubleOrSingle = isa(cData, 'double') || isa(cData, 'single');
    if ~isDoubleOrSingle
        needTextureMap = true;
    end
end

if needTextureMap
    faceColor = 'texturemap';
else
    faceColor = 'interp';
end

isSingleOrDouble = isa(zData,'double') || isa(zData,'single');
if ~isSingleOrDouble
    zData = double(zData);
end
end

%--------------------------------------------------------------------------

function edgeProps = createEdgeSurface(surfaceProps, edgeProps)
% Create the edge surface by combining the end column with the first
% column for the Data properties

% Create new surface properties, XData, YData, ZData from the last and
% first column of their corresponding values from the surface handle.
endCol = size(surfaceProps.ZData, 2);
c1 = [endCol 1];

dataNames = {'XData', 'YData', 'ZData'};
for k=1:numel(dataNames)
    edgeProps.(dataNames{k}) = surfaceProps.(dataNames{k})(:,c1);
end

% Create CData and AlphaData from the last column and first column.
dataNames = {'CData', 'AlphaData'};
for k = 1:numel(dataNames)
    if ~isempty(surfaceProps.(dataNames{k}))
        edgeProps.(dataNames{k}) = surfaceProps.(dataNames{k})(:,[end 1],:);
    end
end
end

%--------------------------------------------------------------------------

function tf = propertyRequiresRefresh(propertyName)
% Return true if propertyName matches:
%   'XData', 'YData', 'ZData', 'CData', 'VertexNormals', 'AlphaData'.
% These properties require special handling since they are trimmed when 
% an edge surface is created.

refreshProperties = {'XData', 'YData', 'ZData', 'CData', ...
    'VertexNormals', 'AlphaData', 'FaceAlpha'}; 
tf = any(ismember(propertyName, refreshProperties));
end

%--------------------------------------------------------------------------

function S = projectGeoRaster(S)
% Project a geographic raster defined by values in the scalar structure, S.    

% Define DisplayType if not previously defined.
if ~isfield(S, 'DisplayType')
    S.DisplayType = '3D';
end

% Restore the original values if required.
if isfield(S, 'ModifiedValues') && ~isempty(S.ModifiedValues)
    S = restoreModifiedValues(S);
end

% If '2D' is requested and the CData is not supplied, then
% assign the object's CData to Z.
if isequal(S.DisplayType, '2D') && ~isfield(S,'CData') 
    S.CData = S.ZData;
end

if isequal(S.DisplayType, '2D')
    Z = S.CData;
else
    Z = S.ZData;
end

if ~isfield(S,'CData')
    S.CData = [];
end

% Create the lat, lon mesh.
[lat, lon, S.EdgeSurfaceEnabled, lonlim] = ...
    createLatLonMesh(Z, S.SpatialRef, S.DisplayType);

% Obtain ZData, CData and FaceColor.
[S.ZData, S.CData, faceColor] = ...
    getZDataAndCData(Z, S.CData, S.DisplayType, size(lon));
if ~isfield(S, 'FaceColor')
    S.FaceColor = faceColor;
end

% Obtain the projection structure.
mstruct = getProjection('Parent', S.Parent);

% Project the latitude and longitude coordinates based on the values in the
% mstruct.
[S.XData, S.YData, Z] = map.crs.internal.mfwdtran(mstruct, lat, lon, S.ZData, 'geosurface');

% Treat globe axes separately because of the third dimension.
if strcmpi(mstruct.mapprojection, 'globe')
    S.ZData = Z;
end

% Trim NaN values from the top and bottom edges of the grid if a 3D surface
% is being displayed, the edge surface is enabled, and there is no latitude
% origin rotation (some projections are not defined for certain high and
% low latitude values). This will remove all the NaN values for some
% projections and thus the edge surface will not be needed.
if isequal(S.DisplayType, '3D') && S.EdgeSurfaceEnabled  ...
        && ~isempty(mstruct.origin) && mstruct.origin(1) == 0
    [S.XData, S.YData, S.ZData, S.CData, S.ModifiedValues] = ...
        trimEdgeNanValues(S.XData, S.YData, S.ZData, S.CData);
end
   
% Update the EdgeSurfaceEnabledFlag to determine if an edge surface is
% required. If the coordinates do not contain any NaN values, then an edge
% surface is not required.
S.EdgeSurfaceEnabled = S.EdgeSurfaceEnabled && any(isnan(S.XData(:)));

% If the longitude limits match the frame limits then an edge surface is
% not required.
S.EdgeSurfaceEnabled = S.EdgeSurfaceEnabled ...
    && ~isequal(lonlim, mstruct.flonlimit);
end

%--------------------------------------------------------------------------

function [xData, yData, zData, cData, ModifiedValues] = ...
    trimEdgeNanValues(xData,  yData, zData, cData)
% Trim away NaN values from the top and bottom of the grid when rows
% contain all NaN values.

% If the grid contains all NaN values, then return all values; otherwise,
% trim away the NaN values along the top and bottom of the grid if the rows
% contain all NaN values.
nanValues = isnan(xData);
ModifiedValues = [];
if ~all(nanValues(:))
    rowIndex = find(all(nanValues, 2));
    if ~isempty(rowIndex)
        % Top rows
        rowSelect = (1:numel(rowIndex))';
        topIndex = rowSelect(rowSelect == rowIndex);
        
        % Bottom Rows
        rowSelect = (size(xData,1)-numel(rowIndex)+1:size(xData,1))';
        bottomIndex = rowSelect(rowSelect == rowIndex);
        
        % Save the original values.
        ModifiedValues = struct( ...
            'ZDataTop',    zData(topIndex,:), ...
            'ZDataBottom', zData(bottomIndex,:), ...
            'CDataTop',    cData(topIndex,:), ...
            'CDataBottom', cData(bottomIndex,:));
        
        % Trim away NaN values from top and bottom of the grid.
        nanIndex = [topIndex; bottomIndex];
        xData(nanIndex,:) = [];
        yData(nanIndex,:) = [];
        zData(nanIndex,:) = [];
        cData(nanIndex,:) = [];
    end 
end
end

%--------------------------------------------------------------------------

function S = restoreModifiedValues(S)
% Restore the original ZData and CData values.

S.ZData = [ ...
    S.ModifiedValues.ZDataTop; ...
    S.ZData; ...
    S.ModifiedValues.ZDataBottom];

S.CData = [ ...
    S.ModifiedValues.CDataTop; ...
    S.CData; ...
    S.ModifiedValues.CDataBottom];

S.ModifiedValues = [];
end

%--------------------------------------------------------------------------

function edgeSurfaceProps = getEdgeSurfaceProps(surfaceHandle)
% Return a structure containing surface properties appropriate for copying
% to the edge surface.

% Use only the defined listener properties. All other surface properties
% either can not be set or are not intended to be set.
edgeSurfacePropNames = internal.mapgraph.GeoRaster.PropertiesToListenFor;

% Remove VertexNormals property from the list of properties that have
% listeners attached. VertexNormals can not be applied from the primary
% surface to the edge surface since the property is a different size.
index = strcmpi('VertexNormals', edgeSurfacePropNames);
edgeSurfacePropNames(index) = [];

% Create a list of surface property names that match edgeSurfacePropNames.
surfaceProps = get(surfaceHandle);
surfacePropNames = fieldnames(surfaceProps);
index = ismember(surfacePropNames, edgeSurfacePropNames);
surfacePropNames(index) = [];

% Return the properties as a scalar structure.
edgeSurfaceProps = rmfield(surfaceProps, surfacePropNames);
end

%--------------------------------------------------------------------------

function [x, y] = cellcenters(R, sizeA)
% Cell centers mesh from referencing matrix input, R and raster size sz.
    height = sizeA(1);
    width  = sizeA(2);
    [r,c] = ndgrid(1:height,1:width);
    [x,y] = pix2map(R,r,c);
end

%--------------------------------------------------------------------------

function [x, y] = celledges(R, sizeA)
%CELLEDGES Cell edge mesh for georeferenced image or data grid
%
%   [X, Y] = CELLEDGES(R, SIZEA) computes the edge coordinates for each
%   pixel in a georeferenced image or regular gridded data set.  R is a
%   3-by-2 affine referencing matrix.  SIZEA is size of the image. Its
%   first two elements are HEIGHT and WIDTH.  X and Y are each a
%   (HEIGHT+1)-by-(WIDTH+1) matrix such that X(COL, ROW), Y(COL, ROW) are
%   the map coordinates of the edge of the pixel with subscripts (ROW,COL).

% Obtain the height and width.
height = sizeA(1);
width  = sizeA(2);

% Compute the row, column grid.
xGrid = .5 + (0:height);
yGrid = .5 + (0:width);
[r,c] = ndgrid(xGrid,yGrid);

% Convert the row and columns to x and y.
[x,y] = pix2map(R,r,c);

end

%--------------------------------------------------------------------------

function proj = getProjection(varargin)
%GETPROJECTION Get projection structure
%
%   PROJ = GETPROJECTION(VARARGIN) returns the projection structure from
%   the variable list of arguments in VARARGIN. If the arguments do not
%   contain the parameter/value pair, 'Parent',axes, then PROJ is the
%   default Plate Carree projection.

% Find the Parent parameter from the inputs,
default = [];
parent = map.internal.findNameValuePair('Parent', default, varargin{:});

% If not found, set the parent to gca.
if isempty(parent)
   parent = gca;
end

% Verify that the parent is a valid axis handle and contains a proj struct.
% If true, obtain the projection structure; otherwise, return a default
% projection.
validAxesHandle = isscalar(parent) && ishghandle(parent,'axes');
if validAxesHandle
   proj = get(parent,'UserData');
   if ~isstruct(proj) && ~isfield(proj,'mapprojection')
      proj = getDefaultProjection;
   end
else
   proj = getDefaultProjection;
end
end

%--------------------------------------------------------------------------

function proj = getDefaultProjection
% Create a default Plate Carree projection structure.  
% Use a scalefactor of 180/pi to scale the natural map units (for an earth
% radius of unity) to degrees.

proj = defaultm('pcarree');
proj.scalefactor = 180/pi;
proj = defaultm(proj);
end

%--------------------------------------------------------------------------

function setMapGraphID(surfaceHandle)
% Assign a unique ID to the surfaceHandle object. If surfaceHandle contains
% more than one element, assign the same ID name.

% Find all surface handles in the axes (ancestor of surfaceHandle).
ax = ancestor(surfaceHandle(1), 'axes');
hSurface = findall(ax, 'type', 'surface');

% Find all the surface handles that contain the mapgraph_ID name.
currentID = 0;
appdataName = 'mapgraph_ID';
for k = 1:numel(hSurface)
    h = hSurface(k);
    if isappdata(h, appdataName)
        currentID = max([currentID, getappdata(h, appdataName)]);
    end
end
currentID = currentID + 1;

% Assign the appdata with the currentID number.
for h = surfaceHandle
    setappdata(h, appdataName, currentID);
end
end
