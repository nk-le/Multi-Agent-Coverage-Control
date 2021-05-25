function renderBoundingBox(this,ax)
%RENDERBOUNDINGBOX Draw bounding box 

%   Copyright 1996-2003 The MathWorks, Inc.

if ~this.isempty
  name = this.getLayerName;
  bb = this.getBoundingBox;
  h = bb.render(name,name,ax);
  h.setVisible(this.getShowBoundingBox);
end
