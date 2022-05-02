function h = LayerOrderChanged(hSrc,layerorder)
%LAYERORDERCHAGNED Subclass of EventData to handle changing the layer order.

%   Copyright 1996-2003 The MathWorks, Inc.

h = LayerEvent.LayerOrderChanged(hSrc,'LayerOrderChanged');
h.layerorder = layerorder;
