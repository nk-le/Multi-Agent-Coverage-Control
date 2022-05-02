function h = maptool(varargin)
%MAPTOOL Add menu activated tools to map figure
%
%  MAPTOOL creates a figure window with a map axes and activates
%  the interactive tool for specifying a map projection.
%
%  MAPTOOL ProjectionName creates a figure window with the default
%  projection specified by ProjectionName.
%
%  MAPTOOL('MapPropertyName',MapPropertyValue,...) creates a figure
%  window and defines a map axes using the supplied Map properties.
%  MAPTOOL supports all the same properties as AXESM.
%
%  h = MAPTOOL(...) returns a two element vector containing the
%  handle of the Maptool figure window and the handle of the map axes.
%
%  See also AXESM

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if ~savedCallbacks(varargin)
    hndl = INITmaptool(varargin{:});   %  Initialize the map figure window
    if ischar(hndl)
        error('map:maptool:mapdispError', hndl);
    else
        if nargout == 1
            h = hndl;
        end
    end
end

%--------------------------------------------------------

function saved = savedCallbacks(args)
% Process maptool callbacks in figures saved in R2013b and earlier.

saved = numel(args) > 1 && isempty(args{1});
if saved
    action = args{2};
    switch(action)
                
        case 'close'
            close_cb(gcbo)
            
        case 'zoom'
            zoom_cb(gcbo)
            
        case 'rotate'
            rotate_cb(gcbo)
            
        case 'origin'
            origin_cb(gcbo)
            
        case 'meshgrat'
            meshgrat_cb(gcbo)
            
        case 'legendON'
            legendON_cb(gcbo)
            
        case 'toolhide'
            toolhide_cb(gcbo)
            
        case 'tooloff'
            tooloff
            
        case 'parallel'
            parallelui
            
        case {'loadvar','loadlayer','variables','createvar','clearvar'}
            h = msgbox(getString(message('map:removed:menuItem')));
            h.Tag = 'MenuItemRemovedMsg';
            
        otherwise
            saved = false;
    end
end

%--------------------------------------------------------

function hndl = INITmaptool(varargin)

%  INITMAPTOOL initializes the maptool window, mouse tools uicontrols,
%  the tool menu choices and the colormap menu.  A map axes
%  is also created, with a Robinson projection specified as
%  a default.

%  Create a new figure window.
%  Ensure V5 color defaults

hndl(1) = gcf;

% Turn off the plot edit Tools menu
plotedit(hndl(1),'hidetoolsmenu');

if strcmp(get(hndl(1),'Tag'),'Map Tool Window')
    error('map:maptool:mapdispError','Maptools already applied to figure')
end
set(hndl(1),'Tag','Map Tool Window',...
    'ButtonDownFcn',@uimaptbx,'CloseRequestFcn',@close_cb);

%  Create the project menu and its submenu items
h = uimenu(hndl(1),'Label','Map');
uimenu(h,'Label','Lines','Interruptible','on','CallBack',@linemui)
uimenu(h,'Label','Patches','Interruptible','on','CallBack',@patchesmui)
uimenu(h,'Label','Regular Surfaces','Interruptible','on','CallBack',@meshmui,'Separator','on')
uimenu(h,'Label','General Surfaces','Interruptible','on','CallBack',@surfacemui)
uimenu(h,'Label','Regular Shaded Relief','Interruptible','on','CallBack',@meshlsrmui,'Separator','on')
uimenu(h,'Label','General  Shaded Relief','Interruptible','on','CallBack',@surflsrmui)
uimenu(h,'Label','Contour Lines','Interruptible','on', 'CallBack',@contour3mui,'Separator','on')
uimenu(h,'Label','Filled Contours','Interruptible','on', 'CallBack',@contourfmui)
uimenu(h,'Label','Quiver 2D','Interruptible','on','CallBack',@quivermui);
uimenu(h,'Label','Quiver 3D','Interruptible','on','CallBack',@quiver3mui);
uimenu(h,'Label','Stem','Interruptible','on','CallBack',@stem3mui)
uimenu(h,'Label','Scatter','Interruptible','on','CallBack',@scattermui)
uimenu(h,'Label','Text','Interruptible','on','Separator','on','CallBack',@textmui)

%  Create the display menu and its submenu items
h = uimenu(hndl(1),'Label','Display');
uimenu(h,'Label','Projection','Interruptible','on', 'CallBack','axesmui');
uimenu(h,'Label','Graticule','Interruptible','on','Separator','on',...
    'CallBack',@meshgrat_cb)
uimenu(h,'Label','Legend','Interruptible','on','CallBack',@legendON_cb)
uimenu(h,'Label','Frame','Interruptible','on','Separator','on','CallBack','framem');
uimenu(h,'Label','Grid','Interruptible','on','CallBack','gridm');
uimenu(h,'Label','Meridian Labels','Interruptible','on','CallBack','mlabel');
uimenu(h,'Label','Parallel Labels','Interruptible','on','CallBack','plabel');
uimenu(h,'Label','Tracks','Interruptible','on',...
    'Separator','on','CallBack','trackui(gca)');
uimenu(h,'Label','Small Circles','Interruptible','on',...
    'CallBack','scirclui(gca)');
uimenu(h,'Label','Surface Distances','Interruptible','on',...
    'CallBack','surfdist(gca)');

hsub = uimenu(h,'Label','Map Distortion','Separator','on');
uimenu(hsub,'Label','Angles', 'CallBack','mdistort angles')
uimenu(hsub,'Label','Area', 'CallBack','mdistort area')
uimenu(hsub,'Label','Scale', 'CallBack','mdistort scale')
uimenu(hsub,'Label','Off', 'CallBack','mdistort off')

uimenu(h,'Label','Scale Ruler', 'CallBack','scaleruler'); % toggle

uimenu(h,'Label','Print Preview','Separator','on','CallBack','previewmap');

%  Create the tool menu and its submenu items
h = uimenu(hndl(1),'Label','Tools');
uimenu(h,'Label','Hide','CallBack',@toolhide_cb);
uimenu(h,'Label','Origin','Interruptible','on','CallBack',@origin_cb);
uimenu(h,'Label','Parallels','Interruptible','on',...
    'CallBack',@(~,~) parallelui);
uimenu(h,'Label','Set Limits','CallBack',@setlimits_cb);
uimenu(h,'Label','Full View','CallBack',@fullview_cb);

uimenu(h,'Label','2D View','Interruptible','on',...
    'Separator','on','CallBack','view(2)');

uimenu(h,'Label','Tight Map', 'CallBack','tightmap','Separator','on');
uimenu(h,'Label','Loose Map', 'CallBack','axis auto');
uimenu(h,'Label','Fill Figure', 'Separator','on','CallBack',@fillfigure_cb)
uimenu(h,'Label','Default Size','Callback',@defaultsize_cb)
uimenu(h,'Label','Objects','Interruptible','on',...
    'Separator','on','CallBack','mobjects(gca)');
hsub = uimenu(h,'Label','Edit','Separator','on');
uimenu(hsub,'Label','Current Object','Interruptible','on',...
    'CallBack',@currentobject_cb);
uimenu(hsub,'Label','Select Object','Interruptible','on',...
    'CallBack',@selectobject_cb)
hsub = uimenu(h,'Label','Show');
uimenu(hsub,'Label','All','Interruptible','on','CallBack','showm(''hidden'')');
uimenu(hsub,'Label','Object','Interruptible','on','CallBack','showm(''taglist'')');
hsub = uimenu(h,'Label','Hide');
uimenu(hsub,'Label','All','Interruptible','on','CallBack','hidem(''all'')');
uimenu(hsub,'Label','Map','Interruptible','on','CallBack','hidem(''map'')');
uimenu(hsub,'Label','Object','Interruptible','on','CallBack','hidem(''taglist'')');
hsub = uimenu(h,'Label','Delete');
uimenu(hsub,'Label','All','Interruptible','on','CallBack','clma(''all'')');
uimenu(hsub,'Label','Map','Interruptible','on','CallBack','clma');
uimenu(hsub,'Label','Object','Interruptible','on','CallBack','clmo(''taglist'')');

hsub = uimenu(h,'Label','Axes','Separator','on');
uimenu(hsub,'Label','Show', 'CallBack','showaxes(''on'')')
uimenu(hsub,'Label','Hide', 'CallBack','showaxes(''off'')')
uimenu(hsub,'Label','Visible', 'CallBack','showm(gca)')
uimenu(hsub,'Label','Invisible', 'CallBack','hidem(gca)')
uimenu(hsub,'Label','Color','Interruptible','on', ...
    'CallBack',@(~,~) showaxes(uisetcolor(get(gca,'XColor'),'Axes Color')))

%  Add the colormap menu bar
clrmenu

%  Initialize the map axes
hndl(2) = gca;

if isempty(varargin)
    if ~ismap(gca)
        cancelflag = axesm;
        if cancelflag
            clma purge ;
        end % was delete(hndl(1))
    end
else
    if ismap(gca)
        if mod(length(varargin),2)==0
            setm(gca,varargin{:});
        else
            setm(gca,'MapProjection',varargin{:});
        end
    else
        try
            axesm(varargin{:});
        catch e
            delete(hndl(1));
            hndl=e.message;
            return
        end
    end
end

%--------------------------------------------------------

function fillfigure_cb(~,~)

units = get(gca,'units');
set(gca,'Units','normalized','Position',[0 0 1 1])
set(gca,'Units',units)

%--------------------------------------------------------

function defaultsize_cb(~,~)

