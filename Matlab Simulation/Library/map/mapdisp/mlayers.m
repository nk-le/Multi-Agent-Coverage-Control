function  mlayers(varargin)
%MLAYERS Control plotting of display structure elements
%
%   MLAYERS will be removed in a future release.
%
%   MLAYERS provides interactive plotting of Mapping Toolbox display
%   structures, which can be provided either in a MAT-file or in a cell
%   array.
%
%   MLAYERS(FILENAME) identifies display structures in the MAT-file
%   specified by the FILENAME, and plots them on the current map axes.
%
%   MLAYERS(DISPLAY_STRUCTS) plots the display structures from the
%   DISPLAY_STRUCTS cell array on the current map axes.  DISPLAY_STRUCTS
%   must be N-by-2, with one row per display structure.  Within each row,
%   the first column must contain a display structure array and the second
%   column must contain a "layer" name with which it will be associated.
%   The DISPLAY_STRUCTS input can be constructed from the current workspace
%   using the ROOTLAYR function.
%
%   MLAYERS(..., AX) plots on the map axes specified by handle AX.
%
%   For further information on display structures, consult the Mapping
%   Toolbox reference page for DISPLAYM.
%
%   Example 
%   ------- 
%   % Greatlakes 
%   usamap('conus') 
%   mlayers('greatlakes.mat')

% Copyright 1996-2017 The MathWorks, Inc. 
% Written by:  E. Byrns, E. Brown

%  Parse the inputs
narginchk(1, 2)

[varargin{:}] = convertStringsToChars(varargin{:});
if nargin == 1
    workspace = varargin{1};
    hndl = get(get(0,'CurrentFigure'),'CurrentAxes');
    action = 'initialize';
    
elseif nargin == 2
    if ischar(varargin{1}) || iscell(varargin{1})
        workspace = varargin{1};
        hndl = varargin{2};
        action = 'initialize';
    elseif ishghandle(varargin{1},'figure')
        hfig = varargin{1};
        action = varargin{2};
    else
        error(['map:' mfilename ':mapdispError'], ...
            'Incorrect number of inputs')
    end
end

%  Programmers note:  The way mlayers works.......... 
%  Build up a userdata cell array which will save each structure found in
%  the workspace.  Each structure is saved in a cell array so that the
%  value of the list dialog uicontrol can be used to recall the data for
%  each layer.  The second column of the cell array is used to store the
%  plot state of that layer. Plotstate = 0 indicates unplotted, 1 means
%  shown, 2 means hidden. The third column of the cell array is used to
%  store the handles to the objects displayed for that layer.  These
%  handles may not always all be valid since the user has many ways to
%  delete objects from an axes, not just using this GUI tool.

