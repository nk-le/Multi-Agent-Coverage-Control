function h = PolygonComponent(attributeNames)
%POLYGONCOMPONENT Constructor for a component of a polygon layer.
%
%   POLYGONCOMPONENT constructs a PolygonComponent.
%   POLYGONCOMPONENT(ATTRIBUTES) constructs a PolygonComponent object with
%   attributes ATTRIBUTES.
% 

%   Copyright 1996-2003 The MathWorks, Inc.

h = MapModel.PolygonComponent;
h.AttributeNames = attributeNames;

%h.BoundingBox = MapModel.BoundingBox(attributes.BoundingBox);

%fnames = fieldnames(attributes);
%if numel(fnames) > 2
%  for i=4:numel(fnames)
%    p = schema.prop(h,fnames{i},'MATLAB array');
%    h.(fnames{i}) = attributes.(fnames{i});
%  end
%end
