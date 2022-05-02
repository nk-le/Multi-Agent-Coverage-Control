function h = MapView(varargin)
%MAPVIEW Interactive map viewer   
%   MAPVIEW starts the map viewer in an empty state.  Using the options in
%   the file menu, you can select data from a file or the MATLAB workspace.

%   With no input arguments, MAPVIEW displays a file chooser dialog so you can
%   select a data file interactively.
%
%   MAPVIEW(FILENAME) starts the map viewer and creates a layer from
%   FILENAME. FILENAME can be a name of an image file with a worldfile, a
%   GeoTiff file or an ESRI shapefile. The name of the layer will be the base
%   name of the file.
%
%   MAPVIEW(R,I) starts the map viewer and creates a layer from the referencing
%   matrix R and the RGB image I. The layer will be named "Layer 1".
%
%   MAPVIEW(R,I,CMAP) starts the map viewer and creates a layer from the
%   referencing matrix R, the indexed image I and the colormap CMAP.
%
%   MAPVIEW(VECTORSHAPESTRUCT) starts the map viewer and creates a layer, named
%   "Layer 1", from the vector shape structure VECTORSHAPESTRUCT. See SHAPEREAD
%   for a definition of the vector shape structure.
%
%   MAPVIEW(...,LAYERNAME) names the layer LAYERNAME.
%
%   H = MAPVIEW(...) returns a handle to the Map Viewer.  CLOSE(H) closes the
%   map viewer.

%   MAPVIEW(MapModel) Undocumented way of creating a viewer that views an
%   existing map model.

% Copyright 2003-2019 The MathWorks, Inc.

h = MapViewer.MapView;
[fromFile,newView,rasterFromWS,...
 shapeFromWS,needFilename,needLayerName,cmap] = parseInputs(varargin{:});

noInputArgs = needFilename;
axesVisibility = 'off';

if ~needFilename
  filename = varargin{1};
end

viewerNumber = getViewerNumber(newView, varargin);

% If necessary, initialize the Map Model.
if newView
  h.map = varargin{1};
  axesVisibility = 'on';
else
  h.map = MapModel.MapModel(viewerNumber(1));
end

h.map.ViewerCount(viewerNumber(2)) = viewerNumber(2);

% Store screen size.
r = groot;
oldRootUnits = r.Units;
r.Units = 'points';
h.ScreenSize = r.ScreenSize;
r.Units = oldRootUnits;

h.Name = ['Map Viewer ' num2str(viewerNumber(1)) ...
          ': View ' num2str(viewerNumber(2))];

h.Figure = figure(...
    'Units','points',...
    'Name',h.Name,getFigureProperties,...
    'HandleVisibility','off',...
    'IntegerHandle','off',...
    'Tag','mapview',...
    'DeleteFcn',{@figureDelete, h}, ...
    'PaperPositionMode', 'auto');

refineFigurePosition(h)

setappdata(h.Figure,'MapModelId',h.map.ModelId);

% Initialize the main axes and two invisible axes.
h.Axis = h.initializeAxis(h.map,axesVisibility);
h.AnnotationAxes = makeInvisibleAxes(h.getAxes());
h.UtilityAxes    = makeInvisibleAxes(h.getAxes());

h.CopiedObjects = {};
h.State = MapViewer.EditState(h);
h.setDefaultState
%%%%%%%%%%%%%%%%%%%%%
h.createMenus;
h.createToolbar;
set(h.Figure,'Pointer','watch');

%%%%%%%%%%%%%%%%%%%%%
%% Turn off select area option if not in MATLAB Desktop
if matlab.ui.internal.desktop.isMOTW
    set(findobj(h.Figure, 'Type', 'uitoggletool', 'Tag', 'select area'), 'Tooltip', 'Select area - Unavailable in MATLAB Online');   
end

set(h.Figure,'Visible','on');
drawnow;

h.PreviousDataTipState=[];

h.DisplayPane = MapViewer.DisplayPanel(h);

newPanel = @() uipanel('Parent',h.Figure,'BorderType','none','Units','normalized');
h.FigurePanel = [newPanel() newPanel() newPanel() newPanel()];

%set(h.FigurePanel,'BackgroundColor','red');
figureResizeFcn([],[],h)

set(h.Figure,'ResizeFcn', @(hSrc,event) figureResizeFcn(hSrc,event,h));

