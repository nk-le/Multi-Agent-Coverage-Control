function bbox = getBoundingBox(this)
%GETBOUNDINGBOX Get the bounding box of a model
%
%  BBOX = GETBOUNDINGBOX returns a BoundingBox object for the model.  The
%  bounding box includes visible and invisible layers.

%   Copyright 1996-2006 The MathWorks, Inc.

if ~this.isempty
  bboxes = zeros(2,2,numel(this.Layers));
  for i=1:numel(this.Layers)
    bboxes(:,:,i) = this.Layers(i).getBoundingBox.getBoxCorners;
  end

  bbox = MapModel.BoundingBox([min(bboxes(1,:,:),[],3); ...
                               max(bboxes(2,:,:),[],3)]);
else
  bbox = MapModel.BoundingBox([0 0; 0 0]);
end
  


