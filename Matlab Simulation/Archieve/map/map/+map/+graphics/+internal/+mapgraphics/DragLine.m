classdef DragLine < matlab.mixin.SetGetExactNames
%DragLine Drag line class for Map Viewer

% Copyright 2012-2020 The MathWorks, Inc.
    
    properties
        hLine
        StartX
        StartY
        EndX
        EndY
        OldPointer
        IsArrow
        ArrowHead
        Finished
    end
    
    methods
        function this = DragLine(ax,isArrow)
            %DRAGLINE Draw a line on an axis between two points.
            
            if nargin == 2
               
                % Define additional variables needed in the nested stopDrag
                % callback.
                hFig = ancestor(ax,'Figure');
                oldWindowButtonMotionFcn = get(hFig,'WindowButtonMotionFcn');
                
                % Initialize DragLine properties.
                this.Finished = false;
                this.IsArrow = isArrow;
                this.OldPointer = get(hFig,'Pointer');
                
                % Initialize DragLine starting point.
                set(hFig,'CurrentObject',ax)
                pt = get(ax,'CurrentPoint');
                this.StartX = pt(1);
                this.StartY = pt(3);
                
                % Construct an HG line object and assign starting point
                % coordinates. Make axes visible before adding line object.
                % This is a workaround for a graphics issue on Linux and
                % Mac.
                visibleState = get(ax, 'Visible');
                set(ax, 'Visible', 'on')
                this.hLine = line('Visible','on', 'Parent', ax, ...
                    'XData',this.StartX,'YData',this.StartY,'ZData',1);
                set(ax, 'Visible', visibleState);
                
                % If its HG line object is deleted, also delete this object.
                set(this.hLine, 'DeleteFcn', @deleteDragLine)
                
                % Set back-pointer from the HG line object to this object.
                setappdata(this.hLine,'AnnotationObject',this)
                
                % Set up figure callbacks to support selection of end point.
                set(hFig, ...
                    'WindowButtonMotionFcn',@lineDrag, ...
                    'WindowButtonUpFcn',@stopDrag)
            end
            
            %---------------- nested callback functions ------------------
            
            function lineDrag(~,~)
                pt = get(ax,'CurrentPoint');
                visibleState = get(ax, 'Visible');
                set(ax, 'Visible', 'on')
                set(this.hLine, ...
                    'XData', [this.StartX pt(1)], ...
                    'YData', [this.StartY pt(3)], ...
                    'ZData', [1 1]);
                set(ax, 'Visible', visibleState)
                drawnow
            end
            
            function stopDrag(~,~)
                pt = get(ax,'CurrentPoint');
                this.EndX = pt(1);
                this.EndY = pt(3);
                set(this.hLine, ...
                    'XData', [this.StartX this.EndX], ...
                    'YData', [this.StartY this.EndY], ...
                    'ZData', [1 1]);
                
                set(hFig,'CurrentObject',ax)
                
                if this.IsArrow
                    this.ArrowHead = map.graphics.internal.mapgraphics.ArrowHead(this.hLine);
                end
                
                set(hFig,'Pointer',this.OldPointer)
                iptPointerManager(hFig,'Enable');
                
                toolbar = findall(hFig,'type','uitoolbar');
                toolButton = findall(toolbar,'ToolTipString','Insert Line');
                
                set(toolButton,'State','off')
                this.Finished = true;
                
                % This keeps things going ... note that we are depending on
                % the function-scoped value of isArrow.  In many cases we
                % could also use this.isArrow, but the problem with that is
                % that it requires 'this' to exist at the time the button
                % down event occurs ... and reading down a few more lines
                % you can see that the DragLine handle 'this' gets deleted
                % if a degenerate point is detected.
                set(hFig,'WindowButtonDownFcn', ...
                    @(hSrc,event) map.graphics.internal.mapgraphics.DragLine(ax,isArrow))
                
                set(hFig,'WindowButtonMotionFcn',oldWindowButtonMotionFcn)
                set(hFig,'WindowButtonUpFcn','')
                
                drawnow
                
                % Destroy line annotations if they are zero length.
                degeneratePoint = ...
                    (this.EndX == this.StartX) &&...
                    (this.EndY == this.StartY);
                
                if degeneratePoint
                    delete(this.hLine)
                end
            end
            
        end
        
        
        function delete(this)
            if ishghandle(this.hLine) && strcmp(get(this.hLine, 'BeingDeleted'), 'on')
                delete(this.hLine)
            end
            
            if ~isempty(this.ArrowHead) && isvalid(this.ArrowHead)
                delete(this.ArrowHead)
            end
        end
        
        
        function newLine = makeCopy(this)
            %makeCopy Copy this DragLine object
            %
            %   makeCopy returns a new drag line that is identical to this
            %   object, except that the copy is invisible.
            
            % Construct an invisible HG line object with nominal properties.
            ax = get(this.hLine,'Parent');
            newLine = line(...
                'XData', get(this.hLine,'XData'),...
                'YData', get(this.hLine,'YData'),...
                'Parent',ax,...
                'Selected','off',...
                'Visible','off');
            
            % Assign the rest of the line properties.
            readOnlyProperties = {'Annotation','BeingDeleted','Type'};
            props = rmfield(get(this.hLine),...
                [readOnlyProperties {'Selected','Visible'}]);
            set(newLine,props)
            
            % Construct a new DragLine object.
            hCopy = map.graphics.internal.mapgraphics.DragLine;
            
            % Assign selected properties.
            hCopy.hLine = newLine;
            hCopy.Finished = true;
            
            % Set back-pointer from HG line object to DragLine object.
            setappdata(hCopy.hLine,'AnnotationObject',hCopy)
            
            % If its HG line object is deleted, also delete this object.
            set(hCopy.hLine, 'DeleteFcn', @deleteAnnotation)
            
        end
        
        
        function hLine = cut(this)
            %CUT Cut this DragLine object
            
            % Note: If the drag line has an ArrowHead object, its
            %       setVisible listener will keep the visibility of its
            %       patch in synch with that of the HG line.
            
            hLine = this.hLine;
            set(hLine,'Selected','off','Visible','off')
        end
        
        
        function paste(this, xShift, yShift)
            
            xData = get(this.hLine,'XData');
            yData = get(this.hLine,'YData');
            
            set(this.hLine,'XData',xData + xShift, ...
                'YData',yData + yShift,'Visible','on')
            
            % If this DragLine has an ArrowHead, then it will be visible
            % now because its patch component listens for changes in the
            % visibility of this.hLine.  This will be the case if we're
            % pasting a DragLine (with arrow head) that was cut. But if
            % we're pasting a copy, it doesn't have an arrow head yet
            % (because we've waited to create it until we need it, which is
            % right now).
            if this.IsArrow
                if isempty(this.ArrowHead) ...
                        || ~isvalid(this.ArrowHead) ...
                        || ~ishghandle(this.ArrowHead.hPatch,'patch')
                    this.ArrowHead = map.graphics.internal.mapgraphics.ArrowHead(this.hLine);
                end
            end            
        end
    end
end

%--------------------------------------------------------------------------

function deleteAnnotation(hSrc, ~)

hAnnotation = getappdata(hSrc, 'AnnotationObject');
if isvalid(hAnnotation)
    delete(hAnnotation)
end
end

%--------------------------------------------------------------------------

function deleteDragLine(hSrc, ~)

hDragLine = getappdata(hSrc, 'AnnotationObject');
if isvalid(hDragLine) && ~isempty(hDragLine.ArrowHead) ...
        && isvalid(hDragLine.ArrowHead) ...
        && ishghandle(hDragLine.ArrowHead.hPatch)
    delete(hDragLine.ArrowHead.hPatch)
end
if isvalid(hDragLine)
    delete(hDragLine)
end
end
