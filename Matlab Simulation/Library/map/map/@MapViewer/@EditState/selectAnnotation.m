function selectAnnotation(this, hObj)
%

% Copyright 2005-2013 The MathWorks, Inc.

hAx = this.AnnotationAxes;

if isempty(hObj)
    return
end

% unselect currently selected annotations
allChildObjs = get(hAx,'Children');

unselectedObjs = setxor(hObj, allChildObjs);

set(hObj,'Selected','on');
set(unselectedObjs,'Selected','off');
this.enableMenus;
