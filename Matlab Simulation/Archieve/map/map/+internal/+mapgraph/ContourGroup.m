%ContourGroup Abstract class for contour displays
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the class
%       itself may be removed in a future release.
%
%   ContourGroup properties:
%      ContourLabels - Whether to label contours and which to label
%      Fill - Color areas between contour lines
%      FillAlpha - Transparency of contour-fill polygons
%      FillColor - Value or method for selecting contour-fill polygon colors
%      FillColormap - Color map for filled contour intervals
%      FillZ - Height at which to display contour-fill polygons
%      LabelSpacing - Distance between labels in points
%      LevelList - Vector of levels at which contours are computed
%      LineColor - Color value or method for selecting contour line colors
%      LineColormap - Color map for contour lines
%      LineStyle - LineStyle property for contour lines
%      LineWidth - Width of contour lines in points
%      LineZ - Height at which to display contour lines
%      SpatialRef - Spatial referencing object for data grid to be contoured
%      ZData - Data grid from which contour lines are generated
%
%   ContourGroup methods:
%      ContourGroup - Construct ContourGroup object
%      fillPolygonColors - Return one color per contour interval
%      contourLineColors - Return one color per contour level
%      getTextLabelHandles - Find associated text objects
%      refresh - Create or update contour display
%
%   Abstract methods (public):
%      getContourLines - Structure array with one line per contour level
%      getFillPolygons - Structure array with one polygon per contour interval
%      reproject - Reproject contour lines and fill
%
%   Abstract methods (protected):
%      constructContourLine - Construct contour line for a single level 
%      constructFillPolygon - Construct fill polygon for a single interval       
%      validateOnRefresh - Validate property consistency during refresh        
%      labelsPermitted - True if geometry supports contour labels        
%      validateSpatialRef - Validate spatial referencing object

% Copyright 2010-2018 The MathWorks, Inc.

