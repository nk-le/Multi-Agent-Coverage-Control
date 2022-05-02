function colorm(varargin)
%COLORM Create index map colormaps
%
%  COLORM will be removed in a future release.
%
%  COLORM(DATAGRID, REFVEC) creates an interactive tool for creating
%  colormaps for indexed regular data grids.  Once created, the colormap
%  can be saved to the workspace.

% Copyright 1996-2014 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(1,2)
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
        validateattributes(map,{'numeric'}, {'integer','nonempty','positive'}, ...
            mfilename, 'DATAGRID', 1);
    end
end

switch action
    case 'initialize'    %  Initialize the tool
        
        h = colorinit;
        h.mapcodes = unique(map(:));
        set(h.codes,'String',h.mapcodes)
        
        if any(map(:) == 0)
            Z = map + 1;
        else
            Z = map;
        end
        grid2image(Z,refvec, 'Parent', h.axes)
        
        fontSize = 9;
        set(h.axes, 'FontSize', fontSize)
        xlabel = get(h.axes, 'XLabel');
        ylabel = get(h.axes, 'YLabel');
        set(xlabel, 'FontSize', fontSize);
        set(ylabel, 'FontSize', fontSize);

        %  Set data for later retrieval
        
        h.map = map;
        h.refvec = refvec;
        
        set(h.figure,'Visible','on','UserData',h)
        colorm('mapcodes')
        
    case 'mapcodes'      %  Select the map code popup menu
        
        h = get(get(0,'CurrentFigure'),'UserData');
        
        mapindx = get(h.codes,'Value');
        clrvec  = get(h.colorpopup,'UserData');
        clrmap  = get(h.figure,'ColorMap');
        
        %  Find the index to the color popup menu for the selected code.
        
        if h.mapcodes(mapindx) <= size(clrmap,1)
            rgbcodes = clrmap(h.mapcodes(mapindx),:);
            clrvec.val = rgbcodes;
        else
            rgbcodes = [NaN NaN NaN];
        end
        
        clrindx = find(clrvec.rgb(:,1) == rgbcodes(1) & ...
            clrvec.rgb(:,2) == rgbcodes(2) & ...
            clrvec.rgb(:,3) == rgbcodes(3) );
        if isempty(clrindx);   clrindx = 1;   end
        
        %  Set the value of the popup menu
        
        set(h.colorpopup,'Value',clrindx,'UserData',clrvec);
        
        
    case 'colorset'      %  Select the color name popup menu
        
        clrpopup;
        h = get(get(0,'CurrentFigure'),'UserData');
        codestr = get(h.codes,'String');
        val = get(h.codes,'Value');
        mapindx = str2double(codestr(val,:));
        clrvec  = get(h.colorpopup,'UserData');
        clrmap  = get(h.figure,'ColorMap');
        
        clrmap(mapindx,1:3) = clrvec.val;
        
        %  Truncate the colormap if entries exceed the maximum map code
        
        maxcode = max(h.mapcodes);
        if size(clrmap,1) > maxcode
            clrmap = clrmap(1:maxcode,:);
        end
        
        colormap(clrmap)
        
        
    case 'save'          %  Save the current colormap
        
        h  = get(get(0,'CurrentFigure'),'UserData');
        
        %  Get the variable name inputs
        
        prompt={'Colormap Variable:'};
        answer={'clrmap'};
        lineNo=1;
        title='Enter the Colormap variable name';
        
        
        while ~isempty(answer)   %  Prompt until correct, or cancel
            answer=inputdlg(prompt,title,lineNo,answer);
            
            breakflag = 1;
            if ~isempty(answer)   % OK button pushed
                if isempty(answer{1})
                    breakflag = 0;
                    uiwait(errordlg('Variable name must be supplied',...
                        'Colormap Error','modal'))
                else
                    if strcmp(answer{1},varargin{1})
                        Btn=questdlg('Replace existing variable?', ...
                            'Save Map Data', 'Yes','No','No');
                        if strcmp(Btn,'No');   breakflag = 0;  end
                    end
                end
            end
            
            if breakflag;  break;   end
        end
        
        if isempty(answer);   return;   end   %  Cancel pushed
        
        assignin('base',answer{1},get(h.figure,'ColorMap'))
        
        
    case 'load'        %  Load a colormap variable
        
        %  Get the variable name inputs
        
        prompt={'Colormap to Apply:'};
        answer={'clrmap'};
        lineNo=1;
        title='Apply Colormap';
        
        
        while ~isempty(answer)   %  Prompt until correct, or cancel
            
            answer=inputdlg(prompt,title,lineNo,answer);
            
            breakflag = 1;
            if ~isempty(answer)   % OK button pushed
                if isempty(answer{1})
                    breakflag = 0;
                    uiwait(errordlg('Variable name must be supplied',...
                        'Colormap Error','modal'))
                else
                    try
                        evalin('base', sprintf('colormap(%s)', answer{1}));
                    catch e
                        uiwait(errordlg(e.message,'Colormap Error','modal'));
                        breakflag = 0;
                    end
                end
            end
            
            if breakflag;  break;   end
        end
        
        
    case 'select'        %  Select a code from the map
        
        colorm('zoomoff')
        h  = get(get(0,'CurrentFigure'),'UserData');
        
        [long,lat] = ginput(1);
        code       = ltln2val(h.map,h.refvec,lat,long);
        if ~isempty(code)
            indx       = find(code == h.mapcodes);
            set(h.codes,'Value',indx);
        end
        
    case 'zoomoff'     %  Turn zoom off
        f = get(0,'CurrentFigure');
        hmenu = findobj(f,'type','uimenu','label','Off');
        zoom(f,'off')
        set(hmenu,'Label','On','Callback','colorm(''zoomon'')')
        
    case 'zoomon'      %  Turn zoom on
        f = get(0,'CurrentFigure');
        hmenu = findobj(f,'type','uimenu','label','On');
        zoom(f,'on')
        set(hmenu,'Label','Off','Callback','colorm(''zoomoff'')')
        
    case 'close'         %  Close figure
        ButtonName = questdlg('Are You Sure?','Confirm Closing','Yes','No','No');
        if strcmp(ButtonName,'Yes');   delete(get(0,'CurrentFigure'));   end
