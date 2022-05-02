function h = RasterImport(viewer,type,varargin)
%RASTERIMPORT Import Raster Image from Workspace
%
%   Any numeric variables in the matlab workspace could be a valid image.
%   Only variables that are 3x2 are valid referencing matrices. Only scalar
%   variables with class map raster reference are valid referencing objects.

% Copyright 1996-2020 The MathWorks, Inc.

h = MapViewer.RasterImport;
h.RasterType = type;
 
hFig = figure(varargin{:},...
    'NumberTitle','off',...
    'Menubar','none',...
    'Units','inches',...
    'Resize','off',...
    'Position',getWindowPosition(viewer,type),...
    'HandleVisibility','off',... 
    'WindowStyle','modal',...
    'CloseRequestFcn',@closeRasterImport);

set(hFig,'Name',sprintf('Import %c%s Data',upper(type(1)),lower(type(2:end))));
ax = axes('Parent',hFig,'Visible','off','Units','normalized','Position',[0 0 1 1]);

% Take inventory of variables in the base workspace
tempWSVars  = evalin('base','whos');

if isempty(tempWSVars)
    workspaceVars = tempWSVars;
else
    % Store only the name, size, bytes and class fields that we need
    [workspaceVars(1:numel(tempWSVars)).name] = deal(tempWSVars(:).name);
    [workspaceVars(:).size] = deal(tempWSVars(:).size);
    [workspaceVars(:).bytes] = deal(tempWSVars(:).bytes);
    [workspaceVars(:).class] = deal(tempWSVars(:).class);
end

clear tempWSVars

if strcmpi(type,'image')
  imageImportDialog(h,hFig,ax,workspaceVars);
else %grid
  gridImportDialog(h,hFig,ax,workspaceVars);
end


% Buttons
buttonHeight = 0.06;
margins = 0.05;
spacing = 0.02;
buttonWidth = (1 - (2 * margins + 3 * spacing)) / 3;
lowerMargin = 0.02;

uicontrol('Parent',hFig,'Units','normalized','Style','push','String','OK',...
          'Position',[margins lowerMargin buttonWidth buttonHeight],...
          'Callback',@doOKButton);

uicontrol('Parent',hFig,'Units','normalized','Style','push','String','Cancel',...
          'Position',[margins + buttonWidth + spacing lowerMargin buttonWidth buttonHeight],...
          'Callback',@doCancelButton);

uicontrol('Parent',hFig,'Units','normalized','Style','push','String','Apply',...
          'Position',[margins + 2 * buttonWidth + 2 * spacing lowerMargin buttonWidth buttonHeight],...
          'Callback',@doApplyButton);
    
    %--- Nested callback functions ---
    
    function closeRasterImport(hSrc,event) %#ok<INUSD>
        % Replacement for the default CLOSEREQ function: Delete the
        % MapViewer.RasterImport object in addition to the HG figure.
        if ishghandle(hFig)
            delete(hFig)
        end
        if ishandle(h)  % Applying ishandle to a non-HG (UDD) object
            delete(h)
        end
    end

    %--------------------------------

    function doApplyButton(hSrc,event) %#ok<INUSD>
        if (strcmpi(h.RasterType,'image'))
            addLayerFromWS_Image(h,viewer);
        else
            addLayerFromWS_Grid(h,viewer);
        end
    end

    %--------------------------------
    
    function doOKButton(hSrc,event) %#ok<INUSD>
        if (strcmpi(h.RasterType,'image'))
            succeeded = ~addLayerFromWS_Image(h,viewer);
        else
            succeeded = ~addLayerFromWS_Grid(h,viewer);
        end
        
        if succeeded
            close(hFig)
        
            % Refresh pointer so that proper pointer displays. The pointer
            % is set to 'arrow' when the user leaves the map axes. Without
            % this manual refresh, the cursor won't update until the user
            % moves the mouse. We want the cursor to be correct immediately.
            iptPointerManager(viewer.Figure,'enable');
         else
            % Leave the figure open and don't refresh the cursor.
       end
    end

    %--------------------------------

    function doCancelButton(hSrc,event) %#ok<INUSD>
        close(hFig)
        
        % Refresh pointer so that proper pointer displays. The pointer
        % is set to 'arrow' when the user leaves the map axes. Without
        % this manual refresh, the cursor won't update until the user
        % moves the mouse. We want the cursor to be correct immediately.
        iptPointerManager(viewer.Figure,'enable');
    end
      
