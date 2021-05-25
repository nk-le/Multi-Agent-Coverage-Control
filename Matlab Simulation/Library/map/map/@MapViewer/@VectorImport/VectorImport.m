function h = VectorImport(viewer,type)
%VECTORIMPORT Import Vector Image from Workspace

% Copyright 1996-2016 The MathWorks, Inc.

h = MapViewer.VectorImport;

hFig = figure(...
    'NumberTitle','off',...
    'Name','Import Vector Data',...
    'Menubar','none',...
    'Units','inches',...
    'Resize','off',...
    'Position',getWindowPosition(viewer,type),...
    'HandleVisibility','off',...
    'WindowStyle','modal',...
    'CloseRequestFcn',@closeVectorImport);

ax = axes('Parent',hFig,'Visible','off',...
          'XLimMode','manual','XLim',[0 1],...
          'YLimMode','manual','YLim',[0 1],...
          'Units','normalized','Position',[0 0 1 1]);

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

% Buttons
buttonHeight = 0.06;
margins = 0.05;
spacing = 0.02;
buttonWidth = (1 - (2 * margins + 3 * spacing)) / 3;
lowerMargin = 0.04;

if strcmpi(type,'cartesian') || strcmpi(type,'latlon')
  cartesianImportDialog(h,hFig,ax,workspaceVars);
else 
  geoStructImportDialog(h,hFig,ax,workspaceVars);
  buttonHeight = buttonHeight*2;
end

uicontrol('Parent',hFig,'Units','normalized','Style','push','String','OK',...
          'Position',[margins lowerMargin buttonWidth buttonHeight],...
          'Callback',@doOKButton);

uicontrol('Parent',hFig,'Units','normalized','Style','push','String','Cancel',...
          'Position',[margins + buttonWidth + spacing lowerMargin buttonWidth buttonHeight],...
          'Callback',@doCancelButton);

uicontrol('Parent',hFig,'Units','normalized','Style','push','String','Apply',...
          'Position',[margins + 2 * buttonWidth + 2 * spacing lowerMargin buttonWidth buttonHeight],...
          'Callback',@doApplyButton);

    function closeVectorImport(hSrc,event) %#ok<INUSD>
        % Replacement for the default CLOSEREQ function: Delete the
        % MapViewer.VectorImport object in addition to the HG figure.
        if ishghandle(hFig)
            delete(hFig)
        end
        if ishandle(h)  % Applying ishandle to a non-HG (UDD) object
            delete(h)
        end
    end

    function doOKButton(hSrc,event)  %#ok<INUSD>
        succeeded = ~doImport(h,hFig,viewer,type);
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

    function doApplyButton(hSrc,event)  %#ok<INUSD>
        doImport(h,hFig,viewer,type);
    end

    function doCancelButton(hSrc,event)  %#ok<INUSD>
        close(hFig)
        
        % Refresh pointer so that proper pointer displays. The pointer
        % is set to 'arrow' when the user leaves the map axes. Without
        % this manual refresh, the cursor won't update until the user
        % moves the mouse. We want the cursor to be correct immediately.
        iptPointerManager(viewer.Figure,'enable');
    end

end

%----------------------------------------------------------------------%
function cartesianImportDialog(h,hFig,ax,workspaceVars)
% Convention for storing text/edit box pairs
%
% The text/edit box pairs of uicontrols are stored in a cell array and
% each assigned to one property of the class.  The text uicontrol is the
% first element of the cell array and the edit box is the second element.
% For example, the uicontrol for the text of X is stored in h.X{1} and the
% editable text uicontrol for X is stored in h.X{2}.

% Dimensions of the listboxes
listWidth = 0.8;
listHeight = 0.22;
listX = (1 - listWidth) / 2;
figColor = get(hFig,'Color');

% X
h.X{1} = text('Parent',ax,'Units','normalized','Position',[0.5, 0.95 ,0],...
              'String','X',...
              'HorizontalAlignment','center','Visible','on');
h.X{2} = uicontrol('Parent',hFig,...
                   'Units','normalized',...
                   'Position',[listX 0.7 listWidth listHeight],...
                   'BackgroundColor','w',...
                   'Style','listbox','Tag','xVarName');

vecVars = getVecVariables(workspaceVars);
if ~any(strcmp('',{vecVars.name}))
  set(h.X{2},'String',{vecVars.name});
else
  set(h.X{2},'String',{''});
  set(h.X{2},'BackGroundColor',figColor);
end

% Y 
h.Y{1} = text('Parent',ax,'Units','normalized','Position',[0.5, 0.67, 0],...
              'String','Y',...
              'HorizontalAlignment','center','Visible','on');
		  
h.Y{2} = uicontrol('Parent',hFig,...
                   'Units','normalized',...
                   'Position',[listX 0.42 listWidth listHeight],...
                   'Style','listbox','Tag','yVarName',...
                   'BackgroundColor','w');

vecVars = getVecVariables(workspaceVars);
if ~any(strcmp('',{vecVars.name}))
  set(h.Y{2},'String',{vecVars.name});
else
  set(h.Y{2},'String',{''});
  set(h.Y{2},'BackgroundColor',figColor);
