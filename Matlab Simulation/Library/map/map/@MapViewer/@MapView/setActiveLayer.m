function setActiveLayer(this,layerName)
%

% Copyright 1996-2008 The MathWorks, Inc.

if isempty(layerName)
  layerName = 'None';
end

switch class(this.State)
 case 'MapViewer.DataTipState'
  dataTipState = this.State;
  dataTipState.setActiveLayer(this,layerName);
 case 'MapViewer.InfoToolState'
  infoToolState = this.State;
  infoToolState.setActiveLayer(this,layerName);
end

this.ActiveLayerName = layerName;
this.DisplayPane.setActiveLayer(layerName);

% Check Active subMenu of appropriate Layer
layersMenu = findall(this.Figure, 'Type','uimenu','tag','layers menu');
index = strmatch(this.getActiveLayerName,get(get(layersMenu,'Children'),'Label'));
activeMenus = findobj(get(layersMenu,'Children'),'tag','make active');
set(activeMenus,'Checked','off');
set(activeMenus(index),'Checked','on');

% Disable the Datatip Tool and Info Tool for raster layers
toolbar = findall(this.Figure,'type','uitoolbar');
toolmenu = findall(this.Figure,'type','uimenu','tag','tools menu');
toggleTool(1) = findobj(get(toolbar,'Children'),'Tag','datatip tool');
toggleTool(2) = findobj(get(toolbar,'Children'),'Tag','info tool');
toggleMenu(1) = findobj(get(toolmenu,'Children'),'Tag','datatip tool menu');
toggleMenu(2) = findobj(get(toolmenu,'Children'),'Tag','info tool menu');
toolComp = [toggleTool;toggleMenu];
newViewFullExt(1) = findall(this.Figure,'Type','uimenu','Label',...
                            'Full Extent Of Active Layer');
newViewFullExt(2) = findall(this.Figure,'Type','uimenu','Label','Full Extent');

if strcmpi(layerName,'none')
  set(newViewFullExt(1),'enable','off');
  if isempty(this.getMap.getLayerOrder)
    set(newViewFullExt(2),'enable','off');
  else
    set(newViewFullExt(2),'enable','on');
  end
else
  set(newViewFullExt,'enable','on');
end

if strcmpi(layerName,'none') ||...
      isa(this.getMap.getLayer(layerName),'MapModel.RasterLayer')
  set(toggleTool,'State','off');
  set(toolComp,'Enable','off');
  this.setDefaultState;
else
    % Disables the Datatip Tool and Info Tool for vector layers without any
    % attributes.
    layerGraphics = this.Axis.getLayerHandles(layerName);
    if isempty(getAttributes(layerGraphics(1)))
      set(toggleTool,'State','off');
      set(toolComp,'Enable','off');
      this.setDefaultState;
    else
      set(toolComp,'Enable','on');
    end
end

%----------------------------------------------------------------------
%  "METHODS" ENCAPSULATING ACCESS TO ADDITIONAL LINE OR POLYGON STATE
%----------------------------------------------------------------------

function attributes = getAttributes(h)
attributes = getappdata(h,'Attributes');
