function h = lengthUnitDialog(unitstring, geoidstr, basegeoid)
% lengthUnitDialog constructs a modal dialog allowing a choice of length
% unit and normalizing spheroid.

% Copyright 1996-2015 The MathWorks, Inc.

units = {'Kilometers','Statute Miles','Nautical Miles','Radians'};
indx = find(strcmpi(unitstring,units));  %  Current units

h.figure = dialog('Name','Define Range Units', ...
                  'Units','Points',  'Position',72*[0.10 0.5 5.3 1.5], 'Visible','off');
colordef(h.figure,'white');
figclr = get(h.figure,'Color');

% shift window if it comes up partly offscreen

shiftwin(h.figure)


%  Range unit label and popup box

h.poplabel = uicontrol(h.figure, 'Style','text', 'String','Range Units',...
            'Units','normalized', 'Position',[.05 .73 .40 .20], ...
	        'BackgroundColor',figclr, 'ForegroundColor','black', ...
	        'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.poprng = uicontrol(h.figure, 'Style','popup', 'String',units,...
            'Units','normalized', 'Position',[.48 .75 .47 .20], ...
	        'BackgroundColor',figclr, 'ForegroundColor','black', ...
			'HorizontalAlignment','left', 'Value',indx,...
	        'FontSize',10,  'FontWeight','bold');

%  Normalizing geoid label and edit box

h.geoidlabel = uicontrol(h.figure, 'Style','text', 'String','',...
            'Units','normalized', 'Position',[.05 .45 .40 .20], ...
	        'BackgroundColor',figclr, 'ForegroundColor','black', ...
	        'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.geoidedit = uicontrol(h.figure, 'Style','edit', 'String',geoidstr,...
            'Units','normalized', 'Position',[.48 .45 .47 .20], ...
	        'BackgroundColor',figclr, 'ForegroundColor','black', 'Max',1,...
	        'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

%  Apply, help and cancel buttons

h.cancel = uicontrol(h.figure, 'Style','push', 'String', 'Cancel', ...
	'Units','normalized', 'Position',[0.07 0.05 0.24 0.30], ...
	'BackgroundColor',figclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', ...
	'Callback', 'uiresume');

h.apply = uicontrol(h.figure, 'Style','push', 'String', 'Apply', ...
	'Units','normalized', 'Position',[0.69 0.05 0.24 0.30], ...
	'BackgroundColor',figclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold');

%  Set callbacks now that all fields of h are populated.

set(h.poprng,    'Callback', @(~,~) rangepopup_cb(h))
set(h.geoidedit, 'Callback', @(~,~) geoidedit_cb(h))
set(h.apply,     'Callback', @(~,~) rangeapply_cb(h))

%  Set data needed for callback processing

displaygeoid = ['[',num2str(basegeoid(1),'%8.3f'),'  ', ...
                    num2str(basegeoid(2),'%8.5f'),']'];

set(h.geoidedit,'UserData',displaygeoid)
set(h.geoidlabel,'UserData',get(h.geoidedit,'String'))

% Use TooltipString values to provide help for certain UI elements

set(h.poplabel,  'TooltipString', tooltipHelpStrings('RangePopup'))
set(h.geoidlabel,'TooltipString', tooltipHelpStrings('NormalizingGeoid'))
set(h.cancel,    'TooltipString', tooltipHelpStrings('Cancel'))
set(h.apply,     'TooltipString', tooltipHelpStrings('Apply'))

%  Turn dialog on and save object handles

set(h.figure,'Visible','on','UserData',h)

%  Process/initialize the popup menu

rangepopup_cb(h)

%-----------------------------------------------------------------------

function geoidedit_cb(h)
%  Callback for normalizing geoid edit.

%  Save current entry for later restoration
set(h.geoidlabel,'UserData', get(h.geoidedit,'String'))

%--------------------------------------------------------------------------

function rangeapply_cb(h)

%  Range units apply button callback
str = get(h.geoidedit,'String');               %  Normalizing entry

%  Reset the last error function and then try to evaluate the
%  normalizing entry

errorflag = false;
if ~isempty(str)
    try
        r = [];
        eval(['r=',str,';'])
    catch e
        errorflag = true;
        errmsg = e.message;
    end
else
    r = [];
end

if errorflag     %  Incorrect string entry
    uiwait(errordlg(errmsg,'Normalizing Geoid','modal'))
elseif isempty(r)    %  Empty string entry
    uiwait(errordlg('Invalid geoid expression','Normalizing Geoid','modal'))
else                 %  Correct string entry
    uiresume        %  Returns to the uiwait in 'rangeunits'
end

%--------------------------------------------------------------------------

function rangepopup_cb(h)
%  Range popup function

%  These are the modal handles
if get(h.poprng,'Value') == 4
    set(h.geoidlabel,'UserData',get(h.geoidedit,'String'),...
        'String','Normalizing Geoid')
    set(h.geoidedit,'Style','text',...
        'String',get(h.geoidedit,'UserData'))
else
    set(h.geoidlabel, 'String','Normalizing Geoid (km)')
    set(h.geoidedit,'Style','edit',...
        'String',get(h.geoidlabel,'UserData'))
end
