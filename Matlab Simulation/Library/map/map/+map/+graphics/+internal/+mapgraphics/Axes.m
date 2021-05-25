% Axes Axes class for Map Viewer

% Copyright 2012-2020 The MathWorks, Inc.

classdef Axes < matlab.mixin.SetGetExactNames
    
    properties
        ComponentListener
        OrigXLim
        OrigYLim
        OrigPosition
        ViewInfo = [];
    end
    
    
    properties (SetAccess = private)
        hAxes
        Listeners = [];
        Model
        MapUnitInCM = 0;
    end
    
    
    methods
        
        function this = Axes(varargin)
            
            this.hAxes = axes(varargin{:});
            
            setappdata(this.hAxes,'MapGraphicsAxesObject',this)
            
            set(this.hAxes,...
                'DataAspectRatioMode','manual',...
                'DataAspectRatio',[1 1 1],...
                'PlotBoxAspectRatioMode','auto',...
                'NextPlot','Add',...
                'ALimMode','manual',...
                'CLimMode','manual',...
                'XLimMode','manual',...
                'YLimMode','manual',...
                'ZLimMode','manual');
        end
                
        function delete(this)
            if ishandle(this.hAxes)
                delete(this.hAxes)
            end
            
            % Don't attempt to delete the listeners; wait
            % until the event classes are converted.
        end
        
        
        
        function addModel(this,model)
            
            this.Model = model;
            
            % Install Listeners
            this.Listeners = [this.Listeners(:);...
                handle.listener(model,'LayerAdded',{@newlayer model this});...
                handle.listener(model,'LayerRemoved',{@removelayer this});...
                handle.listener(model,'LayerOrderChanged',{@layerorderchanged this});...
                handle.listener(model,'ShowBoundingBox',{@showBoundingBox this});...
                handle.listener(model,'Visible',{@setVisible this})
                ];
            
            % Render the graphics in the model
            model.render(this.hAxes);
        end
        
        
        function adjustPositionInPoints(this, positionDelta)
            % Use 4-by-1 positionDelta vector to adjust the axis position in points.
            
            ax = this.hAxes;
            oldunits = get(ax,'Units');
            set(ax,'Units','Points')
            set(ax,'Position',get(ax,'Position') + positionDelta)
            set(ax,'Units',oldunits)
        end
        
        
        function ax = getAxes(this)
            % Return an HG axes handle for this object.
            
            ax = this.hAxes;
        end
        
        
        function bbox = getAxesLimits(this)
            %   Returns the axes lower-left and upper-right corners
            %   [lower-left-x,y; upper-right-x,y],
            %
            %      or equivalently,  [left      bottom;
            %                         right        top]
            
            ax = this.hAxes;
            xLimits = get(ax,'XLim');
            yLimits = get(ax,'YLim');
            bbox = [xLimits(:) yLimits(:)];
        end
        
        
        function center = getCenter(this)
            %GETCENTER Get center of axes
            %
            %   CENTER = GETCENTER returns the coordinates of the center of
            %   the map in map units. CENTER is a 2 element array [X Y],
            %   the x and y coordinates of the center of the axes.
            
            ax = this.hAxes;
            center = [sum(get(ax,'XLim')) sum(get(ax,'YLim'))]/2;
        end
        
        
        function h = getLayerHandles(this,layerName)
            %Get all graphics handles for a layer with the specified layerName.
            
            getLayerName = @(hChild) get(hChild,'Tag');
            
            % Group results by name, and be sure to return handles (not doubles).
            children = get(this.hAxes,'Children');
            h = children(strcmp(layerName, ...
                arrayfun(getLayerName,children,'UniformOutput',false)));
        end
        
        
        function scale = getScale(this)
            %GETSCALE Returns the absolute map scale.
            
            if this.MapUnitInCM == 0
                scale = [];
            else
                ax = this.hAxes;
                units = get(ax,'Units');
                set(ax,'Units','Centimeters')
                p = get(ax,'Position');
                set(ax,'Units',units)
                xScale = p(3) / (diff(get(ax,'XLim')) * this.MapUnitInCM);
                yScale = p(4) / (diff(get(ax,'YLim')) * this.MapUnitInCM);
                scale = min([xScale, yScale]);
            end
            
        end
        
        
        function localPan(this,startPt)
            % Shift axes limits by the difference between the current point
            % and an input startPt.
            
            ax = this.hAxes;
            p = get(ax,'CurrentPoint');
            set(ax,...
                'XLim',get(ax,'XLim') - (p(1) - startPt(1)), ...
                'YLim',get(ax,'YLim') - (p(3) - startPt(2)));
        end
        
        
        function [xLimits, yLimits] = rectanglePositionToMapLimits(this,rect_pos)
            % Given a rectangle defined by a position vector in pixel
            % units, compute the corresponding limits in map coordinates.
            
            ax = this.hAxes;
            
            xLimits = get(ax,'XLim');
            yLimits = get(ax,'YLim');
            
            axes_pos = map.graphics.internal.getPositionInPoints(ax);
            
            xlim_pos_ratio = diff(xLimits)/(axes_pos(3));
            ylim_pos_ratio = diff(yLimits)/(axes_pos(4));
            
            xLimits = xLimits(1) + xlim_pos_ratio * (rect_pos(1) + [0 rect_pos(3)]);
            yLimits = yLimits(1) + ylim_pos_ratio * (rect_pos(2) + [0 rect_pos(4)]);
        end
        
        
        function refitAxisLimits(this)
            %REFITAXISLIMITS
            %   sets the axis limits so that the a 10 point border is
            %   maintained around the axis.
            
            ax = this.hAxes;
            set(ax, 'DataAspectRatioMode','auto')               
            
            p = map.graphics.internal.getPositionInPoints(ax);
            if prod(p(3:4)) > 0
                axisProportion = p(3)/p(4);
            end
            
            oldXlim = get(ax,'XLim');
            oldYlim = get(ax,'YLim');
            if (diff(oldXlim)/diff(oldYlim) < 0)
                return;
            end
            
            if ( diff(oldXlim)/diff(oldYlim) < axisProportion )
                % the x Axis limits need rescaling
                newLimRange = diff(oldYlim) * p(3)/p(4);
                set(ax,'XLim', sum(oldXlim)/2 + newLimRange * [-1/2, 1/2]);
            else
                newLimRange = diff(oldXlim) * p(4)/p(3);
                set(ax,'YLim', sum(oldYlim)/2 + newLimRange * [-1/2, 1/2]);
            end
        end
        
        
        function resizeLimits(this)
            % Resize the axes limits to negate any rescaling
            
            ax = this.hAxes;
            
            p = map.graphics.internal.getPositionInPoints(ax);
            xChngFactor = p(3) / this.OrigPosition(3);
            yChngFactor = p(4) / this.OrigPosition(4);
            
            xlim = sum(this.OrigXLim)/2 + [-1/2, 1/2] * diff(this.OrigXLim) * xChngFactor;
            ylim = sum(this.OrigYLim)/2 + [-1/2, 1/2] * diff(this.OrigYLim) * yChngFactor;
            
            if diff(xlim) > 0
                set(ax,'XLim',xlim);
            end
            if diff(ylim) > 0
                set(ax,'YLim',ylim);
            end
            
        end
        
        
        function setAxesLimits(this,bbox)
            %SETAXESLIMITS Set extent of axes
            %
            %   SETAXESLIMITS(BBOX) sets the extent of the axes to the bounding box BBOX.
            
            x = squeeze(bbox(:,1,:)); % 2-by-n with all the x-bounds
            y = squeeze(bbox(:,2,:)); % 2-by-n with all the y-bounds
            
            set(this.hAxes,...
                'XLim',roundinterval([min(x(:)) max(x(:))]),...
                'YLim',roundinterval([min(y(:)) max(y(:))]));
        end
        
        
        function setCenter(this,center)
            %SETCENTER Set axis center
            %
            %   SETCENTER(CENTER) sets the center of the map to be CENTER.
            %   CENTER is a 2 element array [X Y], the x and y coordinates,
            %   in map units, of the center of the axes.
            
            if isempty(this.mapUnitInCM)
                error(['map:' mfilename ':mapError'], ...
                    'MapUnitInCM must be set before changing the center.')
            else
                ax = this.hAxes;
                units = get(ax,'Units');
                set(ax,'Units','Centimeters')
                p = get(ax,'Position');
                xLimits = center(1) + p(3) * [-1/2 1/2] / (this.getScale * this.mapUnitInCM);
                yLimits = center(2) + p(4) * [-1/2 1/2] / (this.getScale * this.mapUnitInCM);
                set(ax,'XLim',xLimits,'YLim',yLimits)
                set(ax,'Units',units)
            end
        end
        
        
        function setMapUnitInCM(this,mapUnitInCM)
            %SETMAPUNITINCM Set map units
            %
            %   SETMAPUNITINCM(MAPUNITINCM) specifies the number of
            %   centimeters in a map unit. For example, if the map is in
            %   meters, then mapUnitInCM should be 100, because there are
            %   100 centimeters in a meter.
            
            this.MapUnitInCM = mapUnitInCM;
        end
        
        
        function setScale(this,scale)
            %SETSCALE set map scale
            %
            %   SETSCALE(DISPLAYSCALE) sets the absolute map scale to be
            %   the value of DISPLAYSCALE. Typically this number is small.
            %   For example, setting the DISPLAYSCALE to be 0.00001 means
            %   that 1 mile on the ground covers 0.0001 miles on the map.
            
            if isempty(this.MapUnitInCM)
                error(['map:' mfilename ':mapError'], ...
                    'MapUnitInCM must be set before changing the scale.')
            else
                ax = this.hAxes;
                units = get(ax,'Units');
                set(ax,'Units','Centimeters')
                xCenterInMapUnits = sum(get(ax,'XLim')) / 2;
                yCenterInMapUnits = sum(get(ax,'YLim')) / 2;
                p = get(ax,'Position');
                xLimits = xCenterInMapUnits + p(3) * [-1/2 1/2] / (scale * this.MapUnitInCM);
                yLimits = yCenterInMapUnits + p(4) * [-1/2 1/2] / (scale * this.MapUnitInCM);
                set(ax,'XLim',xLimits,'YLim',yLimits)
                set(ax,'Units',units)
                
                this.updateOriginalAxis();
            end
            
        end
        
        
        function updateOriginalAxis(this)
            %UPDATEORIGINALAXIS
            %  changes the OrigPosition, OrigXLim and OrigYLim fields of
            %  the map axis.
            
            ax = this.hAxes;
            
            oldunits = get(ax,'Units');
            set(ax,'Units','points')
            this.OrigPosition = get(ax,'Position');
            this.OrigXLim = get(ax,'XLim');
            this.OrigYLim = get(ax,'YLim');
            set(ax,'Units',oldunits)
        end
        
    end
    
