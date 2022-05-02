function render(this,ax)
%RENDER Render all components in the layer.
%
%   RENDER(AX) renders all components in the layer into the axes AX.

% Copyright 1996-2008 The MathWorks, Inc.

if ~this.isempty
    for i=1:numel(this.Components)
        this.Components(i).render(...
            this.LayerName, this.Legend, ax, this.getVisible);
    end
end
