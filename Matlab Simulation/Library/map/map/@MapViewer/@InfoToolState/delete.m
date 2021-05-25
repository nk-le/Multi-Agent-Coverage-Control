function delete(this)
%

%   Copyright 1996-2003 The MathWorks, Inc.

activeLayerHandles = this.Viewer.Axis.getLayerHandles(this.Viewer.ActiveLayerName);
set(activeLayerHandles,'ButtonDownFcn','');

this.Viewer.PreviousInfoToolState = this;
this= [];
%delete(this);