end

%----------------------------------------------------------------------%
function imageImportDialog(h,hFig,ax,workspaceVars)

% Dimensions of the listboxes
listWidth = 0.8;
listHeight = 0.25;
listX = (1 - listWidth) / 2;
figColor = get(hFig,'Color');

% Referencing Matrix/Object Interface
text('Parent',ax,'Units','normalized','Position',[0.5, 0.93 ,0],...
    'String','Referencing matrix or object name',...
    'HorizontalAlignment','center','Visible','on');

h.RefMatrixList = uicontrol('Parent',hFig,...
                            'Units','normalized',...
                            'Position',[listX 0.66 listWidth listHeight],...
                            'BackgroundColor','w',...
                            'Style','listbox','Tag','RefVarName');

refMatVars = getRefMatrixVariables(workspaceVars);
if ~any(strcmp('',{refMatVars.name}))
  set(h.RefMatrixList,'String',{refMatVars.name});
else
  set(h.RefMatrixList,'String',{''});
  set(h.RefMatrixList,'BackGroundColor',figColor);
end

% Image Data Interface
text('Parent',ax,'Units','normalized','Position',[0.5, 0.64, 0],...
    'String','Raster data name',...
    'HorizontalAlignment','center','Visible','on');

h.RasterMatrixList = uicontrol('Parent',hFig,...
                               'Units','normalized',...
                               'Position',[listX 0.37 listWidth listHeight],...
                               'Style','listbox','Tag','RasterVarName',...
                               'BackgroundColor','w',...
                               'Callback',{@setBandList h});

imageVars = getImageVariables(workspaceVars);
if ~any(strcmp('',{imageVars.name}))
  set(h.RasterMatrixList,'String',{imageVars.name});
else
  set(h.RasterMatrixList,'String',{''});
  set(h.RasterMatrixList,'BackgroundColor',figColor);
end

% Selection of RGB Bands

% Number of bands for first image.  Used to prime RGB popupmenus
if isempty(imageVars(1).name)
  str = {'Band 1'};
else
  n = getNumberOfBands(imageVars(1).name);
  str = cell(1,n);
  for i=1:n
    str{i} = sprintf('Band %d',i);
  end
end

y = 0.3;
t = text('Parent',ax,'Units','normalized','Position',[listX, y, 0],...
         'String','Red:','Color',[0.5 0 0]);
textExtent = get(t,'Extent');
h.RedBandList = uicontrol('Parent',hFig,'Units','normalized',...
                          'Position',[listX + 0.2, y - textExtent(4) / 2, 0.4, textExtent(4)],...
                          'Style','popupmenu','string',str,...
                          'BackgroundColor','w',...
                          'HorizontalAlignment','center');

y = y - 2 * textExtent(4);
t = text('Parent',ax,'Units','normalized','Position',[listX, y, 0],...
         'String','Green:','Color',[0 0.5 0]);
textExtent = get(t,'Extent');
h.GreenBandList = uicontrol('Parent',hFig,'Units','normalized',...
                            'Position',[listX + 0.2, y - textExtent(4) / 2, 0.4, textExtent(4)],...
                            'Style','popupmenu','string',str,...
                            'BackgroundColor','w',...
                            'HorizontalAlignment','center');

y = y - 2 * textExtent(4);
t = text('Parent',ax,'Units','normalized','Position',[listX, y, 0],...
         'String','Blue:','Color',[0 0 0.5]);
textExtent = get(t,'Extent');
h.BlueBandList = uicontrol('Parent',hFig,'Units','normalized',...
                           'Position',[listX + 0.2, y - textExtent(4) / 2, 0.4, textExtent(4)],...
                           'Style','popupmenu','string',str,...
                           'BackgroundColor','w',...
                           'HorizontalAlignment','center');

