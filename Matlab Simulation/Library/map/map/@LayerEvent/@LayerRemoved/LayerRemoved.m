function h = LayerRemoved(hSrc,layername)
%LAYERREMOVED Subclass of EventData to handle removing a layer from the model

%   Copyright 1996-2003 The MathWorks, Inc.

h = LayerEvent.LayerRemoved(hSrc,'LayerRemoved');
h.LayerName = layername;
