function this = DefaultState(viewer)
%

% Copyright 1996-2008 The MathWorks, Inc.

this = MapViewer.DefaultState;

viewer.setDefaultWindowButtonFcn();

% Menus
set(viewer.NewViewAreaMenu,'Enable','off')
set(viewer.ExportAreaMenu, 'Enable','off')