hAx = h.getAxes();
hListener1 = addlistener(hAx, 'XLim',    'PostSet', @localSetScaleDisplay);
hListener2 = addlistener(hAx, 'YLim',    'PostSet', @localSetScaleDisplay);
hListener3 = addlistener(hAx, 'Position','PostSet', @localSetScaleDisplay);
set(h.ScaleDisplay,'DeleteFcn', ...
    @(hSrc,evnt) delete([hListener1 hListener2 hListener3]))

addlistener(hAx, 'XLim',    'PreSet', @saveXLimits);
addlistener(hAx, 'YLim',    'PreSet', @saveYLimits);

hLayersMenu = findobj(h.Figure,'Type','uimenu','tag','layers menu');
layersMenuListener ...
    = addlistener(hLayersMenu, 'ObjectChildAdded', @resetLayersMenu);
set(hLayersMenu,'DeleteFcn',@(hSrc,evnt) delete(layersMenuListener))

% Set listeners on MapModel and MapView objects.
% Note: These classes do not inherit from HG.
h.Listeners = [...
    handle.listener(h.getMap,'LayerRemoved',@layerRemoved), ...
    handle.listener(h.getMap,'LayerAdded',  @layerAdded), ...
    handle.listener(h,'ViewChanged',@storeView)];

% Add first layer
if fromFile && ~needFilename
  if needLayerName
    [~,tmpname] = fileparts(filename);
    layername = tmpname;
  else
    layername = varargin{2};
  end
  if ~needFilename
    filename = varargin{1};
  end
  h.setCurrentPath(filename);
  try
    h.importFromFile(filename);
  catch e
    delete(h.Figure);
    rethrow(e);
  end
elseif rasterFromWS
  if needLayerName
      layername = 'Layer 1';
  else
    if cmap
      layername = varargin{4};
    else
      layername = varargin{3};
    end
  end
  if cmap
    I =  matlab.images.internal.ind2rgb8(varargin{2},varargin{3});
  else
    I = varargin{2};
  end
  R = varargin{1};
  h.addLayer(createRGBLayer(R,I,layername));  
elseif shapeFromWS
  if needLayerName
    layername = 'Layer 1';
  else
    layername = varargin{2};
  end
  [shapeData, spec] = updategeostruct(varargin{1});
  % Project the data if needed
  if isfield(shapeData,'Lat') && isfield(shapeData,'Lon')
     %shape = projectGeoStruct(ax, shape);
     [shapeData.X] = deal(shapeData.Lon);
     [shapeData.Y] = deal(shapeData.Lat);
  end
  layer = map.graphics.internal.createVectorLayer(shapeData,layername);
  if isstruct(spec)
    layerlegend = layer.legend;
    layerlegend.override(rmfield(spec,'ShapeType'));
  end
  h.addLayer(layer);
elseif newView
  layerorder = h.map.getLayerOrder;
  for i=length(h.map.Layers):-1:1
    h.addLayerMenu(h.map.getLayer(layerorder{i}));
  end
  layername = 'None';
else
  layername = 'None';
end

%Disabled for noInputArgs
%h.setActiveLayer(layername);

% Set the axis limits (only for the first layer)
if noInputArgs
  h.Axis.refitAxisLimits;
  setNoLayerState(h,'startup');
elseif newView
  setNoLayerState(h);
else
  h.fitToWindow;
end

h.Axis.updateOriginalAxis;
localSetScaleDisplay([],[]);
set(h.Figure,'Pointer','arrow');

ax = h.getAxes();
h.LastLimits(:,1) = get(ax,'XLim')';
h.LastLimits(:,2) = get(ax,'YLim')';

setSessionPreferences(h);

