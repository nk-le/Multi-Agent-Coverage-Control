function cutOrCopyAnnotation(this,cutOnly)
% Clear out any previously cut/copied objects. Then, if cutOnly is
% false, make an invisible copy of each of the selected annotation
% objects and store its handle in the cell array
% this.MapViewer.CopiedObjects. Otherwise cut each of the selected
% annotation objects and store its handle in
% this.MapViewer.CopiedObjects.  An annotation object can be either an
% HG text with an associated MapGraphics.Text object or an HG line
% object with an associated MapGraphics.DragLine object.

% Copyright 2008 The MathWorks, Inc.

% Clear out previously cut/copied objects.
copiedObjects = this.MapViewer.CopiedObjects;
for k = 1:numel(copiedObjects)
    if ishghandle(copiedObjects{k})
        delete(copiedObjects{k})
    end
end

% Cut or copy each of the selected objects, retrieving a handle to the UDD
% object from the appdata of the corresponding HG text or line object.
selectedObjects = this.getSelectedAnnotation();
if ~isempty(selectedObjects)
    copiedObjects = cell(size(selectedObjects));
    for k = 1:numel(selectedObjects)
        annotation = getappdata(selectedObjects(k),'AnnotationObject');
        if cutOnly
            copiedObjects{k} = annotation.cut();
        else
            copiedObjects{k} = annotation.makeCopy();
        end
    end
else
    copiedObjects = {};    
end

% Store the array of cut/copied objects in within the MapViewer object,
% since this EditState object might be deleted before the user chooses to
% paste them.
this.MapViewer.CopiedObjects = copiedObjects;
this.enableMenus();
