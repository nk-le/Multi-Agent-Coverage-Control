function createMenus(this)
%CREATEMENUS Create menus for MapView

% Copyright 1996-2020 The MathWorks, Inc.

% Delete current menus and create new menus
delete(findall(this.Figure, 'Type','uimenu', 'Parent',this.Figure));

% File 
fileMenu = uimenu('Parent',this.Figure,'Label','&File','Tag','file menu');

% Import
uimenu('Parent',fileMenu,'Label','Import From File...',...
       'Tag','fileimport','Callback',{@localImportFromFile this});
importFromWorkspace = uimenu('Parent',fileMenu,'Label',['Import From ' ...
                    'Workspace']);

RasterImport = uimenu('Parent',importFromWorkspace,'Label','Raster Data');
uimenu('Parent',RasterImport,'Label','Image...',...
       'Callback',{@localImportRasterFromWS this,'image'});       
uimenu('Parent',RasterImport,'Label','Grid...',...
       'Callback',{@localImportRasterFromWS this,'grid'});

VectorImport = uimenu('Parent',importFromWorkspace,'Label','Vector Data');
uimenu('Parent',VectorImport,'Label','Map Coordinates...',...
       'Callback',{@localImportVectorFromWS this 'cartesian'});
uimenu('Parent',VectorImport,'Label','Geographic Data Structure...',...
       'Callback',{@localImportVectorFromWS this 'struct'});

% New View
newview = uimenu('Parent',fileMenu,'Label','New View');
uimenu('Parent',newview,'Label','Duplicate Current View',...
       'Callback',{@localNewViewVisible this});
uimenu('Parent',newview,'Label','Full Extent',...
       'Callback',{@localNewViewFull this});
uimenu('Parent',newview,'Label','Full Extent Of Active Layer',...
       'Callback',{@localNewViewActiveLayer this});
this.NewViewAreaMenu = uimenu('Parent',newview,'Label','Selected Area',...
                                     'Callback',{@localNewViewArea this}, ...
                                     'Enable','off');

% Save Raster Map
SaveAs = uimenu('Parent',fileMenu,'Label','Save As Raster Map');
uimenu('Parent',SaveAs,'Label','Visible Area',...
       'Tag','exportvisiblearea','Callback',{@exportVisibleArea this}); 
this.ExportAreaMenu = uimenu('Parent',SaveAs,'Label','Selected Area',...
       'Tag','exportselectedarea','Callback',{@exportSelectedArea this},...
       'Enable','off');

% Print
uimenu('Parent',fileMenu,'Label','Print...',...
       'Callback',{@localPrint,this});

% Close
uimenu('Parent',fileMenu,'Label','Close',...
       'Callback',{@localClose this});

% Edit 
this.EditMenu = uimenu('Parent',this.Figure,'Label','&Edit','tag','edit menu');
uimenu('Parent',this.EditMenu,'Label','Cu&t','Enable','off',...
       'Accelerator','X',...
       'Tag','cut','Callback',{@localCut this});
uimenu('Parent',this.EditMenu,'Label','&Copy','Enable','off',...
       'Accelerator','C',...
       'Tag','copy','Callback',{@localCopy this});
uimenu('Parent',this.EditMenu,'Label','&Paste','Enable','off',...
       'Accelerator','V',...
       'Tag','paste','Callback',{@localPaste this});
uimenu('Parent',this.EditMenu,'Label','&Select All','Enable','off',...
       'Accelerator','A',...
       'Tag','select all','Separator','on','Callback',{@localSelectAll this});       

% View 
viewMenu = uimenu('Parent',this.Figure,'Label','&View','tag','view menu');
uimenu('Parent',viewMenu,'Label','Fit To Window',...
       'Callback', @(hSrc,evnt) this.fitToWindow());
uimenu('Parent',viewMenu,'Label','Previous View',...
       'Callback',{@doBackToPreviousView this});
uimenu('Parent',viewMenu,'Label','Toolbar',...
       'Checked','on','Callback',{@localToolbar this});