setBandList(h.RasterMatrixList,[],h);
end

%----------------------------------------------------------------------%
function gridImportDialog(h,hFig,ax,workspaceVars)

% Dimensions of the listboxes
listWidth = 0.76;
listHeight = 0.25;
listX = (1 - listWidth) / 2;
figColor = get(hFig,'Color');

% X Geolocation Array Interface
text('Parent',ax,'Units','normalized','Position',[0.5,0.955,0],...
    'String','X geolocation array name',...
    'HorizontalAlignment','center','Visible','on');

h.XGeoArrayList = uicontrol('Parent',hFig,...
                            'Units','normalized',...
                            'Position',[listX 0.68 listWidth listHeight],...
                            'BackgroundColor','w',...
                            'Style','listbox','Tag','XGeoName');

xGeoVars = getXnYGeoArrayVariables(workspaceVars);
if ~any(strcmp('',{xGeoVars.name}))
  set(h.XGeoArrayList,'String',{xGeoVars.name});
else
  set(h.XGeoArrayList,'String',{''});
  set(h.XGeoArrayList,'BackgroundColor',figColor);
end

% Y Geolocation Array Interface
text('Parent',ax,'Units','normalized','Position',[0.5, 0.665 ,0],...
    'String','Y geolocation array name',...
    'HorizontalAlignment','center','Visible','on');
     
h.YGeoArrayList = uicontrol('Parent',hFig,...
                            'Units','normalized',...
                            'Position',[listX 0.39 listWidth listHeight],...
                            'BackgroundColor','w',...
                            'Style','listbox','Tag','YGeoName');

yGeoVars = getXnYGeoArrayVariables(workspaceVars);
if ~any(strcmp('',{yGeoVars.name}))
  set(h.YGeoArrayList,'String',{yGeoVars.name});
else
  set(h.YGeoArrayList,'String',{''});
  set(h.YGeoArrayList,'BackgroundColor',figColor);
end

% Data Grid Array Interface
text('Parent',ax,'Units','normalized','Position',[0.5, 0.375 ,0],...
    'String','Data grid array name',...
    'HorizontalAlignment','center','Visible','on');

h.DataGridArrayList = uicontrol('Parent',hFig,...
                                'Units','normalized',...
                                'Position',[listX 0.1 listWidth listHeight],...
                                'BackgroundColor','w',...
                                'Style','listbox','Tag','DataGridName');

dataGridVars = getDataGridArrayVariables(workspaceVars);
if ~any(strcmp('',{dataGridVars.name}))
  set(h.DataGridArrayList,'String',{dataGridVars.name});
else
  set(h.DataGridArrayList,'String',{''});
  set(h.DataGridArrayList,'BackgroundColor',figColor);
end

h.DisplayType = 'surf';
end

%----------------------------------------------------------------------%
function status = addLayerFromWS_Image(h,viewer)
SUCCESS = 0;
FAIL = 1;
status = SUCCESS;
% Reference Matrix
refVarNames = get(h.RefMatrixList,'String');
if iscell(refVarNames)
  refName = refVarNames{get(h.RefMatrixList,'Value')};
else
  refName = refVarNames;
end
if isempty(refName)
  errordlg('The image must be referenced by a 3-by-2 numeric matrix or a scalar map raster reference object.','Import Error','modal');
  status = FAIL;
  return;
else
  R = evalin('base',refName);
end

rasterVarNames = get(h.RasterMatrixList,'String');
if iscell(rasterVarNames)
  rasterName = rasterVarNames{get(h.RasterMatrixList,'Value')};
else
  rasterName = rasterVarNames;
end
if isempty(rasterName)
  errordlg('You must select the raster data.','Import Error','modal');
  status = FAIL;
  return;
end
r = get(h.RedBandList,'Value');
g = get(h.GreenBandList,'Value');
b = get(h.BlueBandList,'Value');
I = evalin('base',[rasterName '(:,:,[' num2str(r) ',' num2str(g) ',' num2str(b) '])']);

