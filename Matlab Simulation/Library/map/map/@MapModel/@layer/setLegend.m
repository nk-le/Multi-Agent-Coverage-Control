function setLegend(this,legend)
%SETLEGEND Set the legend 
%
% SETLEGEND(LEGEND) sets the legend of the layer to LEGEND, a mapmodel.legend.

% Copyright 1996-2007 The MathWorks, Inc.

layerhandle = classhandle(this);
legendhandle = classhandle(legend);

layerclassname = layerhandle.name;
legendclassname = legendhandle.name;

layerclassname(findstr(layerclassname,'Layer'):end) = '';
legendclassname(findstr(legendclassname,'Legend'):end) = '';

if isequal(layerclassname,legendclassname)
  this.Legend = legend;
else
  error(['map:' mfilename ':mapError'], ...
      'Only a %s spec can symbolize a %s layer.',...
      layerclassname,layerclassname)
end