classdef ContourGroup < internal.mapgraph.HGGroupAdapter
            
    properties
        % ContourLabels Whether to label contours and which to label
        %
        %   {'none'} | 'all' | 'manual' | labelList
        %
        %   ContourLabels controls the application of text labels to the
        %   contour lines. Each label contains the value of the contour
        %   level for the corresponding line. ContourLabels can be a
        %   string or a numerical vector listing a subset of the values
        %   in LevelList. By default ('none'), labels are not applied to
        %   any of the contours. Otherwise, lines can be labeled for all
        %   contour levels ('all'), label positions can be selected
        %   interactively ('manual'), or a labels can be applied to a
        %   specific set of levels specified by a numeric vector whose
        %   elements are a subset of the values in the LevelList vector.
        ContourLabels = 'none';
        
        %Fill  Color areas between contour lines
        %
        %   {'off'} | 'on'
        %
        %   By default, one contour line (which may have multiple parts)
        %   is drawn for each contour level. If you set Fill to 'on',
        %   contourm colors the polygonal regions between the lines,
        %   selecting a distinct color for each contour interval based
        %   on the FillColormap property.
        Fill  = 'off';
        
        %FillAlpha Transparency of contour-fill polygons
        %
        %   Scalar in the interval [0 1]
        %
        %   The default value of 1 designates opaque fill polygons; at
        %   the other extreme, the value 0 designates fill polygons
        %   that are completely transparent (invisible).
        FillAlpha = 1;
        
        %FillColor Value or method for selecting contour-fill polygon colors
        %
        %   {'flat'} | ColorSpec | 'none'
        %
        %   By default, a color is selected for each of the contour
        %   intervals represented in the data. The minimum level of each
        %   interval is used to interpolate into the FillColormap. To
        %   specify a single color to be used for all the polygons, you
        %   can set ColorSpec to a three-element RGB vector or one of
        %   the MATLAB predefined names. See the MATLAB ColorSpec
        %   reference page for more information on specifying color. If
        %   you set FillColor to 'none', the fill polygons will not be
        %   visible.
        FillColor = 'flat';

        %FillColormap Color map for fill polygon colors
        %
        %   M-by-3 RBG colormap
        %
        %   This property specifies an M-by-3 array of red, green, and blue
        %   (RGB) values that define M individual colors that are used to
        %   define the colors of the polygonal regions separating contour
        %   lines. One color is needed for each of the intervals defined by
        %   adjacent contour levels, as well as for the areas below the
        %   lowest level and above the highest. To ensure a distinct color
        %   for each interval, M should be at least as large as 1 + the
        %   number of contour levels. If left unspecified, the color map of
        %   the ancestral figure at the time of creation is used by
        %   default. However, subsequent changes to the figure's color map
        %   do not affect the values in FillColormap.
        FillColormap = [];
        
        %FillZ   Z-coordinate at which contour fill polygons are drawn
        %
        %   Finite, real, scalar
        %   
        %   By default, contour fill polygons are drawn in the z == 0
        %   plane. If you set FillZ to a real, scalar, non-zero value,
        %   the fill will be placed in a different horizontal plane.
        FillZ = 0;
        
        %LabelSpacing Distance between labels in points
        %
        %   Finite, real, scalar
        %
        %   Spacing between labels on each contour line. When you
        %   display contour line labels using the ContourLabels
        %   property, the labels by default are spaced 144 points
        %   (2 inches) apart on each line. You can specify the spacing by
        %   setting the LabelSpacing property to a value in points. If
        %   the length of an individual contour line is less than the
        %   specified value, only one contour label is displayed on that
        %   line.
        LabelSpacing = 144;
    end
    
    properties (Dependent = true)
        %LevelList Values at which contour lines are drawn
        %
        %   This property uses a vector of increasing values to specify
        %   the levels at which contour lines drawn.
        LevelList = [];
    end
    
    properties
    
        %LineColor Color value or method for selecting contour line colors
        %
        %   {'flat'} | ColorSpec | 'none'
        %
        %   By default, a color is selected for each of the contour
        %   levels represented in the data. The level values are used to
        %   interpolate into the LineColormap. To specify a single color
        %   to be used for all the contour lines, you can set ColorSpec
        %   to a three-element RGB vector or one of the MATLAB
        %   predefined names. See the MATLAB ColorSpec reference page
        %   for more information on specifying color. If you set
        %   LineColor to 'none', the contour lines will not be visible.
        LineColor = 'flat';
        
        %LineColormap Color map for contour line colors
        %
        %   M-by-3 RBG colormap
        %
        %   This property specifies an M-by-3 array of red, green, and blue
        %   (RGB) values that define M individual colors. To ensure a
        %   distinct color for each line, M should be at least as large as
        %   the number of contour levels. If left unspecified, the color
        %   map of the ancestral figure at the time of creation is used by
        %   default. However, subsequent changes to the figure's color map
        %   do not affect the values in LineColormap. 
        LineColormap = [];
        
        %LineStyle Line style for contour lines
        %
        %   {'-'} | '--' | ':' | '-.' | 'none'
        %
        %   Options for LineStyle include solid (specified by -), dashed
        %   (--), dotted (:), dash-dot (-.), and none. The specifier
        %   strings work the same as for line objects in MATLAB graphics.
        LineStyle = '-';
        
        %LineWidth Width of contour lines
        %
        %   Real, positive scalar
        %
        %   Contour line width is specified in points (1 point = 1/72
        %   inch), and has a default value of 0.5 points.
        LineWidth = 0.5;
        
        %LineZ   Z-coordinate at which contour lines are drawn
        %
        %   Finite, real scalar
        %
        %   By default, contour lines are drawn in the z == 0 plane. If
        %   you set LineZ to a real, scalar, non-zero value, the lines
        %   are drawn in a different horizontal plane. If you set LineZ
        %   to 'levels', the lines for each contour level are drawn in a
        %   different plane, at the z-coordinate corresponding the level
        %   value.
        LineZ = 0;
        
        % Properties for designating "major contour levels" and giving
        % a distinct appearance to the corresponding contours.
        % Unimplemented for now.
        MajorLevelStep = [];
        MajorLevelLineColor = [];
        MajorLevelLineStyle = [];
        MajorLevelLineWidth = [];
    end
        
    properties (Dependent = true)
        %SpatialRef Spatial referencing object for data grid to be contoured
        %
        %   SpatialRef is an instance of a spatial referencing object (or
        %   structure) that relates the data grid to be contoured to a
        %   system of geographic or map coordinates.
        SpatialRef

        %ZData   Data grid to be contoured
        %
        %   This property contains the data from which the contour lines
        %   are generated (specified as the input argument Z). ZData must
        %   be at least a 2-by-2 matrix.
        ZData
    end
    
    properties (Access = protected, Hidden = true)
        % Keep the actual values of the level list, spatial referencing
        % object, and Z-data in the following properties, which enables
        % LevelList, SpatialRef, and ZData to have set methods that can
        % clear the structures cached in pContourLines and
        % pFillPolygons.
        pLevelList = [];
        pSpatialRef = [];
        pZData = [];
    end

    properties (Access = protected, Hidden = true, Transient = true)
        % Cache the geostructs or mapstructs here. They are expensive to
        % compute and probably don't need to change very often.
        pContourLines = [];
        pFillPolygons = [];
        
        % Cache the most recently used Colormap here, for use when the axes
        % CLim is set.
        Colormap = get(groot,'DefaultFigureColormap');
    end

    %---------------------------- Events -------------------------------
    
    events
        LineColormapUpdate
        FillColormapUpdate
    end

    %------------------------ Public methods ---------------------------
    
    methods
        
        function h = ContourGroup(ax, Z, R, levels)
            %ContourGroup(ax, Z, levels) Abstract class constructor
            %
            %   h = internal.mapgraph.ContourGroup() constructs a default
            %   object.
            %
            %   h = internal.mapgraph.ContourGroup(ax, Z, R, levels)
            %   constructs a ContourGroup object and an associated hggroup
            %   object given an axes AX, raster grid Z, referencing object
            %   R, and vector of contour LEVELS.
            
            % Use base class to initialize new object.
            if nargin ~= 0
                args = {ax};
            else
                args = {};
            end
            h = h@internal.mapgraph.HGGroupAdapter(args{:});
                
            if nargin ~= 0
                % Raster data and levels properties.
                h.LevelList = levels;
                h.SpatialRef = R;
                h.ZData = Z;
                
                % Initialize color maps.
                setContourGroupColormaps(h, h.Colormap)
                
                % Start to listen for changes (via PostSet events) in the
                % figure's Colormap property and the axes' CLim property.
                addColorPropertyListeners(h)
                
                % Set up hggroup handle to work with mouse button clicks.
                set(h.HGGroup, 'ButtonDownFcn', @uimaptbx, ...
                    'HitTest', 'on', 'HitTestArea', 'on');
            end
        end
        
        
        function colors = contourLineColors(h, level)
            %contourLineColors Return one color per contour level
            %
            %   colors = contourLineColors(h, level) accepts an array
            %   indicating each of the contour levels actually present in
            %   the data set. It returns an N-by-3 array of RGB colors,
            %   selected from h.LineColormap, or a character array with M
            %   rows. M is the number of contour levels present in the data
            %   set in the contour object h.
            
            if any(strcmp(h.LineColor,{'flat','none'}))
                % Assign a color to each contour level that is represented
                % by an actual contour line. Return an actual color
                % (rather than [], perhaps) even when LineColor is
                % 'none', to work around the fact that the Color
                % property of an HG line cannot be set to 'none'.
                if ~isempty(level)
                    % Create a linear index into h.LevelList that lists
                    % just the levels actually present. (The set of values
                    % in level will always be a subset of h.LevelList,
                    % which cannot be empty, so as long as level is
                    % non-empty their intersection cannot be empty.)
                    [~, cindex] = intersect(h.LevelList, level);
                    
                    % Ideally, the number of colors in h.LineColormap will
                    % match the length of h.LevelList. But if there are
                    % extra colors that's fine -- only the first
                    % numel(h.LevelList) rows of h.LineColormap will be
                    % used. On the other hand, if there are more levels
                    % used than there are colors in the colormap, we need
                    % to clamp the values in cindex to the maximum number
                    % of colors available to avoid running off the end of
                    % the colormap. In this case, the upper contours will
                    % all share the last color in h.LineColormap.
                    n = size(h.LineColormap,1);
                    cindex(cindex > n) = n;
                    
                    % Select colors from the colormap.
                    colors = h.LineColormap(cindex,:);
                else
                    colors = reshape([],[0 3]);
                end
            else
                % h.LineColor is a 3-by-1 RGB value. Replicate it
                % into numel(level) rows.
                colors = h.LineColor(ones(numel(level),1),:);
            end
        end
        
        
        function colors = fillPolygonColors(h, minLevel, maxLevel)
            %fillPolygonColors Return one color per contour interval
            %
            %   colors = fillPolygonColors(h, minLevel, maxLevel) accepts a
            %   pair of arrays indicating the minimum and maximum level for
            %   each of the contour intervals actually present in the data
            %   set. It returns an M-by-3 array of RGB colors selected from
            %   h.FillColormap, or a character array of with M rows. M is
            %   the number elements in minLevel and MaxLevel.

            % Assign a color to each contour interval that is represented
            % by an actual fill polygon.
            if any(strcmp(h.FillColor,{'flat','none'}))
                if ~isempty(minLevel)
                    % Create a linear index that lists just the intervals
                    % actually present.
                    lower = [-Inf h.LevelList];
                    upper = [h.LevelList  Inf];
                    [~, cindexMin] = intersect(lower, minLevel);
                    [~, cindexMax] = intersect(upper, maxLevel);
                    cindex = union(cindexMin, cindexMax);
                    
                    % Clamp values in cindex if they exceed the number of
                    % colors in h.FillColormap. (See comment in the
                    % contourLineColors method for further explanation.)
                    n = size(h.FillColormap,1);
                    cindex(cindex > n) = n;
                    
                    % Select colors from the colormap.
                    colors = h.FillColormap(cindex,:);
                else
                    colors = reshape([],[0 3]);
                end                
            else
                % h.FillColor is a 3-by-1 RGB value. Replicate it into
                % numel(minLevel) rows.
                colors = h.FillColor(ones(numel(minLevel)),:);
            end
            
        end
        
        
        function hText = getTextLabelHandles(h)
            %getTextLabelHandles Find associated text objects
            %
            %   hText = getTextLabelHandles(h) returns the handles of any
            %   text labels associated with the contour object h.
            
            hText = findobj(h.HGGroup,'Type','text');
        end
        
        
        function refresh(h)
            %refresh Create or update contour display
            %
            %   refresh(h) Creates or updates contour lines and fill
            %   polygons (if specified) as determined from the data set
            %   h.ZData, spatial referencing object h.SpatialRef, and list
            %   of contour levels h.LevelList in the contour object h.
            
            % Replace any existing children in h.HGGroup.
            delete(get(h.HGGroup,'Children'))
            h.validateOnRefresh()
            
            cmap = get(ancestor(h.HGGroup,'figure'),'Colormap');
            setContourGroupColormaps(h, cmap)
            
            if strcmp(h.Fill,'on')
                % When fill is on, draw filled contours before drawing
                % contour lines.
                
                % Property settings that are the same for all polygons.
                props = { ...
                    'Selected',   get(h,'Selected'), ...
                    'Visible',    get(h,'Visible'), ...
                    'ButtonDownFcn', @uimaptbx, ...
                    'CData',      [], ...
                    'EdgeColor', 'none', ...
                    'LineStyle', 'none', ...
                    'FaceAlpha', h.FillAlpha};
                
                % Add the polygons for each level going on up.
                S = h.getFillPolygons();
                colors = h.fillPolygonColors([S.MinLevel],[S.MaxLevel]);
                fillcdata = cdataForFillPatches(h);
                for k = 1:numel(S)
                    minLevel = S(k).MinLevel;
                    maxLevel = S(k).MaxLevel;
                    
                    hFill = h.constructFillPolygon(S(k), h.FillZ, props{:}, ...
                        'FaceColor', colors(k,:), ...
                        'Tag', ['contour interval: [' ...
                        num2str(minLevel) ' ' num2str(maxLevel) ']']);
                    
                    if ~isempty(hFill)
                        setappdata(hFill, 'MinLevel', minLevel)
                        setappdata(hFill, 'MaxLevel', maxLevel)
                        % Set fill patch CData so that the color axis
                        % limits will have reasonable values in the
                        % CLimMode 'auto' case.
                        j = find(minLevel <= fillcdata ...
                            & fillcdata <= maxLevel,1);
                        set(hFill,'CData',fillcdata(j))
                    end
                end
            end
            
            % Always draw the contour lines.
            S = h.getContourLines();
            colors = h.contourLineColors([S.Level]);
            
            % A LineColor value of 'none' has to override the LineStyle
            % property -- work around the fact that HG line objects
            % won't accept a Color value of 'none' by altering the
            % LineStyle instead.
            if strcmp(h.LineColor,'none')
                lineStyle = 'none';
            else
                lineStyle = h.LineStyle;
            end
            
            % Property settings that are the same for all contour lines.
            props = { ...
                'Selected',  get(h,'Selected'), ...
                'Visible',   get(h,'Visible'), ...
                'ButtonDownFcn', @uimaptbx, ...
                'LineWidth', h.LineWidth, ...
                'LineStyle', lineStyle};
            
            for k = 1:numel(S)
                level = S(k).Level;
                
                if strcmp(h.LineZ,'levels')
                    % Draw each line at an elevation matching its
                    % level.
                    zdata = level;
                else
                    % Draw all lines at the same elevation.
                    zdata = h.LineZ;
                end
                
                hLine = h.constructContourLine(S(k), zdata, props{:}, ...
                    'Color', colors(k,:), ...
                    'Tag', ['contour line: ' num2str(level)]);
                
                if ~isempty(hLine)
                    setappdata(hLine, 'Level', level)
                end
            end
            
            % If contours are not filled, add auxiliary patches, one per
            % level, to so that the color axis limits will have reasonable
            % values in the ClimMode 'auto' case.
            addLineCData(h)
            
            % Create contour labels, if needed.
            if ~strcmp(h.ContourLabels,'none') && h.labelsPermitted()
                h.labelContours()
            end
            
            %  Restack to ensure standard child order in the map axes.
            map.graphics.internal.restackMapAxes(h.Parent)
        end
    end
    
    %------------------------- Abstract methods ---------------------------

    % The following methods encapsulate dependencies on a specific spatial
    % coordinate system and need to be implemented by concrete classes
    % which subclass internal.mapgraph.ContourGroup.
    
    methods (Abstract = true)
        
        L = getContourLines(h)
        %getContourLines Structure array with one line per contour level
        %
        %   L = getContourLines(h) is invoked from within h.refresh()
        %   and h.contourLineColors(). It returns a line geostruct or
        %   mapstruct L with contour lines corresponding to the current
        %   ZData, SpatialRef, and LevelList properties of the
        %   mapgraph.ContourGroup h, in the appropriate coordinate system.
        %   There is an element for each contour level intersected by
        %   the range of values in h.ZData, and the contour level values
        %   are stored in a 'Level' field.
        
        P = getFillPolygons(h)
        %getFillPolygons Structure array with one polygon per contour interval
        %
        %   P = getFillPolygons(h) is invoked from within h.refresh() and
        %   h.fillPolygonColors(). It returns a polygon geostruct or
        %   mapstruct P with fill polygons corresponding to the current
        %   ZData, SpatialRef, and LevelList properties of the
        %   mapgraph.ContourGroup h, in the appropriate coordinate system.
        %   There is one element for each contour interval intersected by
        %   the range of values in h.ZData, and the limits of each contour
        %   interval are stored in 'MinLevel' and 'MaxLevel' fields.
        
        reproject(h)
        %reproject Reproject contour lines and fill
        %
        %   reproject(h) Refreshes the display in response to changes
        %   in the geometric properties of the map axes ancestor of the
        %   hggroup associated with the contour object h.
    end
    
    methods (Abstract = true, Access = protected) 
        
        hLine = constructContourLine(h, S, varargin)
        %constructContourLine Construct contour line for a single level
        %
        %   hLine = constructContourLine(h, S, <name-value pairs>)
        %   constructs a single contour line object, in the appropriate
        %   coordinate system, from the scalar line geostruct or mapstruct
        %   S. Graphical properties are set via name-value pairs. This
        %   method is invoked from within h.refresh().
 
        hPolygon = constructFillPolygon(h, S, varargin)
        %constructFillPolygon Construct fill polygon for a single interval
        %
        %   hPolygon = constructFillPolygon(h, S, <name-value pairs>)
        %   constructs a single fill polygon, in the appropriate coordinate
        %   system, from the scalar line geostruct or mapstruct S.
        %   Graphical properties are set via name-value pairs. This method
        %   is invoked from within h.refresh().
        
        validateOnRefresh(h)
        %validateOnRefresh Validate property consistency during refresh
        %
        %   validateOnRefresh(h) is invoked from within h.refresh(). It
        %   provides objects from derived classes a chance to validate the
        %   consistency of ContourGroup properties before the refresh
        %   operation is completed.
        
        tf = labelsPermitted(h)
        %labelsPermitted(h) True if geometry supports contour labels
        %
        %   tf = labelsPermitted(h) returns true if contour labels make
        %   sense in the geometry associated with the contour object h, and
        %   false if they do not (as in the case of a "globe projection".)
        %   It is invoked from within h.refresh().
        
        validateSpatialRef(h, value)
        %validateSpatialRef Validate spatial referencing object
        %
        %   validateSpatialRef(h, value) validates the spatial referencing
        %   object property value, specific to the coordinate system in
        %   use. It is invoked from within h.set.SpatialRef.
    end

    %--------------------------- Get methods ------------------------------
    
    methods
        
        function value = get.LevelList(h)
            value = h.pLevelList;
        end
        
        function value = get.SpatialRef(h)
            value = h.pSpatialRef;
        end
        
        function value = get.ZData(h)
            value = h.pZData;
        end
        
    end

    %---------------- Set methods for dependent properties ----------------

    methods
        
        % The following three methods validate their respective
        % properties, then clear the cached structure arrays to ensure
        % that the contour lines and fill polygons get re-computed in
        % the next refresh.
        
        function set.LevelList(h, value)
            validateattributes(value, {'double'}, ...
                {'real','finite','nonempty','row'}, ...
                'mapgraph.ContourGroup','LevelList')
            value = sort(value);
            h.pLevelList = value;
            
            h.pContourLines = [];
            h.pFillPolygons = [];
        end
        
        
        function set.SpatialRef(h, value)
            
            % Apply abstract validating function.
            h.validateSpatialRef(value)
            
            h.pSpatialRef = value;
            
            h.pContourLines = [];
            h.pFillPolygons = [];
        end
        
        
        function set.ZData(h, value)
            validateattributes(value, {'double'}, ...
                {'real','2d'}, 'mapgraph.ContourGroup','ZData')
            h.pZData = value;
            
            h.pContourLines = [];
            h.pFillPolygons = [];
        end
        
    end
            
   %--------------------------- Set methods ------------------------------
       
     methods
        function set.ContourLabels(h, value)
            if ~ischar(value)
                validateattributes(value, {'double'}, ...
                    {'real','finite','nonempty','row'}, ...
                    'mapgraph.ContourGroup','ContourLabels')
                h.ContourLabels = sort(value);
            else
                h.ContourLabels = validatestring(value, ...
                    {'none','all','manual'}, 'mapgraph.ContourGroup', 'ContourLabels');
            end
        end
        
        
        function set.Fill(h, value)
            h.Fill = validatestring(value, {'on','off'}, ...
                'mapgraph.ContourGroup','Fill');
        end
        
        
        function set.FillAlpha(h, value)
            validateattributes(value, {'double'}, ...
                {'real','finite','nonnegative', '<=' 1, 'scalar'}, ...
                'mapgraph.ContourGroup', 'FillAlpha')
            h.FillAlpha = value;
        end
        
        
        function set.FillColormap(h, value)
            validateattributes(value, {'double'}, ...
                {'real','finite','nonnegative', '<=' 1, '2d', 'nonempty', 'ncols', 3}, ...
                'mapgraph.ContourGroup', 'FillColormap')
            
            if ~isequal(value, h.FillColormap)
                h.FillColormap = value;
                h.refreshFillPolygonColors()
                notify(h,'FillColormapUpdate')
            end
        end
        

        function set.FillZ(h, value)
            validateattributes(value,{'double'}, ...
                {'real','finite','scalar'}, 'mapgraph.ContourGroup', 'FillZ')
            h.FillZ = value;
        end
        
        
        function set.LabelSpacing(h, value)
            validateattributes(value,{'double'}, ...
                {'real','finite','scalar'}, 'mapgraph.ContourGroup', 'LabelSpacing')
            h.LabelSpacing = value;
        end
        
        
        function set.LineColor(h, value)
            if ~ischar(value)
                % Validate numeric-valued color specification.
                validateattributes(value, {'double'}, ...
                    {'real','finite','nonnegative','<=',1,'size',[1 3]}, ...
                    'mapgraph.ContourGroup', 'LineColor')
                color = value;
            else
                if isempty(value)
                    % Ignore empty string input.
                    color = '';
                else
                    % We know that value is class char, but is it a row
                    % vector?
                    if ~isrow(value)
                        error(message('map:validate:stringNotRow', 'LineColor'))
                    end
                    
                    % We know that value is a character string.
                    specialValues = {'flat','none'};
                    indx = strncmp(value, specialValues, numel(value));
                    if any(indx)
                        % A special value has been supplied. Because the
                        % two special values start with different letters,
                        % if we reach the following line exactly one of the
                        % two elements in indx will be true.
                        color = specialValues{indx};
                    else
                        % Validate string-valued color specification.
                        try
                            [~, color] = internal.map.parseLineSpec(value);
                        catch e
                            error('map:validate:invalidColorSpec', ...
                                'The string ''%s'' is not a valid color specification.', ...
                                value)
                        end
                    end
                end
            end
            
            if ~isempty(color)
                h.LineColor = color;
            else
                warning('map:validate:expectedColorValueInLineSpec', ...
                    'Ignoring input ''%s'', which is a valid LineSpec but does not contain a color value.', value)
            end
        end
        
        
        function set.LineColormap(h, value)
            validateattributes(value, {'double'}, ...
                {'real','finite','nonnegative','<=',1,'2d','nonempty','ncols',3}, ...
                'mapgraph.ContourGroup', 'LineColormap')
            
            if ~isequal(value, h.LineColormap)
                h.LineColormap = value;
                h.refreshContourLineColors()
                notify(h,'LineColormapUpdate')
            end
        end
        
        
        function set.LineStyle(h, value)
            styleOptions = {'-', '--', ':', '-.', 'none'};
            value = validatestring(value, styleOptions, ...
                'mapgraph.ContourGroup','LineStyle');
            h.LineStyle = value;
        end
        
        
        function set.LineWidth(h, value)
            validateattributes(value, {'numeric'}, ...
                {'real','finite','positive','scalar'}, ...
                'mapgraph.ContourGroup','LineWidth')
            h.LineWidth = value;
        end
        
        
        function set.LineZ(h, value)
            if ~isnumeric(value)
                h.LineZ = validatestring(value, {'levels'}, ...
                    'mapgraph.ContourGroup','LineZ');
            else
                validateattributes(value,{'double'}, ...
                    {'real','finite','scalar'}, 'mapgraph.ContourGroup', 'LineZ')
                h.LineZ = value;
            end
        end
    end

    %--------------------------- Private methods --------------------------

    methods (Access = private)
        
        function labelContours(h)
            % Insert text labels within contour lines
            
            % Locate individual contour lines
            lines = findobj(h.HGGroup, ...
                'Type','line','-regexp','Tag','contour line: +');
            ax = ancestor(h.HGGroup,'axes');
                        
            % Save current view settings because clabel may change them.
            [az, el] = view(ax);
            
            % Label contours and add the labels to the hggroup.
            if strcmp(h.ContourLabels,'manual')
                % Select lines interactively.
                c = linesToContourMatrix(lines);
                hText = clabel_inline(c, lines, h.LineZ, 'manual', h.LabelSpacing);
            elseif isnumeric(h.ContourLabels)
                % Filter out contour lines whose levels are not in the list.
                levels = h.ContourLabels;
                listed = false(size(lines));
                for k = 1:numel(lines)
                    listed(k) = ismember(getappdata(lines(k),'Level'), levels);
                end
                lines(~listed) = [];
                c = linesToContourMatrix(lines);
                hText = clabel_inline(c, lines, h.LineZ, levels, h.LabelSpacing);
            else
                % Label all lines, obtaining levels from their appdata.
                levels = zeros(size(lines));
                for k = 1:numel(lines)
                    levels(k) = getappdata(lines(k),'Level');
                end
                c = linesToContourMatrix(lines);
                hText = clabel_inline(c, lines, h.LineZ, sort(levels), h.LabelSpacing);
            end
            set(hText,'Parent',h.HGGroup)
            
            % Restore view.
            view(ax, az, el)
        end
        
        
        function refreshContourLineColors(h)
            %refreshContourLineColors Update to use current LineColormap
            %
            %   Update the colors of existing contour line objects to use
            %   the current value of the LineColormap property.
            
            hLine = findobj(h.HGGroup,'Type','line','-regexp','Tag','contour line: +');
            if ~isempty(hLine)
                % Reorder handles in ascending order by level
                hLine = hLine(end:-1:1);
                levels = zeros(size(hLine));
                for k = 1:numel(hLine)
                    levels(k) = getappdata(hLine(k),'Level');
                end
                colors = h.contourLineColors(levels);
                for k = 1:numel(hLine)
                    set(hLine(k),'Color',colors(k,:))
                end
            end
        end
        
        
        function refreshFillPolygonColors(h)
            %refreshFillPolygonColors Update to use current FillColormap
            %
            %   Update the colors of existing fill polygon objects to use
            %   the current value of the FillColormap property.
            
            hFill = findobj(h.HGGroup,'Type','patch','-regexp','Tag','contour interval: +');
            if ~isempty(hFill)
                % Reorder handles in ascending order by level
                hFill = hFill(end:-1:1);
                minLevel = zeros(size(hFill));
                maxLevel = zeros(size(hFill));
                for k = 1:numel(hFill)
                    minLevel(k) = getappdata(hFill(k),'MinLevel');
                    maxLevel(k) = getappdata(hFill(k),'MaxLevel');
                end
                colors = h.fillPolygonColors(minLevel, maxLevel);
                for k = 1:numel(hFill)
                    set(hFill(k),'FaceColor',colors(k,:))
                end
            end
        end
        
    end
    
