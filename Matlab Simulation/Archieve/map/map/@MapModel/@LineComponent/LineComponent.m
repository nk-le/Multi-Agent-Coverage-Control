function h = LineComponent(attributeNames)
%LINECOMPONENT Constructor for a component of a line layer.
%
%   LINECOMPONENT constructs a LineComponent object

%   Copyright 1996-2003 The MathWorks, Inc.

h = MapModel.LineComponent;

h.AttributeNames = attributeNames;
