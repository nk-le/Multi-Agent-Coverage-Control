%GeographicContourGroup Contours in latitude-longitude
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the class
%       itself may be removed in a future release.
%
%   GeographicContourGroup properties:
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
%      SpatialRef - Geographic spatial referencing object or structure
%      ZData - Data grid from which contour lines are generated
%
%   GeographicContourGroup methods:
%      GeographicContourGroup - Construct GeographicContourGroup object
%      fillPolygonColors - Return one color per contour interval
%      contourLineColors - Return one color per contour level
%      getContourLines - Geostruct array with one line per level
%      getFillPolygons - Geostruct array with one polygon per contour interval
%      getTextLabelHandles - Find associated text objects
%      refresh - Create or update contour display
%      reproject - Refresh display in response to map axes geometry

% Copyright 2010-2019 The MathWorks, Inc.

classdef GeographicContourGroup < internal.mapgraph.ContourGroup
        
    %------------------------ Public methods ---------------------------
    
    methods
        
        function h = GeographicContourGroup(varargin)
            %GeographicContourGroup Construct GeographicContourGroup object 
            %
            %   h = internal.mapgraph.GeographicContourGroup() constructs a
            %   default object.
            %
            %   h = internal.mapgraph.GeographicContourGroup(ax, Z, R, levels)
            %   constructs a GeographicContourGroup object h, and an
            %   associated hggroup object, given a parent axes AX, data
            %   grid Z, referencing object R, and a list of contour levels.
            
            % Use base class to initialize new object.
            h = h@internal.mapgraph.ContourGroup(varargin{:});

            %  Restack to ensure standard child order in the map axes.
            map.graphics.internal.restackMapAxes(h)
        end
        
        
        function L = getContourLines(h)
            %getContourLines Contour lines in latitude-longitude
            %
            %   L = getContourLines(h) returns a line geostruct L with
            %   contour lines corresponding to the current ZData,
            %   SpatialRef, and LevelList properties of the contour
            %   object h, in a geographic coordinate system. There is an
            %   element for each contour level intersected by the range
            %   of values in h.ZData, and the contour level values are
            %   stored in a 'Level' field.
            
            if isempty(h.pContourLines)
                % For efficiency, call geocontours only if the contour
                % lines structure hasn't already been computed.
                h.pContourLines ...
                    = geocontours(h.ZData, h.SpatialRef, h.LevelList);
            end
            L = h.pContourLines;
        end
        
        
        function P = getFillPolygons(h)
            %getFillPolygons Fill polygons in latitude-longitude
            %
            %   P = getFillPolygons(h) returns a polygon geostruct P
            %   with fill polygons corresponding to the current ZData,
            %   SpatialRef, and LevelList properties of the contour
            %   object h, in a geographic coordinate system. There is
            %   one element for each contour interval intersected by the
            %   range of values in h.ZData, and the limits of each
            %   contour interval are stored in 'MinLevel' and 'MaxLevel'
            %   fields.

            if isempty(h.pFillPolygons)
                % For efficiency, call geocontours only if the fill
                % polygons structure hasn't already been computed.
               [h.pContourLines, h.pFillPolygons] ...
                    = geocontours(h.ZData, h.SpatialRef, h.LevelList);
            end
            P = h.pFillPolygons;
        end
        
        function reproject(h)
            %reproject Reproject contour lines and fill
            %
            %   reproject(h) Refreshes the display in response to changes
            %   in the geometric properties of the map axes ancestor of the
            %   hggroup associated with the contour object h.
            
            h.refresh()
        end
        
    end
    
    %------------------ Private and protected methods ---------------------
  
    methods (Access = protected)
                
        function hLine = constructContourLine(h, S, zdata, varargin)
            hLine = projectLine(h.HGGroup, S.Lat, S.Lon, zdata, varargin{:});
        end
        
        
        function hPolygon = constructFillPolygon(h, S, zdata, varargin)
            hPolygon = projectPolygonFaces(h.HGGroup, S.Lat, S.Lon, zdata, varargin{:});
        end
        
        
        function validateOnRefresh(h)
            % Check this also: isequal(size(Z), h.SpatialRef.RasterSize)
            if h.usingGlobe()
                if ~strcmpi(h.ContourLabels,'none')
                    warning('map:contour:labelsWithGlobe', ...
                        'Contour labels will not display in a ''%s'' axes.', ...
                        'globe')
                end
                if strcmpi(h.LineZ, 'levels')
                    warning('map:contour:elevateWithGlobe', ...
                        'Contours might not display properly in 3-D in a ''%s'' axes.', ...
                        'globe')
                end
            end
        end
        
        
        function tf = labelsPermitted(h)
            tf = ~h.usingGlobe();
        end
        
        
        function validateSpatialRef(~, value)
            validateattributes(value, {'double','struct', ...
                'map.rasterref.GeographicRasterReference'},{'nonempty'})
        end
        
    end
    
    methods (Access = private)
        
        function tf = usingGlobe(h)
            % True if and only if the axes ancestor of the hggroup is a
            % map axes with MapProjection set to 'globe'.
            ax = ancestor(h.HGGroup,'axes');
            tf= ismap(ax) && strcmp(getm(ax,'MapProjection'),'globe');
        end
        
    end

   %-------------------------- loadobj method -----------------------------

   methods (Static)
       function h = loadobj(S)
           % Construct default object.
           h = internal.mapgraph.GeographicContourGroup;
           
           % Remove fields that were present in R2013b and earlier.
           if isfield(S,'HGGroup')
               S = rmfield(S,'HGGroup');
           end
           if isfield(S,'ObjectIsLoaded')
               S = rmfield(S,'ObjectIsLoaded');
           end
           
           % Use the remaining field values to set the corresponding
           % properties.
           f = fields(S);
          
           % Filter out read-only properties.
           f = setdiff(f,{'Annotation','BeingDeleted','Type'},'stable');
            
           for k = 1:numel(f)
               fieldname = f{k};
               h.(fieldname) = S.(fieldname);
           end
       end
   end
