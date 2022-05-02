%GeoScatterGroup Map data class scatter plot in latitude-longitude
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the class
%       itself may be removed in a future release.

% Copyright 2009-2019 The MathWorks, Inc.

classdef GeoScatterGroup < internal.mapgraph.HGGroupAdapter
    
    properties
        % These point-location properties are not in ScatterGroup. They
        % essentially take the place of the ScatterGroup XData and YData
        % properties.
        LatData
        LonData
        
        % ScatterGroup adds the following properties to hggroup. (It adds
        % others as well, including XData and YData, but we don't want
        % those.)
        CData
        SizeData
        LineWidth
        Marker
        MarkerEdgeColor
        MarkerFaceColor        
    end
    
    %======================== public methods ==========================
    
    methods
                
        function h = GeoScatterGroup(ax, lat, lon, varargin)
            % Construct a GeoScatterGroup object and an associated
            % hggroup object.
            
            % Create a temporary, invisible figure and ScatterGroup, and
            % save a copy of its properties in a structure. Plot
            % longitude vs. latitude in order to include _all_ the
            % points, without applying any trimming.
            fInvisible = figure('Visible','off');
            fCleanup = onCleanup(@() close(fInvisible));
            gTemp = scatter(lon, lat, varargin{:});
            scatterGroupProps = get(gTemp);
            
            % Use base class to initialize new object.
            h = h@internal.mapgraph.HGGroupAdapter(ax);
            
            % Assign property values for new object.
            h.setSpecgraphGroupProps(scatterGroupProps)

            h.CData     = scatterGroupProps.CData;
            h.LineWidth = scatterGroupProps.LineWidth;
            h.Marker    = scatterGroupProps.Marker;
            h.MarkerEdgeColor = scatterGroupProps.MarkerEdgeColor;
            h.MarkerFaceColor = scatterGroupProps.MarkerFaceColor;
            h.SizeData = scatterGroupProps.SizeData;
            
            h.LatData = lat;
            h.LonData = lon;
            
            % Trim and project data to fit current map axes.
            mstruct = gcm(ax);
            if usingGlobe(h)
                [x, y, z, cdata, sizedata] = trimAndProject3D(mstruct, ...
                    h.LatData, h.LonData, h.CData, h.SizeData);
                
                % Construct a scattergroup from the trimmed data, and make
                % it the one and only child of the hggroup.
                scatter3(x, y, z, sizedata, cdata, ...
                    'Parent',          h.HGGroup, ...
                    'LineWidth',       h.LineWidth, ...
                    'Marker',          h.Marker, ...
                    'MarkerEdgeColor', h.MarkerEdgeColor, ...
                    'MarkerFaceColor', h.MarkerFaceColor);
            else
                [x, y, cdata, sizedata] = trimAndProject(mstruct, ...
                    h.LatData, h.LonData, h.CData, h.SizeData);
                
                % Construct a scattergroup from the trimmed data, and make
                % it the one and only child of the hggroup.
                scatter(x, y, sizedata, cdata, ...
                    'Parent',          h.HGGroup, ...
                    'LineWidth',       h.LineWidth, ...
                    'Marker',          h.Marker, ...
                    'MarkerEdgeColor', h.MarkerEdgeColor, ...
                    'MarkerFaceColor', h.MarkerFaceColor);
            end
        end
        
        function reproject(h)
            h.refresh()
        end

        function refresh(h)
            % Update h.HGGroup to be consistent with the current
            % properties of h.
            
            g = h.HGGroup;
            
            % Get the current axes, which must be a map axes.            
            ax = ancestor(g,'axes');
            mstruct = gcm(ax);
            
            % Trim and project data to fit the map axes.
            if usingGlobe(h)
                [x, y, z, cdata, sizedata] = trimAndProject3D(mstruct, ...
                    h.LatData, h.LonData, h.CData, h.SizeData);
                
                % Construct a new scattergroup object in the map axes.
                s = scatter3(x, y, z, sizedata, cdata, ...
                    'Parent',          ax, ...
                    'LineWidth',       h.LineWidth, ...
                    'Marker',          h.Marker, ...
                    'MarkerEdgeColor', h.MarkerEdgeColor, ...
                    'MarkerFaceColor', h.MarkerFaceColor);
            else
                [x, y, cdata, sizedata] = trimAndProject(mstruct, ...
                    h.LatData, h.LonData, h.CData, h.SizeData);
                
                % Construct a new scattergroup object in the map axes.
                s = scatter(x, y, sizedata, cdata, ...
                    'Parent',          ax, ...
                    'LineWidth',       h.LineWidth, ...
                    'Marker',          h.Marker, ...
                    'MarkerEdgeColor', h.MarkerEdgeColor, ...
                    'MarkerFaceColor', h.MarkerFaceColor);
            end
            
            % Replace the (one and only) child of h.HGGroup with the
            % new scattergroup.
            delete(get(g,'Children'))
            set(s, 'Parent', g)
        end
    end
        
    methods (Access = private)
        
        function tf = usingGlobe(h)
            % True if and only if the axes ancestor of the hggroup is a
            % map axes with MapProjection set to 'globe'.
            ax = ancestor(h.HGGroup,'axes');
            tf = ismap(ax) && strcmp(getm(ax,'MapProjection'),'globe');
        end
        
    end
