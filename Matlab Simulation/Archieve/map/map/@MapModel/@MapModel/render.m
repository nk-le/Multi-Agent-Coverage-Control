function render(this,ax)
%RENDER Render all layers in the model
%
%   RENDER(AX) renders all the layers in the model into the axes AX
%   according to the order defined in the configuration of the model.
%

%   Copyright 1996-2018 The MathWorks, Inc.

if ~isempty(this.Configuration)
  unorderedLayers = get(this,'layers');

  % Don't render empty layers
  for i=1:length(unorderedLayers)
    if isempty(unorderedLayers(i))
      unorderedLayers(i) = [];
    end
  end

  % Compute an index that maps each layer, based on its layername, to a
  % name listed in this.Configuration.  There should be a 1:1 mapping.
  if length(unorderedLayers) == 1
    index = 1;
  else
    namesOfUnorderedLayers = get(unorderedLayers,'layername');
    [~, index] = ismember(this.Configuration, namesOfUnorderedLayers);
  end

  % Convert the index to a row vector. Then reverse it, because the layers
  % are listed topmost first in this.Configuration, but the topmost layer
  % must be rendered last.
  index = fliplr(index(:)');

  % Iterate over the index, letting each layer render itself.
  for k = index
      % Let each layer render itself.
      unorderedLayers(k).render(ax);
  end
end