iptPointerManager(h.Figure);

    %--------------------- Listener Callbacks --------------------------
    
    function localSetScaleDisplay(hSrc,event) %#ok<INUSL>
        scale = h.ScaleDisplay;
        if (~isempty(event))
            srcName = event.Source.Name;
        else
            srcName = '';
        end
        fixZoomView(h, srcName);
        if (h.Axis.MapUnitInCM == 0)
            set(scale,'String','Units Not Set');
        else
            s = ['1:' num2str(floor(1/h.Axis.getScale))];
            set(scale,'String',s)
        end
    end


    function saveXLimits(hSrc,event) %#ok<INUSD>
        h.LastLimits(:,1) = get(h.getAxes(),'XLim')';
    end


    function saveYLimits(hSrc,event) %#ok<INUSD>
        h.LastLimits(:,2) = get(h.getAxes(),'YLim')';
    end


    function resetLayersMenu(hSrc,event) %#ok<INUSD>
        m = findobj(h.Figure,'Type','uimenu','tag','layers menu');
        set(m,'Children',get(m,'Children'));
    end


    function layerAdded(hSrc,event) %#ok<INUSL>
        layername = event.LayerName;
        layer = h.getMap.getLayer(layername);
        h.addLayerMenu(layer);
        hDisplayPane = h.DisplayPane;
        hDisplayPane.addLayer(layer);
        setNoLayerState(h);
        changeZoomResetView(h);
    end


    function layerRemoved(hSrc,event) %#ok<INUSL>
        layerName = event.LayerName;
        h.DisplayPane.removeLayer(layerName);
        
        if isa(h.State,'MapViewer.DataTipState')
            h.State.removeLayer(layerName);
        elseif ~isempty(h.PreviousDataTipState)
            h.PreviousDataTipState.removeLayer(layerName);
        end
        if isa(h.State,'MapViewer.InfoToolState')
            h.State.removeLayer(layerName);
        elseif ~isempty(h.PreviousInfoToolState)
            h.PreviousInfoToolState.removeLayer(layerName);
        end
        
        if isempty(h.Map.getLayerOrder)
            setNoLayerState(h);
        end
        layersMenu = findall(h.Figure,'Tag','layers menu');
        menuItem = findall(layersMenu,'Label',layerName);
        delete(menuItem);
        changeZoomResetView(h);
    end


    function storeView(hSrc,event) %#ok<INUSD>
        if hSrc.ViewIndex >= 0
            hSrc.ViewIndex = hSrc.ViewIndex + 1;
            hSrc.PreviousViews(hSrc.ViewIndex:end,:) = [];
            hSrc.PreviousViews(hSrc.ViewIndex,1:2) = get(hSrc.getAxes(),'XLim');
            hSrc.PreviousViews(hSrc.ViewIndex,3:4) = get(hSrc.getAxes(),'YLim');
        end
        
        if size(hSrc.PreviousViews,1)== 2
            viewMenu = findobj(hSrc.Figure,'type','uimenu','tag','view menu');
            toolbar = findall(hSrc.Figure,'type','uitoolbar');
            backMenuItem = findall(viewMenu,'Label','Previous View');
            backTool = findall(toolbar,'tag','back to previous view');
            set([backTool,backMenuItem],'Enable','on');
        end
        %toolbar = findall(this.Figure,'type','uitoolbar');
        %backTool = findall(toolbar,'Tooltip','back to previous view');
        %set(backTool,'Enable','on');
    end
end


function refineFigurePosition(h)
    % Working in points throughout, set the figure to a non-default size
    % and try to ensure that it remains on-screen.
    
    pos = h.Figure.Position;
    
    xCenter = pos(1) + pos(3)/2;
    yCenter = pos(2) + pos(4)/2;
    
    margin = 100;
    
    width  = h.MinWidth;
    height = h.MinHeight;
    
    screenWidth  = h.ScreenSize(3);
    screenHeight = h.ScreenSize(4);
    
    left   = min(max(xCenter - width/2,  margin), screenWidth - width - margin);
    bottom = min(max(yCenter - height/2, margin), screenHeight - height - margin);
    
    h.Figure.Position = [left bottom width height];
end


function ax = makeInvisibleAxes(hMasterAxes)
% Set up an invisible axes; have it listen to a master axes;
% keep a handle to master axes in its appdata.

ax = axes(...
    'DataAspectRatioMode','Manual',...
    'DataAspectRatio',get(hMasterAxes,'DataAspectRatio'),...
    'PlotBoxAspectRatioMode','Manual',...
    'PlotBoxAspectRatio',get(hMasterAxes,'PlotBoxAspectRatio'),...
    'XLimMode','Manual',...
    'YLimMode','Manual',...
    'NextPlot','Add',...
    'Parent',get(hMasterAxes,'Parent'),...
    'Xlim',get(hMasterAxes,'Xlim'),...
    'Ylim',get(hMasterAxes,'Ylim'),...
    'Ydir',get(hMasterAxes,'Ydir'),...
    'Units',get(hMasterAxes,'Units'),...
    'Position',get(hMasterAxes,'Position'),...
    'Box','off',...
    'HitTest','off',...
    'Visible','off',...
    'HandleVisibility','off');

