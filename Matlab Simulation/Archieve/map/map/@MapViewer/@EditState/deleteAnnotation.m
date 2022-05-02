function deleteAnnotation(this)
% Delete any currently-selected DragLines and Text objects from the
% annotation axes.

% Copyright 2005-2008 The MathWorks, Inc.

selectedObjects = this.getSelectedAnnotation;
delete(selectedObjects)
this.enableMenus();