switch action
    case 'initialize'          %  Initialize layer mod GUI
        warning(message('map:removing:mlayers', 'MLAYERS'))
        if ~(length(hndl) == 1 && ismap(hndl))   %  Test for map axes
            error(['map:' mfilename ':mapdispError'], ...
                'Axis associated with mlayers is not a valid map axes')
        end
        
        %  Get the structure variable names
        
        if iscell(workspace)  %  Variables inputed as a cell array
            if isempty(workspace)
                error(['map:' mfilename ':mapdispError'], ...
                    'No structures in workspace')
            elseif size(workspace,2) ~= 2
                error(['map:' mfilename ':mapdispError'], ...
                    'Input cell array must be n by 2')
            end
            
            indx = [];
            namearray = workspace(:,2);   workspace(:,2) = [];
            for i = 1:length(workspace)   %  Keep only the structures
                if ~isstruct(workspace{i})
                    indx = [indx; i];
                end
            end
            workspace(indx) = [];   namearray(indx) = [];
            if ~isempty(workspace)     %  Initialize layer mod box
                userdata = cell(length(workspace),3);  %  Save each structure
                userdata(:,1) = workspace;   userdata(:,2) = {0};
                
                h = mlayersbox(hndl,'Workspace');
                namearray = char(namearray);  %  Add spaces to name array
                spacechar = ' ';                  %  These spaces used for plot symbols
                spacechar = spacechar(ones([size(namearray,1) 2]));
                
                set(h.list,'String',[spacechar namearray],'Value',1,'UserData',userdata)
                mlayers(h.fig,'object')
            else
                error(['map:' mfilename ':mapdispError'], ...
                    'No structures in input cells')
            end
            
        else   %  Workspace name provided.  Load and test
            load(workspace)
            vars = who;    indx = [];
            for i = 1:length(vars)      %  Keep only the structures in workspace
                if eval(['~isstruct(',vars{i},')'])
                    indx(end+1,1) = i;
                end
            end
            vars(indx) = [];
            
            if ~isempty(vars)     %  Initialize layer mod box
                userdata = cell(length(vars),3);  %  Save each structure
                for i = 1:length(vars);   userdata{i,1} = eval(vars{i});   end
                userdata(:,2) = {0};
                
                h = mlayersbox(hndl,workspace);
                vars = char(vars);  %  Add spaces to name array
                spacechar = ' ';        %  These spaces used for plot symbols
                spacechar = spacechar(ones([size(vars,1) 2]));
                set(h.list,'String',[spacechar vars],'Value',1,'UserData',userdata)
                mlayers(h.fig,'object')
            else
                error(['map:' mfilename ':mapdispError'], ...
                    'No structures in workspace %s',workspace)
            end
        end
        set(h.fig, 'HandleVisibility','callback')
        
    case 'object'          %  Update the Object String.  Callback for the list box
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        indx     = get(h.list,'Value');          %  Get layer index
        userdata = get(h.list,'UserData');       %  and its structure data
        namelist = get(h.list,'String');
        
        switch userdata{indx,2}
            case 0
                namelist(indx,1) = ' ';
                set(h.list,'String',namelist,'Value',indx)
                set(h.hide,'String','Plot','CallBack', @(~,~)mlayers(hfig,'plot'));
                set([h.zdata;h.highlight;h.delete;h.property],'Enable','off')
                set(h.highlight,'String','Highlight', ...
                    'CallBack', @(~,~)mlayers(hfig,'highlightON'))
            case 1
                namelist(indx,1) = '*';
                set(h.list,'String',namelist,'Value',indx)
                set(h.hide,'String','Hide', ...
                    'CallBack',@(~,~) mlayers(hfig,'hide'));
                set([h.zdata;h.highlight;h.delete;h.property],'Enable','on')
                highlightstate(h)
            case 2
                namelist(indx,1) = 'h';
                set(h.list,'String',namelist,'Value',indx)
                set(h.hide,'String','Show', ...
                    'CallBack',@(~,~) mlayers(hfig,'show'));
                set([h.zdata;h.highlight;h.delete;h.property],'Enable','on')
                highlightstate(h)
        end
        
    case 'plot'          %  Plot button
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        indx     = get(h.list,'Value');          %  Get layer index
        userdata = get(h.list,'UserData');       %  and its structure data
        
        set(0,'CurrentFigure',get(h.axes,'Parent'))
        set(get(0,'CurrentFigure'),'CurrentAxes',h.axes)
        
        
        try
            h0 = displaym(userdata{indx,1});
        catch e
            [id1, rem] = strtok(e.identifier, ':');
            id2 = strtok(rem, ':');
            mapplotfcns = {'linem','meshm','patchesm','textm','surfacem','lightm'};
            if strcmp(id1, 'map') && any(strcmp(id2, mapplotfcns))
                uiwait(errordlg(e.message,'Layer Tool Plotting Error','modal'));
                return
            else
                rethrow(e)
            end
        end
        
        set(0,'CurrentFigure',h.fig)   % Return to the layer tool GUI
        
        userdata{indx,2} = 1;    %  Update the saved data structure
        userdata{indx,3} = h0;
        set(h.list,'UserData',userdata)
        mlayers(hfig,'object');    %  Update the plot state
        
    case 'hide'          %  Hide button
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        indx     = get(h.list,'Value');          %  Get layer index
        userdata = get(h.list,'UserData');       %  and its structure data
        objects = validhandles(h);               %  Set valid object handles
        if isempty(objects);  return;  end       %  No objects remain on plot
        
        set(objects,'Visible','off');
        userdata{indx,2} = 2;
        set(h.list,'UserData',userdata)
        mlayers(hfig,'object');
        
    case 'show'          %  Show button
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        indx     = get(h.list,'Value');          %  Get layer index
        userdata = get(h.list,'UserData');       %  and its structure data
        objects = validhandles(h);               %  Set valid object handles
        if isempty(objects);  return;  end       %  No objects remain on plot
        
        set(objects,'Visible','on');
        userdata{indx,2} = 1;
        set(h.list,'UserData',userdata)
        mlayers(hfig,'object');
        
    case 'delete'          %  Delete button
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        indx     = get(h.list,'Value');          %  Get layer index
        userdata = get(h.list,'UserData');       %  and its structure data
        namelist = get(h.list,'String');
        objects = validhandles(h);               %  Set valid object handles
        if isempty(objects);  return;  end       %  No objects remain on plot
        
        layername = namelist(indx,:);        layername(1:2) = [];
        quest = strvcat(['Delete Layer:  ',layername],' ','Are You Sure?'); %#ok<*DSTRVCT>
        ButtonName = questdlg(quest,'Confirm Deletion','Yes','No','No');
        
        if strcmp(ButtonName,'Yes')   %  Delete if confirmed
            delete(objects)
            namelist(indx,1) = ' ';
            userdata{indx,2} = 0;
            set(h.list,'UserData',userdata,'String',namelist,'Value',indx)
            mlayers(hfig,'object');
        end
        
    case 'zdata'          %  Zdata button
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        objects = validhandles(h);              %  Set valid object handles
        if isempty(objects);  return;  end       %  No objects remain on plot
        
        savetag = get(objects(1),'Tag');         %  Set up the tag
        indx     = get(h.list,'Value');          %  so that zdata GUI
        liststr  = get(h.list,'String');         %  has reasonable string
        set(objects(1),'Tag',liststr(indx,3:size(liststr,2)))
        
        zdatam(objects);      % Modal GUI for modifying the zdata
        set(objects(1),'Tag',savetag)    %  Restore original tag
        
    case 'highlightON'          %  Highlight button
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        objects = validhandles(h);               %  Set valid object handles
        if isempty(objects);  return;  end       %  No objects remain on plot
        
        set(objects,'Selected','on','SelectionHighlight','on')
        set(h.highlight,'String','Normal', ...
            'CallBack',@(~,~) mlayers(hfig,'highlightOFF'))
        
    case 'highlightOFF'          %  Normal button
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        objects = validhandles(h);               %  Set valid object handles
        if isempty(objects);  return;  end       %  No objects remain on plot
        
        set(objects,'Selected','on','SelectionHighlight','off')
        set(objects,'Selected','off')
        set(h.highlight,'String','Highlight', ...
            'CallBack',@(~,~)mlayers(hfig,'highlightON'))
        
    case 'purge'          %  Purge button
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        indx     = get(h.list,'Value');          %  Get layer index
        userdata = get(h.list,'UserData');       %  and its structure data
        liststr  = get(h.list,'String');
        objects = validhandles(h);               %  Set valid object handles
        
        if ~isempty(objects)   % Purge data and mapped objects
            quest = strvcat('Purge Layer Data and Map Objects',' ','Are You Sure?');
            ButtonName = questdlg(quest,'Confirm Purge','Yes','Data Only','No','No');
            
            if ~strcmp(ButtonName,'No')  %  Purge if confirmed
                if strcmp(ButtonName,'Yes')
                    delete(objects)
                end
                userdata(indx,:) = [];
                liststr(indx,:) = [];
                if ~isempty(liststr)
                    set(h.list,'String',liststr,'Value',1,'UserData',userdata)
                    mlayers(hfig,'object')
                else
                    uiwait(errordlg(['All layers purged from ',get(h.fig,'Name')],...
                        'Layer Tool Warning','modal'))
                    delete(h.fig)
                end
            end
        else        %  Purge layer data only
            quest = strvcat('Purge Layer Data',' ','Are You Sure?');
            ButtonName = questdlg(quest,'Confirm Purge','Yes','No','No');
            
            if strcmp(ButtonName,'Yes')   % Purge if confirmed
                userdata(indx,:) = [];
                liststr(indx,:) = [];
                if ~isempty(liststr)
                    set(h.list,'String',liststr,'Value',1,'UserData',userdata)
                    mlayers(hfig,'object')
                else
                    uiwait(errordlg(['All layers purged from ',get(h.fig,'Name')],...
                        'Layer Tool Warning','modal'))
                    delete(h.fig)
                end
            end
        end
        
    case 'members'          %  Member button
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        indx     = get(h.list,'Value');          %  Get layer index
        userdata = get(h.list,'UserData');       %  and its structure data
        liststr  = get(h.list,'String');
        
        memberlist(liststr(indx,3:size(liststr,2)),userdata{indx,1})
        
        
    case 'property'          %  Property button
        h = getGUIHandles(hfig);             %  Get handles
        if isempty(h);  return;  end   %  Axes gone, abort
        objects = validhandles(h);               %  Set valid object handles
        if isempty(objects);  return;  end       %  No objects remain on plot
        
        str0 = '';   indx = 1;   %  Initialize variables
        
        while 1   %  Prompt for properties.  Remain until no errors or cancelled
            hmodal = PropertyEditBox(objects,str0,indx);    uiwait(hmodal.figure);
            if ~ishandle(hmodal.edit)
                break
            end
            
            %  Get the properties.  Make single row vector
            str0 = get(hmodal.edit,'String');
            str0 = str0(:)';
            str0 = str0(find(str0)); %#ok<*FNDSB>
            
            hndlarray = get(hmodal.popup,'UserData');   %  Get other needed info
            indx = get(hmodal.popup,'Value');
            %  Objects to apply properties to
            hndls = hndlarray{indx};         %#ok<NASGU>
            
            indx = get(hmodal.popup,'Value');
            btn   = get(hmodal.figure,'CurrentObject');
            
            delete(hmodal.figure)   %  Get rid of the modal window
            
            if btn == hmodal.apply   %  Apply the properties
                try
                    eval(['set(hndls,',str0,');']);
                    break;
                catch e
                    uiwait(errordlg(e.message,'Layer Tool Error','modal'));
                end
                
            else
                break
            end
        end
        
    case 'close'          %  Close Request function
        if ishghandle(hfig)
            h = get(hfig, 'UserData');
            prompt = strvcat(['Close:  ',get(hfig,'Name')],' ',...
                'Are You Sure?');
            ButtonName = questdlg(prompt,'Confirm Closing','Yes','No','No');
            if strcmp(ButtonName,'Yes')
                figure(get(h.axes,'Parent'))
                delete(hfig)
            end
        end