uimenu('Parent',viewMenu,'Label','Show Annotations',...
       'Separator','on','Checked','on',...
       'Callback',{@localShowAnnotations this});

% Insert 
insertMenu = uimenu('Parent',this.Figure,'Label','&Insert','tag','insert menu');
uimenu('Parent',insertMenu,'Label','Arrow',...
       'Callback',{@doMenuItemViaToggleTool, this, 'insert arrow'});
uimenu('Parent',insertMenu,'Label','Line',...
       'Callback',{@doMenuItemViaToggleTool, this, 'insert line'});
uimenu('Parent',insertMenu,'Label','Text',...
       'Callback',{@doMenuItemViaToggleTool, this, 'insert text'});

% Tools 
toolsMenu = uimenu('Parent',this.Figure,'Label','&Tools','tag','tools menu');
uimenu('Parent',toolsMenu,'Label','Select Annotations',...
       'Checked','on','Tag','select annotations menu',...
       'Callback',{@doMenuItemViaToggleTool,this,'select annotations'});

uimenu('Parent',toolsMenu,'Label','Datatip','Tag','datatip tool menu',...
                     'Callback',{@doMenuItemViaToggleTool,this,['datatip ' ...
                    'tool']});
uimenu('Parent',toolsMenu,'Label','Info Tool','Tag','info tool menu',...
       'Callback',{@doMenuItemViaToggleTool,this,'info tool'});
uimenu('Parent',toolsMenu,'Label','Select Area','Tag','select area menu',...
       'Callback',{@doMenuItemViaToggleTool,this,'select area'});
mapUnits = uimenu('Parent',toolsMenu,'Label','Set Map Units');
uimenu('Parent',toolsMenu,'Label','Zoom In','Separator','on',...
       'Tag','zoom in menu',...
       'Callback',{@doMenuItemViaToggleTool, this,'zoom in'});
uimenu('Parent',toolsMenu,'Label','Zoom Out',...
       'Tag','zoom out menu',...
       'Callback',{@doMenuItemViaToggleTool,this,'zoom out'});
uimenu('Parent',toolsMenu,'Label','Pan',...
       'Tag','pan tool menu',...
       'Callback',{@doMenuItemViaToggleTool,this,'pan tool'});

uimenu('Parent',toolsMenu,'Label','Delete All Datatips','Tag','delete all datatip',...
       'Separator','on','Callback',{@deleteAllDataTips this});
uimenu('Parent',toolsMenu,'Label','Close All Info Windows','Tag','close all infobox',...
       'Callback',{@closeAllInfoBox this});

% Set Map Units 
uimenu('Parent',mapUnits,'Label','None','Tag','none','Checked','on',...
       'Callback',{@localSetMapUnits this});
uimenu('Parent',mapUnits,'Label','Kilometers','Tag','km','Checked','off',...
       'Callback',{@localSetMapUnits this});
uimenu('Parent',mapUnits,'Label','Meters','Tag','m','Checked','off',...
       'Callback',{@localSetMapUnits this});
uimenu('Parent',mapUnits,'Label','Nautical Miles','Tag','nm','Checked','off',...
       'Callback',{@localSetMapUnits this});
uimenu('Parent',mapUnits,'Label','International Feet','Tag','ft','Checked','off',...
       'Callback',{@localSetMapUnits this});
uimenu('Parent',mapUnits,'Label','U.S. Survey Feet','Tag','sf','Checked','off',...
       'Callback',{@localSetMapUnits this});

% Layers menu
uimenu('Parent',this.Figure,'Label','&Layers','tag','layers menu');

% Help menu
helpMenu = uimenu('Parent',this.Figure,'Label','&Help','tag','help menu');
uimenu('Parent',helpMenu,'Label','Map Viewer Help','tag','mapviewhelpref',...
       'Callback',@localShowHelp);

%---------- Callbacks ----------%

function exportVisibleArea(~, ~, this) 
% Export visible area to image file.

% Copy the map viewer to a new figure window.
hfig = copyMap(this);

% Define a clean-up object to close it automatically -- in case of error in
% the print dialog.
clean = onCleanup(@() close(hfig));

