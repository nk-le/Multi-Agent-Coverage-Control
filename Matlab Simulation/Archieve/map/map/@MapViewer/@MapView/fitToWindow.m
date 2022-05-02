function fitToWindow(this)
%FITTOWINDOW 
% 
%   fitToWindow sets the axis limits to view all data in the map.

%   Copyright 1996-2003 The MathWorks, Inc.

this.Axis.setAxesLimits(this.map.getBoundingBox.getBoxCorners);
this.Axis.refitAxisLimits; 
this.Axis.updateOriginalAxis;
vEvent = MapViewer.ViewChanged(this);
this.send('ViewChanged',vEvent);

