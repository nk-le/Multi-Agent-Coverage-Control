function setCursor(this,cursor)
%SETCURSOR Set icon for MapView cursor.
%
%   setCursor(CURSOR) sets the cursor for the MapView to CURSOR.  CURSOR is
%   a cell array containing valid property value pairs for specifying a
%   pointer in a Handle Graphics figure.

% Copyright 1996-2008 The MathWorks, Inc.

ax = this.getAxes();

iptSetPointerBehavior(ax, @(h_fig,pos) set(h_fig,cursor{:}));                 
iptSetPointerBehavior(this.AnnotationAxes, iptGetPointerBehavior(ax));                  
iptSetPointerBehavior(this.UtilityAxes,    iptGetPointerBehavior(ax));