setappdata(ax,'MasterAxes',hMasterAxes)

hListener1 = addlistener(hMasterAxes, 'XLim',     'PostSet', @xlimUpdate);
hListener2 = addlistener(hMasterAxes, 'YLim',     'PostSet', @ylimUpdate);
hListener3 = addlistener(hMasterAxes, 'Position', 'PostSet', @positionUpdate);

set(ax,'DeleteFcn',@(hSrc,evnt) delete([hListener1 hListener2 hListener3]))

    function xlimUpdate(hSrc, event)
        set(ax, hSrc.Name, event.AffectedObject.XLim);
    end

    function ylimUpdate(hSrc, event)
        set(ax, hSrc.Name, event.AffectedObject.YLim);
    end

    function positionUpdate(hSrc, event)
        set(ax, hSrc.Name, event.AffectedObject.Position);
    end
end


function figureResizeFcn(hSrc,event,this) %#ok
fig_pos = map.graphics.internal.getPositionInPoints(this.Figure);

%    ******** 2
%    *      *
%    *      *
%    *      *
%  1 ********

displayPanelHeight = this.DisplayPane.LayoutPanel.Position(4);

depth = 10;
x_pos1 = 10;
y_pos1 = displayPanelHeight + depth;
x_pos2 = fig_pos(3)-x_pos1;
y_pos2 = fig_pos(4)-depth;

axis_panel_pos = [x_pos1 y_pos1 fig_pos(3)-x_pos1*2 y_pos2-y_pos1];

if any(axis_panel_pos(3:4) <= 0,2)
  return
end
map.graphics.internal.setPositionInPoints(this.AxisPanel, axis_panel_pos);

%bottom
posPad1 = [0,y_pos1-depth+1,fig_pos(3),depth];
%top
posPad2 = [0,y_pos2+1,fig_pos(3),depth];
%left
posPad3 = [0,y_pos1-depth+1,depth+1,fig_pos(4)-y_pos1];
%right
posPad4 = [x_pos2+1,y_pos1-depth+1,depth,fig_pos(4)-y_pos1];

this.DisplayPane.LayoutPanel.Position(3) = fig_pos(3) - 4;

map.graphics.internal.setPositionInPoints(this.FigurePanel(1),posPad1);
map.graphics.internal.setPositionInPoints(this.FigurePanel(2),posPad2);
map.graphics.internal.setPositionInPoints(this.FigurePanel(3),posPad3);
map.graphics.internal.setPositionInPoints(this.FigurePanel(4),posPad4);

this.Axis.resizeLimits();
end


function props = getFigureProperties
props.Visible = 'off'; 
props.NumberTitle = 'off';
props.Toolbar = 'None';
end


function newLayer = createRGBLayer(R,I,name)
newLayer = MapModel.RasterLayer(name);
newComponent = MapModel.RGBComponent(R,I,struct([]));
newLayer.addComponent(newComponent);
end


function [fromFile,newView,rasterFromWS,shapeFromWS,needFilename,needLayerName,cmap] = parseInputs(varargin)
% Variable Initialization
fromFile = false;
newView = false;
rasterFromWS = false;
shapeFromWS = false;
cmap = false;
needFilename = false;
needLayerName = false;

if (nargin == 0) % H = MAPVIEW
  needFilename = true;
  fromFile = true;
  needLayerName = true;
elseif  (nargin == 1) && ischar(varargin{1}) % MAPVIEW(FILENAME)
  internal.map.checkfilename(varargin{1},'mapview',1);
  fromFile = true;
  needLayerName = true;
elseif (nargin == 1) && isa(varargin{1},'MapModel.MapModel') % MAPVIEW(MAP)
  newView = true;
elseif (nargin == 1) && isstruct(varargin{1}) % MAPVIEW(VECTORDATA)
  shapeFromWS = true;
  needLayerName = true;  
elseif (nargin == 2) && (ischar(varargin{1}) && ischar(varargin{2})) % MAPVIEW(FILENAME,LAYERNAME)
  internal.map.checkfilename(varargin{1},'mapview',1);
  fromFile = true;