end


%*********************************************************************
%*********************************************************************
%*********************************************************************


function h = mlayersbox(hndl,workspace)
%  MLAYERSBOX  Displays the MLAYERS GUI.

%  Create the figure window

h.fig = figure('Name',workspace, 'NumberTitle','off',...
    'Toolbar','none', 'Menu','none','IntegerHandle','on', 'Resize','on',...
    'Units','Points',  'Position',72*[0.01 2 2.2 3],...
    'Visible','off');
hfig = h.fig;
set(hfig,'CloseRequestFcn', @(~,~) mlayers(hfig, 'close'));
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

% shift window if it comes up partly offscreen

shiftwin(h.fig)

%  Create the list box

h.list = uicontrol(h.fig,'Style','List', 'String','place holder',...
    'Units','Normalized', 'Position',[0.10  0.50  0.80  0.45], ...
    'Max',1, 'Value',1,...
    'FontWeight','normal',  'FontSize',10, ...
    'HorizontalAlignment','center', ...
    'ForegroundColor','black', 'BackgroundColor',figclr,...
    'CallBack',@(~,~)mlayers(hfig,'object'));

%  Plot/Hide/Show button

h.hide = uicontrol(h.fig,'Style','Push', 'String','Plot', ...
    'Units', 'Normalized', 'Position', [0.10  0.35  0.40  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment','center',...
    'ForegroundColor','black', 'BackgroundColor',figclr,...
    'CallBack',@(~,~)mlayers(hfig,'plot'));

%  Delete button

h.delete = uicontrol(h.fig,'Style','Push', 'String','Delete', ...
    'Units', 'Normalized', 'Position', [0.50  0.35  0.40  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment','center',...
    'ForegroundColor','black', 'BackgroundColor',figclr,...
    'Interruptible','on',...
    'CallBack',@(~,~)mlayers(hfig,'delete'));

%  Zdata button

h.zdata = uicontrol(h.fig,'Style','Push', 'String','Zdata', ...
    'Units', 'Normalized', 'Position', [0.10  0.25  0.40  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment','center',...
    'ForegroundColor','black', 'BackgroundColor',figclr,...
    'Interruptible','on',...
    'CallBack',@(~,~)mlayers(hfig,'zdata'));

%  Highlight button

h.highlight = uicontrol(h.fig,'Style','Push', 'String','Highlight', ...
    'Units', 'Normalized', 'Position',[0.10  0.15  0.40  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment','center',...
    'ForegroundColor','black', 'BackgroundColor',figclr,...
    'CallBack', @(~,~) mlayers(hfig,'highlightON'));

%  Property button

h.property = uicontrol(h.fig,'Style','Push', 'String','Property', ...
    'Units', 'Normalized', 'Position', [0.50  0.15  0.40  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment','center',...
    'ForegroundColor','black', 'BackgroundColor',figclr,...
    'CallBack', @(~,~)mlayers(hfig,'property'));

%  Members button

h.members = uicontrol(h.fig,'Style','Push', 'String','Members', ...
    'Units', 'Normalized', 'Position', [0.10  0.05  0.40  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment','center',...
    'ForegroundColor','black', 'BackgroundColor',figclr,...
    'Interruptible','on',...
    'CallBack', @(~,~)mlayers(hfig,'members'));

%  Purge button

h.purge = uicontrol(h.fig,'Style','Push', 'String','Purge', ...
    'Units', 'Normalized', 'Position',[0.50  0.05  0.40  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment','center',...
    'ForegroundColor','black', 'BackgroundColor',figclr,...
    'CallBack',@(~,~)mlayers(hfig,'purge'));

%  Save the axes handle and all handles for this GUI

h.axes = hndl;
set(h.fig,'UserData',h,'Visible','on')



%*********************************************************************
%*********************************************************************
%*********************************************************************


function objects = validhandles(h)

%  VALIDHANDLES  Gets valid object handles for the MLAYERS function.
%
%  This handle list stored in the userdata slot may not contain all valid
%  handles since users can delete individual objects while working with a
%  map without exclusively using the mlayers gui tool


indx     = get(h.list,'Value');              %  Get layer index
userdata = get(h.list,'UserData');           %  and its structure data
liststring = get(h.list,'String');           %  and the string list

objects = userdata{indx,3};                  %  Get only objects
objects( find(~ishghandle(objects)) ) = [];    %  which still exist

if isempty(objects)   %  Build the error/warning string if no objects remain
    listentry = deblank(liststring(indx,:));     %  Selected list item
    uiwait(errordlg(['No members of ',listentry(2:length(listentry)),' are mapped'],...
        'Layer Tool Error','modal'))
    
    userdata{indx,2} = 0 ;             %  Update the plot state flag and save
    liststring(indx,1) = ' ';
    set(h.list,'UserData',userdata,'String',liststring,'Value',indx)
    mlayers(hfig,'object')
end


%*********************************************************************
%*********************************************************************
%*********************************************************************


function memberlist(listentry,datastruct)
%  MEMBERLIST displays a list with all members of a layer object

%  Determine the unique tags in the data structure

members = unique(strvcat(datastruct(:).tag),'rows');

%  Create the list box in case the select button is pushed

figsize = [3 2 3 3];
h = dialog('Name',['Object Sets in ',deblank(listentry)],...
    'Units','Points',  'Position',72*figsize,...
    'Visible','off');

% shift window if it comes up partly offscreen

shiftwin(h)

%  Ensure V5 color defaults

colordef(h,'white');
figclr = get(h,'Color');

%  Create the list box

uicontrol(h,'Style','List', 'String',members ,...
    'Units','Normalized', 'Position',[0.10  0.30  0.80  0.60], ...
    'Max',1, ...
    'FontWeight','normal',  'FontSize',10, ...
    'HorizontalAlignment','center', ...
    'ForegroundColor','black', 'BackgroundColor',figclr);

%  Buttons to exit the modal dialog

buttonsize = [0.875  0.5];      %  Button size in inches
xoffset = (figsize(3) - buttonsize(1) )/2;
btnpos = [xoffset 0.15 buttonsize];   %  Button Position in inches

uicontrol(h,'Style','Push', 'String', 'Close', ...    %  Close Button
    'Units','Points',  'Position',72*btnpos, ...
    'FontWeight','bold',  'FontSize',12, ...
    'HorizontalAlignment','center', ...
    'ForegroundColor','black', 'BackgroundColor',figclr,...
    'CallBack','uiresume');

%  Turn dialog box on.  Then wait unit a button is pushed

set(h,'Visible','on');     uiwait(h)

if ~ishghandle(h);   return;   end

%  Close the dialog box

delete(h)


%*********************************************************************
%*********************************************************************
%*********************************************************************


function highlightstate(h)

%  HIGHLIGHTSTATE sets the highlight button to correspond with the objects
%  current highlight state


objects = validhandles(h);   %  Set valid object handles
if isempty(objects);  return;  end

highlight = get(objects(1),'SelectionHighlight');
selected = get(objects(1),'Selected');

if strcmp(highlight,'on') && strcmp(selected,'on')
    set(h.highlight,'String','Normal', ...
        'CallBack',@(~,~) mlayers(h.fig,'highlightOFF'))
else
    set(h.highlight,'String','Highlight', ...
        'CallBack',@(~,~)mlayers(h.fig,'highlightON'))
end


%*********************************************************************
%*********************************************************************
%*********************************************************************


function h = getGUIHandles(hfig)

%  getGUIHandles(hfig)  Gets the handles associated with the mlayers GUI
%  and also test to ensure that the associated axes still exists.


h = get(hfig,'UserData');  %  Get GUI handles
if ~ishghandle(h.axes)     %  Abort tool if axes is gone
    uiwait(errordlg({'Associated Map Axes has been deleted',' ',...
        'Layer Tool No Longer Appropriate'},...
        'Layer Tool Error','modal'));
    delete(h.fig);
    h = [];
end


%*********************************************************************
%*********************************************************************
%*********************************************************************


function h = PropertyEditBox(hndls,str0,indx)

%  PROPERTYEDITBOX will construct the modal dialog allowing the
%  specification of properties for all objects referenced by hndls.


%  Initialize variables

deleterow = [];
objstr = strvcat('All','Line','Patch','Surface','Text','Light');

%  Get the types of objects referenced by hndls

hndlarray{1} = hndls;
if length(hndls) == 1
    objtypes = get(hndls,'Type');
else
    objtypes = char(get(hndls,'Type'));
end

%  Determine the object types contained in hndls.  Keep only these objects
%  in the popup menu string.  Save the corresponding subset of handles

for i = 2:size(objstr,1)
    indxmatch = strmatch(lower(deblank(objstr(i,:))),objtypes); %#ok<*MATCH2>
    if ~isempty(indxmatch)
        hndlarray{length(hndlarray)+1} = hndls(indxmatch); %#ok<*AGROW>
    else
        deleterow = [deleterow; i];
    end
end

%  Clear the unnecessary rows of the popup menu string.  If only two rows
%  remain ("All" will always remain), then the objects in hndls are all
%  alike.  In this case, get rid of the all option and make the popup menu
%  into a text object (done later).

if ~isempty(deleterow);     objstr(deleterow,:) = [];    end
if length(hndlarray) == 2;  hndlarray(1) = [];      objstr(1,:) = [];  end

%  Create the dialog window

h.figure = dialog('Name','Define Layer Properties', ...
    'Units','Points',  'Position',72*[1 1 3.5 2.5], ...
    'Visible','on');
colordef(h.figure,'white');
figclr = get(h.figure,'Color');

% shift window if it comes up partly offscreen

shiftwin(h.figure)


%  Object type and popup (or text) box

h.popuplabel = uicontrol(h.figure, 'Style','text', 'String','Object Type:',...
    'Units','normalized', 'Position',[.05 .84 .40 .10], ...
    'BackgroundColor',figclr, 'ForegroundColor','black', ...
    'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.popup = uicontrol(h.figure, 'Style','popup', 'String',objstr,...
    'Units','normalized', 'Position',[.48 .85 .47 .10], ...
    'BackgroundColor',figclr, 'ForegroundColor','black', ...
    'HorizontalAlignment','left', 'Value',indx,...
    'FontSize',10,  'FontWeight','bold', ...
    'UserData', hndlarray);
if length(hndlarray) == 1
    set(h.popup,'Style','text','Position',[.48 .84 .47 .10])
end

%  Object Property label and edit box

h.editlabel = uicontrol(h.figure, 'Style','text', ...
    'String','Object Properties (eg: ''Color'',''blue''):',...
    'Units','normalized', 'Position',[.05 .70 .90 .10], ...
    'BackgroundColor',figclr, 'ForegroundColor','black', ...
    'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.edit = uicontrol(h.figure, 'Style','edit', 'String',str0,...
    'Units','normalized', 'Position',[.05 .33 .90 .32], ...
    'BackgroundColor',figclr, 'ForegroundColor','black', 'Max',2,...
    'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Apply, help and cancel buttons

h.apply = uicontrol(h.figure, 'Style','push', 'String', 'Apply', ...
    'Units','normalized', 'Position',[0.15 0.05 0.25 0.20], ...
    'BackgroundColor',figclr, 'ForegroundColor','black', ...
    'FontSize',10,  'FontWeight','bold',...
    'Callback', 'uiresume');

h.cancel = uicontrol(h.figure, 'Style','push', 'String', 'Cancel', ...
    'Units','normalized', 'Position',[0.60 0.05 0.25 0.20], ...
    'BackgroundColor',figclr, 'ForegroundColor','black', ...
    'FontSize',10,  'FontWeight','bold', ...
    'Callback', 'uiresume');

%  Turn dialog on and save object handles

set(h.figure,'Visible','on','UserData',h)
