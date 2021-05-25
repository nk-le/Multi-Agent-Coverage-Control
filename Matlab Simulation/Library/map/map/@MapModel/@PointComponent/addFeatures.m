function addFeatures(this,shapeData,attributes)
%ADDFEATURES Add features to a PointComponent.
%
%   Vector components are composed of zero or more features.
%   ADDFEATURE(SHAPEDATA,ATTRIBUTES) adds features to the
%   VectorComponent. SHAPEDATA is an array of Vector Shape Structures. Each
%   feature has coordinates SHAPEDATA.X, SHAPDATA.Y, a bounding box
%   SHAPEDATA.BoundingBox and attributes in the corresponding element of the
%   array of structures, ATTRIBUTES.

% Copyright 1996-2008 The MathWorks, Inc.

xMin = min([shapeData.X]);
yMin = min([shapeData.Y]);
xMax = max([shapeData.X]);
yMax = max([shapeData.Y]);
boundingBox = [xMin,yMin,diff([xMin,xMax]),diff([yMin,yMax])];

temp(numel(shapeData)) = MapModel.feature(0,0,zeros(2,2),[]);
for i=1:length(shapeData)
  if isempty(attributes)
    attribute = [];
  else
    attribute = attributes(i);
  end
  temp(i) = MapModel.feature(shapeData(i).X,shapeData(i).Y,...
                             boundingBox, ...
                             attribute);
end
this.Features = temp;
