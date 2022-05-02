function layersMenu = addLayerMenu(viewer,layer)
%

% Copyright 1996-2017 The MathWorks, Inc.

layersMenu = findall(viewer.Figure, 'Type','uimenu','tag','layers menu');

newLayersMenu = rebuildLayersMenu(viewer,layersMenu);
addMenu(viewer,newLayersMenu,layer);
enableMenuItems(viewer);


function addMenu(viewer,layersMenu,layer)
newMenu = uimenu('Parent',layersMenu,'Label',layer.getLayerName,...
                 'Position',1);

% To ensure that "Active" is appropriately checked for the layer menu
if strcmp(viewer.getActiveLayerName,layer.getLayerName) 
  isActive = 'on';
else
  isActive = 'off';
end

uimenu('Parent',newMenu,'Label','Active','Tag','make active',...
       'Position',1,'Callback',{@localMakeActive viewer layer.getLayerName},...
       'Checked',isActive);

visibility = get(layer,'visible'); 
uimenu('Parent',newMenu,'Label','Visible','Tag','visible',...
       'Checked',visibility,...
       'Position',2,'Callback',{@localMakeVisible viewer layer.getLayerName});

isBoundingBox = layer.getShowBoundingBox;
uimenu('Parent',newMenu,'Label','Bounding Box','Tag','bounding box',...
       'Checked',isBoundingBox,...
       'Position',3,'Callback',{@localShowBoundingBox viewer layer.getLayerName});

uimenu('Parent',newMenu,'Label','To Top','Tag','to top','Separator','on',...
       'Position',4,'Callback',{@localToTop viewer layer.getLayerName});

uimenu('Parent',newMenu,'Label','To Bottom','Tag','to bottom',...
       'Checked','off',...
       'Position',5,'Callback',{@localToBottom viewer layer.getLayerName});

uimenu('Parent',newMenu,'Label','Move Up','Tag', 'move up',...
       'Callback',{@localMoveUp viewer layer.getLayerName},...
       'Position',6,'Enable','off');

uimenu('Parent',newMenu,'Label','Move Down','Tag','move down',...
       'Position',7,'Callback',{@localMoveDown viewer layer.getLayerName});

uimenu('Parent',newMenu,'Label','Remove','Tag','remove','Separator','on',...
       'Position',8,'Callback',{@localRemoveLayer viewer layer});

if ~isa(layer,'MapModel.RasterLayer')
    uimenu('Parent',newMenu,'Label','Set Symbol Spec...','Tag','set symbols',...
       'Position',9,'Callback',{@openLegendDialog viewer layer},...
       'Checked','off');
    
  uimenu('Parent',newMenu,'Label','Set Label Attribute...','Tag','set attribute',...
         'Position',10,'Callback',{@localSetLabelAttribute viewer layer},...
         'Checked','off');

end

% $$$ uimenu('Parent',newMenu,'Label','Change Layer Name...','Tag','rename','Separator','on',...
% $$$        'Position',nextInd,'Callback',{@changeLayerName viewer layer});

%----------Callbacks----------%
function openLegendDialog(hSrc,event,viewer,layer) %#ok<INUSL>

h = figure('NumberTitle','off',...
           'IntegerHandle','off',...
           'Name','Layer Symbols',...
           'Menubar','none',...
           'Units','inches',...
           'Resize','off',...
           'Position',getWindowPosition(viewer,3,2),...
           'HandleVisibility','off',...
           'WindowStyle','modal');

backgroundColor = get(h,'Color');

uicontrol('Parent',h,'Style','Text',...
          'String',['Choose a layer symbolization structure',...
                    ' for the ' layer.getLayerName ' layer.'],...
          'Units','inches','Position',[0 1.5 3 0.4],...
          'BackgroundColor',backgroundColor);


symbolSpecs = uicontrol('Parent',h,'Style','list',...
                        'Units','inches','Position',[0.05 0.4 2.95 1]);

specNames = '';
workspaceVars = evalin('base','whos');
workspaceVarNames = {workspaceVars.name};
j = 1;
for i=1:length(workspaceVars)
  fcn = ['map.graphics.internal.isValidSymbolSpec(', workspaceVarNames{i} ');'];
  if evalin('base', fcn)
    specNames{j} = workspaceVarNames{i};
    j = j+1;
  end
end
set(symbolSpecs,'String',specNames);


uicontrol('Parent',h,'Style','pushbutton',...
          'Units','inches','Position',[0.7 0.05 0.7 0.3],...
          'String','OK',...
          'Callback',{@setMapLegendOK symbolSpecs viewer layer});

