function removeLayer(this,layerName)
%REMOVELAYER Remove layer from viewer
%
%   removeLayer(LAYERNAME) removes the layer with the name LAYERNAME from the
%   view.

%   Copyright 1996-2003 The MathWorks, Inc.

this.Map.removeLayer(layerName);