elseif (nargin == 2) && (isnumeric(varargin{1}) && isnumeric(varargin{2})) % MAPVIEW(R,I)
  validateattributes(varargin{1},{'numeric'},{'real' 'nonempty' 'finite'},...
        'mapview','R',1);
  validateattributes(varargin{2},{'numeric'},{'real' 'nonempty' 'finite'},...
        'mapview','I',2);
  rasterFromWS = true;
  needLayerName = true;
elseif (nargin == 3) && (isnumeric(varargin{1}) && ...
                         isnumeric(varargin{2}) && isnumeric(varargin{3})) % MAPVIEW(R,I,CMAP)
  validateattributes(varargin{1},{'numeric'},{'real' 'nonempty' 'finite'},...
             'mapview','R',1);
  validateattributes(varargin{2},{'numeric'},{'real' 'nonempty' 'finite'},...
             'mapview','I',2);
  validateattributes(varargin{2},{'numeric'},{'real' 'nonempty' 'finite'},...
             'mapview','CMAP',2);
  rasterFromWS = true;
  needLayerName = true;
  cmap = true;
elseif (nargin == 2) && (isstruct(varargin{1}) && ischar(varargin{2})) % MAPVIEW(VECTORDATA,LAYERNAME)
  shapeFromWS = true;
elseif (nargin == 3) && (isnumeric(varargin{1}) && isnumeric(varargin{2})) % MAPVIEW(R,I,LAYERNAME)
  validateattributes(varargin{1},{'numeric'},{'real' 'nonempty' 'finite'},...
        'mapview','R',1);
  validateattributes(varargin{2},{'numeric'},{'real' 'nonempty' 'finite'},...
        'mapview','I',2);
  rasterFromWS = true;
elseif (nargin == 4) &&...
      (isnumeric(varargin{1}) && isnumeric(varargin{2}) ...
        && isnumeric(varargin{3}) && ischar(varargin{4})) % MAPVIEW(R,I,CMAP,LAYERNAME)
  validateattributes(varargin{1},{'numeric'},{'real' 'nonempty' 'finite'},...
        'mapview','R',1);
  validateattributes(varargin{2},{'numeric'},{'real' 'nonempty' 'finite'},...
             'mapview','I',2);
  validateattributes(varargin{3},{'numeric'},{'real' 'nonempty' 'finite'},...
             'mapview','CMAP',3);
  rasterFromWS = true;
  cmap = true;
else
  error('map:MapView:invalidInput', 'Invalid inputs for MAPVIEW.')
end
end


function setSessionPreferences(this)
this.Preferences.ShowDatatipUsage = true;
end


function viewerNumber= getViewerNumber(newView, varargin)
% Returns the MapModel Id and the MapViewer number

currentMapViews = findall(0,'Tag','mapview');

if isempty(currentMapViews)
  newModelId = 1;
  newViewNumber = 1;
else
  mapModelIds = zeros(1,length(currentMapViews));
  for n = 1:length(currentMapViews)
    % extract the Model Ids from the figure's appdata.
    mapModelIds(n) = getappdata(currentMapViews(n),'MapModelId');
  end
  
  if newView
    newMap = varargin{1}{1};
    newModelId = newMap.ModelId;
    
    % Get the lowest unused viewer number.
    newViewNumber = find(newMap.ViewerCount == 0);
    if isempty(newViewNumber)
      % Typically we'll end up here, with one or more viewers attached to
      % the MapModel and newMap.ViewerCount equal to 1 (most often) or, for
      % example, [1 2 3] if two extra viewers have been added and none have
      % been deleted.
      newViewNumber = max(newMap.ViewerCount) + 1;
    else
      % We could end up here, for example, by adding 3 extra viewers to the
      % same MapModel then closing two of them. If we close the first and
      % last of these, then newMap.Viewer count will equal [1 0 3 0].
      % And newViewNumber will equal [2 4], and we'll return 2.
      newViewNumber = newViewNumber(1);
    end      
  else
    % Determine any unused Model Ids.
    newModelId = setxor(1:max(mapModelIds), mapModelIds);
    if isempty( newModelId )
      newModelId = max(mapModelIds)+1;
    end
    newViewNumber = 1;
  end
end