end

%--------------------------------------------------------------------------

function c = linesToContourMatrix(lines)
% Convert contour lines to geographic contour matrix c.

if isempty(lines) 
    c = [];
    return
end

% Allocate contour matrix.
ncols = 0;
for k = 1:numel(lines)
    xd = get(lines(k),'XData');
    ncols = ncols + numel(xd) + 1;
end
c = zeros(2,ncols);

% Fill in contour matrix.
n = 1;
for k = 1:numel(lines)
    % Process the k-th level.
    xd = get(lines(k), 'XData');
    xd = xd(:)';
    yd = get(lines(k), 'YData');
    yd = yd(:)';
    cd = getappdata(lines(k), 'Level');
    z_level = cd(1);

    [first, last] = internal.map.findFirstLastNonNan(xd);
    for j = 1:numel(first)
        % Process the j-th part of the k-th level.
        s = first(j);
        e = last(j);
        x = xd(s:e);
        y = yd(s:e);
        count = numel(x);
        c(:,n) = [z_level; count];
        m = n + count;
        n = n + 1;
        c(1,n:m) = x(:)';
        c(2,n:m) = y(:)';
        n = m + 1;
    end
end
c(:,n:end) = [];

end

%-------------------------------------------------------------------

function setContourGroupColormaps(h, cmap)
% Set the Linecolormap and FillColormap properties of the ContourGroup
% object h by scaling cmap, the colormap of the ancestral figure or parent
% axes. The scaling is relative to the color limits of the axes if its
% CLimMode is 'manual'. The result will be to assign one color per level to
% h.LineColormap and one color per interval to h.FillColormap. (Given n
% levels there are n + 1 intervals.)

