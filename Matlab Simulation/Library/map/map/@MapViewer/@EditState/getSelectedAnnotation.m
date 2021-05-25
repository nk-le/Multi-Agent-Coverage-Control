function hSelectedAnnotation = getSelectedAnnotation(this)
% Return the handles of all Annotation Axes children that (1) are selected
% and (2) have 'AnnotationObject' appdata.

% Copyright 2005-2012 The MathWorks, Inc.

hAx = this.AnnotationAxes;
hSelected = findobj(get(hAx,'Children'),'Selected','on');
isAnnotation = arrayfun(@(h) isappdata(h,'AnnotationObject'), hSelected);
hSelectedAnnotation = hSelected(isAnnotation);
