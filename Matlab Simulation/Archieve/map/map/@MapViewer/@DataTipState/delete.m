function delete(this)
%

%   Copyright 1996-2003 The MathWorks, Inc.

activeLayerHandles = this.Viewer.Axis.getLayerHandles(this.ActiveLayerName);
set(activeLayerHandles,'ButtonDownFcn','');
