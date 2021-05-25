function addLayer(this,layer)
%

%   Copyright 1996-2003 The MathWorks, Inc.

layername = layer.getLayerName;
newUIString = [get(this.ActiveLayerDisplay,'String');{layername}];
set(this.ActiveLayerDisplay,'String',newUIString);