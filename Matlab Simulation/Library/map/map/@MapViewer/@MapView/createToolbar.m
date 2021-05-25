function createToolbar(this)
%CREATETOOLBAR Create toolbar for Map Viewer

% Copyright 1996-2016 The MathWorks, Inc.

selectionIcon   = makeToolbarIconFromPNG('tool_select.png');
zoomInIcon      = makeToolbarIconFromPNG('view_zoom_in.png');
zoomOutIcon     = makeToolbarIconFromPNG('view_zoom_out.png');
arrowIcon       = makeToolbarIconFromPNG('tool_arrow.png');
lineIcon        = makeToolbarIconFromPNG('tool_line.png');
textIcon        = makeToolbarIconFromPNG('tool_text.png');
fitToWindowIcon = makeToolbarIconFromPNG('view_fit_to_window.png');
datatipIcon     = makeToolbarIconFromPNG('tool_datatip.png');
panIcon         = makeToolbarIconFromPNG('tool_hand.png');
prevViewIcon    = makeToolbarIconFromPNG('view_prev.png');
selectAreaIcon  = makeToolbarIconFromPNG('tool_marquee.png');
infoToolIcon    = makeToolbarIconFromPNG('info.png');

toolbar = uitoolbar('Parent',this.Figure);
printTool = uitoolfactory(toolbar,'Standard.PrintFigure');

set(printTool,'TooltipString','Print figure');
set(printTool,'ClickedCallback',{@localPrint, this});

selectionTool = uitoggletool(toolbar,...
                             'Cdata',selectionIcon,...
                             'TooltipString','Select annotations',...
                             'Tag','select annotations',...
                             'State','on','Enable','on',...
                             'ClickedCallback',@ClickedCallback,...
                             'OnCallback',{@initEditState this},...
                             'OffCallback',{@endEditState this});

rectTool = createToolbarToggleItem(toolbar,selectAreaIcon,...
                                   {@initSelectAreaState this},...
                                   'Select area',{@endSelectAreaState this});


zoomInTool = createToolbarToggleItem(toolbar,zoomInIcon,...
                                     {@initZoomInState this},...
                                     'Zoom in',{@endZoomInState this});

zoomOutTool = createToolbarToggleItem(toolbar,zoomOutIcon,...
                                     {@initZoomOutState this},...
                                     'Zoom out',{@endZoomOutState this});

panTool = createToolbarToggleItem(toolbar,panIcon,...
                                  {@initPanState this},'Pan tool',...
                                  {@endPanState this});

insertTextItem = createToolbarToggleItem(toolbar,textIcon,...
                                         {@initInsertTextState this},...
                                         'Insert text',...
                                         {@endInsertTextState this});

insertArrowItem = createToolbarToggleItem(toolbar,arrowIcon,...
                                          {@initInsertArrowState this},...
                                          'Insert arrow',...
                                          {@endInsertArrowState this});

insertLineItem = createToolbarToggleItem(toolbar,lineIcon,...
                                         {@initInsertLineState this},...
                                         'Insert line',...
                                         {@endInsertLineState this});

dataTipTool = createToolbarToggleItem(toolbar,datatipIcon,...
                                      {@initDatatipState this},...
                                      'Datatip tool',{@endDatatipState this});

infoTool = createToolbarToggleItem(toolbar,infoToolIcon,...
                                      {@initInfoToolState this},...
                                      'Info tool',{@endInfoToolState this});

backTool = createToolbarPushItem(toolbar,prevViewIcon,...
                                 {@doBackToPreviousView this},...
                                 'Back to previous view');

fitToWindowItem = createToolbarPushItem(toolbar,fitToWindowIcon, ...
    @(hSrc,evnt) this.fitToWindow(),'Fit to window');

set(selectionTool, 'Separator','on');
set(zoomInTool,    'Separator','on');
set(insertTextItem,'Separator','on');
set(dataTipTool,   'Separator','on');
set(backTool,      'Separator','on');


%----------Callbacks----------%

% Start Tools / Initialize States

% Functions initializing a state should follow this template:
%
%  function initXYZState(hSrc,event,viewer,...)
%  delete(viewer.State);
%  viewer.setDefaultState;
%  viewer.State = PKG.XYZState(...);
%

function localPrint(hSrc,event,this)
this.printMap;

function initDatatipState(hSrc,event,viewer)
changeStateToDefault(viewer);
showUsage = true;
if ispref('MathWorks_MapViewer','ShowDatatipUsage')
  if ~getpref('MathWorks_MapViewer','ShowDatatipUsage')
    showUsage = false;
  end
