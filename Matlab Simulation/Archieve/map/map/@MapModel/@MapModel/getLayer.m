function layer = getLayer(this,name)
%GETLAYER Return a layer in the mapmodel.
%
%   GETLAYER(NAME) returns the layer NAME in the mapmodel.  

% Copyright 1996-2007 The MathWorks, Inc.

if isempty(strmatch(name,getLayerOrder(this)))  
  error(['map:' mfilename ':mapError'], ...
      'The layer %s does not exist in this map.',name)
end

for i=1:length(this.layers)
  names{i} = this.Layers(i).getLayerName;
end
I = strmatch(name,names,'exact');
layer = this.Layers(I);