end

%=========================================================================

function y = roundinterval( x )

% Round out an interval: Let d be the length of the interval divided by 10.
% Find f, the closest value to d of the form 10^n, 2 * 10^n, or 5 * 10^n.
% Subtract f from min(x) and round down to the nearest multiple of f.
% Add f to max(x) and round up to the nearest multiple of f.

d = abs(x(2)-x(1))/10;
if d ==0
    % If the interval x degrades to a point, numerically nudge the interval
    % x to 2*eps(x) about the location of the point. HG requires that XLim
    % and YLim intervals are increasing.
    point_val = x(1);
    y = [-eps(point_val) eps(point_val)]+point_val;
else
    e = [1 2 5 10] * 10^(floor(log10(d)));
    [~, i] = min(abs(e - d));
    f = e(i);
    y = f * [floor(min(x)/f - 1) ceil(max(x)/f + 1)];
end

end

%-------------------------------------------------------------------------

function h = createComponentListener(layer,model,hMapAxes)

componentProp = findprop(layer,'Components');
h = handle.listener(layer,componentProp,...
    'PropertyPostSet',{@newcomponent model hMapAxes});

end

%-------------------------------------------------------------------------

function reorderChildren(hMapAxes,layerorder)

newChildren = [];
for i=1:length(layerorder)
    newChildren = [newChildren; hMapAxes.getLayerHandles([layerorder{i} '_BoundingBox']);...
        hMapAxes.getLayerHandles(layerorder{i})]; %#ok<AGROW>
