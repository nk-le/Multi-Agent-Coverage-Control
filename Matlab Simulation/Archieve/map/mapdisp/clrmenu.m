function clrmenu(f)
%CLRMENU Add colormap menu to figure window
%
%  CLRMENU adds a colormap menu choices to the current figure.
%
%  CLRMENU(h) adds the menu choices to the figure window specified
%  by the handle h.
%
%  Each of the menu choices operates on the colormap:
%  PARULA, GRAY, HSV, HOT, PINK, COOL, BONE, JET, COPPER, SPRING, SUMMER,
%  AUTUMN, WINTER, FLAG and PRISM allow selection of standard colormaps.
%  RAND is a random colormap.
%  BRIGHTEN increases the brightness.
%  DARKEN decreases the brightness.
%  FLIPUD inverts the order of the colormap entries.
%  FLIPLR interchanges the red and blue components.
%  PERMUTE cyclic permutations: red -> blue, blue -> green, green -> red.
%  DEFINE allows a workspace variable to be specied for the colormap
%  DIGITAL ELEVATION creates a digital elevation colormap using DEMCMAP
%  POLITICAL creates a political colormap using POLCMAP
%  REMEMBER pushes a copy of the current colormap onto a stack.
%  RESTORE pops a map from the stack (initially, the stack contains the
%       map in use when CLRMENU was invoked.)

% Copyright 1996-2015 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

if nargin < 1
    f = gcf;
else
    validateattributes(f,{'handle','double'},{'scalar'},'','h')
end

h = uimenu(f,'Label','Colormaps');

%  Define the standard colormaps
maps = {'Parula','Gray','Hsv','Hot','Pink','Cool','Bone','Jet',...
    'Copper','Spring','Summer','Autumn','Winter','Flag','Prism'};
for k = 1:numel(maps)
    uimenu(h,'Label',maps{k},'Callback',@(h,~) colormap(fig(h),lower(maps{k})))
end

%  Some operations on the colormap
uimenu(h,'Label','Rand','Separator','on','Callback', ...
    @(h,~) randomizeColormap(fig(h)))

uimenu(h,'Label','Brighten', 'Callback', @(h,~) brighten(fig(h),0.25))
uimenu(h,'Label','Darken',   'Callback', @(h,~) brighten(fig(h),-0.25))
uimenu(h,'Label','Flipud',   'Callback', @(h,~) colormap(fig(h),flipud(colormap(fig(h)))))
uimenu(h,'Label','Fliplr',   'Callback' ,@(h,~) colormap(fig(h),fliplr(colormap(fig(h)))))
uimenu(h,'Label','Permute',  'Callback', @(h,~) permuteColormap(fig(h)))

%  Additional colormaps
uimenu(h,'Label','Define','Callback',@defineColormap,'Separator','on')
uimenu(h,'Label','Digital Elevation','Callback',@demcmapui)
uimenu(h,'Label','Political','Callback',@politicalColormap)

%  Remember/restore/refresh
%     Manage stack of colormaps via a cell array in the menu's appdata
setappdata(h,'ColormapStack',{colormap(f)})  % "Remember" initial colormap
uimenu(h,'Label','Remember','Callback',@rememberColormap,'Separator','on')
uimenu(h,'Label','Restore', 'Callback',@restoreColormap)

%  Refresh figure
uimenu(h,'Label','Refresh','Separator','on','Callback',@(h,~) refresh(fig(h)))

%--------------------------------------------------------------------------

function f = fig(h)
% Handle to figure ancestor of h
f = ancestor(h,'figure');

%--------------------------------------------------------------------------

function randomizeColormap(f)
cmap = colormap(f);
cmap = rand(size(cmap));
colormap(f,cmap)

%--------------------------------------------------------------------------

function permuteColormap(f)
cmap = colormap(f);
cmap = cmap(:,[2 3 1]);
colormap(f,cmap)

%--------------------------------------------------------------------------

function defineColormap(~,~)
colormapdlg('Colormap variable:','Define Colormap','')

%--------------------------------------------------------------------------

function politicalColormap(h,~)
f = fig(h);
ncolors = size(colormap(f),1);
cmap = polcmap(ncolors);
colormap(f,cmap)

%--------------------------------------------------------------------------

function rememberColormap(h,~)
p = get(h,'Parent');
maps = getappdata(p,'ColormapStack');
maps(1,end+1) = {colormap(fig(p))}; % Push current colormap
setappdata(p,'ColormapStack',maps)

%--------------------------------------------------------------------------

function restoreColormap(h,~)
p = get(h,'Parent');
maps = getappdata(p,'ColormapStack');
colormap(fig(p),maps{end})
if length(maps) > 1
    % Pop colormap, unless that would empty the stack
    maps(end) = [];
    setappdata(p,'ColormapStack',maps)
end

