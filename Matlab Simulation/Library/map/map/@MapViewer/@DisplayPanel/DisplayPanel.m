function this = DisplayPanel(viewer)
%DisplayPanel

% Copyright 2003-2016 The MathWorks, Inc.

this = MapViewer.DisplayPanel;

viewerPosition = viewer.getFigurePositionInPoints;
borderWidth = 2;
panelWidth = viewerPosition(3) - 2*borderWidth;
panelHeight = 54;
position = [borderWidth, borderWidth, panelWidth, panelHeight];

this.LayoutPanel = uipanel( ...
    'Parent', viewer.Figure, ...
    'Units', 'points', ...
    'BorderType', 'beveledin',...
    'BorderWidth', borderWidth  ,...
    'Position', position, ...
    'Visible', 'on', ...
    'HandleVisibility', 'off');

viewer.Figure.Color = this.LayoutPanel.BackgroundColor;

this.MapUnits = mapUnitList();

% Construct three subpanels to manage the horizontal placement.

% Position elements in characters
pos.BoxWidth = 20;
pos.BoxHeight = 1.5;
pos.TextHeight = 1.25;
pos.Row1Bottom = 1.8;
pos.Row2Bottom = 0.1;
pos.PanelHeight = 3.5;

% Update panel height
this.LayoutPanel.Units = 'characters';
this.LayoutPanel.Position(4) = pos.PanelHeight + 0.1;
this.LayoutPanel.Units = 'points';
this.LayoutPanel.Position(4) = this.LayoutPanel.Position(4) + 2*borderWidth;

xyPanel = createXYPanel(this, viewer, pos);
scaleAndUnitsPanel = createScaleAndUnitsPanel(this, viewer, pos);
activeLayerPanel = createActiveLayerPanel(this, viewer, pos);

% Reset the left edge of each subpanel to achieve even spacing.
resetSubpanelAlignment(this.layoutPanel, ...
    xyPanel, scaleAndUnitsPanel, activeLayerPanel)

% Reset spacing whenever layout panel is resized.
this.LayoutPanel.ResizeFcn = @(~,~) resetSubpanelAlignment(this.layoutPanel, ...
    xyPanel, scaleAndUnitsPanel, activeLayerPanel);
end

%-----------------------------------------------------------------------

function xyPanel = createXYPanel(this, viewer, pos)

% Create a subpanel to hold the X: and Y: strings and associated text
% boxes. Fill the entire layout panel for now; refine the width later.
xyPanel = uipanel( ...
    'Parent', this.LayoutPanel, ...
    'Units', this.LayoutPanel.Units, ...
    'BorderType', 'none',...
    'Position', this.LayoutPanel.Position, ...
    'Visible', 'off', ...
    'HandleVisibility', 'off', ...
    'Tag', 'XYPanel');

width = 4;
xStringPosition = [0 pos.Row1Bottom width pos.TextHeight];
yStringPosition = [0 pos.Row2Bottom width pos.TextHeight];

