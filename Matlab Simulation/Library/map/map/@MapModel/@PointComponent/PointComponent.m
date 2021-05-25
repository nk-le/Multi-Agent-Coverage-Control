function h = PointComponent(attributeNames)
%POINTCOMPONENT Constructor for a component of a point layer.
%
%   POINTCOMPONENT constructs a PointComponent object

%   Copyright 1996-2003 The MathWorks, Inc.

h = MapModel.PointComponent;

h.AttributeNames = attributeNames;