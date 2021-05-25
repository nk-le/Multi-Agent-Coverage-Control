function selectAll(this)
%

%   Copyright 2005 The MathWorks, Inc.

hAx = this.AnnotationAxes;
annotations = findobj(get(hAx,'Children'),'Visible','on');

this.selectAnnotation(annotations);








