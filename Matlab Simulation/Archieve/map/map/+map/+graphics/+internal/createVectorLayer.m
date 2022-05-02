function layer = createVectorLayer(S, name)
%CREATEVECTORLAYER Create a vector layer from a geographic data structure.
%
%   LAYER = CREATEVECTORLAYER(S, NAME) constructs a point, line, or polygon
%   layer given a geographic data structure, S, and the layer name, NAME.

% Copyright 2003-2012 The MathWorks, Inc.

attributes = map.graphics.internal.extractFeatureAttributes(S);
if ~isempty(attributes)
  attrnames = fieldnames(attributes);

  % add Index to the geographic data struct as the 
  % the last attribute, if it does not exist.
  if ~any(strcmpi('index',attrnames))
     attrnames = [attrnames; {'INDEX'}];
     indexNums = num2cell(1:length(attributes));
     [attributes(1:length(indexNums)).INDEX] = deal(indexNums{:});
  end
else
  attrnames = '';
end

% Assume only one Geometry type per structure.
type = S(1).Geometry;
switch lower(type)
  case {'point', 'multipoint'}
     layer = MapModel.PointLayer(name);
     component = MapModel.PointComponent(attrnames);
  case 'line'
     layer = MapModel.LineLayer(name);
     component = MapModel.LineComponent(attrnames);
  case 'polygon'
     layer = MapModel.PolygonLayer(name);
     component = MapModel.PolygonComponent(attrnames);
  otherwise
     validatestring(type,{'point','multipoint','line','polygon'}, ...
         '','Geometry')
end
component.addFeatures(S,attributes);
layer.addComponent(component);
