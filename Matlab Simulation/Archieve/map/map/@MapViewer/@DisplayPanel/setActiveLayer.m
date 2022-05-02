function setActiveLayer(this,layerName)
%

%   Copyright 1996-2003 The MathWorks, Inc.

idx = strmatch(layerName,get(this.ActiveLayerDisplay,'String'),'exact');
set(this.ActiveLayerDisplay,'Value',idx);
