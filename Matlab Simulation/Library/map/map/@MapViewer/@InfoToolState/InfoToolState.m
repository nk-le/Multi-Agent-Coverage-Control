function this = InfoToolState(viewer)
%

%   Copyright 1996-2007 The MathWorks, Inc.


if isempty(viewer.PreviousInfoToolState)
  this = MapViewer.InfoToolState;
else
  this = viewer.PreviousInfoToolState;
  viewer.PreviousInfoToolState = [];
end

this.Viewer = viewer;

viewer.setCursor({'Pointer','crosshair'});
                  
this.setActiveLayer(viewer, viewer.ActiveLayerName);