function this = ZoomInState(viewer,mode)
%

% Copyright 1996-2008 The MathWorks, Inc.

this = MapViewer.ZoomInState;

this.MapViewer = viewer;

viewInfo = this.MapViewer.Axis.ViewInfo;
if (isempty(viewInfo))
  this.MapViewer.Axis.ViewInfo = viewInfo;
end

% Turn on zoom but preserve the WindowButtonMotionFcn
WindowButtonMotionFcn = get(viewer.Figure,'WindowButtonMotionFcn');
zoom(viewer.Figure,'inmode');
set(viewer.Figure,'WindowButtonMotionFcn',WindowButtonMotionFcn);

glassPlusPtr = setptr('glassplus');
viewer.setCursor(glassPlusPtr);