ax = ancestor(h.HGGroup,'axes');
if ~isempty(ax) && isvalid(ax)
    levels = h.LevelList;
    if strcmp(get(ax,'CLimMode'),'auto')
        [h.LineColormap, h.FillColormap] ...
            = colormapsForAutoCLim(cmap, levels, h.ZData);
    else
        % Axes CLimMode is 'manual'
        climits = get(ax,'CLim');
        cmin = climits(1);
        cmax = climits(2);
                
        % The scaleColors function assigns colors to the elements of cdata
        % that are in the closed interval [cmin cmax]. But its scaling is
        % based solely on the content of cdata. That's fine for fill
        % colors. But in the case of lines, we need the scaling to take
        % cmin and cmax into account, so we add them to the list, keeping
        % track of where, ensure ascending cdata, peform the scaling, then
        % back out the two extra colors corresponding to the two elements
        % we added. In some cases those colors will be duplicates, and in
        % some cases they will not. That depends on whether cmin or cmax
        % are already members of the set of levels.
        cdata = [cmin levels cmax];
        [cdata, ~, ix] = unique(cdata);
        lineColormap = scaleColors(cmap, cdata, cmin, cmax);
        lineColormap = lineColormap(ix,:);
        h.LineColormap = lineColormap(2:end-1,:);
        
        fillcdata = calculateFillCData(levels, cmin, cmax);
        h.FillColormap = scaleColors(cmap, fillcdata, cmin, cmax);
    end
    
    % Cache latest figure or axes Colormap.
    h.Colormap = cmap;
