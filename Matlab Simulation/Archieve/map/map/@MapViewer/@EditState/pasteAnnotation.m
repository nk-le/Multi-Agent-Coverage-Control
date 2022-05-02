function pasteAnnotation(this)
% Paste all the annotation objects currently stored in the array of
% handles in this.MapViewer.CopiedObjects, shifting each one in X and Y
% by 1/30 of size of the visible axes limits for the given dimension.
% Then replace the pasted object in the list of copied objects with a
% copy itself. An annotation object can be either an HG text object with
% an associated MapGraphics.Text object or an HG line object with an
% associated MapGraphics.DragLine object.

% Copyright 2005-2008 The MathWorks, Inc.

copiedObjects = this.MapViewer.CopiedObjects;
if ~isempty(copiedObjects)
    hAx = this.AnnotationAxes;
    xLim = get(hAx,'XLim');
    yLim = get(hAx,'YLim');
    xShift = diff(xLim)/30;
    yShift = diff(yLim)/30;
    
    for k = 1:numel(copiedObjects)
        annotation = getappdata(copiedObjects{k},'AnnotationObject');
        annotation.paste(xShift,yShift)
        copiedObjects{k} = annotation.makeCopy();
    end
    
    this.MapViewer.CopiedObjects = copiedObjects;
    this.enableMenus();
end
