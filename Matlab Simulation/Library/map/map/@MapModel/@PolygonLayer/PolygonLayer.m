function h = PolygonLayer(name)
%POLYGONLAYER Constructor for the polygon layer class
%
%   POLYGONLAYER(NAME) creates a polygon layer with the name NAME.

%   Copyright 1996-2003 The MathWorks, Inc.

h = MapModel.PolygonLayer;

h.componentType = 'PolygonComponent';
h.layername = name;
h.legend = MapModel.PolygonLegend;
h.visible = 'on';