end
end

%-------------------------------------------------------------------

function [linecmap, fillcmap] = colormapsForAutoCLim(cmap, levels, z)
% Given a colormap to interpolate, CMAP, a set of contour levels, LEVELS,
% and a ZData grid, Z, compute color maps LINECMAP and FILLCMAP for to use
% with direct color mapping in an internal.mapgraph.ContourGroup object.

z = z(:);
zmin = min(z);
zmax = max(z);
geMinZ = (levels >= zmin);
leMaxZ = (levels <= zmax);

if ~any(geMinZ)
    
    % All levels fall below the minimim ZData:
    %   Replicate the first color in cmap.
    n = numel(levels);
    firstColor = cmap(1,:);
    linecmap = firstColor(ones(n,1),:);
    fillcmap = firstColor(ones(n+1,1),:);
    
elseif ~any(leMaxZ)
    
    % All levels fall above the maximum ZData:
    %   Replicate the last color in cmap.
    n = numel(levels);
    lastColor = cmap(end,:);
    linecmap = lastColor(ones(n,1),:);
    fillcmap = lastColor(ones(n+1,1),:);
    
else
    
    % The interval bounding the levels intersects the span of the ZData:
    %   At least some levels fall above the minimum ZData
    %   At least some levels fall below the maximum ZData
    % Scale/interpolate cmap:
    
    % Line Colormap
    cdata = levels;
    cmin = min(levels(geMinZ));  % Smallest level bounded by the data
    cmax = max(levels(leMaxZ));  % Largest level bounded by the data
    linecmap = scaleColors(cmap, cdata, cmin, cmax);    
 
    % Fill Colormap
    cmin = zmin;
    cmax = zmax;
    fillcdata = calculateFillCData(levels, cmin, cmax);
    fillcmap = scaleColors(cmap, fillcdata, cmin, cmax);
end

end

%-------------------------------------------------------------------

function cdata = calculateFillCData(levels, cmin, cmax)

if isscalar(levels)
    cdata = [-Inf Inf];
    if cmin <= levels
        cdata(1) = (cmin + levels)/2;
    end
    if levels <= cmax
        cdata(2) = (levels + cmax)/2;
    end
else
    % We know that levels is non-empty, so it has at least two elements.
    
    % Nominal cdata values: means of adjacent levels, extrapolated by
    % reflecting across the first and last levels.
    cdata = [ ...
        3*levels(1) - levels(2), ...
        levels(1:end-1) + levels(2:end), ...
        3*levels(end) - levels(end-1)] / 2;
    
    % Set cdata to -/+ Inf for intervals that fall outside [cmin cmax].
    cdata([levels  Inf] <= cmin) = -Inf;
    cdata([-Inf levels] >= cmax) =  Inf;

    % Adjust cdata for intervals that contain cmin and/or cmax.
    finite = isfinite(cdata);
    n = sum(finite);
    if n == 1 && isfinite(cmin) && isfinite(cmax)
        % cmin and cmax fall within the same finite interval; reset the
        % cdata value for that interval to equal their mean.
        cdata(finite) = (cmin + cmax)/2;
    elseif n > 1
        if any(finite)
            if isfinite(cmin)
                % cmin falls within a finite interval (and cmax does not
                % fall in that interval); reset the cdata value for that
                % interval to the mean of cmin and the upper limit.
                k = find(finite,1,'first');
                cdata(k) = (cmin + levels(k))/2;
            end
            if isfinite(cmax)
                % cmax falls within a finite interval (and cmin does not
                % fall in that interval); reset the cdata value for that
                % interval to the mean of cmax and the lower limit.
                k = find(finite,1,'last');
                cdata(k) = (levels(k-1) + cmax)/2;
            end
        end
    end