units = get(gca,'units');
set(gca,'Units','normalized','Position',get(0,'FactoryAxesPosition'))
set(gca,'Units',units)

%--------------------------------------------------------

function currentobject_cb(hSrc,~)

f = ancestor(hSrc,'figure');
h = get(f,'CurrentObject');
if ~isempty(h)
    propedit(h)
else
    uiwait(errordlg('No current object','Edit Error','modal'))
end

%--------------------------------------------------------

function selectobject_cb(~,~)

h = handlem('taglist');
if ~isempty(h)
    propedit(h(1))
end

%--------------------------------------------------------

function close_cb(h,~)

answer = questdlg('Are You Sure?','Confirm Closing','Yes','No','Yes');
if strcmp(answer,'Yes')
    delete(ancestor(h,'figure'))
end

%--------------------------------------------------------

function meshgrat_cb(hSrc,~)
%  Reset the graticule of a regular grid

fig = ancestor(hSrc,'figure');
h = get(fig,'CurrentObject');

if ~ismapped(h)
    uiwait(errordlg('Current object is not mapped','Selection Error','modal'))
else
    userdata = get(h,'UserData');
    mfields = fieldnames(userdata);
    indx = find(strcmp('maplegend',mfields));
    if length(indx) ~= 1
        uiwait(errordlg('Current object is not a regular surface map',...
            'Selection Error','modal'))
    else
        prompt   = 'Edit Graticule size (2 element vector):';
        titlestr = 'Graticule Mesh';
        answer = {['[',num2str(size(get(h,'Xdata'))),']']};
        
        while 1
            answer=inputdlg(prompt,titlestr,1,answer(1));
            
            if ~isempty(answer)
                try
                    % Use str2num because we expect a 2-vector.
                    setm(h, 'MeshGrat', str2num(answer{1})); %#ok<ST2NM>
                    break;
                catch e
                    uiwait(errordlg(e.message,'Graticule Mesh Error','modal'))
                end
            else
                break
            end
        end
    end
end

%--------------------------------------------------------

function zoom_cb(h,~)

f = ancestor(h,'figure');

if ~ishghandle(h,'uicontrol')
    h = findobj(f,'Type','uicontrol','String','Zoom');
    set(h,'Value',~get(h,'Value'))
end

if strcmp(get(h,'FontWeight'),'normal')
    set(h,'FontWeight','bold','Tag','on');
    tooloff(h);
    zoom('on')
    set(h,'KeyPressFcn',get(f,'KeyPressFcn'));
else
    set(h,'FontWeight','normal','Tag','off');
    zoom('off')
    set(h,'KeyPressFcn','');
end

%--------------------------------------------------------

function rotate_cb(h,~)

f = ancestor(h,'figure');

if ~ishghandle(h,'uicontrol')
    h = findobj(f,'Type','uicontrol','String','Rotate');
    set(h,'Value',~get(h,'Value'))
end

if strcmp(get(h,'FontWeight'),'normal')
    set(h,'FontWeight','bold','Tag','on');
    tooloff(h);
    rotate3d(f,'on')
else
    set(h,'FontWeight','normal','Tag','off');
    rotate3d(f,'off')
end

%--------------------------------------------------------

function origin_cb(h,~)

f = ancestor(h,'figure');

if ~ishghandle(h,'uicontrol')
    h = findobj(f,'Type','uicontrol','String','Origin');
    set(h,'Value',~get(h,'Value'))
end

if strcmp(get(h,'FontWeight'),'normal')
    set(h,'FontWeight','bold','Tag','on');
    tooloff(h);
    originui('on')
    set(h,'KeyPressFcn',get(gcf,'KeyPressFcn'));
else
    set(h,'FontWeight','normal','Tag','off');
    originui('off')
    set(h,'KeyPressFcn','');
end

%--------------------------------------------------------

function toolhide_cb(h,~)
%  Hide the mouse tool uicontrols (menu choice)

f = ancestor(h,'figure');
set(h,'Label','Show','CallBack',@toolshow_cb);
set(findobj(f,'Type','uicontrol'),'Visible','off')

%--------------------------------------------------------

function toolshow_cb(h,~)
%  Show the mouse tool uicontrols (menu choice)

f = ancestor(h,'figure');
set(h,'Label','Hide','CallBack',@toolhide_cb);
set(findobj(f,'Type','uicontrol'),'Visible','on')

%--------------------------------------------------------

function legendON_cb(h,~)

f = ancestor(h,'figure');
ax = findobj(f,'Type','axes');
if isempty(ax)
    return
end

children = get(ax,'children');
legndhndl = findobj(gcf,'Type','axes','Tag','legend');

%  Allow abort if legend already exists
if ~isempty(legndhndl)
    btn = questdlg('Legend will be deleted.  Continue?','Confirm Legend','Yes','No','No');
    if strcmp(btn,'No')
        set(h,'Label','Legend Off','CallBack',@legendOFF_cb)
        return
    end
end

%  Keep only the line children.
hndl = children;
hndl(~ishghandle(hndl,'line')) = [];

%  Get their name (tag or handle) to use for the legend string.
linename = namem(hndl);

%  If no lines remain, simply warn and end
if isempty(hndl)
    uiwait(errordlg('No Lines on Map Axes','MapTool Warning','modal'));
    return
end

%  Add the legend object off the axes
legend(hndl,linename,'Location','NorthEastOutside');

%  Set the menu to delete the displayed legend
set(h,'Label','Legend Off','CallBack',@legendOFF_cb)

%--------------------------------------------------------

function legendOFF_cb(h,~)

legend off
set(h,'Label','Legend','CallBack',@legendON_cb)

%--------------------------------------------------------

function tooloff(except)
%  TOOLOFF turns off the mouse tools and sets the corresponding
%  radio button value to zero.  The exception to turning off the
%  tools may be provided by the input argument.  This allows
%  one tool to be left on.  This operation provides the mutual
%  exclusiveness necessary for the radio button operation.  Note
%  that the RadioGroup property can not be used with the radio
%  buttons because the tool function must also be turned off
%  when the button value is set to zero.

if nargin == 0
    except = [];
end   %  Default is all off

%  Determine the handles of the radio buttons.  Eliminate an
%  exception button from this list.
hindx = findobj(gcf,'Type','uicontrol','Tag','on');
if ~isempty(except)
    hindx(hindx == except) = [];
end

%  Determine any other radio buttons which may be on

if ~isempty(hindx)         %  Turn these buttons (and operations) off
    set(hindx,'Tag','off','FontWeight','normal');
    switch get(hindx,'String')     %  Turn off the appropriate tool
        case 'Zoom',      zoom('off')
        case 'Rotate',    rotate3d('off')
        case 'Origin',    originui('off')
        case 'Parallel',  disp('No parallel option in TOOLOFF')
        otherwise
            uiwait(errordlg('Unrecognized radio button string in TOOLOFF',...
                'MapTool Error','modal'))
    end
end

%---------------------------------------------------------

function setlimits_cb(src,~)
f = ancestor(src,'figure');
zoom(f,'reset')

%---------------------------------------------------------

function fullview_cb(src,~)
f = ancestor(src,'figure');
ax = findobj(f,'Type','axes');
if ~isempty(ax)
    axis(ax,'auto')
    zoom(f,'reset')
end

%---------------------------------------------------------
function quivermui(~,~)
%  QUIVERMUI creates the dialog box to allow the user to enter in
%  the variable names for a quivem command.  It is called when
%  QUIVERM is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.
%  Create axes if none found

if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return
    end
end

