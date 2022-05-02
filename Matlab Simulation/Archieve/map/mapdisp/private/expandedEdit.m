function expandedEdit(hndl,titlestr)
% EXPANDEDEDIT activates a modal dialog box to allow edits of large entries
% in the edit boxes.  The button activating this function must store the
% associated edit box handle in its UserData.

% Copyright 2013-2015 The MathWorks, Inc.

edithndl = get(hndl,'UserData');

h.figure = dialog('Name','Expanded Edit Field', ...
                  'Units','Points',  'Position',72*[2 1 3.5 2], 'Visible','off');
colordef(h.figure,'white');
figclr = get(h.figure,'Color');

% shift window if it comes up partly offscreen

shiftwin(h.figure)

%  Display title string and edit box

h.text = uicontrol(h.figure, 'Style','text', 'String',titlestr,...
            'Units','normalized', 'Position',[.05 .85 .90 .10], ...
	        'BackgroundColor',figclr, 'ForegroundColor','black', ...
	        'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.edit = uicontrol(h.figure, 'Style','edit', 'String', get(edithndl,'String'), ...
	        'Units','normalized', 'Position',[0.05 0.20 0.90 0.60], ...
	        'BackgroundColor',figclr, 'ForegroundColor','black', 'Max',2, ...
	        'FontSize',10,  'FontWeight','bold', 'HorizontalAlignment','left');

h.apply = uicontrol(h.figure, 'Style','push', 'String', 'OK', ...
	'Units','normalized', 'Position',[0.35 0.03 0.30 0.14], ...
	'BackgroundColor',figclr, 'ForegroundColor','black', ...
	'FontSize',10,  'FontWeight','bold', 'Callback', 'uiresume');

set(h.figure,'Visible','on')

uiwait(h.figure)

if ~ishghandle(h.figure)
    return
end

set(edithndl,'String',get(h.edit,'String'))   %  Update associated edit box
delete(h.figure)