uicontrol('Parent',h,'Style','pushbutton',...
          'Units','inches','Position',[1.7 0.05 0.7 0.3],...
          'String','Cancel',...
          'Callback',@setMapLegendCancel);

function setMapLegendCancel(hSrc,event) %#ok<INUSD>
close(get(hSrc,'Parent'));

function setMapLegendOK(hSrc,event,symbolSpecs,viewer,layer) %#ok<INUSL>
listStrs = get(symbolSpecs,'String');
if ~isempty(listStrs)
  listValue = get(symbolSpecs,'Value');
  specName = listStrs{listValue};
  symbolspec = evalin('base',specName);
  if isstruct(symbolspec)
    try
      layerlegend = layer.legend;
      origPropValues = get(layerlegend);
      layerlegend.override(rmfield(symbolspec,'ShapeType'));
    catch e
      errordlg(e.message,'Symbol Spec Error','modal');
      return;
    end
  else
    errordlg(sprintf('%s is not a valid Symbol Spec Structure.',specName),...
             'Symbol Spec Error','modal');
    return
  end
  
  try
    viewer.Map.setLayerLegend(layer.getLayerName,layerlegend,viewer.Axis);
    close(get(hSrc,'Parent'));
  catch e
    errordlg(e.message,'Layer Symbol Error','modal');
    % restore previous values of the legend
    layerlegend.override(origPropValues); 
    return
  end
else
  close(get(hSrc,'Parent'));
end

function localSetLabelAttribute(hSrc,event,viewer,layer) %#ok<INUSL>
attrNames = layer.getAttributeNames;

widthInInches = 2.5;
heightInInches = 3;

% Find the center of the viewer.
oldUnits = get(viewer.Figure,'Units');
set(viewer.Figure,'Units','inches')
position = get(viewer.Figure,'Position');
centerX = position(1) + position(3)/2;
centerY = position(2) + position(4)/2;
set(viewer.Figure,'Units',oldUnits)

% Add memory to the uicontrol
activeLayerHandles = viewer.Axis.getLayerHandles(layer.getLayerName);
attr = [];
if ~isempty(activeLayerHandles)
  attr = getDataTipAttribute(activeLayerHandles(1));
end
if isempty(attr)
  stridx = 1;
else
  stridx = find(strcmp(attr, attrNames));
end

x = centerX - widthInInches/2;
y = centerY - heightInInches/2;
f = figure('Units','inches',...
           'Position',[x y widthInInches heightInInches],...
           'NumberTitle','off',...
           'Name','Attribute Names',...
           'IntegerHandle','off',...
           'WindowStyle','modal');
lb = uicontrol('Style','listbox','Parent',f,'Units','normalized',...
               'Position',[0.05 0.25 0.9 0.7],...
               'String',attrNames,...
               'Min',1,'Max',1,... % Single Selection
               'Value',stridx,...
               'UserData',layer.getLayerName);
%'Callback',{@setLayerLabel viewer},...

numOfbuttons = 2;
buttonWidth = 0.25;
buttonSpacing = 0.005;
leftMargin = (1 - numOfbuttons*(buttonWidth+2*buttonSpacing))/numOfbuttons;

uicontrol('Style','pushbutton','Parent',f,'Units','normalized',...
                 'Position',[leftMargin 0.05 buttonWidth 0.1],...
                 'String','OK',...
                 'Callback',{@setLayerLabel viewer lb f});
uicontrol('Style','pushbutton','Parent',f,'Units','normalized',...
                 'Position',[leftMargin + buttonWidth+2*buttonSpacing,...
                             0.05 buttonWidth 0.1],...
                 'String','Cancel',...
                 'Callback',@(~,~) delete(f));


function setLayerLabel(hSrc,event,viewer,listbx,f) %#ok<INUSL>
val = get(listbx,'Value');
strings = get(listbx,'String');
if ~isempty(strings)
    activeLayerHandles = viewer.Axis.getLayerHandles(get(listbx, ...
                                                  'UserData'));
    setDataTipAttribute(activeLayerHandles,strings{val});   
end
delete(f);

function localMakeActive(hSrc,event,viewer,layerName) %#ok<INUSL>
if strcmp(get(hSrc,'Checked'),'on')
  setActiveLayer(viewer,'None');
else
  setActiveLayer(viewer,layerName);
end

