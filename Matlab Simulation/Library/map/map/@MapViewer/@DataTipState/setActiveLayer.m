function setActiveLayer(this,viewer,activeLayerName)
%

% Copyright 1996-2013 The MathWorks, Inc.

% Initialize layers to default state before managing hittest/buttondownfcn of active layer.
initializeLayers(viewer);

activeLayerHandles = viewer.Axis.getLayerHandles(activeLayerName);
set(activeLayerHandles,...
    'ButtonDownFcn',{@addDataTip this viewer activeLayerHandles},...
    'HitTest','on');
set(viewer.Figure,'WindowButtonDownFcn','');
set(viewer.Figure,'WindowButtonUpFcn','');

this.ActiveLayerName = activeLayerName;

%-------------------------------------------------------------
function addDataTip(hSrc,~,this,viewer,activeLayerHandles)
%allows only left clicks
if ~strcmpi('normal',get(viewer.Figure,'SelectionType'))
  return
end
p = viewer.getMapCurrentPoint;
layerHandle = hSrc;
if isempty(getDataTipAttribute(layerHandle))
  lyr = viewer.getMap.getLayer(getLayerName(activeLayerHandles(1)));
  attrNames = lyr.getAttributeNames;
  setDataTipAttribute(activeLayerHandles,attrNames{1})
end
if ~strcmpi(this.ActiveLayerName,'none')
  str = getDataTipAttributeValue(layerHandle);
  
  % Make axes visible before adding text object. 
  % This is a workaround for a graphics issue on Linux and Mac.
  ax = viewer.UtilityAxes;
  visibleState = get(ax, 'Visible');
  set(ax, 'Visible', 'on')
  h = text( ...
      'Parent', ax,...
      'String', str,...
      'Position', [p 0],...
      'Color', [0 0 0],...
      'BackgroundColor', [0.9 0.9 0],...
      'Interpreter', 'none');
  set(ax, 'Visible', visibleState);
  
  contextmenu = createUIContextMenu(this,h);
  set(h, 'UIContextMenu', contextmenu);
  
  addHandleToList(this,getLayerName(layerHandle),h,contextmenu);
end

%------------------------------------------
function addHandleToList(this,name,h,cmenu)
if isempty(this.LabelHandles)
    this.LabelHandles{1,1} = name;
    this.LabelHandles{1,2} = h;
    this.LabelHandles{1,3} = cmenu;
    
else
  i = strmatch(name,this.LabelHandles(:,1),'exact'); %#ok<MATCH3>
  if ~isempty(i)
    nextHandleIdx = length(this.LabelHandles{i,2}) + 1;
    this.LabelHandles{i,2}(nextHandleIdx) = h;
    this.LabelHandles{i,3}(nextHandleIdx) = cmenu;
  else
    nextRow = size(this.LabelHandles,1) + 1;
    this.LabelHandles{nextRow,1} = name;
    this.LabelHandles{nextRow,2} = h;
    this.LabelHandles{nextRow,3} = cmenu;
  end
end

%------Datatip Context Menu---------------------------------------------------%
function contextmenu = createUIContextMenu(this,textHandle)
contextmenu = uicontextmenu('Parent',this.Viewer.Figure);
uimenu('Parent',contextmenu,'Label','Delete datatip',...
                    'Callback',{@DeleteDatatip this textHandle});
uimenu('Parent',contextmenu,'Label','Delete all datatips',...
                    'Callback',{@DeleteAllDatatips this});

%-------------------------------------------------
function DeleteDatatip(~,~,this,textHandle)
for n = 1:length(this.LabelHandles(:,1))
    tst = (textHandle == this.LabelHandles{n,2});
    if any(tst), break, end
end
this.LabelHandles{n,2}(tst) = [];
this.LabelHandles{n,3}(tst) = [];
delete(textHandle);

%------------------------------------------
function DeleteAllDatatips(~,~,this)
delete([this.LabelHandles{:,2}]);
delete([this.LabelHandles{:,3}]);
this.LabelHandles = [];

%--------------------------------
function initializeLayers(viewer)
% Set hittest/buttonDownFcn of all layers to an initial state. Only the
% activeLayer should have an active hittest in order to ensure that the
% ButtonDown function of the active layer handles is not blocked.
layerNames = viewer.getMap.getLayerOrder();
layerHandles = [];
for i = 1:length(layerNames)
    layerHandles = [layerHandles; viewer.Axis.getLayerHandles(layerNames{i})]; %#ok<AGROW>
end         
set(layerHandles,...
    'ButtonDownFcn','',...
    'HitTest','off');

%----------------------------------------------------------------------
%  "METHODS" ENCAPSULATING ACCESS TO ADDITIONAL LINE OR POLYGON STATE
%----------------------------------------------------------------------

function layerName = getLayerName(h)
layerName = get(h,'Tag');

%----------------------------------------------------------------------

function attributes = getAttributes(h)
attributes = getappdata(h,'Attributes');

%----------------------------------------------------------------------

function dataTipAttribute = getDataTipAttribute(h)
dataTipAttribute = getappdata(h,'DataTipAttribute');

%----------------------------------------------------------------------

function setDataTipAttribute(h, dataTipAttribute)
for k = 1:numel(h)
    setappdata(h(k),'DataTipAttribute',dataTipAttribute)
end

%----------------------------------------------------------------------

function value = getAttributeValue(h,attributeName)
attributes = getAttributes(h);
value = attributes.(attributeName);

%----------------------------------------------------------------------

function value = getDataTipAttributeValue(h)
value = getAttributeValue(h,getDataTipAttribute(h));