end


%**************************************************************************
%**************************************************************************
%**************************************************************************


function h = colorinit

%  COLORINIT creates the interface window for COLORM.

%  Written by:  E. Byrns, E. Brown

%  Initialize some variables used

names  = {'custom','black','white','red','cyan','green',...
    'yellow','blue','magenta'};
colorvec.rgb = [NaN NaN NaN; 0 0 0; 1 1 1; 1 0 0; 0 1 1;
    0 1 0; 1 1 0; 0 0 1; 1 0 1];
initpopup = 1;
colorvec.val = [];

%  Control panel window
%  Creating invisible figure flickers patches while window draws.

h.figure = figure( ...
    'Visible','off', ...
    'Name', 'Colormap',...
    'Toolbar', 'none', ...
    'CloseRequestFcn','colorm(''close'')');

colordef(h.figure,'white')
colormap('prism')
figclr = get(h.figure,'Color');

%  Add Zoom and Color menus
hmenu = uimenu(h.figure,'Label','Zoom');
uimenu(hmenu,'Label','On','Callback',@(~,~) colorm('zoomon'))
clrmenu(h.figure);

set(gca,'Units','Normalized','Position',[0.13 0.20 0.80 0.72])
h.axes = gca;


%  Map codes popup object
bottom = .05;
h.codelabel = uicontrol(h.figure, 'Style', 'Text', ...
    'Units', 'Normalized', 'Position', [0.37  bottom  0.06  0.04], ...
    'String','Codes', 'HorizontalAlignment','left',...
    'BackgroundColor',figclr, 'ForegroundColor','black' );


h.codes = uicontrol(h.figure, 'Style', 'popup',...
    'Units', 'Normalized', 'Position', [0.44  bottom  0.15  0.05],  ...
    'String', 'PlaceHolder', 'CallBack', 'colorm(''mapcodes'')',...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  Color selection popup object

h.colorlabel = uicontrol(h.figure, 'Style', 'Text', ...
    'Units', 'Normalized', 'Position', [0.61  bottom  0.06  0.04], ...
    'String','Colors', 'HorizontalAlignment','left',...
    'BackgroundColor',figclr, 'ForegroundColor','black' );


h.colorpopup = uicontrol(h.figure, 'Style', 'popup',...
    'Units', 'Normalized', 'Position', [0.68  bottom  0.15  0.05],  ...
    'String', names, 'UserData',colorvec, ...
    'Value', initpopup, 'CallBack', 'colorm(''colorset'')' ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  Load button

h.load  = uicontrol(h.figure, 'Style', 'push', 'String','Load',...
    'Units', 'Normalized', 'Position', [0.13  bottom 0.10  0.06], ...
    'CallBack', 'colorm(''load'')' ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  Select button

h.select  = uicontrol(h.figure, 'Style', 'push', 'String','Select', ...
    'Units', 'Normalized', 'Position', [0.25  bottom  0.10  0.06], ...
    'CallBack', 'colorm(''select'');colorm(''mapcodes'')' ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );

%  Save button

h.save  = uicontrol(h.figure, 'Style', 'push', 'String','Save', ...
    'Units', 'Normalized', 'Position', [0.87  bottom  0.10  0.06], ...
    'CallBack', 'colorm(''save'',who)' ,...
    'BackgroundColor',figclr, 'ForegroundColor','black' );