end

%======================= Non-Method Utilities ==========================

function [x, y, cdata, sizedata] ...
    = trimAndProject(mstruct, lat, lon, cdata, sizedata)
% Trim the points defined by LAT and LON, and remove the elements of
% CDATA and SIZEDATA that corresponding to any points that are trimmed
% away.

% Convert lat-lon to projected map coordinates.
[x, y] = feval(mstruct.mapprojection, mstruct, lat, lon, 'point', 'forward');

% Where points have been trimmed away their coordinate values in x and y
% will be replaced with NaN. Locate and remove these elements.
indx = isnan(x);

x(indx) = [];
y(indx) = [];

[cdata, sizedata] = trimSizeAndColor(indx, cdata, sizedata);

end

function [x, y, z, cdata, sizedata] ...
    = trimAndProject3D(mstruct, lat, lon, cdata, sizedata)
% Trim the points defined by LAT and LON, and remove the elements of
% CDATA and SIZEDATA that corresponding to any points that are trimmed
% away.

% Convert lat-lon to projected map coordinates.
zdata = zeros(size(lat));
spheroid = map.internal.mstruct2spheroid(mstruct);
[lat, lon] = toDegrees(mstruct.angleunits, lat, lon);
[x, y, z] = geodetic2ecef(spheroid, lat, lon, zdata);

% Where points have been trimmed away their coordinate values in x and y
% will be replaced with NaN. Locate and remove these elements.
indx = isnan(x);

x(indx) = [];
y(indx) = [];
z(indx) = [];

[cdata, sizedata] = trimSizeAndColor(indx, cdata, sizedata);

end

function [cdata, sizedata] = trimSizeAndColor(indx, cdata, sizedata)
% Locate and remove the corresponding CData elements (but only when
% matrix-valued or vector-valued, not scalar-valued).
hasCDataPerPoint = ~isequal(size(cdata),[1 3]) && ~ischar(cdata);
if hasCDataPerPoint
    
    % If vector of CData values, to be scaled to the colormap
    if numel(cdata) == numel(indx)
        cdata = cdata(:);
        cdata(indx) = [];
        
        % If matrix of CData values, one color-triplet per point
    elseif size(cdata,2) == 3 && size(cdata,1) == numel(indx)
        cdata(indx,:) = [];
    end
end

% Locate and remove the corresponding SizeData elements (but only when
% vector-valued, not scalar-valued).
if numel(sizedata) == numel(indx)
    sizedata = sizedata(:);
    sizedata(indx) = [];
end

end