% Turn off the ToolBar and MenuBar.
set(hfig, 'ToolBar', 'none', 'MenuBar', 'none')

% Obtain the axes handle from the new figure.
ax = get(hfig, 'CurrentAxes');

% Determine the width and height of the axes in points
% as the 3rd and 4th elements of a position rectangle. 
ax_pos_points = map.graphics.internal.getPositionInPoints(ax);

% Define the position of the axes relative to its own lower left corner in
% points.
rect_pos = [0 0 ax_pos_points(3:4)];

% Export an image frame of the area outlined by the axes position.
frame = getframe(ax);
set(hfig, 'Visible', 'off');
exportFrameToFile(this ,rect_pos, frame)

%--------------------------------------------------------------------------
function exportSelectedArea(~, ~, this)
% Export selected area to image file.

% Copy the map viewer to a new figure window.
hfig = copyMap(this);

% Define a clean-up object to close it automatically -- in case of
% error in the print dialog.
clean = onCleanup(@() close(hfig));

% Obtain the axes handle from the new temporary figure.
ax = get(hfig, 'CurrentAxes');

% Ensure the axes fits the figure window.
set(ax, 'Units', 'normalized', 'Position', [0 0 1 1])

% Grab the entire frame.
frame = getframe(hfig);

% Create referencing object for entire frame.
xLimits = get(ax, 'XLim');
yLimits = get(ax, 'YLim');
R = maprasterref('RasterSize', size(frame.cdata), ...
    'XWorldLimits', xLimits, 'YWorldLimits', yLimits, ...
    'ColumnsStartFrom', 'north');

% Create referencing object for selection.
hSelectionBox = findobj(this.UtilityAxes, 'Type', 'line',  ...
    'Tag', 'selectAreaBox');
xData = hSelectionBox.XData;
yData = hSelectionBox.YData;
xLimits = [min(xData) max(xData)];
yLimits = [min(yData) max(yData)];

% Construct the image for the selection.
[row, col] = R.worldToDiscrete(xLimits, yLimits);
frame.cdata = frame.cdata(min(row):max(row), min(col):max(col), :);

% Construct the referencing object for the image.
R = maprasterref('RasterSize', size(frame.cdata), ...
    'XWorldLimits', xLimits, 'YWorldLimits', yLimits, ...
    'ColumnsStartFrom', 'north');

% Export an image frame of the area outlined by the selection rectangle.    
exportToFile(frame,R);

%--------------------------------------------------------------------------
function exportFrameToFile(this,rect_pos,frame)
% rect_pos is position of clipping rectangle relative to axes in point
% units. frame is a structure of the type returned by getframe.

[xLimits, yLimits] = this.Axis.rectanglePositionToMapLimits(rect_pos);
numRow = size(frame.cdata,1);
numCol = size(frame.cdata,2);

dy  = -diff(xLimits)/(numCol);
dx  =  diff(yLimits)/(numRow);
y11 = yLimits(2) + dy/2;
x11 = xLimits(1) + dx/2;

W = [dx  0   x11;
     0   dy  y11];
R = map.internal.referencingMatrix(W);

exportToFile(frame,R);

%--------------------------------------------------------------------------
function exportToFile(frame,R)

filter =  {'*.tif','TIFF (*.tif,*.tiff,*.TIF,*.TIFF)';...
                                 '*.jpg','JPEG (*.jpg)';...
                                 '*.png','PNG (*.png)'};

[filename, pathname, filterindex] = uiputfile(filter,'Export To File');

file_extensions = {'.tif', '.jpg', '.png'};

if isequal(filename,0) || isequal(pathname,0)
    % User hit cancel.  Do nothing.
else
  [~,name,ext] = fileparts(filename);
  if isempty(ext)
    ext = file_extensions{filterindex};
  end
  imfilename = fullfile(pathname,[name ext]);
  worldfilename = getworldfilename(imfilename);
  if ~isempty(frame.colormap)
    imwrite(frame.cdata,frame.colormap,imfilename,ext(2:end));
    worldfilewrite(R,worldfilename);
  else
    imwrite(frame.cdata,imfilename,ext(2:end));
    worldfilewrite(R,worldfilename);
  end