viewerNumber = [newModelId, newViewNumber];
end


function figureDelete(fig, event, this) %#ok
if ishghandle(fig, 'figure')
    set(fig,'Visible','off')
end
ind = strfind(this.Name,'w');
num = str2num(this.Name(ind(end)+1:end)); %#ok<ST2NM>
this.Map.ViewerCount(num) = 0;
if isa(this.State,'MapViewer.InfoToolState')
    this.State.closeAll;
elseif ~isempty(this.PreviousInfoToolState)
    this.PreviousInfoToolState.closeAll;
end
end


function changeZoomResetView(this)

layerOrder = this.map.getLayerOrder;
if isempty(layerOrder) % There are no layers in the MapViewer      
  return
end

viewInfo = this.Axis.ViewInfo;
if isempty(viewInfo)
  viewInfo = localCreateViewInfo(this);
  this.Axis.ViewInfo = viewInfo;
  return
end

hAxes = this.getAxes();
tmpAxes = map.graphics.internal.mapgraphics.Axes( ...
    'Parent',get(hAxes,'Parent'), ...
    'Visible','off', ...
    'Position',get(hAxes,'Position'));
tmpAxes.setAxesLimits(this.map.getBoundingBox.getBoxCorners);
tmpAxes.refitAxisLimits(); 

viewinfo.XLim = get(tmpAxes.getAxes(),'XLim');
viewinfo.YLim = get(tmpAxes.getAxes(),'YLim');

delete(tmpAxes.getAxes())

this.Axis.ViewInfo = viewInfo;
end


function fixZoomView(h, srcName)
st = class(h.State);
isZoomState = strncmpi('zoom',st(strfind(st,'.')+1:end),4);
if (~isZoomState || ~strcmp(srcName,'YLim'))
  return
end

%defaultAxisSize(h);

h.Axis.refitAxisLimits;
h.Axis.updateOriginalAxis;
vEvent = MapViewer.ViewChanged(h);
h.send('ViewChanged',vEvent);

set(h.UtilityAxes, ...
    'XLim',get(h.getAxes(),'XLim'), ...
    'YLim',get(h.getAxes(),'YLim'));
end


function setNoLayerState(this,state)
% Sets the viewer to the no Layer states:
%   startup: when the viewer starts up without any arguments.
% The layername argument enables setting the first layer
% added to the viewer as the active layer.

toolbar = findall(this.Figure,'type','uitoolbar');
toolbarCh = get(toolbar,'Children');
printTool = findall(toolbar,'Tooltip','Print figure');

fileMenu = findobj(this.Figure,'type','uimenu','tag','file menu');
fmenuOptions = get(fileMenu,'Children');

viewMenu = findobj(this.Figure,'type','uimenu','tag','view menu');
vmenuOptions = get(viewMenu,'Children');

insertMenu = findobj(this.Figure,'type','uimenu','tag','insert menu');
imenuOptions = get(insertMenu,'Children');

toolsMenu = findobj(this.Figure,'type','uimenu','tag','tools menu');
tmenuOptions = get(toolsMenu,'Children');

% make sure the right menu options are checked
if nargin > 1 && strcmp(state,'startup')
  set([toolbarCh;vmenuOptions;imenuOptions;tmenuOptions],'Enable','off');
  set(fmenuOptions([2,3,4]),'Enable','off');
  set(printTool,'Enable','off');
  set(this.Figure,'WindowButtonMotionFcn','');
  set(this.DisplayPane.MapUnitsDisplay,'String','None');