%  Initialize the entries of the dialog box
str1 = 'lat';
str2 = 'long';
str3 = 'u';
str4 = 'v';
str5 = '';
str6 = '';
fill0 = 0;

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box

    h = QuivermUIBox(str1,str2,str3,str4,str5,str6,fill0);
    uiwait(h.fig)

    if ~ishghandle(h.fig)
        return
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.
    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.latedit,'String');    %  Get the dialog entries
        str2 = get(h.lonedit,'String');
        str3 = get(h.uedit,'String');
        str4 = get(h.vedit,'String');
        str5 = get(h.scledit,'String');
        str6 = get(h.lineedit,'String');
        fill0 = get(h.arrow,'Value');
        delete(h.fig)

        %  Construct the appropriate plotting string and assemble the callback string
        switch fill0
            case 0
                if isempty(str5) && isempty(str6)
                    plotstr = ['quiverm(',str1,',',str2,',',str3,',',str4,')'];
                elseif isempty(str5) && ~isempty(str6)
                    plotstr = ['quiverm(',str1,',',str2,',',str3,',',str4,',',str6,')'];
                elseif ~isempty(str5) && isempty(str6)
                    plotstr = ['quiverm(',str1,',',str2,',',str3,',',str4,',',str5,')'];
                elseif ~isempty(str5) && ~isempty(str6)
                    plotstr = ['quiverm(',str1,',',str2,',',str3,',',str4,',',str6,',',str5,')'];
                end
            case 1
                fillstr = ' ''filled'' ';
                if isempty(str5) && isempty(str6)
                    plotstr = ['quiverm(',str1,',',str2,',',str3,',',str4,',[],',fillstr,')'];
                elseif isempty(str5) && ~isempty(str6)
                    plotstr = ['quiverm(',str1,',',str2,',',str3,',',str4,',',str6,',[],',fillstr,')'];
                elseif ~isempty(str5) && isempty(str6)
                    plotstr = ['quiverm(',str1,',',str2,',',str3,',',str4,',',str5,',',fillstr,')'];
                elseif ~isempty(str5) && ~isempty(str6)
                    plotstr = ['quiverm(',str1,',',str2,',',str3,',',str4,',',str6,',',str5,',',fillstr,')'];
                end
        end

        try
            evalin('base', plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%--------------------------------------------------------
function h = QuivermUIBox(lat0,lon0,u0,v0,scale0,line0,fill0)
%  QUIVERMUIBOX creates the dialog box and places the appropriate
%  objects for the QUIVERMUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Quiver Map Input',...
    'Units','Points',  'Position',72*[2 1 3 4],...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

% shift window if it comes up partly offscreen
shiftwin(h.fig)

%  Latitude Text and Edit Box
h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.922  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .85  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .85  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box
h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.782  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .71  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .71  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  U Text and Edit Box
h.ulabel = uicontrol(h.fig,'Style','Text','String','U Component variable:', ...
    'Units','Normalized','Position', [0.05  0.642  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.uedit = uicontrol(h.fig,'Style','Edit','String', u0, ...
    'Units','Normalized','Position', [0.05  .57  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.ulist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .57  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.uedit,...
    'CallBack',@varpick_cb);

%  V Text and Edit Box
h.vlabel = uicontrol(h.fig,'Style','Text','String','V Component variable:', ...
    'Units','Normalized','Position', [0.05  0.502  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.vedit = uicontrol(h.fig,'Style','Edit','String', v0, ...
    'Units','Normalized','Position', [0.05  .43  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.vlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .43  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.vedit,...
    'CallBack',@varpick_cb);

%  Scale Text and Edit Box
h.scllabel = uicontrol(h.fig,'Style','Text','String','Scale (optional):', ...
    'Units','Normalized','Position', [0.05  0.34  0.60  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.scledit = uicontrol(h.fig,'Style','Edit','String', scale0, ...
    'Units','Normalized','Position', [0.70  .34  0.25  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',1,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Linespec Text and Edit Box
h.linelabel = uicontrol(h.fig,'Style','Text','String','LineSpec (optional):', ...
    'Units','Normalized','Position', [0.05  0.24  0.60  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lineedit = uicontrol(h.fig,'Style','Edit','String', line0, ...
    'Units','Normalized','Position', [0.70  .24  0.25  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',1,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Filled Arrow Heads Check Box
h.arrow = uicontrol(h.fig,'Style','Check','String','Filled Base Marker', ...
    'Units','Normalized','Position', [0.05  0.14  0.60  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Value',fill0,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.01  0.26  0.09], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.01  0.26  0.09], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.ulist,     'TooltipString', tooltipHelpStrings('ListButton'))
set(h.vlist,     'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.ulabel,    'TooltipString', tooltipHelpStrings('UComponent'))
set(h.vlabel,    'TooltipString', tooltipHelpStrings('VComponent'))
set(h.linelabel, 'TooltipString', tooltipHelpStrings('LineSpec'))
set(h.scllabel,  'TooltipString', tooltipHelpStrings('QuiverScale'))
set(h.arrow,     'TooltipString', tooltipHelpStrings('FilledBase'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%-----------------------------------------------------------------------
function linemui(~,~)
%  LINEMUI creates the dialog box to allow the user to enter in
%  the variable names for a linem command.  It is called when
%  LINEM is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Christopher Byrns (age 2) contributed by (get this):
%       One day, MATLAB was open and at the command line when Christopher
%       Byrns decided to bang on the keyboard.  His actions brought
%       up the help window, and ended up on the function ASSIGNIN.M
%       (which was undocumented at the time).  The See Also function
%       for ASSIGNIN.M is EVALIN.M which is key to making these (and
%       similar) dialog boxes work.  Originally, this function
%       used a convoluted hack around with the ChangeFcn property
%       so that the command was executed in the base workspace.
%       EVALIN eliminates this hack.  I had no idea about the
%       existence of ASSIGNIN or EVALIN before the keyboard was smacked.

%  Create axes if none found
if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return;
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'lat';
str2 = 'long';
str3 = '';
str4 = '';

while 1      %  Loop until no error break or cancel break
    %  Display the variable prompt dialog box
    h = LinemUIBox(str1,str2,str3,str4);
    uiwait(h.fig)

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.
    if ~ishghandle(h.fig)
        return;
    end

    if get(h.fig,'CurrentObject') ~= h.cancel
        str1 = get(h.latedit,'String');    %  Get the dialog entries
        str2 = get(h.lonedit,'String');
        str3 = get(h.altedit,'String');
        str4 = get(h.propedit,'String');
        delete(h.fig)

        %  Make the other property string into a single row vector.
        %  Eliminate any padding 0s since they mess up a string
        str4 = str4(:)';
        str4 = str4(str4~=0);

        %  Construct the appropriate plotting string and assemble the callback string
        if isempty(str3) && isempty(str4)
            plotstr = ['linem(',str1,',',str2,')'];
        elseif isempty(str3) && ~isempty(str4)
            plotstr = ['linem(',str1,',',str2,',',str4,')'];
        elseif ~isempty(str3) && isempty(str4)
            plotstr = ['linem(',str1,',',str2,',',str3,');'];
        elseif ~isempty(str3) && ~isempty(str4)
            plotstr = ['linem(',str1,',',str2,',',str3,',',str4,');'];
        end

        try
            evalin('base', plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%-----------------------------------------------------------------------
function h = LinemUIBox(lat0,lon0,alt0,prop0)
%  LINEMUIBOX creates the dialog box and places the appropriate
%  objects for the LINEMUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Line Map Input',...
    'Units','Points',  'Position',72*[2 1 3 3.3],...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

% shift window if it comes up partly offscreen
shiftwin(h.fig)

%  Latitude Text and Edit Box
h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.91  0.90  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .82  0.70  0.09], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .82  0.18  0.09], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box
h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.722  0.90  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .63  0.70  0.09], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .63  0.18  0.09], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  Altitude Text and Edit Box
h.altlabel = uicontrol(h.fig,'Style','Text','String','Altitude variable (optional):', ...
    'Units','Normalized','Position', [0.05  0.532  0.90  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altedit = uicontrol(h.fig,'Style','Edit','String', alt0, ...
    'Units','Normalized','Position', [0.05  .44  0.70  0.09], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .44  0.18  0.09], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.altedit,...
    'CallBack',@varpick_cb);

%  Other Properties Text and Edit Box
h.proplabel = uicontrol(h.fig,'Style','Text','String','Other Properties:', ...
    'Units','Normalized','Position', [0.05  0.343  0.90  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.propedit = uicontrol(h.fig,'Style','Edit','String', prop0, ...
    'Units','Normalized','Position', [0.05  .19  0.90  0.15], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.altlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.altlabel,  'TooltipString', tooltipHelpStrings('Altitude'))
set(h.proplabel, 'TooltipString', tooltipHelpStrings('OtherProperties1'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%--------------------------------------------------------------------------
function patchesmui(~,~)
%  PATCHESMUI creates the dialog box to allow the user to enter in
%  the variable names for a patchesm command.  It is called when
%  PATCHESM is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Create axes if none found
if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return;
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'lat';
str2 = 'long';
str3 = '''red''';
str4 = '';
str5 = '';

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box

    h = PatchesmUIBox(str1,str2,str3,str4,str5);  uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.

    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.latedit,'String');    %  Get the dialog entries
        str2 = get(h.lonedit,'String');
        str3 = get(h.cdedit,'String');
        str4 = get(h.altedit,'String');
        str5 = get(h.propedit,'String');
        delete(h.fig)

        %  Make the other property string into a single row vector.
        %  Eliminate any padding 0s since they mess up a string

        str5 = str5(:)';
        str5 = str5(str5 ~= 0);

        %  Construct the appropriate plotting string and assemble the callback string

        if isempty(str4) && isempty(str5)
            plotstr = ['patchesm(',str1,',',str2,',',str3,')'];
        elseif isempty(str4) && ~isempty(str5)
            plotstr = ['patchesm(',str1,',',str2,',',str3,',',str5,')'];
        elseif ~isempty(str4) && isempty(str5)
            plotstr = ['patchesm(',str1,',',str2,',',str4,',',str3,')'];
        elseif ~isempty(str4) && ~isempty(str5)
            plotstr = ['patchesm(',str1,',',str2,',',str4,',',str3,',',str5,');'];
        end

        try
            evalin('base', plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%---------------------------------------------------------
function h = PatchesmUIBox(lat0,lon0,cdata0,alt0,prop0)

%  PATCHESMUIBOX creates the dialog box and places the appropriate
%  objects for the PATCHESMUI function.

%  Create the dialog box.  Make visible when all objects are drawn

h.fig = dialog('Name','Patches Map Input',...
    'Units','Points',  'Position',72*[2 1 3 3.7], ...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

% shift window if it comes up partly offscreen

shiftwin(h.fig)


%  Latitude Text and Edit Box

h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.925  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .85  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .85  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box

h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.775  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .70  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .70  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  Altitude Text and Edit Box

h.altlabel = uicontrol(h.fig,'Style','Text','String','Scalar Altitude (optional):', ...
    'Units','Normalized','Position', [0.05  0.625  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altedit = uicontrol(h.fig,'Style','Edit','String', alt0, ...
    'Units','Normalized','Position', [0.05  .55  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .55  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.altedit,...
    'CallBack',@varpick_cb);

%  Cdata Text and Edit Box

h.cdlabel = uicontrol(h.fig,'Style','Text','String','Face Color:', ...
    'Units','Normalized','Position', [0.05  0.475  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.cdedit = uicontrol(h.fig,'Style','Edit','String', cdata0, ...
    'Units','Normalized','Position', [0.05  .40  0.90  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Other Properties Text and Edit Box

h.proplabel = uicontrol(h.fig,'Style','Text','String','Other Properties:', ...
    'Units','Normalized','Position', [0.05  0.325  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.propedit = uicontrol(h.fig,'Style','Edit','String', prop0, ...
    'Units','Normalized','Position', [0.05  .16  0.90  0.16], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Buttons to exit the modal dialog

h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.altlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.altlabel,  'TooltipString', tooltipHelpStrings('PatchAltitude'))
set(h.cdlabel,   'TooltipString', tooltipHelpStrings('FaceColor'))
set(h.proplabel, 'TooltipString', tooltipHelpStrings('OtherProperties2'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%------------------------------------------------------------
function meshmui(~,~)

%  MESHMUI creates the dialog box to allow the user to enter in
%  the variable names for a meshm command.  It is called when
%  MESHM is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Create axes if none found
if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return;
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'map';
str2 = 'maplegend';
str3 = '[50 100]';
str4 = '';
str5 = '';

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = MeshmUIBox(str1,str2,str3,str4,str5);  uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.
    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.mapedit,'String');    %  Get the dialog entries
        str2 = get(h.legedit,'String');
        str3 = get(h.nptsedit,'String');
        str4 = get(h.altedit,'String');
        str5 = get(h.propedit,'String');
        delete(h.fig)

        %  Make the other property string into a single row vector.
        %  Eliminate any padding 0s since they mess up a string
        str5 = str5(:)';
        str5 = str5(str5 ~= 0);

        %  Construct the appropriate plotting string and assemble the callback string
        if isempty(str4) && isempty(str5)
            plotstr = ['meshm(',str1,',',str2,',',str3,')'];
        elseif isempty(str4) && ~isempty(str5)
            plotstr = ['meshm(',str1,',',str2,',',str3,',',str5,')'];
        elseif ~isempty(str4) && isempty(str5)
            plotstr = ['meshm(',str1,',',str2,',',str3,',',str4,')'];
        elseif ~isempty(str4) && ~isempty(str5)
            plotstr = ['meshm(',str1,',',str2,',',str3,',',str4,',',str5,');'];
        end

        try
            evalin('base', plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%------------------------------------------------------------
function h = MeshmUIBox(map0,maplegend0,npts0,alt0,prop0)

%  MESHMUIBOX creates the dialog box and places the appropriate
%  objects for the MESHMUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Mesh Map Input',...
    'Units','Points',  'Position',72*[2 1 3 3.7], ...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');


% shift window if it comes up partly offscreen
shiftwin(h.fig)

%  Map Text and Edit Box
h.maplabel = uicontrol(h.fig,'Style','Text','String','Map variable:', ...
    'Units','Normalized','Position', [0.05  0.925  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.mapedit = uicontrol(h.fig,'Style','Edit','String', map0, ...
    'Units','Normalized','Position', [0.05  .85  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.maplist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .85  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.mapedit,...
    'CallBack',@varpick_cb);

%  Maplegend Text and Edit Box
h.leglabel = uicontrol(h.fig,'Style','Text','String','Maplegend variable:', ...
    'Units','Normalized','Position', [0.05  0.775  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.legedit = uicontrol(h.fig,'Style','Edit','String', maplegend0, ...
    'Units','Normalized','Position', [0.05  .70  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.leglist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .70  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.legedit,...
    'CallBack',@varpick_cb);

%  Npts Text and Edit Box
h.nptslabel = uicontrol(h.fig,'Style','Text','String','Graticule size variable:', ...
    'Units','Normalized','Position', [0.05  0.625  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.nptsedit = uicontrol(h.fig,'Style','Edit','String', npts0, ...
    'Units','Normalized','Position', [0.05  .55  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.nptslist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .55  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.nptsedit,...
    'CallBack',@varpick_cb);

%  Altitude Text and Edit Box
h.altlabel = uicontrol(h.fig,'Style','Text','String','Altitude variable (optional):', ...
    'Units','Normalized','Position', [0.05  0.475  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altedit = uicontrol(h.fig,'Style','Edit','String', alt0, ...
    'Units','Normalized','Position', [0.05  .40  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .40  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.altedit,...
    'CallBack',@varpick_cb);

%  Other Properties Text and Edit Box
h.proplabel = uicontrol(h.fig,'Style','Text','String','Other Properties:', ...
    'Units','Normalized','Position', [0.05  0.325  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.propedit = uicontrol(h.fig,'Style','Edit','String', prop0, ...
    'Units','Normalized','Position', [0.05  .16  0.90  0.16], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.maplist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.leglist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.nptslist,  'TooltipString', tooltipHelpStrings('ListButton'))
set(h.altlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.maplabel,  'TooltipString', tooltipHelpStrings('Map'))
set(h.leglabel,  'TooltipString', tooltipHelpStrings('Maplegend'))
set(h.nptslabel, 'TooltipString', tooltipHelpStrings('Npts'))
set(h.altlabel,  'TooltipString', tooltipHelpStrings('Altitude'))
set(h.proplabel, 'TooltipString', tooltipHelpStrings('OtherProperties2'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%------------------------------------------------------------
function surfacemui(~,~)

%  SURFACEMUI creates the dialog box to allow the user to enter in
%  the variable names for a surfacem command.  It is called when
%  SURFACEM is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Create axes if none found
if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return;
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'lat';
str2 = 'long';
str3 = 'map';
str4 = '';
str5 = '';

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = SurfmUIBox(str1,str2,str3,str4,str5);  uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.
    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.latedit,'String');    %  Get the dialog entries
        str2 = get(h.lonedit,'String');
        str3 = get(h.mapedit,'String');
        str4 = get(h.altedit,'String');
        str5 = get(h.propedit,'String');
        delete(h.fig)

        %  Make the other property string into a single row vector.
        %  Eliminate any padding 0s since they mess up a string
        str5 = str5(:)';
        str5(str5 == 0) = [];

        %  Construct the appropriate plotting string and assemble the callback string
        if isempty(str4) && isempty(str5)
            plotstr = ['surfacem(',str1,',',str2,',',str3,')'];
        elseif isempty(str4) && ~isempty(str5)
            plotstr = ['surfacem(',str1,',',str2,',',str3,',',str5,')'];
        elseif ~isempty(str4) && isempty(str5)
            plotstr = ['surfacem(',str1,',',str2,',',str3,',',str4,')'];
        elseif ~isempty(str4) && ~isempty(str5)
            plotstr = ['surfacem(',str1,',',str2,',',str3,',',str4,',',str5,');'];
        end

        try
            evalin('base', plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%--------------------------------------------------------------------------
function h = SurfmUIBox(lat0,lon0,map0,alt0,prop0)

%  SURFMUIBOX creates the dialog box and places the appropriate
%  objects for the SURFMUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Surface Map Input',...
    'Units','Points',  'Position',72*[2 1 3 3.7], ...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

%  Latitude Text and Edit Box
h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.925  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .85  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .85  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box
h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.775  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .70  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .70  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  Map Text and Edit Box
h.maplabel = uicontrol(h.fig,'Style','Text','String','Map variable:', ...
    'Units','Normalized','Position', [0.05  0.625  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.mapedit = uicontrol(h.fig,'Style','Edit','String', map0, ...
    'Units','Normalized','Position', [0.05  .55  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.maplist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .55  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.mapedit,...
    'CallBack',@varpick_cb);

%  Altitude Text and Edit Box
h.altlabel = uicontrol(h.fig,'Style','Text','String','Altitude variable (optional):', ...
    'Units','Normalized','Position', [0.05  0.475  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altedit = uicontrol(h.fig,'Style','Edit','String', alt0, ...
    'Units','Normalized','Position', [0.05  .40  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .40  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.altedit,...
    'CallBack',@varpick_cb);

%  Other Properties Text and Edit Box
h.proplabel = uicontrol(h.fig,'Style','Text','String','Other Properties:', ...
    'Units','Normalized','Position', [0.05  0.325  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.propedit = uicontrol(h.fig,'Style','Edit','String', prop0, ...
    'Units','Normalized','Position', [0.05  .16  0.90  0.16], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.maplist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.altlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.maplabel,  'TooltipString', tooltipHelpStrings('Map'))
set(h.altlabel,  'TooltipString', tooltipHelpStrings('Altitude'))
set(h.proplabel, 'TooltipString', tooltipHelpStrings('OtherProperties2'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%------------------------------------------------------------------
function meshlsrmui(~,~)

%  MESHLSRMUI creates the dialog box to allow the user to enter in
%  the variable names for a MESHLSRM command.  It is called when
%  MESHLSRM is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'map';
str2 = 'maplegend';
str3 = '[90 45]';
str4 = '';
str5 = '';

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = MeshlsrmUIBox(str1,str2,str3,str4,str5);  uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.
    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.mapedit,'String');    %  Get the dialog entries
        str2 = get(h.legedit,'String');
        str3 = get(h.azeledit,'String');
        str4 = get(h.cmapedit,'String');
        str5 = get(h.climedit,'String');
        delete(h.fig)

        %  Construct the appropriate plotting string and assemble the callback string

        str3use = str3;
        str4use = str4;
        str5use = str5;

        if isempty(str3use)
            str3use = '[]';
        end

        if isempty(str4use)
            str4use = '[]';
        end

        if isempty(str5use)
            str5use = '[]';
        end

        plotstr = ['meshlsrm(',str1,',',str2,',',str3use,',',...
            str4use,',',str5use,');'];

        try
            evalin('base', plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%------------------------------------------------------------------
function h = MeshlsrmUIBox(map0,maplegend0,azel0,cmap0,clim0)

%  MESHLSRMUIBOX creates the dialog box and places the appropriate
%  objects for the MESHLSRMUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Shaded Relief Mesh Map Input',...
    'Units','Points',  'Position',72*[1.5 1 3.5 4], ...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');


%  Map Text and Edit Box
h.maplabel = uicontrol(h.fig,'Style','Text','String','Map variable:', ...
    'Units','Normalized','Position', [0.05  0.92  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.mapedit = uicontrol(h.fig,'Style','Edit','String', map0, ...
    'Units','Normalized','Position', [0.05  .84  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.maplist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .84  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.mapedit,...
    'CallBack',@varpick_cb);

%  Maplegend Text and Edit Box
h.leglabel = uicontrol(h.fig,'Style','Text','String','Maplegend variable:', ...
    'Units','Normalized','Position', [0.05  0.76  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.legedit = uicontrol(h.fig,'Style','Edit','String', maplegend0, ...
    'Units','Normalized','Position', [0.05  .68  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.leglist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .68  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.legedit,...
    'CallBack',@varpick_cb);

%  Azimuth/Elevation Text and Edit Box
h.azellabel = uicontrol(h.fig,'Style','Text','String','Light Source [az, el] (optional):', ...
    'Units','Normalized','Position', [0.05  0.60  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.azeledit = uicontrol(h.fig,'Style','Edit','String', azel0, ...
    'Units','Normalized','Position', [0.05  .52  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.azellist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .52  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.azeledit,...
    'CallBack',@varpick_cb);

%  Colormap Text and Edit Box
h.cmaplabel = uicontrol(h.fig,'Style','Text','String','Colormap (optional):', ...
    'Units','Normalized','Position', [0.05  0.44  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.cmapedit = uicontrol(h.fig,'Style','Edit','String', cmap0, ...
    'Units','Normalized','Position', [0.05  .36  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.cmaplist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .36  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.cmapedit,...
    'CallBack',@varpick_cb);

%  Color Axis Limits Text and Edit Box
h.climlabel = uicontrol(h.fig,'Style','Text','String','Color Axis Limits (optional):', ...
    'Units','Normalized','Position', [0.05  0.28  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.climedit = uicontrol(h.fig,'Style','Edit','String', clim0, ...
    'Units','Normalized','Position', [0.05  .20  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.climlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .20  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.climedit,...
    'CallBack',@varpick_cb);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.maplist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.leglist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.azellist,  'TooltipString', tooltipHelpStrings('ListButton'))
set(h.cmaplist,  'TooltipString', tooltipHelpStrings('ListButton'))
set(h.climlist,  'TooltipString', tooltipHelpStrings('ListButton'))
set(h.maplabel,  'TooltipString', tooltipHelpStrings('Map'))
set(h.leglabel,  'TooltipString', tooltipHelpStrings('Maplegend'))
set(h.azellabel, 'TooltipString', tooltipHelpStrings('AzEl'))
set(h.cmaplabel, 'TooltipString', tooltipHelpStrings('ColorMap'))
set(h.climlabel, 'TooltipString', tooltipHelpStrings('CLim'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%----------------------------------------------------------------
function surflsrmui(~,~)

%  SURFLSRMUI creates the dialog box to allow the user to enter in
%  the variable names for a SURFLSRM command.  It is called when
%  SURFLSRM is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'lat';
str2 = 'lon';
str3 = 'map';
str4 = '';
str5 = '';
str6 = '';

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = SurflsrmUIBox(str1,str2,str3,str4,str5,str6);  uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.

    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.latedit,'String');    %  Get the dialog entries
        str2 = get(h.lonedit,'String');
        str3 = get(h.mapedit,'String');
        str4 = get(h.azeledit,'String');
        str5 = get(h.cmapedit,'String');
        str6 = get(h.climedit,'String');
        delete(h.fig)

        %  Construct the appropriate plotting string and assemble the callback string
        str4use = str4;
        str5use = str5;
        str6use = str6;

        if isempty(str4use)
            str4use = '[]';
        end

        if isempty(str5use)
            str5use = '[]';
        end

        if isempty(str6use)
            str6use = '[]';
        end

        plotstr = ['surflsrm(',str1,',',str2,',',str3,',',...
            str4use,',',str5use,',',str6use,');'];

        try
            evalin('base', plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%-----------------------------------------------------------------------
function h = SurflsrmUIBox(lat0,lon0,map0,azel0,cmap0,clim0)

%  SURFLSRMUIBOX creates the dialog box and places the appropriate
%  objects for the SURFLSRMUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Shaded Relief Map Input',...
    'Units','Points',  'Position',72*[1.5 1 3.5 4.5], ...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');


%  Latitude Text and Edit Box
h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.92  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .85  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .85  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box
h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.79  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .72  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .72  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  Map Text and Edit Box
h.maplabel = uicontrol(h.fig,'Style','Text','String','Map variable:', ...
    'Units','Normalized','Position', [0.05  0.66  0.91  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.mapedit = uicontrol(h.fig,'Style','Edit','String', map0, ...
    'Units','Normalized','Position', [0.05  .59  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.maplist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .59  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.mapedit,...
    'CallBack',@varpick_cb);

%  Azimuth/Elevation Text and Edit Box
h.azellabel = uicontrol(h.fig,'Style','Text','String','Light Source [az, el] (optional):', ...
    'Units','Normalized','Position', [0.05  0.53  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.azeledit = uicontrol(h.fig,'Style','Edit','String', azel0, ...
    'Units','Normalized','Position', [0.05  .46  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.azellist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .46  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.azeledit,...
    'CallBack',@varpick_cb);

%  Colormap Text and Edit Box
h.cmaplabel = uicontrol(h.fig,'Style','Text','String','Colormap (optional):', ...
    'Units','Normalized','Position', [0.05  0.40  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.cmapedit = uicontrol(h.fig,'Style','Edit','String', cmap0, ...
    'Units','Normalized','Position', [0.05  .33  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.cmaplist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .33  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.cmapedit,...
    'CallBack',@varpick_cb);

%  Color Axis Limits Text and Edit Box
h.climlabel = uicontrol(h.fig,'Style','Text','String','Color Axis Limits (optional):', ...
    'Units','Normalized','Position', [0.05  0.27  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.climedit = uicontrol(h.fig,'Style','Edit','String', clim0, ...
    'Units','Normalized','Position', [0.05  .20  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.climlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .20  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.climedit,...
    'CallBack',@varpick_cb);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.maplist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.azellist,  'TooltipString', tooltipHelpStrings('ListButton'))
set(h.cmaplist,  'TooltipString', tooltipHelpStrings('ListButton'))
set(h.climlist,  'TooltipString', tooltipHelpStrings('ListButton'))
set(h.maplabel,  'TooltipString', tooltipHelpStrings('Map'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.azellabel, 'TooltipString', tooltipHelpStrings('AzEl'))
set(h.cmaplabel, 'TooltipString', tooltipHelpStrings('ColorMap'))
set(h.climlabel, 'TooltipString', tooltipHelpStrings('CLim'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%------------------------------------------------------------------
function contour3mui(~,~)
%CONTOR3MUI Dialog box for contour inputs.
%
%  CONTOR3MUI creates the dialog box to allow the user to enter in the
%  variable names for a contour command.  It is called when CONTOURM or
%  CONTOUR3M is executed with no input arguments.
%
%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Create axes if none found
if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return;
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'lat';
str2 = 'long';
str3 = 'map';
str4 = '';
str5 = '';
popvalu = 1;
flag2d = 1;

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = Contour3mUIBox(str1,str2,str3,str4,str5,flag2d,popvalu);
    uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.
    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.latedit,'String');    %  Get the dialog entries
        str2 = get(h.lonedit,'String');
        str3 = get(h.mapedit,'String');
        str4 = get(h.lvledit,'String');
        str5 = get(h.propedit,'String');
        flag2d = get(h.mode2d,'Value');
        popvalu = get(h.legpopup,'Value');
        delete(h.fig)

        %  Make the other property string into a single row vector.
        %  Eliminate any padding 0s since they mess up a string
        str5 = str5(:)';
        str5 = str5(str5 ~= 0);

        %  Set the 2D or 3D function name
        if flag2d
            fnname = 'contourm(';
        else
            fnname = 'contour3m(';
        end

        %  Set the plot string prefix and suffix based upon the legend option requested
        switch popvalu
            case 1,     prefix = '';   suffix = '';
            case 2,     prefix = 'clear ans;[ans.c,ans.h]=';
                suffix = 'clabelm(ans.c);clear ans';
            case 3,     prefix = 'clear ans;[ans.c,ans.h]=';
                suffix = 'clabelm(ans.c,ans.h);clear ans';
            case 4,     prefix = 'clear ans;[ans.c,ans.h]=';
                suffix = 'clabelm(ans.c,''manual'');clear ans';
            case 5,     prefix = 'clear ans;[ans.c,ans.h]=';
                suffix = 'clabelm(ans.c,ans.h,''manual'');clear ans';
            case 6,     prefix = 'clear ans;[ans.c,ans.h]=';
                suffix = 'clegendm(ans.c,ans.h,-1);clear ans';
        end

        %  Construct the appropriate plotting string and assemble the callback string
        if isempty(str4) && isempty(str5)
            plotstr = [fnname,str1,',',str2,',',str3,');'];
        elseif isempty(str4) && ~isempty(str5)
            plotstr = [fnname,str1,',',str2,',',str3,',',str5,');'];
        elseif ~isempty(str4) && isempty(str5)
            plotstr = [fnname,str1,',',str2,',',str3,',',str4,');'];
        elseif ~isempty(str4) && ~isempty(str5)
            plotstr = [fnname,str1,',',str2,',',str3,',',str4,',',str5,');'];
        end

        try
            evalin('base',[prefix plotstr suffix]);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%------------------------------------------------------------------
function h = Contour3mUIBox(lat0,lon0,map0,alt0,prop0,flag2d,popvalu)
%  CONTOR3MUIBOX creates the dialog box and places the appropriate
%  objects for the CONTOR3MUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Contour Map Input',...
    'Units','Points',  'Position',72*[2 1 3 4],...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

% shift window if it comes up partly offscreen
shiftwin(h.fig)

%  2D/3D Radio Buttons
h.modelabel = uicontrol(h.fig,'Style','Text','String','Mode:', ...
    'Units','Normalized','Position', [0.05  0.92  0.20  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);
h.mode2d = uicontrol(h.fig,'Style','Radio','String', '2D', ...
    'Units','Normalized','Position', [0.30  .92  0.17  0.06], ...
    'FontWeight','bold',  'FontSize',10, 'Value',flag2d,...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Callback',@toggle_cb);
h.mode3d = uicontrol(h.fig,'Style','Radio','String', '3D', ...
    'Units','Normalized','Position', [0.50  .92  0.17  0.06], ...
    'FontWeight','bold',  'FontSize',10, 'Value',~flag2d,...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Callback',@toggle_cb);

set(h.mode2d,'UserData',h.mode3d);     %  Set the user data so that the radio callback
set(h.mode3d,'UserData',h.mode2d);     %  functions to make buttons exclusive

%  Latitude Text and Edit Box
h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.853  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .78  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .78  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box
h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.713  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .64  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .64  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  Map Text and Edit Box
h.maplabel = uicontrol(h.fig,'Style','Text','String','Map variable:', ...
    'Units','Normalized','Position', [0.05  0.573  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.mapedit = uicontrol(h.fig,'Style','Edit','String', map0, ...
    'Units','Normalized','Position', [0.05  .50  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.maplist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .50  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.mapedit,...
    'CallBack',@varpick_cb);

%  Levels Text and Edit Box
h.lvllabel = uicontrol(h.fig,'Style','Text','String','Level variable (optional):', ...
    'Units','Normalized','Position', [0.05  0.433  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lvledit = uicontrol(h.fig,'Style','Edit','String', alt0, ...
    'Units','Normalized','Position', [0.05  .36  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lvllist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .36  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lvledit,...
    'CallBack',@varpick_cb);

%  Legend Text and Popup Menu
h.leglabel = uicontrol(h.fig,'Style','Text','String','Legend:', ...
    'Units','Normalized','Position', [0.05  0.29  0.25  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.legpopup = uicontrol(h.fig,'Style','Popup',...
    'String', ['None|Label Above|Label Inline|Label Above Manual|',...
    'Label Inline Manual|Plot Legend'], ...
    'Units','Normalized','Position', [0.35  .28  0.60  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Value',popvalu,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Other Properties Text and Edit Box
h.proplabel = uicontrol(h.fig,'Style','Text','String','Other Properties:', ...
    'Units','Normalized','Position', [0.05  0.214  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.propedit = uicontrol(h.fig,'Style','Edit','String', prop0, ...
    'Units','Normalized','Position', [0.05  .10  0.90  0.11], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.01  0.26  0.07], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.01  0.26  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.maplist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lvllist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.maplabel,  'TooltipString', tooltipHelpStrings('Map'))
set(h.lvllabel,  'TooltipString', tooltipHelpStrings('ContourLevels'))
set(h.modelabel, 'TooltipString', tooltipHelpStrings('ContourMode'))
set(h.leglabel,  'TooltipString', tooltipHelpStrings('ContourLegend'))
set(h.proplabel, 'TooltipString', tooltipHelpStrings('OtherProperties1'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h);

%--------------------------------------------------------------------

function toggle_cb(hSrc,~)
% Toggle UserData values between 0 and 1 for a pair of linked 
% radio button uicontrols

set(hSrc,'Value',1)
t = get(hSrc,'UserData');
set(t,'Value',0)

%--------------------------------------------------------------------

function contourfmui(~,~)
%  CONTOR3MUI creates the dialog box to allow the user to enter in
%  the variable names for a surfacem command.  It is called when
%  CONTOR3M is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Create axes if none found

if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return;
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'lat';
str2 = 'long';
str3 = 'map';
str4 = '';
str5 = '';
popvalu = 1;

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = ContourfmUIBox(str1,str2,str3,str4,str5,popvalu);
    uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.
    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.latedit,'String');    %  Get the dialog entries
        str2 = get(h.lonedit,'String');
        str3 = get(h.mapedit,'String');
        str4 = get(h.lvledit,'String');
        str5 = get(h.propedit,'String');
        %         flag2d = get(h.mode2d,'Value');
        popvalu = get(h.legpopup,'Value');
        delete(h.fig)

        %  Make the other property string into a single row vector.
        %  Eliminate any padding 0s since they mess up a string

        str5 = str5(:)';
        str5 = str5(str5 ~= 0);

        %  Set the function name
        fnname = 'contourfm(';

        %  Set the plot string prefix and suffix based upon the legend option requested
        switch popvalu
            case 1,     prefix = '';   suffix = '';
            case 2,     prefix = 'clear ans;[ans.c,ans.h]=';
                suffix = 'clabelm(ans.c);clear ans';
            case 3,     prefix = 'clear ans;[ans.c,ans.h]=';
                suffix = 'clabelm(ans.c,ans.h);clear ans';
            case 4,     prefix = 'clear ans;[ans.c,ans.h]=';
                suffix = 'clabelm(ans.c,''manual'');clear ans';
            case 5,     prefix = 'clear ans;[ans.c,ans.h]=';
                suffix = 'clabelm(ans.c,ans.h,''manual'');clear ans';
            case 6,     prefix = 'clear ans;[ans.c,ans.h]=';
                suffix = 'clegendm(ans.c,ans.h,-1);clear ans';
        end

        %  Construct the appropriate plotting string and assemble the callback string
        if isempty(str4) && isempty(str5)
            plotstr = [fnname,str1,',',str2,',',str3,');'];
        elseif isempty(str4) && ~isempty(str5)
            plotstr = [fnname,str1,',',str2,',',str3,',',str5,');'];
        elseif ~isempty(str4) && isempty(str5)
            plotstr = [fnname,str1,',',str2,',',str3,',',str4,');'];
        elseif ~isempty(str4) && ~isempty(str5)
            plotstr = [fnname,str1,',',str2,',',str3,',',str4,',',str5,');'];
        end

        try
            evalin('base',[prefix plotstr suffix]);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%--------------------------------------------------------------------
function h = ContourfmUIBox(lat0,lon0,map0,alt0,prop0,popvalu)

%  CONTOR3MUIBOX creates the dialog box and places the appropriate
%  objects for the CONTOR3MUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Filled Contour Map Input',...
    'Units','Points',  'Position',72*[2 1 3 4],...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

% shift window if it comes up partly offscreen

shiftwin(h.fig)

%  Latitude Text and Edit Box
h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.853  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .78  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .78  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box
h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.713  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .64  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .64  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  Map Text and Edit Box
h.maplabel = uicontrol(h.fig,'Style','Text','String','Map variable:', ...
    'Units','Normalized','Position', [0.05  0.573  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.mapedit = uicontrol(h.fig,'Style','Edit','String', map0, ...
    'Units','Normalized','Position', [0.05  .50  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.maplist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .50  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.mapedit,...
    'CallBack',@varpick_cb);

%  Levels Text and Edit Box
h.lvllabel = uicontrol(h.fig,'Style','Text','String','Level variable (optional):', ...
    'Units','Normalized','Position', [0.05  0.433  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lvledit = uicontrol(h.fig,'Style','Edit','String', alt0, ...
    'Units','Normalized','Position', [0.05  .36  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lvllist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .36  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lvledit,...
    'CallBack',@varpick_cb);

%  Legend Text and Popup Menu
h.leglabel = uicontrol(h.fig,'Style','Text','String','Legend:', ...
    'Units','Normalized','Position', [0.05  0.29  0.25  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.legpopup = uicontrol(h.fig,'Style','Popup',...
    'String', ['None|Label Above|Label Inline|Label Above Manual|',...
    'Label Inline Manual|Plot Legend'], ...
    'Units','Normalized','Position', [0.35  .28  0.60  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Value',popvalu,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Other Properties Text and Edit Box
h.proplabel = uicontrol(h.fig,'Style','Text','String','Other Properties:', ...
    'Units','Normalized','Position', [0.05  0.214  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.propedit = uicontrol(h.fig,'Style','Edit','String', prop0, ...
    'Units','Normalized','Position', [0.05  .10  0.90  0.11], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.01  0.26  0.07], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.01  0.26  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.maplist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lvllist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.maplabel,  'TooltipString', tooltipHelpStrings('Map'))
set(h.lvllabel,  'TooltipString', tooltipHelpStrings('ContourLevels'))
set(h.leglabel,  'TooltipString', tooltipHelpStrings('ContourLegend'))
set(h.proplabel, 'TooltipString', tooltipHelpStrings('OtherProperties1'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%--------------------------------------------------------------------
function quiver3mui(~,~)

%  QUIVER3MUI creates the dialog box to allow the user to enter in
%  the variable names for a quiver3m command.  It is called when
%  QUIVER3M is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Create axes if none found
if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return;
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'lat';
str2 = 'long';
str3 = 'alt';
str4 = 'u';
str5 = 'v';
str6 = 'w';
str7 = '';
str8 = '';
fill0 = 0;

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = Quiver3mUIBox(str1,str2,str3,str4,str5,str6,str7,str8,fill0);  uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.

    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.latedit,'String');    %  Get the dialog entries
        str2 = get(h.lonedit,'String');
        str3 = get(h.altedit,'String');
        str4 = get(h.uedit,'String');
        str5 = get(h.vedit,'String');
        str6 = get(h.wedit,'String');
        str7 = get(h.scledit,'String');
        str8 = get(h.lineedit,'String');
        fill0 = get(h.arrow,'Value');
        delete(h.fig)

        %  Construct the appropriate plotting string and assemble the callback string

        switch fill0
            case 0
                if isempty(str7) && isempty(str8)
                    plotstr = ['quiver3m(',str1,',',str2,',',str3,',',str4,',',...
                        str5,',',str6,')'];
                elseif isempty(str7) && ~isempty(str8)
                    plotstr = ['quiver3m(',str1,',',str2,',',str3,',',str4,',',...
                        str5,',',str6,',',str8,')'];
                elseif ~isempty(str7) && isempty(str8)
                    plotstr = ['quiver3m(',str1,',',str2,',',str3,',',str4,',',...
                        str5,',',str6,',',str7,')'];
                elseif ~isempty(str7) && ~isempty(str8)
                    plotstr = ['quiver3m(',str1,',',str2,',',str3,',',str4,',',...
                        str5,',',str6,',',str8,',',str7,')'];
                end
            case 1
                fillstr = ' ''filled'' ';
                if isempty(str7) && isempty(str8)
                    plotstr = ['quiver3m(',str1,',',str2,',',str3,',',str4,',',...
                        str5,',',str6,',[],',fillstr,')'];
                elseif isempty(str7) && ~isempty(str8)
                    plotstr = ['quiver3m(',str1,',',str2,',',str3,',',str4,',',...
                        str5,',',str6,',',str8,',[],',fillstr,')'];
                elseif ~isempty(str7) && isempty(str8)
                    plotstr = ['quiver3m(',str1,',',str2,',',str3,',',str4,',',...
                        str5,',',str6,',',str7,',',fillstr,')'];
                elseif ~isempty(str7) && ~isempty(str8)
                    plotstr = ['quiver3m(',str1,',',str2,',',str3,',',str4,',',...
                        str5,',',str6,',',str8,',',str7,',',fillstr,')'];
                end
        end

        try
            evalin('base', plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%----------------------------------------------------------------------
function h = Quiver3mUIBox(lat0,lon0,alt0,u0,v0,w0,scale0,line0,fill0)

%  QUIVER3MUIBOX creates the dialog box and places the appropriate
%  objects for the QUIVER3MUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Quiver3 Map Input',...
    'Units','Points',  'Position',72*[2 1 3 4.5],...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

% shift window if it comes up partly offscreen
shiftwin(h.fig)

%  Latitude Text and Edit Box
h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.942  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .88  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .88  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box
h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.822  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .76  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .76  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  Altitude Text and Edit Box
h.altlabel = uicontrol(h.fig,'Style','Text','String','Altitude variable:', ...
    'Units','Normalized','Position', [0.05  0.702  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altedit = uicontrol(h.fig,'Style','Edit','String', alt0, ...
    'Units','Normalized','Position', [0.05  .64  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .64  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.altedit,...
    'CallBack',@varpick_cb);

%  U Text and Edit Box
h.ulabel = uicontrol(h.fig,'Style','Text','String','U Component variable:', ...
    'Units','Normalized','Position', [0.05  0.582  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.uedit = uicontrol(h.fig,'Style','Edit','String', u0, ...
    'Units','Normalized','Position', [0.05  .52  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.ulist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .52  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.uedit,...
    'CallBack',@varpick_cb);

%  V Text and Edit Box
h.vlabel = uicontrol(h.fig,'Style','Text','String','V Component variable:', ...
    'Units','Normalized','Position', [0.05  0.462  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.vedit = uicontrol(h.fig,'Style','Edit','String', v0, ...
    'Units','Normalized','Position', [0.05  .40  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.vlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .40  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.vedit,...
    'CallBack',@varpick_cb);

%  W Text and Edit Box
h.wlabel = uicontrol(h.fig,'Style','Text','String','W Component variable:', ...
    'Units','Normalized','Position', [0.05  0.342  0.90  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.wedit = uicontrol(h.fig,'Style','Edit','String', w0, ...
    'Units','Normalized','Position', [0.05  .28  0.70  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.wlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .28  0.18  0.06], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.wedit,...
    'CallBack',@varpick_cb);

%  Scale Text and Edit Box
h.scllabel = uicontrol(h.fig,'Style','Text','String','Scale (optional):', ...
    'Units','Normalized','Position', [0.05  0.22  0.60  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.scledit = uicontrol(h.fig,'Style','Edit','String', scale0, ...
    'Units','Normalized','Position', [0.70  .22  0.25  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',1,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Linespec Text and Edit Box
h.linelabel = uicontrol(h.fig,'Style','Text','String','LineSpec (optional):', ...
    'Units','Normalized','Position', [0.05  0.15  0.60  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lineedit = uicontrol(h.fig,'Style','Edit','String', line0, ...
    'Units','Normalized','Position', [0.70  .15  0.25  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',1,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Filled Arrow Heads Check Box
h.arrow = uicontrol(h.fig,'Style','Check','String','Filled Base Marker', ...
    'Units','Normalized','Position', [0.05  0.08  0.60  0.05], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Value',fill0,...
    'ForegroundColor', 'black','BackgroundColor', figclr);


%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.01  0.26  0.06], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.01  0.26  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.altlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.ulist,     'TooltipString', tooltipHelpStrings('ListButton'))
set(h.vlist,     'TooltipString', tooltipHelpStrings('ListButton'))
set(h.wlist,     'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.altlabel,  'TooltipString', tooltipHelpStrings('Altitude'))
set(h.ulabel,    'TooltipString', tooltipHelpStrings('UComponent'))
set(h.vlabel,    'TooltipString', tooltipHelpStrings('VComponent'))
set(h.wlabel,    'TooltipString', tooltipHelpStrings('WComponent'))
set(h.linelabel, 'TooltipString', tooltipHelpStrings('LineSpec'))
set(h.scllabel,  'TooltipString', tooltipHelpStrings('QuiverScale'))
set(h.arrow,     'TooltipString', tooltipHelpStrings('FilledBase'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%------------------------------------------------------------------
function stem3mui(~,~)

%  STEM3MUI creates the dialog box to allow the user to enter in
%  the variable names for a stem3m command.  It is called when
%  STEM3M is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Create axes if none found
if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return;
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'lat';
str2 = 'long';
str3 = 'z';
str4 = '';

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = Stem3mUIBox(str1,str2,str3,str4);  uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.

    if get(h.fig,'CurrentObject') ~= h.cancel
        str1 = get(h.latedit,'String');    %  Get the dialog entries
        str2 = get(h.lonedit,'String');
        str3 = get(h.altedit,'String');
        str4 = get(h.propedit,'String');
        delete(h.fig)

        %  Make the other property string into a single row vector.
        %  Eliminate any padding 0s since they mess up a string
        str4 = str4(:)';
        str4 = str4(str4 ~= 0);

        %  Construct the appropriate plotting string and assemble the callback string

        if isempty(str4)
            plotstr = ['stem3m(',str1,',',str2,',',str3,');'];
        else
            plotstr = ['stem3m(',str1,',',str2,',',str3,',',str4,');'];
        end

        try
            evalin('base',plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%------------------------------------------------------------------
function h = Stem3mUIBox(lat0,lon0,z0,prop0)
%  STEM3MUIBOX creates the dialog box and places the appropriate
%  objects for the STEM3MUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Stem Map Input',...
    'Units','Points',  'Position',72*[2 1 3 3.3],...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

% shift window if it comes up partly offscreen
shiftwin(h.fig)

%  Latitude Text and Edit Box
h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.91  0.90  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .82  0.70  0.09], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .82  0.18  0.09], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box
h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.722  0.90  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .63  0.70  0.09], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .63  0.18  0.09], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  Count Text and Edit Box
h.altlabel = uicontrol(h.fig,'Style','Text','String','Stem Height Variable:', ...
    'Units','Normalized','Position', [0.05  0.532  0.90  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altedit = uicontrol(h.fig,'Style','Edit','String', z0, ...
    'Units','Normalized','Position', [0.05  .44  0.70  0.09], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .44  0.18  0.09], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.altedit,...
    'CallBack',@varpick_cb);

%  Other Properties Text and Edit Box
h.proplabel = uicontrol(h.fig,'Style','Text','String','Other Properties:', ...
    'Units','Normalized','Position', [0.05  0.343  0.90  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.propedit = uicontrol(h.fig,'Style','Edit','String', prop0, ...
    'Units','Normalized','Position', [0.05  .19  0.90  0.15], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.altlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.altlabel,  'TooltipString', tooltipHelpStrings('StemHeight'))
set(h.proplabel, 'TooltipString', tooltipHelpStrings('OtherProperties1'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%-------------------------------------------------------------------
function scattermui(~,~)

%  SCATTERMUI creates the dialog box to allow the user to enter in
%  the variable names for a scatterm command.  It is called when
%  SCATTERM is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Create axes if none found
if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return;
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = 'lat';
str2 = 'long';
str3 = '';
str4 = '';
str5 ='''o''';
str6 = 'notfilled';

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = scattermUIBox(str1,str2,str3,str4,str5,str6);  uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.
    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.latedit,'String');    %  Get the dialog entries
        str2 = get(h.lonedit,'String');
        str3 = get(h.altedit,'String');
        str4 = get(h.coloredit,'String');
        
        pick_list = get(h.markpopup, 'String');
        selection = get(h.markpopup, 'Value');
        str5 = ['''' pick_list{selection} ''''];
        
        str6 = '';
        if get(h.fillcheck,'Value')
            str6 = '''filled''';
        end
        delete(h.fig)

        %  Construct the appropriate plotting string and assemble the callback
        %  string
        str = {...
            str1, ',';
            str2, ',';
            str3, ',';
            str4, ',';
            str5, ',';
            str6, ','}';

        str(:,cellfun(@isempty,str(1,:))) = [];
        str = [str{:}];
        str(end) = [];  % Remove trailing comma

        plotstr = ['scatterm(' str ');'];

        try
            evalin('base',plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%--------------------------------------------------------------------
function h = scattermUIBox(lat0,lon0,z0,color0,style0,fill0)

%  SCATTERMUIBOX creates the dialog box and places the appropriate
%  objects for the SCATTERMUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Scatter Map Input',...
    'Units','Points',  'Position',72*[2 1 3 3.7], ...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');


% shift window if it comes up partly offscreen
shiftwin(h.fig)

%  Latitude Text and Edit Box
h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.925  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .85  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .85  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box
h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.775  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .70  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .70  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  Count Data Text and Edit Box
h.altlabel = uicontrol(h.fig,'Style','Text','String','Marker size (optional):', ...
    'Units','Normalized','Position', [0.05  0.625  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altedit = uicontrol(h.fig,'Style','Edit','String', z0, ...
    'Units','Normalized','Position', [0.05  .55  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .55  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.altedit,...
    'CallBack',@varpick_cb);

%  Color Data Text and Edit Box
h.colorlabel = uicontrol(h.fig,'Style','Text','String','Marker color (optional):', ...
    'Units','Normalized','Position', [0.05 0.475  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.coloredit = uicontrol(h.fig,'Style','Edit','String', color0, ...
    'Units','Normalized','Position', [0.05  .40  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.colorlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .40  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.coloredit,...
    'CallBack',@varpick_cb);

%  Marker Style Text and Edit Box
h.marklabel = uicontrol(h.fig,'Style','Text','String','Marker Style:', ...
    'Units','Normalized','Position', [0.05  0.3  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

strings={'+','o','*','.','x','v','^','>','<'};

indx = (style0 == ''''); style0(indx) = []; % strip quotes
indx = find(strcmp(style0,strings));

h.markpopup = uicontrol(h.fig,'Style','popup','String', strings, 'Value',indx, ...
    'Units','Normalized','Position', [0.2  .25-0.025  0.25  0.07], ...
    'FontSize',10,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Fill labels checkbox
fvalue = 0;
if strcmp('filled',fill0)
    fvalue = 1;
end

h.fillcheck = uicontrol(h.fig,'Style','check',  'Value',fvalue,'String','Filled',...
    'Units','Normalized','Position', [0.55  .245-0.025  0.25  0.075], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Min',0,'Max',1,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.altlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.colorlist, 'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.altlabel,  'TooltipString', tooltipHelpStrings('MarkerSizeWeight'))
set(h.colorlabel,'TooltipString', tooltipHelpStrings('MarkerColor'))
set(h.marklabel, 'TooltipString', tooltipHelpStrings('MarkerSymbolPopup'))
set(h.fillcheck, 'TooltipString', tooltipHelpStrings('FillCheck'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%-------------------------------------------------------------------------
function textmui(~,~)

%  TEXTMUI creates the dialog box to allow the user to enter in
%  the variable names for a surfacem command.  It is called when
%  TEXTM is executed with no input arguments.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Create axes if none found
if isempty(get(get(0,'CurrentFigure'),'CurrentAxes'))
    Btn = questdlg('Create Map Axes in Current Figure?','No Map Axes',...
        'Yes','No','Yes');
    if strcmp(Btn,'No')
        return;
    end
    axes;
end

%  Create map definition if necessary
if ~ismap
    cancelflag = axesm;
    if cancelflag
        clma purge;
        return;
    end
end

%  Initialize the entries of the dialog box
str1 = '';
str2 = 'lat';
str3 = 'long';
str4 = '';
str5 = '';

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = TextmUIBox(str1,str2,str3,str4,str5);  uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.

    if get(h.fig,'CurrentObject') == h.apply
        str1 = get(h.txtedit,'String');    %  Get the dialog entries
        str2 = get(h.latedit,'String');
        str3 = get(h.lonedit,'String');
        str4 = get(h.altedit,'String');
        str5 = get(h.propedit,'String');
        delete(h.fig)

        %  Make the other property string into a single row vector.
        %  Eliminate any padding 0s since they mess up a string
        str5 = str5(:)';
        str5 = str5(str5 ~= 0);

        %  Construct the appropriate plotting string and assemble the callback
        %  string
        if isempty(str4) && isempty(str5)
            plotstr = ['textm(',str2,',',str3,',',str1,')'];
        elseif isempty(str4) && ~isempty(str5)
            plotstr = ['textm(',str2,',',str3,',',str1,',',str5,')'];
        elseif ~isempty(str4) && isempty(str5)
            plotstr = ['textm(',str2,',',str3,',',str4,',',str1,')'];
        elseif ~isempty(str4) && ~isempty(str5)
            plotstr = ['textm(',str2,',',str3,',',str4,',',str1,',',str5,');'];
        end

        try
            evalin('base',plotstr);
            break;
        catch e
            uiwait(errordlg(e.message,'Map Projection Error','modal'))
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%---------------------------------------------------------------------
function h = TextmUIBox(text0,lat0,lon0,alt0,prop0)

%  TEXTMUIBOX creates the dialog box and places the appropriate
%  objects for the TEXTMUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','Text Map Input',...
    'Units','Points',  'Position',72*[2 1 3 3.7], ...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

% shift window if it comes up partly offscreen
shiftwin(h.fig)

%  Text Variable Text and Edit Box
h.txtlabel = uicontrol(h.fig,'Style','Text','String','Text variable/string:', ...
    'Units','Normalized','Position', [0.05  0.925  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.txtedit = uicontrol(h.fig,'Style','Edit','String', text0, ...
    'Units','Normalized','Position', [0.05  .85  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.txtlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .85  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.txtedit,...
    'CallBack',@varpick_cb);

%  Latitude Text and Edit Box
h.latlabel = uicontrol(h.fig,'Style','Text','String','Latitude variable:', ...
    'Units','Normalized','Position', [0.05  0.775  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left',...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latedit = uicontrol(h.fig,'Style','Edit','String', lat0, ...
    'Units','Normalized','Position', [0.05  .70  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.latlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .70  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.latedit,...
    'CallBack',@varpick_cb);

%  Longitude Text and Edit Box
h.lonlabel = uicontrol(h.fig,'Style','Text','String','Longitude variable:', ...
    'Units','Normalized','Position', [0.05  0.625  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonedit = uicontrol(h.fig,'Style','Edit','String', lon0, ...
    'Units','Normalized','Position', [0.05  .55  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.lonlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .55  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.lonedit,...
    'CallBack',@varpick_cb);

%  Altitude Text and Edit Box
h.altlabel = uicontrol(h.fig,'Style','Text','String','Scalar Altitude (optional):', ...
    'Units','Normalized','Position', [0.05  0.475  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altedit = uicontrol(h.fig,'Style','Edit','String', alt0, ...
    'Units','Normalized','Position', [0.05  .40  0.70  0.07], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.altlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .40  0.18  0.07], ...
    'FontWeight','bold',  'FontSize',9, ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'Interruptible','on', 'UserData',h.altedit,...
    'CallBack',@varpick_cb);

%  Other Properties Text and Edit Box
h.proplabel = uicontrol(h.fig,'Style','Text','String','Other Properties:', ...
    'Units','Normalized','Position', [0.05  0.325  0.90  0.06], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', ...
    'ForegroundColor', 'black','BackgroundColor', figclr);

h.propedit = uicontrol(h.fig,'Style','Edit','String', prop0, ...
    'Units','Normalized','Position', [0.05  .16  0.90  0.16], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor', 'black','BackgroundColor', figclr);

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units', 'Normalized','Position', [0.06  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10,...
    'HorizontalAlignment', 'center',...
    'ForegroundColor', 'black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units', 'Normalized','Position', [0.68  0.02  0.26  0.10], ...
    'FontWeight','bold',  'FontSize',10, ...
    'HorizontalAlignment', 'center', ...
    'ForegroundColor', 'black','BackgroundColor', figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.txtlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.latlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.lonlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.altlist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.txtlabel,  'TooltipString', tooltipHelpStrings('Text'))
set(h.latlabel,  'TooltipString', tooltipHelpStrings('Latitude'))
set(h.lonlabel,  'TooltipString', tooltipHelpStrings('Longitude'))
set(h.altlabel,  'TooltipString', tooltipHelpStrings('Altitude'))
set(h.proplabel, 'TooltipString', tooltipHelpStrings('OtherProperties2'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)

%----------------------------------------------------------------------
function lightmui(~,~) %#ok<DEFNU>
% This callback performs no operations. It's a stub to take the place of
% a callback that has been removed, allowing for figures saved in earlier
% releases to be loaded without error.

%--------------------------------------------------------------------------

function varpick_cb(h,~)

var = evalin('base','who');
varpick(var,get(h,'UserData'))