end

%--------------------------------------------------------------------------
function localSetMapUnits(hSrc,~,this) 
mapUnitsDropMenu = this.DisplayPane.MapUnitsDisplay;
mapUnitsTag = get(hSrc,'Tag');
mapUnitsInd = find(strcmp(mapUnitsTag,this.DisplayPane.MapUnits(:,2)));
mapParent = get(hSrc,'Parent');
set(get(mapParent,'Children'),'Checked','off');
set(hSrc,'Checked','on');

set(mapUnitsDropMenu,'Value',mapUnitsInd);
this.setMapUnits(mapUnitsTag)

%--------------------------------------------------------------------------
function localImportFromFile(~,~,viewer) 
filename = viewer.getFilename;
if ~isempty(filename)
  try
    viewer.importFromFile(filename);
  catch e
    errordlg(e.message,'Import Error','model');
    restorePointer(viewer);
  end
end

%--------------------------------------------------------------------------
function localImportRasterFromWS(hSrc,event,viewer,type) %#ok
MapViewer.RasterImport(viewer,type);

%--------------------------------------------------------------------------
function localImportVectorFromWS(hSrc,event,viewer,type) %#ok
MapViewer.VectorImport(viewer,type);

%--------------------------------------------------------------------------
function localClose(hSrc,event,viewer) %#ok
delete(viewer.Figure);

%--------------------------------------------------------------------------
function localToolbar(hSrc,event,viewer) %#ok
menu = gcbo;
switch get(menu,'Checked')
 case 'on'
  set(menu,'Checked','off');
  toolbar = findall(viewer.Figure,'type','uitoolbar');
  set(toolbar,'Visible','off');
 case 'off'
  set(menu,'Checked','on');
  toolbar = findall(viewer.Figure,'type','uitoolbar');
  set(toolbar,'Visible','on');
end

%--------------------------------------------------------------------------
function doMenuItemViaToggleTool(hSrc,event,viewer,tag) %#ok
% Execute the menu item by "pushing" the appropriate toggle tool button.
toolbar = findall(viewer.Figure,'type','uitoolbar');
toggleTool = findobj(get(toolbar,'Children'),'Tag',tag);
if strcmp(get(toggleTool,'State'),'off')
  set(toggleTool,'State','on');
else
  set(toggleTool,'State','off');
end
toolGroup(toggleTool);

%--------------------------------------------------------------------------
% Edit Menu
function localCut(hSrc,event,viewer) %#ok
if ~isa(viewer.State,'MapViewer.EditState')
    viewer.State = MapViewer.EditState(viewer);
end
editstate = viewer.State;
editstate.cutOrCopyAnnotation(true);

%--------------------------------------------------------------------------
function localCopy(hSrc,event,viewer) %#ok
if ~isa(viewer.State,'MapViewer.EditState')
    viewer.State = MapViewer.EditState(viewer);
end
editstate = viewer.State;
editstate.cutOrCopyAnnotation(false);

%--------------------------------------------------------------------------
function localPaste(hSrc,event,viewer) %#ok
if ~isa(viewer.State,'MapViewer.EditState')
    viewer.State = MapViewer.EditState(viewer);
end
editstate = viewer.State;
editstate.pasteAnnotation;

%--------------------------------------------------------------------------
function localSelectAll(hSrc,event,viewer) %#ok
if ~isa(viewer.State,'MapViewer.EditState')
    viewer.State = MapViewer.EditState(viewer);
end
editstate = viewer.State;
editstate.selectAll;

%--------------------------------------------------------------------------
function localShowAnnotations(hSrc,event,viewer) %#ok
annotations = get(viewer.AnnotationAxes,'Children');

menu = gcbo;
switch get(menu,'Checked')
 case 'on'
  set(menu,'Checked','off');
  set(annotations,'Visible','off');
 case 'off'
  set(menu,'Checked','on');
  set(annotations,'Visible','on');
end

%-------------------------------
function setWatchPointer(viewer) 
iptPointerManager(viewer.Figure,'Disable');
set(viewer.Figure,'Pointer','watch');