%---------------------------------------------------------------
function colormapdlg(prompt,titlestr,strsave)
%  COLORMAPDLG creates the dialog box to allow the user to enter in
%  the colormap variables.  It is called from CLRMENU.

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = colormapbox(prompt,titlestr,strsave);  uiwait(h.fig)
    if ~ishghandle(h.fig)
        return
    end

    btn = get(h.fig,'CurrentObject');
    str = get(h.txtedit,'String');   strsave = str;
    delete(h.fig)

    if btn == h.apply
        %  Make multi-lines of string entry into a single row vector
        %  Ensure that all quotes are doubled.  Save the original entry of
        %  the other properties string in case its needed during the error loop.

        if ~isempty(str)
            indx = find(str == 0);     %  Replace nulls, but not blanks
            if ~isempty(indx)
                str(indx) = ' ';
            end
            str = str(:)';
            str = str(str ~=0 );
        end

        try
            evalin('base', sprintf('colormap(%s);', str));
            break;
        catch e
            uiwait(errordlg(e.message,'Colormap Error','modal'))
        end
        
    else
        break             %  Exit the loop
    end
end

%-----------------------------------------------------------------
function h = colormapbox(prompt,titlestr,def)

%  COLORMAPBOX creates the dialog box and places the appropriate
%  objects for the COLORMAPDLG function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name',titlestr,...
    'Units','Points','Position',72*[2 1.5 3 1.5],...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

%  Colormap Text and Edit Box
h.txtlabel = uicontrol(h.fig,'Style','Text', 'String',prompt, ...
    'Units','Normalized','Position',[0.05  0.85  0.90  0.10], ...
    'FontWeight','bold','FontSize',10, ...
    'HorizontalAlignment','left',...
    'ForegroundColor','black','BackgroundColor', figclr);

h.txtedit = uicontrol(h.fig,'Style','Edit', 'String',def, ...
    'Units','Normalized', 'Position',[0.05  .40  0.70  0.40], ...
    'FontWeight','bold', 'FontSize',10,...
    'HorizontalAlignment', 'left', 'Max',2,...
    'ForegroundColor','black','BackgroundColor',figclr);

h.txtlist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position',[0.77  .50  0.18  0.20], ...
    'FontWeight','bold','FontSize',9, ...
    'ForegroundColor','black','BackgroundColor',figclr,...
    'Interruptible','on','UserData',h.txtedit,...
    'CallBack','varpick(who,get(gco,''UserData''))');

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String','Accept', ...
    'Units','Points','Position',72*[0.30  0.05  1.05  0.40], ...
    'FontWeight','bold','FontSize',12, ...
    'HorizontalAlignment','center', 'Tag','OK',...
    'ForegroundColor','black', 'BackgroundColor', figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push', 'String','Cancel', ...
    'Units','Points','Position',72*[1.65  0.05  1.05  0.40], ...
    'FontWeight','bold','FontSize',12, ...
    'HorizontalAlignment','center', ...
    'ForegroundColor','black','BackgroundColor',figclr,...
    'CallBack','uiresume');

set(h.fig,'Visible','on');

%----------------------------------------------------------------------
function demcmapui(~,~)
%  DEMCMAPUI creates the dialog box to allow the user to enter in
%  the variable names for a DEMCMAP command.

%  Define map for current axes if necessary.  Note that if the
%  user cancels this operation, the display dialog is aborted.

%  Initialize the entries of the dialog box
value1 = 1;
str1 = '';
str2 = '';
str3 = '';
str4 = '';

while 1      %  Loop until no error break or cancel break

    %  Display the variable prompt dialog box
    h = DemcmapUIBox(value1,str1,str2,str3,str4);
    uiwait(h.fig)

    if ~ishghandle(h.fig)
        return;
    end

    %  If the accept button is pushed, build up the command string and
    %  evaluate it in the base workspace.  Delete the modal dialog box
    %  before evaluating the command so that the proper axes are used.
    %  The proper axes were current before the modal dialog was created.
    if get(h.fig,'CurrentObject') == h.apply
        value1 = get(h.radio1,'Value');
        str1 = get(h.mapedit,'String');    %  Get the dialog entries
        str2 = get(h.sizeedit,'String');
        str3 = get(h.rgbsedit,'String');
        str4 = get(h.rgbledit,'String');
        delete(h.fig)

        %  Construct the appropriate plotting string and assemble the
        %  callback string
        if isempty(str1)
            uiwait(errordlg('Map entry required.','DEM Colormap Error','modal'))
        else

            str2use = str2;
            str3use = str3;
            str4use = str4;

            if isempty(str2use)
                str2use = '[]';
            end

            if isempty(str3use)
                str3use = '[]';
            end

            if isempty(str4use)
                str4use = '[]';
            end

            if value1
                plotstr = ['demcmap(''size'',',str1,',',str2use,',',...
                    str3use,',',str4use,')'];
            else
                plotstr = ['demcmap(''inc'',',str1,',',str2use,',',...
                    str3use,',',str4use,')'];
            end

            try
                evalin('base', plotstr);
                break;
            catch e
                uiwait(errordlg(e.message,'DEM Colormap Error','modal'));
            end
            
        end
    else
        delete(h.fig)     %  Close the modal dialog box
        break             %  Exit the loop
    end