function localMoveUp(hSrc,event,viewer,layerName) %#ok<INUSL>
% Re-order layers in the map
layerOrder = viewer.Map.getLayerOrder;
idx = find(strcmp(layerName,layerOrder));
tmp = layerOrder{idx};
layerOrder{idx} = layerOrder{idx - 1};
layerOrder{idx - 1} = tmp;
viewer.Map.setLayerOrder(layerOrder);

% Re-order menu items
menuItem = get(hSrc,'Parent');
pos = get(menuItem,'Position');
set(menuItem,'Position',pos - 1);

% Rebuild Layers Menu - Remove when HG bug with Uimenu is fixed.
layersMenu = findall(viewer.Figure, 'Type','uimenu','Tag','layers menu');
rebuildLayersMenu(viewer,layersMenu);

enableMenuItems(viewer);

function localMoveDown(hSrc,event,viewer,layerName) %#ok<INUSL>
% Re-order layers in the map
layerOrder = viewer.Map.getLayerOrder;
idx = find(strcmp(layerName,layerOrder));
tmp = layerOrder{idx};
layerOrder{idx} = layerOrder{idx + 1};
layerOrder{idx + 1} = tmp;
viewer.Map.setLayerOrder(layerOrder);

% Re-order menu items
menuItem = get(hSrc,'Parent');
pos = get(menuItem,'Position');
set(menuItem,'Position',pos + 1);

% Rebuild Layers Menu - Remove when HG bug with Uimenu is fixed.
layersMenu = findall(viewer.Figure, 'Type','uimenu','Tag','layers menu');
rebuildLayersMenu(viewer,layersMenu);

enableMenuItems(viewer);

function localToBottom(hSrc,event,viewer,layerName) %#ok<INUSL>
% Re-order layers in the map
layerOrder = viewer.Map.getLayerOrder;
layerOrder(strcmp(layerName,layerOrder)) = [];
newLayerOrder = [layerOrder; {layerName}];
viewer.Map.setLayerOrder(newLayerOrder);

% Re-order menu items
layersMenu = findall(viewer.Figure,'Tag','layers menu');
numChildren = length(get(layersMenu,'Children'));
menuItem = get(hSrc,'Parent');
set(menuItem,'Position',numChildren);

% Rebuild Layers Menu - Remove when HG bug with Uimenu is fixed.
layersMenu = findall(viewer.Figure, 'Type','uimenu','Tag','layers menu');
rebuildLayersMenu(viewer,layersMenu);

enableMenuItems(viewer);

function localToTop(hSrc,event,viewer,layerName) %#ok<INUSL>
% Re-order layers in the map
layerOrder = viewer.Map.getLayerOrder;
layerOrder(strcmp(layerName,layerOrder)) = [];
newLayerOrder = [{layerName}; layerOrder];
viewer.Map.setLayerOrder(newLayerOrder);

% Re-order menu items
menuItem = get(hSrc,'Parent');
set(menuItem,'Position',1);

% Rebuild Layers Menu - Remove when HG bug with Uimenu is fixed.
layersMenu = findall(viewer.Figure, 'Type','uimenu','Tag','layers menu');
rebuildLayersMenu(viewer,layersMenu);

enableMenuItems(viewer);

function localShowBoundingBox(hSrc,event,viewer,layerName) %#ok<INUSL>
state = get(gcbo,'Checked');
if strcmp(state,'on')
  set(gcbo,'Checked','off')
  viewer.Map.setShowBoundingBox(layerName,false);
else
  set(gcbo,'Checked','on')
  layer = viewer.Map.getLayer(layerName);
  layer.renderBoundingBox(viewer.getAxes());
  viewer.Map.setShowBoundingBox(layerName,true);
end

function localMakeVisible(hSrc,event,viewer,layerName) %#ok<INUSL>
state = get(gcbo,'Checked');
if strcmp(state,'on')
  set(gcbo,'Checked','off')
  viewer.Map.setLayerVisible(layerName,false);
else
  set(gcbo,'Checked','on')
  viewer.Map.setLayerVisible(layerName,true);
end

function localRemoveLayer(hSrc,event,viewer,layer) %#ok<INUSL>

% Change to None if the layer is the active layer
if strcmp(viewer.ActiveLayerName,layer.getLayerName)
  viewer.setActiveLayer('None');
end
viewer.removeLayer(layer.getLayerName);

% Rebuild Layers Menu - Remove when HG bug with Uimenu is fixed.
layersMenu = findall(viewer.Figure, 'Type','uimenu','Tag','layers menu');
rebuildLayersMenu(viewer,layersMenu);

