function uimaptbx(h,~)
%UIMAPTBX Process button down callbacks for mapped objects
%
%   UIMAPTBX processes the mouse events for objects displayed using the
%   Mapping Toolbox, as long as no WindowButtonDownFcn is currently
%   assigned.  To assign it to an object, set the ButtonDownFcn to
%   @uimaptbx. This is the default setting for many Mapping Toolbox
%   objects.
%
%   If UIMAPTBX is assigned to an object, the following mouse events are
%   recognized.  Single click and hold on an object displays its tag, or
%   type if no tag is specified.  Double click or alternative click on an
%   object opens up the Property Editor allowing object properties to be
%   changed. Extended click on an object allows the map properties to be
%   edited.
%
%   For Macintosh:  Extend click - Shift click mouse button
%                   Alternate click - Option click mouse button
% 
%   For Windows:    Extend click - Shift click left button or both buttons
%                   Alternate click - Control click left button or right button
%
%   For X-Windows:  Extend click - Shift click left button or middle button
%                   Alternate click - Control click left button or right button

% Copyright 1996-2016 The MathWorks, Inc.

if nargin == 0
    h = gcbo;
elseif ~isscalar(h) || ~ishghandle(h)
    uiwait(errordlg('Scalar HG handle required in UIMAPTBX',...
        'Mapping Toolbox Error','modal'))
    return
end

f = ancestor(h,'figure');

%  Return if there is a WindowButtonDownFcn active.

if ~isempty(get(f,'WindowButtonDownFcn'))
    return
end

%  Switch on the mouse selection type

switch get(f,'SelectionType')
    case 'normal',       tagui(h)
    case 'open',         propedit(h)
    case 'extend'
        %  Click on axes or an object on the axes
        if ishghandle(h,'axes')
            axesmui(h)
        else
            axesmui(get(h,'Parent'))
        end
    case 'alt'
        switch get(h,'Type')
            case 'axes',     axesmui(h);
            case 'surface',  propedit(h);
            case 'line',     propedit(h);
            case 'patch',    propedit(h);
            case 'text',     propedit(h);
            case 'figure',   propedit(h);
        end
end

%--------------------------------------------------------------------------

function tagui(h)
%TAGUI  Interactive display of line tags
%
%  TAGUI(h) allows users to interactively display an object's
%  tag at the lower left hand corner of the figure window.
%  When the button is released, then this display is deleted.

f = ancestor(h,'figure');

% Lock the current state of the toolbar, so it doesn't bounce on and
% off with each mouse click

originalToolbarState = get(f,'toolbar');
plotedit(f,'locktoolbarvisibility');

%  Create the display object

name = namem(h);
pos = [2 2 10*length(name) 20];
hText = uicontrol('Style','Text','String',name,...
    'Units','Points','Position',pos,...
    'FontWeight','normal','FontSize',12,...
    'HorizontalAlignment','left','Tag','TextObjectToDelete',...
    'ForegroundColor','black','BackgroundColor',get(f,'Color'));

% Save the toolbar's state for when the button is released
setappdata(hText,'OriginalToolbarState',originalToolbarState);

% Save the figure's WindowButtonUpFcn, then reset it.
setappdata(hText,'OriginalButtonUpFcn',get(f,'WindowButtonUpFcn'));
set(f,'WindowButtonUpFcn',@taguiButtonUp);

%--------------------------------------------------------------------------

function taguiButtonUp(f,~)
% Restore the original ButtonUpFunction and toolbar state of the figure f,
% and delete the text object constructed by tagui.

h = findobj(f,'Type','uicontrol','Tag','TextObjectToDelete');
if ~isempty(h)
    set(f,'WindowButtonUpFcn',getappdata(h,'OriginalButtonUpFcn'));
    % Restore the toolbar's state
    originalToolbarState = getappdata(h,'OriginalToolbarState');
    delete(h);
    set(f,'toolbar',originalToolbarState)
end
