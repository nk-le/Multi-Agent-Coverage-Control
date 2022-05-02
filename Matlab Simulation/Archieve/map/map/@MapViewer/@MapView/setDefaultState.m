function setDefaultState(this)
%

% Copyright 1996-2006 The MathWorks, Inc.

toolbar = findall(this.Figure,'type','uitoolbar');

if isa(this.State,'MapViewer.ZoomInState')
    zoomInTool = findobj(get(toolbar,'Children'),'Tag','zoom in');
    set(zoomInTool,'State','off');
end

if isa(this.State,'MapViewer.ZoomOutState')
    zoomOutTool = findobj(get(toolbar,'Children'),'Tag','zoom out');
    set(zoomOutTool,'State','off');
end

if isa(this.State,'MapViewer.PanState')
    panTool = findobj(get(toolbar,'Children'),'Tag','pan tool');
    set(panTool,'State','off');
end

delete(this.State)
this.State = MapViewer.DefaultState(this);

toggleTool = findobj(get(toolbar,'Children'),'Tag','select annotations');
set(toggleTool,'State','on');
this.Axis.updateOriginalAxis;
