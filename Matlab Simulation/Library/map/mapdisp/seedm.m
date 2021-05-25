function seedm(varargin)
%SEEDM Interactively fill regular data grids with seed values
%
%  SEEDM will be removed in a future release.
%
%  SEEDM(Z,refvec) creates an interactive tool for encoding regular data
%  grids.  Seeds can be interactively specified and the encoded grid
%  generated.  The encoded grid can then be saved back to the workspace.

% Copyright 1996-2014 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(1, 2)

if nargin == 1
    action = varargin{1};
elseif nargin == 2
    if ischar(varargin{1})
        action = varargin{1};
        varargin(1) = [];
    else
        action = 'initialize';
        map = varargin{1};
        refvec = varargin{2};
    end
end

switch action
    case 'initialize'    %  Initialize the display
        h = seedinit;
        if any(map(:) == 0)
            Z = map + 1;
        else
            Z = map;
        end
        h.image = grid2image(Z, refvec, 'Parent', h.axes);
        set(h.axes, 'NextPlot', 'add');
        
        fontSize = 9;
        set(h.axes, 'FontSize', fontSize)
        xlabel = get(h.axes, 'XLabel');
        ylabel = get(h.axes, 'YLabel');
        set(xlabel, 'FontSize', fontSize);
        set(ylabel, 'FontSize', fontSize);
        zoom(ancestor(h.axes,'figure'),'on')
        
        %  Set data for later retrieval
        h.map = map;
        h.refvec = refvec;
        h.seeds = [];
        set(h.figure, 'Visible', 'on', 'UserData', h)
        
    case 'get'
        %  Get seeds for map
        f = get(0,'CurrentFigure');
        h = get(f,'UserData');
        
        nseeds  = str2double(get(h.seednum,'String'));
        seedval = str2double(get(h.seedval,'String'));
        
        if ~isnan(nseeds) && ~isnan(seedval)
            seedmat = getseeds(h.map,h.refvec,nseeds,seedval);
            h.seeds = [h.seeds; seedmat];
        else
            error('map:seedm:mapdispError', 'Blank number of seeds or value.')
        end
        
        % Turn zoom off
        zoom(f,'off')
        
        % Turn zoom back on
        seedm('zoomon')
        
        set(h.figure,'UserData',h);
        
    case 'seed'
        %  Seed the map
        f = get(0,'CurrentFigure');
        h = get(f,'UserData');
        h.map = encodem(h.map,h.seeds);
        h = refreshImage(f,h);
        set(h.figure,'UserData',h)
        
    case 'change'
        %  Change map codes
        f = get(0,'CurrentFigure');
        h = get(f,'UserData');
        
        oldcode = str2double(get(h.from,'String'));
        if isnan(oldcode)
            oldcode = 0;
        end
        
        newcode = str2double(get(h.to,'String'));
        if isnan(newcode)
            newcode = 0;
        end
        
        h.map = changem(h.map,newcode,oldcode);
        h = refreshImage(f,h);
        set(h.figure,'UserData',h)
        
    case 'clear'
        %  Clear the map seeds
        h = get(get(0,'CurrentFigure'),'UserData');
        h.seeds = [];
        set(h.figure,'UserData',h)
        
    case 'save'
        h = get(get(0,'CurrentFigure'),'UserData');
        
        %  Get the variable name inputs
        prompt={'Map Variable:'};
        answer={'map'};
        lineNo=1;
        title='Enter the Surface Map variable name';
        
        while ~isempty(answer)
            %  Prompt until correct, or cancel
            answer=inputdlg(prompt,title,lineNo,answer);
            
            breakflag = 1;
            if ~isempty(answer)   % OK button pushed
                if isempty(answer{1})
                    breakflag = 0;
                    uiwait(errordlg('Variable name must be supplied',...
                        'Seed Map Error','modal'))
                else
                    if strcmp(answer{1}, varargin{1})
                        Btn=questdlg('Replace existing variable?', ...
                            'Save Map Data', 'Yes','No','No');
                        if strcmp(Btn,'No')
                            breakflag = 0;
                        end
                    end
                end
            end
            
            if breakflag
                break;
            end
        end
        
        if isempty(answer)
            %  Cancel pushed
            return
        end
        
        assignin('base',answer{1},h.map)
        
    case 'zoomoff'
        %  Turn zoom off
        f = get(0,'CurrentFigure');
        hmenu = findobj(f,'type','uimenu','label','Off');
        zoom(f,'off')
        set(hmenu,'Label','On','Callback','seedm(''zoomon'')')
        
    case 'zoomon'
        %  Turn zoom on
        f = get(0,'CurrentFigure');
        hmenu = findobj(f,'type','uimenu','label','On');
        zoom(f,'on')
        set(hmenu,'Label','Off','Callback','seedm(''zoomoff'')')
        
    case 'close'
        %  Close figure
        ButtonName = questdlg('Are You Sure?','Confirm Closing','Yes','No','Yes');
        if strcmp(ButtonName,'Yes')
            delete(get(0,'CurrentFigure'))
        end
