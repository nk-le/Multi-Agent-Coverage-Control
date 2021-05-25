function addLayer(this,layer)
%ADDLAYER Add a layer to the model
%
%   ADDLAYER(LAYER) adds a layer to the model. LAYER is a raster or vector
%   layer object. The layer is added to the top of the configuration.

% Copyright 1996-2007 The MathWorks, Inc.

if ~isempty(strmatch(layer.getLayerName,getLayerOrder(this),'exact'))
  error(['map:' mfilename ':mapError'], ...
      'A layer with the name "%s" already exists in this map.',...
      layer.getLayerName);
end

this.Layers = [this.Layers; layer];
this.Configuration = [{layer.getLayerName}; this.Configuration];

% Generate and broadcast an event that a layer has been removed.
EventData = LayerEvent.LayerAdded(this,layer.getLayerName);
this.send('LayerAdded',EventData);