end

% Geometry
t =  text('Parent',ax,'Units','normalized','Position',[0.5, 0.38, 0],...
              'String','Geometry',...
              'HorizontalAlignment','center','Visible','on');

h.VectorTopologyText = t;

radioX = listX + 0.2;
y = 0.31;
textExtent = get(t,'Extent');
radioPosition = [radioX, y - textExtent(4) / 2, 0.4, textExtent(4)];
pointButton = uicontrol('Parent',hFig,...
                        'Units','normalized',...
                        'Position',radioPosition,...
                        'Style','radiobutton','Tag','point',...
                        'BackgroundColor',figColor,...
                        'Enable','on',...
                        'String','Point','HorizontalAlignment','center');

y = y - 2 * textExtent(4);
radioPosition = [radioX, y - textExtent(4) / 2, 0.4, textExtent(4)];

lineButton = uicontrol('Parent',hFig,...
                       'Units','normalized',...
                       'Position',radioPosition,...
                       'Style','radiobutton','Tag','point',...
                       'BackgroundColor',figColor,...
                       'Enable','on',...
                       'String','Line','HorizontalAlignment','center');

y = y - 2 * textExtent(4);
radioPosition = [radioX, y - textExtent(4) / 2, 0.4, textExtent(4)];

polygonButton = uicontrol('Parent',hFig,...
                          'Units','normalized',...
                          'Position',radioPosition,...
                          'Style','radiobutton','Tag','point',...
                          'BackgroundColor',figColor,...
                          'Enable','on',...
                          'String','Polygon','HorizontalAlignment','center');

set([pointButton,polygonButton,lineButton],...
    'Callback',{@mutuallyExclusive, [pointButton, polygonButton, lineButton]});

h.Topology = [pointButton,polygonButton,lineButton];
end

%----------------------------------------------------------------------%
function geoStructImportDialog(h,hFig,ax,workspaceVars)
% Vector Shape Structure

% This should be the same for unix and windows.  Why would points be
% different sizes?
%if isunix
%  textPosition = [margin, radioPosition(2) - radioHeight - 24, 120 16];
%else
%  textPosition = [margin, radioPosition(2) - radioHeight - 24 - 13, 120 16];
%end

% Dimensions of the listboxes
listWidth = 0.9;
listHeight = 0.6;
listX = (1 - listWidth) / 2;
figColor = get(hFig,'Color');

% Geo Data Structure
h.ShapeStruct{1} = text('Parent',ax,'Units','normalized','Position',[0.5, 0.92 ,0],...
                        'String','Geographic Data Structure',...
                        'HorizontalAlignment','center','Visible','on');

h.ShapeStruct{2} = uicontrol('Parent',hFig,...
                             'Units','normalized',...
                             'Position',[listX 0.25 listWidth listHeight],...
                             'BackgroundColor','w',...
                             'Style','listbox','Tag','RefVarName');


geoStructVars = getGeoStructVariables(workspaceVars);
if ~any(strcmp('',{geoStructVars.name}))
  set(h.ShapeStruct{2},'String',{geoStructVars.name});
else
  set(h.ShapeStruct{2},'String',{''});
  set(h.ShapeStruct{2},'BackGroundColor',figColor);
end
end

%----------------------------------------------------------------------%
function mutuallyExclusive(hSrc,event,handles) %#ok<INUSL>
set(handles(handles ~= hSrc),'Value',0);
end

%----------------------------------------------------------------------%
function type = getShapeType(this)
values = get(this.Topology,'Value');
idx = find([values{:}] == 1);
if isempty(idx)
  type = '';
else
  switch lower(get(this.Topology(idx),'String'))
   case 'polygon'
    type = 'Polygon';
   case 'line'
    type = 'Line';
   case {'point','multipoint'}
    type = 'Point';
   otherwise 
    type = '';
  end
end
end

