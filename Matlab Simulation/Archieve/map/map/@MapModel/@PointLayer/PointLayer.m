function h = PointLayer(name)
%POINTLAYER Constructor for the point layer class
%
%   POINTLAYER(NAME) creates a vector layer with the name NAME for point
%   features. The object will be constructed with a default legend.

%   Copyright 1996-2003 The MathWorks, Inc.

h = MapModel.PointLayer;

h.componentType = 'PointComponent';
h.layername = name;
h.legend = MapModel.PointLegend;
h.visible = 'on';