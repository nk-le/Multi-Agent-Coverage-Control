function unselectAnnotation(this, hObj)
%

%   Copyright 2005 The MathWorks, Inc.

hAx = this.AnnotationAxes;
if nargin == 1
    annotations = get(hAx,'Children');
else
    annotations = hObj;
end
set(annotations,'Selected','off');
this.enableMenus;