end
assert(numel(newChildren) == numel(get(hMapAxes.getAxes(),'Children')), ...
    'MapGraphics:axes:addModel:layerHandleMismatch',...
    'Number of re-ordered children fails to match original count.')
set(hMapAxes.getAxes(),'Children',newChildren);
refresh(ancestor(hMapAxes.getAxes(),'Figure'))

end


%============================== Listeners =================================

function setVisible(src,eventData,hMapAxes) %#ok<INUSL>
set(hMapAxes.getLayerHandles(eventData.Name),...
    'Visible',eventData.Value);
end

function showBoundingBox(src,eventData,hMapAxes) %#ok<INUSL>
delete(hMapAxes.getLayerHandles([eventData.Name '_BoundingBox']));
hMapAxes.Model.getLayer(eventData.Name).renderBoundingBox(hMapAxes.getAxes());
end

function layerorderchanged(src,eventData,hMapAxes) %#ok<INUSL>
reorderChildren(hMapAxes,eventData.layerorder);
end

function removelayer(src,eventData,hMapAxes) %#ok<INUSL>
% Remove Layer
delete(hMapAxes.getLayerHandles(eventData.LayerName));
% Remove Bounding Box
delete(hMapAxes.getLayerHandles([eventData.LayerName '_BoundingBox']))
end

function newlayer(src,eventData,model,hMapAxes) %#ok<INUSL>
% Update graphics when a layer is added or removed
layername = eventData.LayerName;
model.renderLayer(hMapAxes.getAxes(),layername);
% Add a listener to the new layer's component property
hMapAxes.ComponentListener= createComponentListener(model.getLayer(layername),model,hMapAxes);
end

function newcomponent(src,eventData,model,hMapAxes) %#ok<INUSL>
% Update graphics when a new component is added to a layer
layer = eventData.AffectedObject;
component = eventData.NewValue(end,:);
layer.renderComponent(hMapAxes.getAxes(),component);
reorderChildren(hMapAxes,model.getLayerOrder);
end