else
  st = class(get(this,'state'));
  if isequal(st,'MapViewer.DefaultState') || isequal(st,'MapViewer.EditState')
     set(findobj(toolbarCh,'type','uitoggletool'),'State','off');
     this.setDefaultState;
  end
  if (isempty(this.Map.getLayerOrder))
    this.ViewIndex = 0;
    this.PreviousViews = [];
    toolbar = findall(this.Figure,'type','uitoolbar');
    viewMenu = findobj(this.Figure,'type','uimenu','tag','view menu');
    backTool = findall(toolbar,'tag','back to previous view');
    backMenuItem = findall(viewMenu,'Label','Previous View');
    set([backTool,backMenuItem,toolbarCh(1)],'Enable','off');
    set(vmenuOptions(4),'Enable','off');
    this.setActiveLayer('None');
  elseif (length(this.Map.getLayerOrder) == 1)
    if strcmp(get(this.getAxes(),'Visible'),'off') %first layer is being added
      set(this.getAxes(),'Visible','on')
      set(this.DisplayPane.MapUnitsDisplay,...
          'String',this.DisplayPane.MapUnits(:,1));
      % When the first layer is added we want to exclude the previous view, 
      % info and data tip toolbar buttons and menu items
      tbarInd = setxor(1:length(toolbarCh),2:4);
      tmenuInd = setxor(1:length(tmenuOptions),8:9);
      
      set([toolbarCh(tbarInd);...
           vmenuOptions((1:end)~=3);...
           imenuOptions;...
           tmenuOptions(tmenuInd);...
           fmenuOptions([2,3,4])],...
          'Enable','on');
      set(printTool,'Enable','on');
      this.setActiveLayer(this.Map.getLayerOrder{1});
    end
    this.setActiveLayer(this.getActiveLayerName);
    this.ViewIndex = -1;
    this.fitToWindow;
    this.PreviousViews = [];
    this.ViewIndex = 0;
    vEvent = MapViewer.ViewChanged(this);
    this.send('ViewChanged',vEvent);
    set(toolbarCh(1),'Enable','on');
    set(vmenuOptions(4),'Enable','on');  
    
    if matlab.ui.internal.desktop.isMOTW
        %If Mapviewer is used in MO, then we disable the Select Area
        %options
        set(findobj(this.Figure, 'Type', 'uitoggletool', 'Tag', 'select area'), 'Enable', 'off');
        set(findobj(this.Figure, 'Type', 'uitoggletool', 'Tag', 'select area'), 'Tooltip', 'Select area - Unavailable in MATLAB Online');
        set(findobj(this.Figure, 'Type', 'uimenu', 'Tag', 'select area menu'), 'Enable', 'off');
        set(findobj(this.Figure, 'Type', 'uimenu', 'Text', 'Selected Area'), 'Enable', 'off');        
    end
  end
end
end


function [viewinfo] = localCreateViewInfo(this)  
% Same as the resetplotview localCreateViewInfo except that
% the XLim and YLim are from the largest layers on the map
% axis

% Create a temporary Map axis for obtaining the maximum
% axis limits for the layers currently on the map.
hAxes = this.getAxes();
tmpAxes = map.graphics.internal.mapgraphics.Axes( ...
    'Parent',get(hAxes,'Parent'),'Visible','off');
tmpAxes.setAxesLimits(this.map.getBoundingBox.getBoxCorners);
tmpAxes.refitAxisLimits; 

viewinfo.XLim = get(tmpAxes.getAxes(),'XLim');
viewinfo.YLim = get(tmpAxes.getAxes(),'YLim');

% Store axes view state
viewinfo.DataAspectRatio = get(hAxes,'DataAspectRatio');
viewinfo.DataAspectRatioMode = get(hAxes,'DataAspectRatioMode');
viewinfo.PlotBoxAspectRatio = get(hAxes,'PlotBoxAspectRatio');
viewinfo.PlotBoxAspectRatioMode = get(hAxes,'PlotBoxAspectRatioMode');
viewinfo.XLim = get(hAxes,'xLim');
viewinfo.XLimMode = get(hAxes,'XLimMode');
viewinfo.YLim = get(hAxes,'yLim');
viewinfo.YLimMode = get(hAxes,'YLimMode');
viewinfo.ZLim = get(hAxes,'zLim');
viewinfo.ZLimMode = get(hAxes,'ZLimMode');
viewinfo.CameraPosition = get(hAxes,'CameraPosition');
viewinfo.CameraViewAngleMode = get(hAxes,'CameraViewAngleMode');
viewinfo.CameraTarget = get(hAxes,'CameraTarget');
viewinfo.CameraPositionMode = get(hAxes,'CameraPositionMode');
viewinfo.CameraUpVector = get(hAxes,'CameraUpVector');
viewinfo.CameraTargetMode = get(hAxes,'CameraTargetMode');
viewinfo.CameraViewAngle = get(hAxes,'CameraViewAngle');
viewinfo.CameraUpVectorMode = get(hAxes,'CameraUpVectorMode');
viewinfo.View = get(hAxes,'View');

delete(tmpAxes.getAxes())
end