% Perform some additional error checking
if ~(isnumeric(R) || (isscalar(R) && isa(R, 'map.rasterref.MapRasterReference')))
  errordlg('The image must be referenced by a 3-by-2 numeric matrix or a scalar map raster reference object.','Import Error','modal');
  status = FAIL;
  return
elseif isobject(R) && ~strcmp(R.RasterInterpretation,'cells')
  errordlg('The referencing object must have a RasterInterpretation of ''cells''.','Import Error','modal');
  status = FAIL;
  return
elseif isobject(R) && ~R.sizesMatch(I)
  errordlg('The RasterSize property of the referencing object must match the image size.','Import Error','modal');
  status = FAIL;
  return    
elseif ~isnumeric(I)
  errordlg('The image must be numeric.','Import Error','modal');  
  status = FAIL;
  return  
end

% If necessary, convert R from a map raster reference object to
% a referencing matrix
if isobject(R)
    R = map.internal.referencingMatrix(R.worldFileMatrix());
end

% Create and Add New Layer
try
  layer = createRGBLayer(R,I,rasterName);      
  viewer.addLayer(layer);
catch ME    
  errordlg(ME.message,'Import Error','modal');
  status = FAIL;
end
end

%----------------------------------------------------------------------%
function status = addLayerFromWS_Grid(h,viewer)
SUCCESS = 0;
FAIL = 1;
status = SUCCESS;

% X Geolocation Array
xGeoVarNames = get(h.XGeoArrayList,'String');
if iscell(xGeoVarNames)
  xGeoName = xGeoVarNames{get(h.XGeoArrayList,'Value')};
else
  xGeoName = xGeoVarNames;
end

if isempty(xGeoName)
  errordlg('The X geolocation array must vector.','Import Error','modal');
  status = FAIL;
  return;
else
  X = evalin('base',xGeoName);
end

% Y Geolocation Array
yGeoVarNames = get(h.YGeoArrayList,'String');
if iscell(yGeoVarNames)
  yGeoName = yGeoVarNames{get(h.YGeoArrayList,'Value')};
else
  yGeoName = yGeoVarNames;
end

if isempty(yGeoName)
  errordlg('The Y geolocation array must vector.','Import Error','modal');
  status = FAIL;
  return;
else
  Y = evalin('base',yGeoName);
end

% Data Grid Array
dataGridVarNames = get(h.DataGridArrayList,'String');
if iscell(yGeoVarNames)
  dataGridName = dataGridVarNames{get(h.DataGridArrayList,'Value')};
else
  dataGridName = dataGridVarNames;
end

if isempty(dataGridName)
  errordlg('The Data Grid Array must be a M-by-N matrix.','Import Error','modal');
  status = FAIL;
  return;
else
  Z = evalin('base',dataGridName);
end

% Perform some additional error checking
sizeX = size(X);
sizeY = size(Y);
sizeZ = size(Z);
if ~isnumeric(X) || ~isnumeric(Y) || ~isnumeric(Z)
    errordlg('The X, Y geolocation array and Data Grid Array must be numeric.','Import Error','modal');
  status = FAIL;
  return
elseif any(sizeX==1) ~= any(sizeY==1)
  errordlg(sprintf(['The X and Y geolocation array must be M-by-N matrices of the \n',...
                    'size or vectors']),'Import Error','modal');
  status = FAIL;
  return  
elseif (all(sizeX~=1) && all(sizeY~=1))
  if ~isequal(sizeX,sizeY,sizeZ)
    errordlg(sprintf(['For X and Y geolocation array matrices, the sizes ' ...
                      '\nmust be equal to the Data Grid Array.']),['Import ' ...
                        'Error'],'modal');
    status = FAIL;
    return 
  end
end

rasterName = dataGridName;

% Create and Add New Layer
try
  layer = createGridLayer(X,Y,Z,rasterName,h.DisplayType);      
  viewer.addLayer(layer);
catch ME
  errordlg(ME.message,'Import Error','modal');
  status = FAIL;
end
end

