function this = SelectAreaState(viewer)
%

% Copyright 1996-2008 The MathWorks, Inc.

this = MapViewer.SelectAreaState;

this.MapViewer = viewer;
this.NewViewAreaMenu = viewer.NewViewAreaMenu;
this.ExportAreaMenu = viewer.ExportAreaMenu;

viewer.setDefaultState;
viewer.setCursor({'Pointer','crosshair'});

% Only valid on axes
ax = viewer.getAxes();
set(ax,'ButtonDownFcn',{@dragRect this viewer});
set(get(ax,'Children'),'ButtonDownFcn',{@dragRect this viewer});


function dragRect(hSrc,event,this,viewer) %#ok

is_normal_click = strcmpi(get(viewer.Figure,'SelectionType'),'normal');

% We ignore right click and double clicks
if ~is_normal_click
  return
end

deselectArea(this)

corner1 = viewer.getMapCurrentPoint;
corner1Figure = viewer.getFigureCurrentPoint;
showHidden = get(0,'ShowHiddenHandles');
set(0,'ShowHiddenHandles','on');
finalRect = rbbox;
set(0,'ShowHiddenHandles',showHidden);
corner2 = viewer.getMapCurrentPoint;
corner2Figure = viewer.getFigureCurrentPoint;

lower_left  = min(corner1,corner2);
upper_right = max(corner1,corner2);

p1Figure = min(corner1Figure,corner2Figure);
p2Figure = max(corner1Figure,corner2Figure);

% If this is a regular click outside the selected area 
% we simply return 
if (any(finalRect(3:4)== 0,2))
  return
end

% If the drag rect extends beyond the axes limits we do 
% nothing and simply return.
ax = viewer.getAxes();
map_limits = [get(ax,'XLim')', get(ax,'YLim')'];

% map_limits is formatted as:
%    [ lower_left_cords  ]
%    [ upper_right_cords ]

is_rect_outside_lower_left = any(lower_left < map_limits(1,:),2);
is_rect_outside_upper_right = any(upper_right > map_limits(2,:),2);

if is_rect_outside_lower_left || is_rect_outside_upper_right
  return
end

viewer.SelectionBox = [lower_left; upper_right];
viewer.FigureSelectionBox = [p1Figure; p2Figure];

% This line will be drawn clock-wise
x_line = [lower_left(1)  lower_left(1)  upper_right(1) upper_right(1) lower_left(1)];
y_line = [lower_left(2) upper_right(2)  upper_right(2)  lower_left(2) lower_left(2)];

this.Box = line(...
    'Parent',viewer.UtilityAxes,...
    'XData',x_line,...
    'YData',y_line,...
    'Color','r',...
    'LineWidth',1,...
    'Tag','selectAreaBox',...
    'ButtonDownFcn',{@dragRect this viewer});

this.enableMenus;


function deselectArea(this)
if ~isempty(this.Box) && ishghandle(this.Box)
  delete(this.Box);
end
