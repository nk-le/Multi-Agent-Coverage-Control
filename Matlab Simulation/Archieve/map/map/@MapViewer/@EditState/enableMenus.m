function enableMenus(this)
%

% Copyright 1996-2013 The MathWorks, Inc.

% set(get(this.EditMenu,'Children'),'Enable','on');

cutMenu = findall(this.EditMenu,'Tag','cut');
copyMenu = findall(this.EditMenu,'Tag','copy');
pasteMenu = findall(this.EditMenu,'Tag','paste');
selectAllMenu = findall(this.EditMenu,'Tag','select all');

viewer = this.MapViewer;

allChildObjs = get(viewer.AnnotationAxes,'Children');

isAnnotation = ~isempty(allChildObjs);

isCopiedObject = any(cellfun(...
    @ishghandle,viewer.CopiedObjects));

isObjectSelected = ~isempty(this.getSelectedAnnotation);

% handle any annotation displayed 
if isAnnotation
    set(selectAllMenu,'Enable','on');
else
    set(selectAllMenu,'Enable','off');
end

% handle copy and cut menu items
if isObjectSelected 
    set([cutMenu,copyMenu],'Enable','on');
else
    set([cutMenu,copyMenu],'Enable','off');
end

% handle paste menu
if isCopiedObject
    set(pasteMenu,'Enable','on');
else
    set(pasteMenu,'Enable','off');
end
