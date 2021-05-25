function h = LineLayer(name)
%LINELAYER Constructor for the line layer class
%
%   LINELAYER(NAME) creates a vector layer with the name NAME for line
%   features. The object will be constructed with a default legend.

%   Copyright 1996-2003 The MathWorks, Inc.

h = MapModel.LineLayer;

h.componentType = 'LineComponent';
h.layername = name;
h.legend = MapModel.LineLegend;
h.visible = 'on';