end

end

%-------------------------------------------------------------------

function colors = scaleColors(cmap, cdata, cmin, cmax)
% Scale and subsample the colormap CMAP to assign a color to each element
% of CDATA such that values of CMIN in CDATA are assigned the color
% CMAP(1,:) and values of CMAX are assigned the color CMAP(end,:).

n = size(cmap,1);
if all(cdata < cmin)
    % Replicate the first color.
    index = ones(size(cdata));
elseif all(cdata > cmax)
    % Replicate the last color.
    index = zeros(size(cdata)) + n;
elseif cmin >= cmax  % Always false for manual CLim
    % Replicate the middle color.
    index = zeros(size(cdata)) + round((1 + n)/2);
elseif isfinite(cmin) && cmax == Inf  % Always false for manual CLim
    % Map all elements of cdata to the first color in the colormap, except
    % for values of +Inf. Map those to the last color.
    index = ones(size(cdata));
    index(cdata == Inf) = n;
elseif cmin == -Inf && isfinite(cmax)  % Always false for manual CLim
    % Map all elements of cdata to the last color in the colormap, except
    % for values of -Inf. Map those to the first color.
    index = n + zeros(size(cdata));
    index(cdata == -Inf) = 1;
elseif cmin == -Inf && cmax == Inf  % Always false for manual CLim
    % Map all elements of cdata to the middle color in the colormap.
    index = round((n + 1)/2) + zeros(size(cdata));
    index(cdata == -Inf) = 1;
    index(cdata ==  Inf) = n;
else
    % Both cmin and cmax are finite, with cmin < cmax, and at least one
    % element of levels overlaps the interval [cmin cmax].
    
    index = zeros(size(cdata));
    
    % Clamp the parts that fail to overlap
    index(cdata < cmin) = 1;
    index(cdata > cmax) = n;
    
    % Apply a quasi-linear mapping to the rest.
    q = (index == 0);
    index(q) = internal.mapgraph.cdata2ind(cdata(q),n);
end
colors = cmap(index,:);

end

%-------------------------------------------------------------------

function addLineCData(h)
% There are no patches, and line objects do not have CData. As a
% workaround, for each contour line, construct an "auxiliary" patch
% consisting of only the first vertex, and set its CData to the
% corresponding contour level. This is consistent with the way contour
% manages line colors.
hLine = findobj(h.HGGroup,'Type','line');
if ~isempty(hLine)
    ax = ancestor(hLine(1),'axes');
    n = numel(hLine);
    for k = n:-1:1
        p(k) = oneVertexPatch(ax, hLine(k));
    end
    
    % Push the new patches to the bottom in the list of axes children,
    % to keep them hidden under their respective lines.
    c = get(ax,'Children');
    c = circshift(c, -length(p));
    set(ax,'Children',c)
    
    % Keep these patches from getting processed in setm, for example.
    set(p,'HandleVisibility','off')
end
end

%-------------------------------------------------------------------

function fillcdata = cdataForFillPatches(h)
% Values to be assigned to the CData property of the fill patches. They
% will contribute to the axes CLim value when CLimMode is auto. They are
% not necessarily the same as fillcdata values used to scale the colormap
% in setContourGroupColormaps.

levels = h.LevelList;
z = h.ZData;

z = z(:);
zmin = min(z);
zmax = max(z);
geMinZ = (levels >= zmin);
leMaxZ = (levels <= zmax);

if ~any(geMinZ)
    % All levels fall below the minimim ZData:
    %   Replicate the first color in cmap.
    fillcdata = calculateFillCData(levels, -Inf, zmin);
elseif ~any(leMaxZ)
    % All levels fall above the maximum ZData:
    %   Replicate the last color in cmap.
    fillcdata = calculateFillCData(levels, zmax, Inf);
else
    % The interval bounding the levels intersects the span of the ZData:
    %   At least some levels fall above the minimum ZData
    %   At least some levels fall below the maximum ZData
    % Scale/interpolate cmap:
    cmin = zmin;
    cmax = zmax;
    fillcdata = calculateFillCData(levels, cmin, cmax);
end

end

%-------------------------------------------------------------------

function p = oneVertexPatch(ax, hLine)
% Construct a one-vertex patch coincident with the first vertex in the
% line. Use the contour level corresponding to the line as its CData.

level = getappdata(hLine,'Level');
x = hLine.XData;
y = hLine.YData;
z = hLine.ZData;
if ~isempty(x)
    p = patch('Parent',ax,'XData',x(1),'YData',y(1),'ZData',z(1), ...
        'CData',level,'FaceColor','flat');
else
    p = patch('Parent',ax,'XData',[],'YData',[],'ZData',[], ...
        'CData',level,'FaceColor','flat');
end

% Set the patch handle on the appdata of the line to ensure that it is
% deleted.
setappdata(hLine, 'mapcontourpatch', p)

% Ensure that when a contour line is deleted, the auxiliary
% patch is deleted also.
set(hLine,'DeleteFcn',@deletePatch)
end

%-------------------------------------------------------------------

function deletePatch(hLine, ~)
% Delete the fill patch contained in the appdata of the line.

if ishghandle(hLine, 'line') && isappdata(hLine, 'mapcontourpatch')
    p = getappdata(hLine, 'mapcontourpatch');
    if ishghandle(p, 'patch')
        delete(p)
    end
end
end

%-------------------------------------------------------------------
    
function addColorPropertyListeners(h)
% Prepare to update the colormap properties of the
% internal.mapgraph.ContourGroup object, h, in response to changes in the
% axes's colormap or color limits.

ax = ancestor(h.HGGroup,'axes');
if  ~isempty(ax)
    axListener = addlistener(ax, 'Colormap','PostSet', @axesColormapPostSetCallback);
    climListener = addlistener(ax,'CLim','PostSet', @axesClimPostSetCallback);
    
    hgroupParentListener = addlistener( ...
        h.HGGroup,'Parent','PostSet', @newParentCallback);
    
    axParentListener = addlistener( ...
        ax,'Parent','PostSet', @newParentCallback);
end


    function axesColormapPostSetCallback(~, eventData)
        if isvalid(h)
            g = h.HGGroup;
            if isvalid(g)
                affectedObject = eventData.AffectedObject;
                if isequal(affectedObject,ax) && isvalid(ax)
                    setContourGroupColormaps(h, ax.Colormap)
                end
            end
        end
    end
    
    
    function axesClimPostSetCallback(~, eventData)
        if isvalid(h)
            g = h.HGGroup;
            if isvalid(g)
                affectedObject = eventData.AffectedObject;
                if isequal(affectedObject,ax) && isvalid(ax)
                    setContourGroupColormaps(h, h.Colormap)
                end
            end
        end
    end
    
    
    function newParentCallback(~, ~)
        if strcmp(get(ax,'BeingDeleted'),'off') && isvalid(h)
            f  = ancestor(h.HGGroup,'figure');
            if ~isempty(f)
                setContourGroupColormaps(h, f.Colormap)
                
                % Start over again if the hggroup is re-parented to a new
                % axes or if the axes is re-parented to a new figure.
                delete(axListener)
                delete(climListener)
                delete(hgroupParentListener)
                delete(axParentListener)
                addColorPropertyListeners(h)
            end
        end
    end
