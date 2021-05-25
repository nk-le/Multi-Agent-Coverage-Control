function this = InsertLineState(viewer)
%

% Copyright 1996-2012 The MathWorks, Inc.

this = MapViewer.InsertLineState;
this.MapViewer = viewer;
viewer.setCursor({'Pointer','crosshair'});
set(viewer.Figure,'WindowButtonDownFcn',@insertLine);

    function insertLine(hSrc,event) %#ok<INUSD>
        if viewer.isOverMapAxes()
            map.graphics.internal.mapgraphics.DragLine(viewer.AnnotationAxes,false);
        end
    end
end
