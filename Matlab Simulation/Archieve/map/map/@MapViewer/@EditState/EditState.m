function this = EditState(viewer)
%

% Copyright 1996-2014 The MathWorks, Inc.

this = MapViewer.EditState;
this.MapViewer = viewer;
this.EditMenu = viewer.EditMenu;
this.AnnotationAxes = viewer.AnnotationAxes;
c = get(this.AnnotationAxes,'Children');

if ~isempty(c)
    if ishghandle(c(1),'line')
        hDragLine = getappdata(c(1),'AnnotationObject');
        if ~isempty(hDragLine) && ~(hDragLine.Finished)
            % Delete DragLine if line wasn't finished
            delete(c(1))
        end
    end
end

this.enableMenus;

viewer.setCursor({'Pointer','arrow'});

set(viewer.Figure,...
    'WindowButtonDownFcn',{@selectAnnotation, this},...
    'KeyPressFcn',{@checkSelectionType, this});

%==========================================================================

function selectAnnotation(hSrc,evt,this)

annotationAxes = this.AnnotationAxes;
annotations = get(annotationAxes,'Children');

% if there are no annotations we return
if isempty(annotations)
    return;
end

selectedAnnotation = evt.HitObject;

% if no annotation was clicked or if the object clicked on is not on the 
% annotation axes we return
if isempty(selectedAnnotation) ||...
        annotationAxes ~= get(selectedAnnotation,'Parent')
        this.unselectAnnotation;
    return
end

allSelectedObj = this.getSelectedAnnotation;

% select the object
selectionType = get(hSrc,'SelectionType');

if strcmpi(selectionType,'open')
  inspect(selectedAnnotation);
end

% the selected annotation had already been selected
if strcmpi(get(selectedAnnotation,'Selected'),'on') &&...
        strcmpi(selectionType,'extend')
    this.unselectAnnotation(selectedAnnotation);
else
    switch selectionType
        case 'extend' % select multiple objects
            selectedAnnotation = [selectedAnnotation; allSelectedObj];
            this.selectAnnotation(selectedAnnotation);
        case 'normal'
            this.selectAnnotation(selectedAnnotation);
    end
    this.moveAnnotation(selectedAnnotation);
end

%==========================================================================

function checkSelectionType(hSrc,evt, this) %#ok

hFig = hSrc;

key = double(get(hFig,'CurrentCharacter'));
if isempty(key)
  return
end

switch key
 case {8, 127} % Backspace or Delete keys
  this.deleteAnnotation;
 case 27 % Escape key
  this.unselectAnnotation;
end