end

%--------------------------------------------------------------------------

function hh = clabel_inline(cs, h, lineZ, arg3, labelSpacing)
%CLABEL Contour plot elevation labels.
%   CLABEL(CS, H) adds height labels to the contour plot specified by H.
%   The labels are rotated and inserted within the contour lines.  CS and H
%   are the contour matrix output and object handle outputs from CONTOUR,
%   CONTOUR3, or CONTOURF.
%
%   CLABEL(CS, H, V) labels just those contour levels given in
%   vector V.  The default action is to label all known contours.
%   The label positions are selected randomly.
%
%   CLABEL(CS, H, 'manual') places contour labels at the locations
%   clicked on with a mouse.  Pressing the return key terminates
%   labeling.  Use the space bar to enter contours and the arrow
%   keys to move the crosshair if no mouse is available.
%
%   CLABEL(CS) or CLABEL(CS, V) or CLABEL(CS, 'manual') places
%   contour labels as above, except that the labels are drawn as
%   plus signs on the contour with a nearby height value.
%
%   H = CLABEL(...) returns handles to the TEXT (and possibly LINE)
%   objects in H.  The UserData property of the TEXT objects contain
%   the height value for each label.
%
%   CLABEL(..., 'text property', property_value, ...) allows arbitrary
%   TEXT property/value pairs to specified for the label strings.
%
%   One special property ('LabelSpacing') is also available to specify
%   the spacing between labels (in points). This defaults to 144, or
%   2 inches.

%   Adapted from the following version of clabel.m
%     Revision: 5.38.4.18.4.1  Date: 2010/03/09 14:54:37

if ~isempty(cs)
    validateattributes(cs, {'double'}, {'2d','nrows',2}, 'CLABEL_INLINE', 'CS')
end

cax = ancestor(h(1), 'axes');
threeD = IsThreeD(cax);
h = inline_labels(cax, cs, lineZ, arg3, 'LabelSpacing', labelSpacing);

if ~ishold(cax)
    if threeD
        view(cax, 3);
    else
        view(cax, 2);
    end
end

if nargout > 0
    hh = h;
end
end

function H = inline_labels(cax, CS, lineZ, varargin)
%
% Draw the labels along the contours and rotated to match the local slope.
%

% Original author: R. Pawlowicz IOS rich@ios.bc.ca     12/12/94

manual = 0;
v = [];
inargs = zeros(1, length(varargin));

if nargin >= 4 && strcmp(varargin{1}, 'manual')
    manual = 1;
    inargs(1) = 1;
end

if ~manual && nargin >= 4 && ~ischar(varargin{1})
    v = varargin{1};
    inargs(1) = 1;
end

lab_int = 72 * 2;  % label interval (points)

for k = find(inargs == 0)
    if strncmpi(varargin{k}, 'lab', 3)
        inargs([k, k + 1]) = 1;
        lab_int = varargin{k + 1};
    end
end
varargin(inargs ~= 0) = [];

if (strcmp(get(cax, 'XDir'), 'reverse'))
    XDir = -1;
else
    XDir = 1;
end
if (strcmp(get(cax, 'YDir'), 'reverse'))
    YDir = -1;
else
    YDir = 1;
end

% Compute scaling to make sure printed output looks OK. We have to go via
% the figure's 'paperposition', rather than the absolute units of the axes
% 'position' since those would be absolute only if we kept the 'units'
% property in some absolute units (like 'points') rather than the default
% 'normalized'.

UN = get(cax, 'Units');
parent = get(cax, 'Parent');
if strcmp(UN, 'normalized') && strcmp(get(parent, 'Type'), 'figure')
    UN = get(parent, 'PaperUnits');
    set(parent, 'PaperUnits', 'points');
    PA = get(parent, 'PaperPosition');
    set(parent, 'PaperUnits', UN);
    PA = PA .* get(cax, 'Position');
else
    set(cax, 'Units', 'points');
    PA = get(cax, 'Position');
    set(cax, 'Units', UN);
end

% Find beginning of all lines
lCS = size(CS, 2);

if ~isempty(get(cax, 'Children'))
    XL = get(cax, 'XLim');
    YL = get(cax, 'YLim');
else
    iL = [];
    k = 1;
    XL = [Inf, -Inf];
    YL = [Inf, -Inf];
    while (k < lCS)
        x = CS(1, k + (1 : CS(2, k)));
        y = CS(2, k + (1 : CS(2, k)));
        XL = [min([XL(1), x]), max([XL(2), x])];
        YL = [min([YL(1), y]), max([YL(2), y])];
        iL = [iL, k]; %#ok<AGROW>
        k = k + CS(2, k) + 1;
    end
    set(cax, 'XLim', XL, 'YLim', YL);
end

Aspx = PA(3) / diff(XL);  % To convert data coordinates to paper (we need to do this
Aspy = PA(4) / diff(YL);  % to get the gaps for text the correct size)

H = [];

% Set up a dummy text object from which you can get text extent info
H1 = text(XL(1), YL(1), 'dummyarg', 'Parent', cax, ...
    'Units', 'points', 'Visible', 'off', varargin{:});