%----------------------------------------------------------------------%
function newLayer = createRGBLayer(R,I,name)
newLayer = MapModel.RasterLayer(name);
newComponent = MapModel.RGBComponent(R,I,struct([]));
newLayer.addComponent(newComponent);
end

%----------------------------------------------------------------------%
function newLayer = createGridLayer(X,Y,Z,name,dispType)
newLayer = MapModel.RasterLayer(name);
newComponent = MapModel.GriddedComponent(X,Y,Z,dispType);
newLayer.addComponent(newComponent);
end

%--------------------Listbox Callbacks--------------------%

%----------------------------------------------------------------------%
function setBandList(hSrc,event,h) %#ok<INUSL>
v = get(hSrc,'value');
strs = get(hSrc,'String');

if isempty(strs{1})
  n = 0;
  str = {'Band 1'};
else
  n = getNumberOfBands(strs{v});
  str = cell(1,n);
  for i=1:n
    str{i} = sprintf('Band %d',i);
  end
end

if n>=3
  set(h.RedBandList,'Value',1,'String',str);
  set(h.GreenBandList,'Value',2,'String',str);
  set(h.BlueBandList,'Value',3,'String',str);
else
  set(h.RedBandList,'Value',1,'String',str);
  set(h.GreenBandList,'Value',1,'String',str);
  set(h.BlueBandList,'Value',1,'String',str);
end
end

%--------------------Helper Functions--------------------%

%----------------------------------------------------------------------%
function n = getNumberOfBands(varname)
variable = evalin('base',['whos(''' varname ''');']);
if length(variable.size) > 2
  n = variable.size(3);
else
  n = 1;
end
end

%----------------------------------------------------------------------%
function vars = getRefMatrixVariables(workspaceVars)
% Reference matrix variables must either be 3-by-2 and numeric,
% or a scalar map raster reference object.

% Cell array of supported raster reference class names. In the future
% (after postings is supported) add 'map.rasterref.MapPostingsReference'
rasterRefenceClassNames = {'map.rasterref.MapCellsReference'};

% Loop through each structure element from whos and select any that match.
vars = struct('name','','size',[],'bytes',[],'class','');
j = 1;
for i=1:numel(workspaceVars)
  v = workspaceVars(i);
  if isequal(v.size, [3 2]) || (isequal(v.size, [1 1]) ...
          && any(strcmp(v.class, rasterRefenceClassNames)))
    vars(j) = v;
    j = j + 1;
  end
end
end

%----------------------------------------------------------------------%
function vars = getImageVariables(workspaceVars)
vars = struct('name','','size',[],'bytes',[],'class','');
numericClasses = {'double','single','uint8','int8','uint16','int16',...
                 'uint32','int32','uint64','int64','logical'};
j = 1;
for i = 1:length(workspaceVars)
  if any(strcmp(workspaceVars(i).class,numericClasses))
    vars(j) = workspaceVars(i);
    j = j + 1;
  end
end
end

%----------------------------------------------------------------------%
function vars = getXnYGeoArrayVariables(workspaceVars)
vars = struct('name','','size',[],'bytes',[],'class','');

%j = 1;
for i=1:length(workspaceVars)
%  if (any(workspaceVars(i).size == 1))
    vars(i) = workspaceVars(i);
%    vars(j) = workspaceVars(i);
%    j = j + 1;
%  end
end
end

%----------------------------------------------------------------------%
function vars = getDataGridArrayVariables(workspaceVars)
vars = struct('name','','size',[],'bytes',[],'class','');

j = 1;
for i = 1:length(workspaceVars)
  if (~any(workspaceVars(i).size == 1))
    vars(j) = workspaceVars(i);
    j = j + 1;
  end
end
end

%----------------------------------------------------------------------%
function pos = getWindowPosition(viewer,type)
pos = viewer.getPosition('inches');

w = 2.75;
x = pos(1) + pos(3)/2 - 2.8/2;
if strcmpi(type,'image')
  h = 5;
else 
  h = 4.75;
end
y = pos(2) + pos(4)/2 - h/2;
pos = [x,y,w,h];
end

