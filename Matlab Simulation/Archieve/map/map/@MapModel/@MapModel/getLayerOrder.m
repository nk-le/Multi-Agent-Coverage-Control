function order = getLayerOrder(this)
%GETLAYERORDER Get order of layers in model
%
%   LAYERORDER = GETLAYERORDER returns a cell array of strings with the names
%   of the layers.  The first element of LAYERORDER is the top most layer.

%   Copyright 1996-2003 The MathWorks, Inc.

if isempty(this.Configuration)
  order = '';
else
  % The order will always be returned as a column cell array.
  order = this.Configuration(:);
end