enableMenuItems(viewer)

%----------Helper Functions----------%
function enableMenuItems(viewer)
layersMenu = findall(viewer.Figure,'Tag','layers menu');
numChildren = length(get(layersMenu,'Children'));
if numChildren == 1
  disableMoveMenuItems(viewer);
else
  enableTopMenuItems(viewer);
  enableMiddleMenuItems(viewer);
  enableBottomMenuItems(viewer);
end

function disableMoveMenuItems(viewer)
layersMenu = findall(viewer.Figure,'Tag','layers menu');
topMenu = findall(viewer.Figure,'Parent',layersMenu,'Position',1);
toTopMenu = findall(topMenu,'Tag','to top');
set(toTopMenu,'Enable','off');
toBottomMenu = findall(topMenu,'Tag','to bottom');
set(toBottomMenu,'Enable','off');
moveUpMenu = findall(topMenu,'Tag','move up');
set(moveUpMenu,'Enable','off');
moveDownMenu = findall(topMenu,'Tag','move down');
set(moveDownMenu,'Enable','off');

function enableMiddleMenuItems(viewer)
layersMenu = findall(viewer.Figure,'Tag','layers menu');
children = get(layersMenu,'Children');
for i=1:length(children)
  pos = get(children(i),'Position');
  if (pos ~= 1) && (pos ~= length(children))
    toTopMenu = findall(children(i),'Tag','to top');
    set(toTopMenu,'Enable','on');
    toBottomMenu = findall(children(i),'Tag','to bottom');
    set(toBottomMenu,'Enable','on');
    moveUpMenu = findall(children(i),'Tag','move up');
    set(moveUpMenu,'Enable','on');
    moveDownMenu = findall(children(i),'Tag','move down');
    set(moveDownMenu,'Enable','on');
  end
end

function enableTopMenuItems(viewer)
layersMenu = findall(viewer.Figure,'tag','layers menu');
topMenu = findall(viewer.Figure,'Parent',layersMenu,'Position',1);
toTopMenu = findall(topMenu,'Tag','to top');
set(toTopMenu,'Enable','off');
toBottomMenu = findall(topMenu,'Tag','to bottom');
set(toBottomMenu,'Enable','on');
moveUpMenu = findall(topMenu,'Tag','move up');
set(moveUpMenu,'Enable','off');
moveDownMenu = findall(topMenu,'Tag','move down');
set(moveDownMenu,'Enable','on');

function enableBottomMenuItems(viewer)
layersMenu = findall(viewer.Figure,'tag','layers menu');
%topMenu = findall(viewer.Figure,'Parent',layersMenu,'Position',1);
numChildren = length(get(layersMenu,'Children'));
bottomMenu = findall(viewer.Figure,'Parent',layersMenu,...
                     'Position',numChildren);
toTopMenu = findall(bottomMenu,'Tag','to top');
set(toTopMenu,'Enable','on');  
toBottomMenu = findall(bottomMenu,'Tag','to bottom');
set(toBottomMenu,'Enable','off');
moveUpMenu = findall(bottomMenu,'Tag','move up');
set(moveUpMenu,'Enable','on');
moveDownMenu = findall(bottomMenu,'Tag','move down');
set(moveDownMenu,'Enable','off');


function newLayersMenu = rebuildLayersMenu(viewer,layersMenu)
newLayersMenu = uimenu('Parent',viewer.Figure,'Label','&Layers',...
                       'Tag','layers menu','Position',6);
layerMenuChildren = get(layersMenu,'Children');
for i=1:length(layerMenuChildren)
  l = viewer.getMap.getLayer(get(layerMenuChildren(i),'Label'));
  addMenu(viewer,newLayersMenu,l);
end
delete(layersMenu)

%--------------------------------------------------%
function p = getWindowPosition(viewer,w,h)
p = viewer.getPosition('inches');
x = p(1) + p(3)/2 - 2.8/2;
y = p(2) + p(4)/2 - h/2;
p = [x,y,w,h];

%----------------------------------------------------------------------
%  "METHODS" ENCAPSULATING ACCESS TO ADDITIONAL LINE OR POLYGON STATE
%----------------------------------------------------------------------

function dataTipAttribute = getDataTipAttribute(h)
dataTipAttribute = getappdata(h,'DataTipAttribute');

%----------------------------------------------------------------------

function setDataTipAttribute(h, dataTipAttribute)
for k = 1:numel(h)
    setappdata(h(k),'DataTipAttribute',dataTipAttribute)
end
