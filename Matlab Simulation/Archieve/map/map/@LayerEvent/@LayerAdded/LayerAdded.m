function h = LayerAdded(hSrc,layername)
%LAYERADDED Subclass of EventData to handle adding a layer to the model

%   Copyright 1996-2003 The MathWorks, Inc.

h = LayerEvent.LayerAdded(hSrc,'LayerAdded');
h.LayerName = layername;