end

%--------------------------------------------------------------------------

function h = seedinit
% Create the interface window for SEEDM.

%  Control panel window
%  Creating invisible figure flickers patches while window draws.

hfig = figure(...
    'Visible','off', ...
    'Toolbar', 'none', ...
    'Name', 'Seed Map',...
    'CloseRequestFcn','seedm(''close'')');
h.figure = hfig;

colordef(hfig,'white')
colormap('prism')
figclr = get(hfig,'Color');

hmenu = uimenu(hfig,'Label','Zoom');   %  Add the menu items
uimenu(hmenu,'Label','Off','Callback','seedm(''zoomoff'')')
clrmenu;

set(gca,'Units','Normalized','Position',[0.13 0.20 0.80 0.72])
h.axes = gca;

%  Get button
h.get = uicontrol(hfig, 'Style', 'push',...
    'Units', 'Normalized','Position', [0.13  0.08  0.10  0.06],...
    'String','Get', 'CallBack', 'seedm(''get'')' ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  Seed button
h.seed = uicontrol(hfig, 'Style', 'push',...
    'Units', 'Normalized', 'Position', [0.25  0.08  0.10  0.06], ...
    'String','Fill In', 'CallBack', 'seedm(''seed'')' ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  Clear button
h.clear = uicontrol(hfig, 'Style', 'push',...
    'Units', 'Normalized', 'Position', [0.13  0.01  0.10  0.06], ...
    'String','Reset', 'CallBack', 'seedm(''clear'')' ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  Change button
h.change = uicontrol(hfig, 'Style', 'push',...
    'Units', 'Normalized','Position', [0.25  0.01  0.10  0.06], ...
    'String','Change', 'CallBack', 'seedm(''change'')',...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  Save button
h.save  = uicontrol(hfig, 'Style', 'push',...
    'Units', 'Normalized', 'Position', [0.85  0.01  0.10  0.06], ...
    'String','Save', 'CallBack', 'seedm(''save'',who)',...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  Number of seeds edit object
h.seedlabel = uicontrol(hfig, 'Style', 'Text', ...
    'Units', 'Normalized', 'Position', [0.40  0.06  0.11  0.04], ...
    'String','# of Seeds', 'HorizontalAlignment','left',...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

h.seednum = uicontrol(hfig, 'Style', 'edit', ...
    'Units', 'Normalized','Position', [0.52  0.06  0.09  0.05],...
    'Max', 1 ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  Seed value edit object
h.vallabel = uicontrol(hfig, 'Style', 'Text', ...
    'Units', 'Normalized','Position', [0.64  0.06  0.07  0.04], ...
    'String','Value', 'HorizontalAlignment','left',...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

h.seedval = uicontrol(hfig, 'Style', 'edit', ...
    'Units', 'Normalized','Position', [0.72  0.06  0.09  0.05],...
    'Max', 1 ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  From/To edit object
h.fromlabel = uicontrol(hfig, 'Style', 'Text', ...
    'Units', 'Normalized', 'Position', [0.40  0.01  0.09  0.04], ...
    'String','From/To', 'HorizontalAlignment','left',...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

h.from = uicontrol(hfig, 'Style', 'edit', ...
    'Units', 'Normalized', 'Position', [0.52  0.005  0.05  0.05], ...
    'Max', 1 ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

h.to = uicontrol(hfig, 'Style', 'edit', ...
    'Units', 'Normalized', 'Position', [0.59  0.005  0.05  0.05], ...
    'Max', 1 ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%--------------------------------------------------------------------------

function h = refreshImage(f,h)
% Refresh image.

% Turn zoom off
zoom(f,'off')

% Delete image.
if isfield(h, 'image') && ishghandle(h.image)
    delete(h.image);
end

% Create new image.
if any(h.map(:) == 0)
    Z = h.map + 1;
else
    Z = h.map;
end
h.image = grid2image(Z, h.refvec, 'Parent', h.axes);

fontSize = 9;
xlabel = get(h.axes, 'XLabel');
ylabel = get(h.axes, 'YLabel');
set(xlabel, 'FontSize', fontSize);
set(ylabel, 'FontSize', fontSize);

%  Turn zoom back on
seedm('zoomon')