% Decompose contour data structure if manual mode.
if manual
    disp(' ')
    disp('    Please wait a moment...')
    x = [];
    y = [];
    ilist = [];
    klist = [];
    plist = [];
    ii = 0;
    k = 0;
    n = 0;
    while (1)
        k = k + 1;
        ii = ii + n + 1;
        if ii > lCS
            break
        end
        n = CS(2, ii);
        nn = 2 .* n - 1;
        xtemp = zeros(nn, 1);
        ytemp = zeros(nn, 1);
        xtemp(1 : 2 : nn) = CS(1, ii + 1 : ii + n);
        xtemp(2 : 2 : nn) = (xtemp(1 : 2 : nn - 2) + xtemp(3 : 2 : nn)) ./ 2;
        ytemp(1 : 2 : nn) = CS(2, ii + 1 : ii + n);
        ytemp(2 : 2 : nn) = (ytemp(1 : 2 : nn - 2) + ytemp(3 : 2 : nn)) ./ 2;
        x = [x; xtemp]; %#ok<AGROW>
        y = [y; ytemp]; %#ok<AGROW>
        ilist = [ilist; ii(ones(nn, 1))]; %#ok<AGROW>
        klist = [klist; k(ones(nn, 1))];  %#ok<AGROW>
        plist = [plist; (1 : .5 : n)'];   %#ok<AGROW>
    end
    ax = axis;
    xmin = ax(1);
    xmax = ax(2);
    ymin = ax(3);
    ymax = ax(4);
    xrange = xmax - xmin;
    yrange = ymax - ymin;
    xylist = (x .* yrange + sqrt(-1) .* y .* xrange);
    view(cax, 2);
    disp(' ')
    disp('   Carefully select contours for labeling.')
    disp('   When done, press RETURN while the Graph window is the active window.')
end

% Get labels all at once to get the length of the longest string.
% This allows us to call extent only once, thus speeding up this routine
if ~manual
    labels = getlabels(CS);
    % Get the size of the label
    set(H1, 'String', repmat('9', 1, size(labels, 2)), ...
        'Visible', 'on', varargin{:});
    EX = get(H1, 'Extent');
    set(H1, 'Visible', 'off');
end

ii = 1;
k = 0;

% Create background and foreground color for the text object.
if isequal(get(cax, 'Visible'), 'off')
    backgroundColor = get(ancestor(cax, 'figure'), 'Color');
else
    backgroundColor = get(cax, 'Color');
end

darkBackgroundValue = .8;
if all(backgroundColor < darkBackgroundValue)
    textColor = [1 1 1];
else
    textColor = [0 0 0];
end

while (ii < lCS)
    if manual
        try
            [xx, yy, button] = ginput(1);
        catch err %#ok<NASGU>
            return
        end
        if isempty(button) || isequal(button, 13)
            break
        end
        if xx < xmin || xx > xmax
            break
        end
        if yy < ymin || yy > ymax
            break
        end
        xy = xx .* yrange + sqrt(-1) .* yy .* xrange;
        dist = abs(xylist - xy);
        [~, f] = min(dist);
        if ~isempty(f)
            f = f(1);
            ii = ilist(f);
            k = klist(f);
            p = floor(plist(f));
        end
    else
        k = k + 1;
    end
    
    l = CS(2, ii);
    x = CS(1, ii + (1 : l));
    y = CS(2, ii + (1 : l));
    
    lvl = CS(1, ii);
    if strcmpi(lineZ, 'levels')
        z = lvl;
    else
        z = lineZ;
    end
    
    if manual
        lab = num2str(lvl);
        % Get the size of the label
        set(H1, 'String', lab, 'Visible', 'on', varargin{:});
        EX = get(H1, 'Extent');
        set(H1, 'Visible', 'off');
        len_lab = EX(3) / 2;
    else
        %RP - get rid of all blanks in label
        lab = labels(k, labels(k, :) ~= ' ');
        %RP - scale label length by string size instead of a fixed length
        len_lab = EX(3) / 2 * length(lab) / size(labels, 2);
    end
    
    % RP28/10/97 - Contouring sometimes returns x vectors with
    % NaN in them - we want to handle this case!
    sx = x * Aspx;
    sy = y * Aspy;
    d = [0, hypot(diff(sx),diff(sy))];
    
    % Determine the location of the NaN separated sections
    section = cumsum(isnan(d));
    d(isnan(d)) = 0;
    d = cumsum(d);
    
    if ~manual
        len_contour = max(0, d(l) - 3 * len_lab);
        slop = (len_contour - floor(len_contour / lab_int) * lab_int);
        start = 1.5 * len_lab + max(len_lab, slop) * rands(1); % Randomize start
        psn = start : lab_int : d(l) - 1.5 * len_lab;
    else
        psn = min(max(max(d(p), d(2) + eps * d(2)), d(1) + len_lab), d(end) - len_lab);
        psn = max(0, min(psn, max(d)));
    end
    psn = sort(psn);
    lp = size(psn, 2);
    
    if (lp > 0) && isfinite(lvl) && ...
            (isempty(v) || any(abs(lvl - v) / max(eps + abs(v)) < .00001))
        
        Ic = sum(d(ones(1, lp), :)' < psn(ones(1, l), :), 1);
        Il = sum(d(ones(1, lp), :)' <= psn(ones(1, l), :) - len_lab, 1);
        Ir = sum(d(ones(1, lp), :)' < psn(ones(1, l), :) + len_lab, 1);
        
        % Check for and handle out of range values
        out = (Ir < 1 | Ir > length(d) - 1) | ...
            (Il < 1 | Il > length(d) - 1) | ...
            (Ic < 1 | Ic > length(d) - 1);
        Ir = max(1, min(Ir, length(d) - 1));
        Il = max(1, min(Il, length(d) - 1));
        Ic = max(1, min(Ic, length(d) - 1));
        
        % For out of range values, don't remove data points under label
        Il(out) = Ic(out);
        Ir(out) = Ic(out);
        
        % Remove label if it isn't in the same section
        bad = (section(Il) ~= section(Ir));
        Il(bad) = [];
        Ir(bad) = [];
        Ic(bad) = [];
        psn(:, bad) = [];
        out(bad) = [];
        lp = length(Il);
        in = ~out;
        
        if ~isempty(Il)
            
            % Endpoints of text in data coordinates
            wl = (d(Il + 1) - psn + len_lab .* in) ./ (d(Il + 1) - d(Il));
            wr = (psn - len_lab .* in - d(Il)) ./ (d(Il + 1) - d(Il));
            xl = x(Il) .* wl + x(Il + 1) .* wr;
            yl = y(Il) .* wl + y(Il + 1) .* wr;
            
            wl = (d(Ir + 1) - psn - len_lab .* in) ./ (d(Ir + 1) - d(Ir));
            wr = (psn + len_lab .* in - d(Ir)) ./ (d(Ir + 1) - d(Ir));
            xr = x(Ir) .* wl + x(Ir + 1) .* wr;
            yr = y(Ir) .* wl + y(Ir + 1) .* wr;
            
            trot = atan2((yr - yl) * YDir * Aspy, (xr - xl) * XDir * Aspx) * 180 / pi;
            backang = abs(trot) > 90;
            trot(backang) = trot(backang) + 180;
            
            % Text location in data coordinates
            wl = (d(Ic + 1) - psn) ./ (d(Ic + 1) - d(Ic));
            wr = (psn - d(Ic)) ./ (d(Ic + 1) - d(Ic));
            xc = x(Ic) .* wl + x(Ic + 1) .* wr;
            yc = y(Ic) .* wl + y(Ic + 1) .* wr;
            
            
            % Display the text. The rotational angle may change for each
            % value of jj; thus the text must be drawn in a loop.
            staticProps = { ...
                'Parent', cax, ...
                'VerticalAlignment',   'middle', ...
                'HorizontalAlignment', 'center', ...
                'Clipping', 'on', ...
                'Color', textColor,...
                'BackgroundColor', backgroundColor,...
                'Interpreter','none', ...
                'UserData', lvl, ...
                'Tag', ['contour label: ' num2str(lvl)]};
            for jj = 1 : lp               
                hText = text(xc(jj), yc(jj), z(1), lab, ...
                    'Rotation', trot(jj), staticProps{:}, varargin{:});
                H = [H; hText]; %#ok<AGROW>            
            end
        end
    end
    
    if ~manual
        ii = ii + 1 + CS(2, ii);
    end
end

% delete dummy string
delete(H1);
end

function labels = getlabels(CS)
    %GETLABELS Get contour labels
    v = [];
    i = 1;
    while i < size(CS, 2)
        v = [v, CS(1, i)]; %#ok<AGROW>
        i = i + CS(2, i) + 1;
    end
    labels = num2str(v');
end

function threeD = IsThreeD(cax)
    %ISTHREED  True for a contour3 plot
    hp = findobj(cax, 'Type', 'patch');
    if isempty(hp)
        hp = findobj(cax, 'Type', 'line');
    end
    if ~isempty(hp)
        % Assume a contour3 plot if z data not empty
        threeD = ~isempty(get(hp(1), 'ZData'));
    else
        threeD = 0;
    end
end

function r = rands(sz)
    %RANDS Uniform random values without affecting the global stream
    dflt = RandStream.getGlobalStream();
    savedState = dflt.State;
    r = rand(sz);
    dflt.State = savedState;
end
