function delete(this)
%

% Copyright 1996-2008 The MathWorks, Inc.

viewer = this.MapViewer;
set(viewer.Figure,'WindowButtonDownFcn','');
ax = viewer.getAxes();
set(ax,'ButtonDownFcn','')
set(get(ax,'Children'),'ButtonDownFcn','')

if ~isempty(this.Box) && ishghandle(this.Box)
  delete(this.Box);
end
this.disableMenus;
