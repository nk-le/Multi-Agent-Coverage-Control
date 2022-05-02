function renderLayer(this,ax,layername)
%RENDERLAYER Render one layer in the model
%
%   H = RENDERLAYER(AX,LAYERNAME) renders the layer LAYERNAME into the axes
%   AX. 

% Copyright 1996-2007 The MathWorks, Inc.

for i=1:length(this.Layers)
  names{i} = this.Layers(i).getLayerName;
end
I = strmatch(layername,names,'exact');
if isempty(I)
  error(['map:' mfilename ':mapError'], ...
      'A layer named %s does not exist in this model.',layername)
end
this.Layers(I).render(ax);
