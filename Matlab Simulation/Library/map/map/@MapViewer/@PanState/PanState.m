function this = PanState(viewer)
%

% Copyright 1996-2013 The MathWorks, Inc.

this = MapViewer.PanState;

this.MapViewer = viewer;

viewer.setDefaultState;

openHandPtr = setptr('hand');
viewer.setCursor(openHandPtr);

set(viewer.Figure,'WindowButtonDownFcn',{@localStartPan viewer});
set(viewer.Figure,'WindowButtonUpFcn','');

function localStartPan(hSrc,event,viewer) %#ok<INUSL>

if ~isOverAxes(viewer)
    return
end

closedHandPtr = setptr('closedhand');
viewer.setCursor(closedHandPtr);

p  = get(viewer.getAxes(),'CurrentPoint');
startPt = [p(1) p(3)];
set(viewer.Figure,'WindowButtonUpFcn',{@localStopPan viewer});
set(viewer.Figure,'WindowButtonMotionFcn', ...
    @(hSrc,event) viewer.Axis.localPan(startPt))

function localStopPan(hSrc,event,viewer) %#ok<INUSL>

openHandPtr = setptr('hand');
viewer.setCursor(openHandPtr); 

viewer.setDefaultWindowButtonFcn();
viewer.Axis.updateOriginalAxis;
vEvent = MapViewer.ViewChanged(viewer);
viewer.send('ViewChanged',vEvent);

function over = isOverAxes(viewer)
% isOverAxes determines whether buttonDown occurred over the map axes region
% based on the existence of an axes ancestor of the object returned by
% hittest.

hit_obj = hittest(viewer.Figure);

hitAxes = ancestor(hit_obj,'axes');

%axes annotations are the annotations that are actual drawn within the map
%axes region.
hitAxesAnnotation = ~isempty(hitAxes) && (hitAxes == viewer.AnnotationAxes);
                                           
hitUtilityAxes = ~isempty(viewer.UtilityAxes) &&...
                 ~isempty(hitAxes) &&...
                  hitAxes == viewer.UtilityAxes;
              
hitMapAxes = ~isempty(hitAxes) && (hitAxes == viewer.getAxes());

over = hitMapAxes || hitAxesAnnotation || hitUtilityAxes;
