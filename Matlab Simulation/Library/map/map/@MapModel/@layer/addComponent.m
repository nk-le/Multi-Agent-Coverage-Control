function addComponent(this,component)
%ADDCOMPONENT Add a component to the layer
%
%   ADDCOMPONENT(COMPONENT) adds a COMPONENT to the layer.  The layer is
%   homogeneous, so the component must be the same type as the layer.

% Copyright 1996-2007 The MathWorks, Inc.

if isempty(strmatch(regexprep(class(component),'^\w*\.','','once'),...
                    this.ComponentType))
  error(['map:' mfilename ':mapError'], 'Layers must be homogeneous')
end

this.Components = [this.Components; component];