end

%-------------------------- Non-Method Functions -------------------------

function h = projectLine(parent, lat, lon, zdata, varargin)
% Project and display line objects.

ax = ancestor(parent,'axes');
if ismap(ax)
    % There is a map axes; trim and project.
    mstruct = gcm(ax);
    usingGlobe = strcmp(mstruct.mapprojection,'globe');
    if ~usingGlobe
        [x, y] = feval(mstruct.mapprojection, mstruct, ...
            lat, lon, 'geoline', 'forward');
        z = zdata + zeros(size(x));
    else
        spheroid = map.internal.mstruct2spheroid(mstruct);
        [lat, lon] = toDegrees(mstruct.angleunits, lat, lon);
        [x, y, z] = geodetic2ecef(spheroid, lat, lon, zdata);
    end
else
    % No map axes; trim with maptriml then display in ordinary axes.
    [y, x] = maptriml(lat, lon, [-90 90], [-180 180]);
    
    % Ensure row vectors.
    x = x(:)';
    y = y(:)';
    z = zdata + zeros(size(x));
end

% Construct the (multipart) contour line.
h = line('XData', x, 'YData', y, 'ZData', z, varargin{:}, 'Parent', parent);

end

%--------------------------------------------------------------------------

function h = projectPolygonFaces(parent, lat, lon, zdata, varargin)
% Project and a contour fill polygon.  Return a patch handle, assuming that
% at least part of the fill polygon remains after trimming.  Otherwise
% return empty.

h = gobjects(0);

pairs = [varargin {'Parent',parent,'EdgeLine',false}];

ax = ancestor(parent,'axes');
if ismap(ax)
    % There is a map axes; trim and project.
    mstruct = gcm(ax);
    usingGlobe = strcmp(mstruct.mapprojection,'globe');
    if ~usingGlobe
        [x, y] = feval(mstruct.mapprojection, mstruct, ...
            lat, lon, 'geopolygon', 'forward');
        if any(~isnan(x))
            h = map.graphics.internal.mappolygon(x, y, zdata, pairs{:});
        end
    else
        [lat, lon] = toDegrees(mstruct.angleunits, lat, lon);
        spheroid = map.internal.mstruct2spheroid(mstruct);
        h = map.graphics.internal.globepolygon( ...
            spheroid, lat, lon, zdata, pairs{:});
    end
else
    % No map axes; use maptrimp to convert to planar topology then display.
    [y, x] = maptrimp(lat, lon, [-90 90], [-180 180]);
    if any(~isnan(x))
        h = map.graphics.internal.mappolygon(x, y, zdata, pairs{:});
    end
end

end