end

%-------------------------------------------------------------------
function h = DemcmapUIBox(value0,map0,size0,rgbs0,rgbl0)
%  DEMCMAPUIBOX creates the dialog box and places the appropriate
%  objects for the DEMCMAPMUI function.

%  Create the dialog box.  Make visible when all objects are drawn
h.fig = dialog('Name','DEM Colormap Input',...
    'Units','Points',  'Position',72*[1.5 1 3.5 3.5], ...
    'Visible','off');
colordef(h.fig,'white');
figclr = get(h.fig,'Color');

% shift window if it comes up partly offscreen
shiftwin(h.fig)

%  DEMCMAP radio buttons
callbackstr = ['get(get(gcbo,''Parent''),''UserData'');',...
    'set(gcbo,''Value'',1);set(get(gcbo,''UserData''),''Value'',0);'];

h.radiolabel = uicontrol(h.fig,'Style','Text','String','Mode:', ...
    'Units','Normalized','Position',[0.05  0.90  0.20  0.07], ...
    'FontWeight','bold','FontSize',10, ...
    'HorizontalAlignment','left', ...
    'ForegroundColor','black','BackgroundColor',figclr);

h.radio1 = uicontrol(h.fig,'Style','Radio','String','Size', ...
    'Value',value0, ...
    'Units','Normalized','Position',[0.30  .90  0.30  0.08], ...
    'FontWeight','bold','FontSize',10, ...
    'HorizontalAlignment','left', ...
    'ForegroundColor','black','BackgroundColor',figclr,...
    'CallBack',...
    [callbackstr,...
    'set(ans.sizelabel,''Visible'',''on'');',...
    'set(ans.ranglabel,''Visible'',''off'');clear ans']);

h.radio2 = uicontrol(h.fig,'Style','Radio','String', 'Range', ...
    'Value',~value0, ...
    'Units','Normalized','Position', [0.65  .90  0.30  0.08], ...
    'FontWeight','bold','FontSize',9, ...
    'ForegroundColor','black','BackgroundColor',figclr,...
    'CallBack',...
    [callbackstr,...
    'set(ans.sizelabel,''Visible'',''off'');',...
    'set(ans.ranglabel,''Visible'',''on'');clear ans']);

set(h.radio1,'UserData',h.radio2)
set(h.radio2,'UserData',h.radio1)

%  Map Text and Edit Box
h.maplabel = uicontrol(h.fig,'Style','Text','String','Map variable:', ...
    'Units','Normalized','Position',[0.05  0.81  0.90  0.07], ...
    'Tag','maplabel','FontWeight','bold','FontSize',10, ...
    'HorizontalAlignment','left', ...
    'ForegroundColor','black','BackgroundColor',figclr);

h.mapedit = uicontrol(h.fig,'Style','Edit','String', map0, ...
    'Units','Normalized','Position',[0.05  .72  0.70  0.08], ...
    'Tag','mapedit','FontWeight','bold','FontSize',10, ...
    'HorizontalAlignment','left', ...
    'ForegroundColor','black','BackgroundColor',figclr);

h.maplist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position',[0.77  .72  0.18  0.08], ...
    'Tag','maplist','FontWeight','bold','FontSize',9, ...
    'ForegroundColor','black','BackgroundColor',figclr,...
    'Interruptible','on','UserData',h.mapedit,...
    'CallBack','varpick(who,get(gco,''UserData''))');

%  Size Text and Edit Box
h.sizelabel = uicontrol(h.fig,'Style','Text','String','Colormap Size (optional):', ...
    'Units','Normalized','Position',[0.05  0.63  0.90  0.07], ...
    'Tag', 'sizelabel','FontWeight','bold','FontSize',10, ...
    'HorizontalAlignment','left', ...
    'ForegroundColor','black','BackgroundColor',figclr,'Visible','off');

h.ranglabel = uicontrol(h.fig,'Style','Text','String','Altitude Range (optional):', ...
    'Units','Normalized','Position',[0.05  0.63  0.90  0.07], ...
    'FontWeight','bold','FontSize',10, ...
    'Tag','rangelabel','HorizontalAlignment','left', ...
    'ForegroundColor','black','BackgroundColor',figclr,'Visible','off');

if value0
    set(h.sizelabel,'Visible','on');
else
    set(h.ranglabel,'Visible','on');
end