end
if ~viewer.Preferences.ShowDatatipUsage
  showUsage = false;
end

if strcmpi(viewer.ActiveLayerName,'none') ||...
      isempty(viewer.ActiveLayerName)
  viewer.dataTipUsage('NoActiveLayer','Datatip Tool');
  set(hSrc,'State','off');
  viewer.setDefaultState;
  return
  %changeStateToDefault(viewer);
end
if showUsage
  viewer.dataTipUsage('Default');
end

viewer.State = MapViewer.DataTipState(viewer);
checkToolMenu(hSrc,'on');

function initSelectAreaState(hSrc,event,viewer)                         
changeStateToDefault(viewer);
viewer.State = MapViewer.SelectAreaState(viewer);
checkToolMenu(hSrc,'on');

function initZoomInState(hSrc,event,viewer)
changeStateToDefault(viewer);
viewer.State = MapViewer.ZoomInState(viewer);
checkToolMenu(hSrc,'on');

function initZoomOutState(hSrc,event,viewer)
changeStateToDefault(viewer);
viewer.State = MapViewer.ZoomOutState(viewer);
checkToolMenu(hSrc,'on');

function initPanState(hSrc,event,viewer)
changeStateToDefault(viewer);
viewer.State = MapViewer.PanState(viewer);
checkToolMenu(hSrc,'on');

function initEditState(hSrc,event,viewer)
changeStateToDefault(viewer);
viewer.State = MapViewer.EditState(viewer);
checkToolMenu(hSrc,'on');

function initInsertTextState(hSrc,event,viewer)
changeStateToDefault(viewer);
viewer.State = MapViewer.InsertTextState(viewer);
checkToolMenu(hSrc,'on');

function initInsertArrowState(hSrc,event,viewer)
changeStateToDefault(viewer);
viewer.State = MapViewer.InsertArrowState(viewer);
checkToolMenu(hSrc,'on');

function initInsertLineState(hSrc,event,viewer)
changeStateToDefault(viewer);
viewer.State = MapViewer.InsertLineState(viewer);
checkToolMenu(hSrc,'on');

function initInfoToolState(hSrc,event,viewer)                         
changeStateToDefault(viewer);
if strcmpi(viewer.ActiveLayerName,'none') ||...
      isempty(viewer.ActiveLayerName)
  viewer.dataTipUsage('NoActiveLayer','Info Tool');
  set(hSrc,'State','off');
  viewer.setDefaultState;
  return
  %changeStateToDefault(viewer);
end
viewer.State = MapViewer.InfoToolState(viewer);
checkToolMenu(hSrc,'on');


% End State
% The "Off Callback"  functions are called in the following order:
%
% Situation 1 - Deselect a selected item
%   The callback is executed immediately.
%
% Situation 2 - Select the item. Then select a different item (mutually exclusive)
%   New item's "On Callback" is executed (state is switched).
%   Old item's "Off Callback" is executed.
%  
% Because of Situation 2, the current state of the viewer must be queried before
% deleting it.  If the current state is the same as the state associated with
% the OffCallback, then it is Situation 1, and the current state should be
% deleted.  If it is Situation 2, then the state has been switched to another
% (non-default) state and the other state should handle deleting the current
% state. 
%
% Functions ending a state should follow this template:
%
%  function endXYZState(hSrc,event,viewer,...)
%  if strcmp(class(viewer.State),'PGH.XYZState');
%    delete(viewer.State);
%    viewer.setDefaultState;
%  end
%

function endDatatipState(hSrc,event,viewer)
if strcmp(class(viewer.State),'MapViewer.DataTipState')
  changeStateToDefault(viewer);
end

function endSelectAreaState(hSrc,event,viewer)
if strcmp(class(viewer.State),'MapViewer.SelectAreaState')
  changeStateToDefault(viewer);
end

function endEditState(hSrc,event,viewer)
if strcmp(class(viewer.State),'MapViewer.EditState')
  changeStateToDefault(viewer);
end

function endInsertTextState(hSrc,event,viewer)
if strcmp(class(viewer.State),'MapViewer.InsertTextState') 
  changeStateToDefault(viewer);
end

function endInsertArrowState(hSrc,event,viewer)
if strcmp(class(viewer.State),'MapViewer.InsertArrowState')
  changeStateToDefault(viewer);