%-------------------------------
function restorePointer(viewer)
set(viewer.Figure,'Pointer','arrow');
iptPointerManager(viewer.Figure,'Enable');

%--------------------------------------------------------------------------
function localNewViewFull(hSrc,event,this) %#ok
setWatchPointer(this);
newview = MapViewer.MapView(this.Map);
newview.setActiveLayer(this.getActiveLayerName);
newview.fitToWindow;
restorePointer(this);

%--------------------------------------------------------------------------
function localNewViewActiveLayer(hSrc,event,this) %#ok
activeLayer = this.getMap.getLayer(this.getActiveLayerName);
if isempty(activeLayer)
  warndlg('You must make a layer active.','No Active Layer','modal');
else
  setWatchPointer(this);  
  newview = MapViewer.MapView(this.map);
  newview.setMapLimits(activeLayer.getBoundingBox.getBoxCorners);
  newview.setActiveLayer(this.getActiveLayerName);
  newview.Axis.refitAxisLimits;
  newview.Axis.updateOriginalAxis;
  restorePointer(this);
end

%--------------------------------------------------------------------------
function localNewViewVisible(hSrc,event,this) %#ok
setWatchPointer(this); 
newview = MapViewer.MapView(this.Map);
newview.setMapLimits(this.getMapLimits);
newview.setActiveLayer(this.getActiveLayerName);
newview.Axis.refitAxisLimits;
newview.Axis.updateOriginalAxis;
restorePointer(this);

%--------------------------------------------------------------------------
function localNewViewArea(hSrc,event,this) %#ok
setWatchPointer(this); 
newview = MapViewer.MapView(this.Map);
newview.setMapLimits(this.SelectionBox);
newview.setActiveLayer(this.getActiveLayerName);
newview.Axis.refitAxisLimits;
newview.Axis.updateOriginalAxis;
restorePointer(this);

%--------------------------------------------------------------------------
function localPrint(hSrc,event,this) %#ok
this.printMap;

%--------------------------------------------------------------------------
function toolGroup(tool) 
hiddenHandles = get(0,'ShowHiddenHandles');
set(0,'ShowHiddenHandles','on');
fig = ancestor(tool,'Figure');
tools = findall(fig,'type','uitoggletool');
set(0,'ShowHiddenHandles',hiddenHandles);
set(tools(tools ~= tool),'State','off');

%--------------------------------------------------------------------------
function doBackToPreviousView(hSrc,event,viewer) %#ok
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

%--------------------------------------------------------------------------
function deleteAllDataTips(hSrc,event,this) %#ok
if isa(this.State,'MapViewer.DataTipState') &&...
  ~isempty(this.State.LabelHandles)
  lblHandles = this.State.LabelHandles;
  delete([lblHandles{:,2}]);
  delete([lblHandles{:,3}]);
  lblHandles = [];
  this.State.LabelHandles = lblHandles;
elseif ~isempty(this.PreviousDataTipState) &&...
  ~isempty(this.PreviousDataTipState.LabelHandles)
  lblHandles = this.PreviousDataTipState.LabelHandles;
  delete([lblHandles{:,2}]);
  delete([lblHandles{:,3}]);
  lblHandles = [];
  this.PreviousDataTipState.LabelHandles = lblHandles;
end

%--------------------------------------------------------------------------
function closeAllInfoBox(hSrc,event,this) %#ok

if isa(this.State,'MapViewer.InfoToolState') &&...
      ~isempty(this.State.InfoBoxHandles)
  this.State.closeAll;
elseif ~isempty(this.PreviousInfoToolState) &&...
      ~isempty(this.PreviousInfoToolState.InfoBoxHandles)
  this.PreviousInfoToolState.closeAll;
end

%--------------------------------------------------------------------------
function localShowHelp(hSrc,event) %#ok

try
  helpview(fullfile(docroot,'toolbox','map','map.map'),'mapviewref');
catch %#ok<CTCH>
  message = sprintf('Unable to display help for the MapViewer.');
  errordlg(message);
end