%----------------------------------------------------------------------%
function failed = doImport(this,hFig,viewer,type)
failed = false;
switch type
    case 'cartesian'
        shapeData.Geometry = getShapeType(this);
        if isempty(shapeData.Geometry)
            displayError(hFig,{'You must select a','Vector Topology.'});
            failed = true;
            return;
        end
        xstr = get(this.X{2},'String');
        xInd = get(this.X{2},'Value');
        ystr = get(this.Y{2},'String');
        yInd = get(this.Y{2},'Value');
        
        xstr = xstr{xInd};
        ystr = ystr{yInd};
        layername = [xstr '/' ystr];
        if isempty(xstr) || isempty(ystr)
            displayError(hFig,{'X and Y must be names of 1-by-N or N-by-1',...
                'vectors in the base workspace.'});
            failed = true;
            return
        end
        try
            shapeData.X = evalin('base',xstr);
            shapeData.Y = evalin('base',ystr);
            shapeData.BoundingBox = [min(shapeData.X), min(shapeData.Y);...
                max(shapeData.X), max(shapeData.Y)];
        catch %#ok<CTCH>
            displayError(hFig,{'X and Y must be names of 1-by-N or N-by-1',...
                'vectors in the base workspace.'});
            failed = true;
            return;
        end
        
    case 'latlon'
        shapeData.Geometry= getShapeType(this);
        if isempty(shapeData.Geometry)
            displayError(hFig,{'You must select a','Vector Topology.'});
            failed = true;
            return;
        end
        latstr = get(this.Lat{2},'String');
        lonstr = get(this.Lon{2},'String');
        layername = [latstr '/' lonstr];
        if isempty(latstr) || isempty(lonstr)
            displayError(hFig,{'Lat and Lon must be names of 1-by-N or N-by-1',...
                'vectors in the base workspace.'});
            failed = true;
            return;
        end
        try
            shapeData.X = evalin('base',latstr);
            shapeData.Y = evalin('base',lonstr);
            shapeData.BoundingBox = [min([shapeData.X, shapeData.Y]);...
                max([shapeData.X, shapeData.Y])];
        catch %#ok<CTCH>
            displayError(hFig,{'Lat and Lon must be names of 1-by-N or N-by-1',...
                'vectors in the base workspace.'});
            failed = true;
            return;
        end
        
    case 'struct'
        shapestr = get(this.ShapeStruct{2},'String');
        ind = get(this.ShapeStruct{2},'Value');
        layername = shapestr{ind};
        if isempty(shapestr{ind})
            displayError(hFig,{'Vector Shape Structure must be a structure',...
                'in the base workspace.'});
            failed = true;
            return;
        end
        try
            shapeData = evalin('base',shapestr{ind});
        catch %#ok<CTCH>
            displayError(hFig,{'Vector Shape Structure must be a structure',...
                'in the base workspace.'});
            failed = true;
            return;
        end
        
        % The geographic data structure may not have the correct
        % BoundingBox. If present, remove it since updategeostruct
        % calculates and adds a BoundingBox when missing.
        boundingBoxStr = 'BoundingBox';
        if isfield(shapeData, boundingBoxStr)
            shapeData = rmfield(shapeData, boundingBoxStr);
        end
end
try
    % Validate the geostruct and add a BoundingBox if missing.
    [shapeData, spec] = updategeostruct(shapeData);
    
    % Project the data if needed
    if isfield(shapeData,'Lat') && isfield(shapeData,'Lon')
        [shapeData.X] = deal(shapeData.Lon);
        [shapeData.Y] = deal(shapeData.Lat);
    end
    
    layer = map.graphics.internal.createVectorLayer(shapeData,layername);
    if isstruct(spec)
        layerlegend = layer.legend;
        layerlegend.override(rmfield(spec,'ShapeType'));
    end
    
catch %#ok<CTCH>
    displayError(hFig,'Invalid Geographic Data Structure');
    failed = true;
    return;
end

try
    viewer.addLayer(layer);
catch %#ok<CTCH>
    displayError(hFig,['A layer named ' layername ' already exists.']);
    failed = true;
end
end

%----------------------------------------------------------------------%
function p = getWindowPosition(viewer,type)
p = viewer.getPosition('inches');

w = 2.75;
x = p(1) + p(3)/2 - 2.8/2;
if strcmpi(type,'cartesian') || strcmpi(type,'latlon')
  h = 4.75;
else
  h = 2;
end
y = p(2) + p(4)/2 - h/2;
p = [x,y,w,h];
end

%----------------------------------------------------------------------%
function vars = getVecVariables(workspaceVars)
vars = struct('name','','size',[],'bytes',[],'class','');
j = 1;
for i = 1:length(workspaceVars)
  if (any(workspaceVars(i).size ==1))
    vars(j) = workspaceVars(i);
    j = j + 1;
  end
end
end

%----------------------------------------------------------------------%
function vars = getGeoStructVariables(workspaceVars)
vars = struct('name','','size',[],'bytes',[],'class','');
j = 1;
for i = 1:length(workspaceVars)
  if strcmp(workspaceVars(i).class,'struct')
    vars(j) = workspaceVars(i);
    j = j + 1;
  end
end
end

%----------------------------------------------------------------------%
function displayError(hFig,str)

w = 2.5;
h = 1;

oldunits = get(hFig,'Units');
set(hFig,'Units','inches');
p = get(hFig,'Position');
x = p(1) + p(3)/2 - w/2;
y = p(2) + p(4)/2 - h/2;
set(hFig,'Units',oldunits);

f = figure('WindowStyle','modal','Units','inches',...
           'Position',[x y w h],'Resize','off',...
           'NumberTitle','off','Menubar','none',...
           'Name','Error','IntegerHandle','off');

uicontrol('Style','text','String',str,...
          'Units','inches','Position',[w/2-2.3/2 h/2-0.2 2.3 0.6],...
          'HorizontalAlignment','center',...
          'BackgroundColor',get(f,'Color'));

uicontrol('Style','pushbutton','String','OK',...
          'Units','inches','Position',[w/2-0.25 h/2-0.4 0.5 0.3],...
          'HorizontalAlignment','center',...
          'Callback',@closeErrorWindow);

uiwait(f);

    function closeErrorWindow(hSrc,event) %#ok<INUSD>
        close(f)
    end
end