end

function endInsertLineState(hSrc,event,viewer)
if strcmp(class(viewer.State),'MapViewer.InsertLineState')
  changeStateToDefault(viewer);
end

function endPanState(hSrc,event,viewer)
if strcmp(class(viewer.State),'MapViewer.PanState')
  changeStateToDefault(viewer);
end

function endZoomInState(hSrc,event,viewer)
if strcmp(class(viewer.State),'MapViewer.ZoomInState')
  changeStateToDefault(viewer);
end

function endZoomOutState(hSrc,event,viewer)
if strcmp(class(viewer.State),'MapViewer.ZoomOutState')
  changeStateToDefault(viewer);
end

function endInfoToolState(hSrc,event,viewer)
if strcmp(class(viewer.State),'MapViewer.InfoToolState')
  changeStateToDefault(viewer);
end

%-----------------------------------------------------------------------

function doBackToPreviousView(hSrc,event,viewer)
viewCount = size(viewer.PreviousViews,1);
ind = viewer.ViewIndex;
ind = mod(ind-1,viewCount+1);
if ind < 1, ind = viewCount;end
% make view index -1 so as to skip store view
skipStoreView = -1;
viewer.ViewIndex = skipStoreView;
lastXLimits = viewer.PreviousViews(ind,1:2);
lastYLimits = viewer.PreviousViews(ind,3:4);
set(viewer.Axis.getAxes(),'XLim',lastXLimits,'YLim',lastYLimits)
viewer.Axis.refitAxisLimits;
viewer.ViewIndex = ind;

%-----------------------------------------------------------------------

% Toggle items that call ClickedCallback will be mutually exclusive.

function ClickedCallback(hSrc,event)
fig = ancestor(hSrc,'Figure');
uiresume(fig);
hiddenHandles = get(0,'ShowHiddenHandles');
set(0,'ShowHiddenHandles','on');
tools = findall(fig,'type','uitoggletool');
set(0,'ShowHiddenHandles',hiddenHandles);
set(tools(tools ~= hSrc),'State','off');
if (strcmp(get(hSrc,'State'),'off'))
  selAnnot = findobj(tools,'tag','select annotations');
  set(selAnnot,'State','on');
end

%--------------------------- Helper Functions --------------------------

function item = createToolbarPushItem(toolbar,icon,callback,tooltip)
item = uipushtool(toolbar,...
                  'Cdata',icon,...
                  'TooltipString',tooltip,...
                  'Tag',lower(tooltip),...
                  'ClickedCallback',callback);

%-----------------------------------------------------------------------

function item = createToolbarToggleItem(toolbar,icon,callback,...
                                        tooltip,offcallback)
item = uitoggletool(toolbar,...
                    'Cdata',icon,...
                    'TooltipString',tooltip,...
                    'Tag',lower(tooltip),...
                    'ClickedCallback',@ClickedCallback,...
                    'OnCallback',callback,...
                    'OffCallback',offcallback);

%-----------------------------------------------------------------------

function icon = makeToolbarIconFromPNG(imagefilename)

filename = fullfile(matlabroot,'toolbox','map','icons',imagefilename);

% Icon's background color is [0 1 1]
[icon,map] = imread(filename);
idx = 0;
for i=1:size(map,1)
  if all(map(i,:) == [0 1 1])
    idx = i;
    break;
  end
end
mask = icon==(idx-1); % Zero based.
[r,c] = find(mask);
icon = ind2rgb(icon,map);
for i=1:length(r)
  icon(r(i),c(i),:) = NaN;
end

%-----------------------------------------------------------------------

function changeStateToDefault(viewer)
if isa(viewer.State,'MapViewer.DataTipState')
  viewer.PreviousDataTipState = viewer.State;
end

viewer.setDefaultState;

%-----------------------------------------------------------------------

function checkToolMenu(toolbarItem, checked)
fig = ancestor(toolbarItem,'Figure');
toolmenu = findobj(fig,'type','uimenu','tag','tools menu');

set(get(toolmenu,'Children'),'Checked','off');
thisToolMenu = findobj(toolmenu,'Tag',[get(toolbarItem,'Tag'), ' menu']);

if strcmp(checked,'off')
  selectAnnotMenuItem = findobj(toolmenu,'Tag','select annotations menu');
  set(selectAnnotMenuItem,'Checked','on');
else
  if ~isempty(thisToolMenu)
    set(thisToolMenu,'Checked','on');
  end
end