h.sizeedit = uicontrol(h.fig,'Style','Edit','String', size0, ...
    'Units','Normalized','Position',[0.05  .54  0.70  0.08], ...
    'FontWeight','bold','FontSize',10, ...
    'Tag','sizeedit','HorizontalAlignment','left', ...
    'ForegroundColor','black','BackgroundColor',figclr);

h.sizelist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position',[0.77  .54  0.18  0.08], ...
    'Tag','sizelist','FontWeight','bold','FontSize',9, ...
    'ForegroundColor','black','BackgroundColor',figclr,...
    'Interruptible','on','UserData',h.sizeedit,...
    'CallBack','varpick(who,get(gco,''UserData''))');

%  RGB Sea Text and Edit Box
h.rgbslabel = uicontrol(h.fig,'Style','Text','String','RGB Sea (optional):', ...
    'Units','Normalized','Position',[0.05  0.45  0.90  0.07], ...
    'Tag','rgbslabel','FontWeight','bold', 'FontSize',10, ...
    'HorizontalAlignment','left', ...
    'ForegroundColor','black','BackgroundColor',figclr);

h.rgbsedit = uicontrol(h.fig,'Style','Edit','String', rgbs0, ...
    'Units','Normalized','Position',[0.05  .36  0.70  0.08], ...
    'Tag','rgbsedit','FontWeight','bold','FontSize',10, ...
    'HorizontalAlignment','left', ...
    'ForegroundColor','black','BackgroundColor',figclr);

h.rgbslist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position', [0.77  .36  0.18  0.08], ...
    'Tag','rgbslist','FontWeight','bold','FontSize',9, ...
    'ForegroundColor','black','BackgroundColor',figclr,...
    'Interruptible','on','UserData',h.rgbsedit,...
    'CallBack','varpick(who,get(gco,''UserData''))');

%  Other Properties Text and Edit Box
h.rgbllabel = uicontrol(h.fig,'Style','Text','String','RGB Land (optional):', ...
    'Units','Normalized','Position',[0.05  0.27  0.90  0.07], ...
    'Tag','rgbllabel','FontWeight','bold','FontSize',10, ...
    'HorizontalAlignment','left', ...
    'ForegroundColor', 'black','BackgroundColor',figclr);

h.rgbledit = uicontrol(h.fig,'Style','Edit','String', rgbl0, ...
    'Units','Normalized','Position', [0.05  .18  0.70  0.08], ...
    'Tag','rgbledit','FontWeight','bold','FontSize',10, ...
    'HorizontalAlignment','left','Max',2,...
    'ForegroundColor','black','BackgroundColor',figclr);

h.rgbllist = uicontrol(h.fig,'Style','Push','String', 'List', ...
    'Units','Normalized','Position',[0.77  .18  0.18  0.08], ...
    'Tag','rgbllist','FontWeight','bold','FontSize',9, ...
    'ForegroundColor','black','BackgroundColor',figclr,...
    'Interruptible','on','UserData',h.rgbledit,...
    'CallBack','varpick(who,get(gco,''UserData''))');

%  Buttons to exit the modal dialog
h.apply = uicontrol(h.fig,'Style','Push','String', 'Apply', ...
    'Units','Normalized','Position',[0.06  0.02  0.26  0.10], ...
    'Tag','applybtn','FontWeight','bold','FontSize',10,...
    'HorizontalAlignment','center',...
    'ForegroundColor','black','BackgroundColor',figclr,...
    'CallBack','uiresume');

h.cancel = uicontrol(h.fig,'Style','Push','String', 'Cancel', ...
    'Units','Normalized','Position',[0.68  0.02  0.26  0.10], ...
    'Tag','cancelbtn','FontWeight','bold','FontSize',10, ...
    'HorizontalAlignment','center', ...
    'ForegroundColor','black','BackgroundColor',figclr,...
    'CallBack','uiresume');

% Set TooltipString values to provide help for certain UI elements.

set(h.maplist,   'TooltipString', tooltipHelpStrings('ListButton'))
set(h.sizelist,  'TooltipString', tooltipHelpStrings('ListButton'))
set(h.rgbslist,  'TooltipString', tooltipHelpStrings('ListButton'))
set(h.rgbllist,  'TooltipString', tooltipHelpStrings('ListButton'))
set(h.radiolabel,'TooltipString', tooltipHelpStrings('DEMMode'))
set(h.maplabel,  'TooltipString', tooltipHelpStrings('Map'))
set(h.sizelabel, 'TooltipString', tooltipHelpStrings('DEMSize'))
set(h.ranglabel, 'TooltipString', tooltipHelpStrings('DEMRange'))
set(h.rgbslabel, 'TooltipString', tooltipHelpStrings('RGBSea'))
set(h.rgbllabel, 'TooltipString', tooltipHelpStrings('RGBLand'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))

set(h.fig,'Visible','on','UserData',h)