xString = uicontrol(xyPanel, 'String','X:', ...
    'Style', 'text', 'Enable', 'inactive',...
    'Units', 'characters', 'Position', xStringPosition, ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', viewer.Figure.Color);

yString = uicontrol(xyPanel, 'String', 'Y:', ...
    'Style', 'text',  'Enable', 'inactive', ...
    'Units', 'characters', 'Position', yStringPosition,...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', viewer.Figure.Color);

left = xString.Position(3);
xDisplayPosition = [left, pos.Row1Bottom, pos.BoxWidth, pos.BoxHeight];
yDisplayPosition = [left, pos.Row2Bottom, pos.BoxWidth, pos.BoxHeight];

% Add text boxes.
xDisplay = uicontrol(xyPanel, 'Style', 'edit', ...
    'String', ' ', 'Enable',' inactive', 'Tag', 'XDisplay', ...
    'Units', 'characters', 'Position', xDisplayPosition, ...
      'Tag', 'xReadout');

yDisplay = uicontrol(xyPanel, 'Style', 'edit', ...
    'String', ' ', 'Enable',' inactive', 'Tag', 'YDisplay', ...
    'Units', 'characters', 'Position', yDisplayPosition, ...
    'Tag', 'yReadout');

% Work in points from here on.
xString.Units = 'points';
yString.Units = 'points';
xDisplay.Units = 'points';
xyPanel.Units = 'points';

% Reduce panel width to fit actual content.
xyPanel.Position(3) ...
    = xString.Position(1) + xString.Position(3) + xDisplay.Position(3) + 2;

% Tell viewer where to find the text boxes.
viewer.XDisplay = xDisplay;
viewer.YDisplay = yDisplay;
end

%-----------------------------------------------------------------------

function scaleAndUnitsPanel = createScaleAndUnitsPanel(this, viewer, pos)

% Create a subpanel to hold the map scale text box, map units popup, and
% associated strings. Fill the entire layout panel for now; refine the
% width later.
scaleAndUnitsPanel = uipanel( ...
    'Parent', this.LayoutPanel, ...
    'Units', this.LayoutPanel.Units, ...
    'BorderType', 'none',...
    'Position', this.LayoutPanel.Position, ...
    'Visible', 'off', ...
    'HandleVisibility', 'off', ...
    'Tag', 'ScaleAndUnitsPanel');

% Provisional string placement.
scaleStringWidth = 10;
mapUnitsStringWidth = 15;
scaleStringPositionInCharacters    = [0 pos.Row1Bottom scaleStringWidth pos.TextHeight];
mapUnitsStringPositionInCharacters = [0 pos.Row2Bottom mapUnitsStringWidth pos.TextHeight];

scaleString = uicontrol(scaleAndUnitsPanel, 'String', 'Scale:',...
    'Style', 'text', 'Enable', 'inactive', 'Units', 'characters', ...
    'Position', scaleStringPositionInCharacters, ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', viewer.Figure.Color);

mapUnitsString = uicontrol(scaleAndUnitsPanel, 'String', 'Map units:',...
    'Style', 'text', 'Enable', 'inactive', 'Units', 'characters', ...
    'Position', mapUnitsStringPositionInCharacters, ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', viewer.Figure.Color);


left = mapUnitsString.Position(3);

scaleBoxPosition = [left, pos.Row1Bottom, pos.BoxWidth, pos.BoxHeight];
mapUnitsPosition = [left, pos.Row2Bottom, pos.BoxWidth, pos.BoxHeight];

units = 'characters';
scaleDisplay = createScaleDisplay(this, viewer, scaleAndUnitsPanel, units, scaleBoxPosition);

mapunits = this.MapUnits(:,1)';

mapUnitsDisplay = uicontrol(scaleAndUnitsPanel, ...
     'Style', 'popupmenu', ...
     'Units', 'characters', ...  
     'Position', mapUnitsPosition, ...
     'String', mapunits, ... 
     'HorizontalAlignment', 'left', ...
     'Callback', @(hSrc, event) localSetMapUnits(hSrc, event, this, viewer), ...
     'Tag', 'mapUnitsPulldown');

% Work in points from here on.
scaleString.Units = 'points';
scaleDisplay.Units = 'points';
mapUnitsString.Units = 'points';
mapUnitsDisplay.Units = 'points';

% Reduce panel width to fit actual content.
scaleAndUnitsPanel.Position(3) = ...
    + mapUnitsDisplay.Position(1) + mapUnitsDisplay.Position(3) + 5;

% Tell viewer and display panel where to find the scale and map units.
viewer.ScaleDisplay = scaleDisplay;
this.MapUnitsDisplay = mapUnitsDisplay;
end

%-----------------------------------------------------------------------

function scaleDisplay = createScaleDisplay(~, viewer, ...
    scaleAndUnitsPanel, units, scaleBoxPosition)


scaleDisplay = uicontrol(scaleAndUnitsPanel, ...
    'String', ' ', 'Style', 'Edit', ...
    'Enable', 'inactive', 'SelectionHighlight', 'off', ...
    'Units', units, 'Position', scaleBoxPosition, ...
    'Callback',@localSetScale, ...
    'Tag', 'scaleReadout');
                            
    function localSetScale(hSrc,event) %#ok<INUSD>
        err = false;
        str = get(hSrc,'String');
        % Remove commas
        str(str==',') = [];
        % Remove spaces
        str(isspace(str)) = [];
        if isempty(str)
            err = true;
        elseif isempty(strfind(str,':'))
            num = 1;
            den = str2double(str);
            if isempty(den)
                err = true;
            end
        else
            [values, count] = sscanf(str,'%f:%f');
            if count ~= 2
                err = true;
            else
                num = values(1);
                den = values(2);
            end
        end
        if err
            oldscale = viewer.Axis.getScale;
            viewer.Axis.setScale(oldscale);
        else
            viewer.Axis.setScale(num/den);
        end
    end

end

%-----------------------------------------------------------------------

function activeLayerPanel = createActiveLayerPanel(this, viewer, pos)

% Create a panel to hold the string and menu.
% Fill the panel for now; we'll refine the width later.
activeLayerPanel = uipanel( ...
    'Parent', this.LayoutPanel, ...
    'Units', this.LayoutPanel.Units, ...
    'BorderType', 'none',...
    'Position', this.LayoutPanel.Position, ...
    'Visible', 'off', ...
    'HandleVisibility', 'off', ...
    'Tag', 'activeLayerPanel');

menuWidth = 30;
activeLayerStringPosition  = [0 pos.Row1Bottom pos.BoxWidth pos.TextHeight];
activeLayerDisplayPosition = [0 pos.Row2Bottom menuWidth   pos.BoxHeight];

activeLayerString = uicontrol(activeLayerPanel, 'String', 'Active layer:', ...
    'Style','text','Units','characters', ...
    'Position', activeLayerStringPosition, ...
    'HorizontalAlignment','left','BackgroundColor',viewer.Figure.Color);

activeLayerDisplay = uicontrol(activeLayerPanel, ...
    'Style', 'popupmenu', 'Units', 'characters', ...
    'Position', activeLayerDisplayPosition, ...
    'String', [{'None'};viewer.getMap.getLayerOrder], ...
    'HorizontalAlignment', 'left', ...
    'Callback', {@localSetActiveLayer this viewer}, ...
    'Tag', 'activeLayerPulldown');

% Work in points from here on.
activeLayerString.Units = 'points';
activeLayerDisplay.Units  = 'points';

% Reduce panel width to fit actual content.
activeLayerPanel.Position(3) = activeLayerDisplay.Position(3) + 2;

% Tell display panel where to find the menu.
this.ActiveLayerDisplay = activeLayerDisplay;
end

%-----------------------------------------------------------------------

function resetSubpanelAlignment(layoutPanel, ...
    xyPanel, scaleAndUnitsPanel, activeLayerPanel)

% Hide subpanels.
xyPanel.Visible = 'off';
scaleAndUnitsPanel.Visible = 'off';
activeLayerPanel.Visible = 'off';

% Compute subpanel spacing.
w = layoutPanel.Position(3);

w1 = xyPanel.Position(3);
w2 = scaleAndUnitsPanel.Position(3);
w3 = activeLayerPanel.Position(3);

minSpacing = 2;
spacing = max(minSpacing,(w - (w1 + w2 + w3))/4);

% Shift subpanels horizontally.
activeLayerPanel.Position(1)   = spacing + w1 + spacing + w2 + spacing;
scaleAndUnitsPanel.Position(1) = spacing + w1 + spacing;
xyPanel.Position(1)            = spacing;

% Make subpanels visible.
xyPanel.Visible = 'on';
scaleAndUnitsPanel.Visible = 'on';
activeLayerPanel.Visible = 'on';
end

%-----------------------------------------------------------------------
    
function localSetActiveLayer(hSrc,event,this,viewer) %#ok<INUSL>
val = get(this.ActiveLayerDisplay,'Value');
strs = get(this.ActiveLayerDisplay,'String');
activelayer = strs{val};
setActiveLayer(viewer,activelayer);
end

%-----------------------------------------------------------------------

function localSetMapUnits(hSrc,event,this,viewer) %#ok<INUSL>
mapUnitsInd = get(this.MapUnitsDisplay,'Value');
mapUnitsTag = this.MapUnits{mapUnitsInd,2};

mapUnitsMenu = findobj(get(viewer.Figure,'Children'),'Label','Set Map Units');
selectedMapUnitMenu = findobj(get(mapUnitsMenu,'Children'),'Tag', mapUnitsTag);
set(get(mapUnitsMenu,'Children'),'Checked','off');
set(selectedMapUnitMenu,'Checked','on');

viewer.setMapUnits(mapUnitsTag)
end

%-----------------------------------------------------------------------

function list = mapUnitList()

list = { ...
    'None','none';
    'Kilometers','km';
    'Meters','m';
    % 'Centimeters','cm';
    % 'Milimeters','mm';
    % 'Microns','u';
    'Nautical Miles','nm';
    'International Feet','ft';
    % 'Inches','in';
    % 'Yards','yd';
    %  'International Miles','mi';
    'US Survey Feet','sf';
    % 'US Survey Miles','sm';
    };
end
