function fig = copyMap(this)
%copyMap Copy MapViewer

% Copyright 2013 The MathWorks, Inc.

% Construct a temporary, invisible figure. This is what will actually be
% printed.
fig = figure('Visible','off','Position',get(this.Figure,'Position'));

% Clone the main axes into the temporary figure.
ax = copyobj(this.getAxes(),fig);

% Clone the descendents of the annotation axes into the temporary figure;
% use setdiff to remove the annotation axes itself from the output of
% findobj. (It's sufficient to put all the map objects and annotation
% objects into a single axes for the purposes of printing.)
descendents = setdiff(findobj(this.AnnotationAxes),this.AnnotationAxes);
copyobj(descendents,ax);

% Turn off the delete functions for all objects in the temporary figure, to
% avoid side effects when closing that figure. (Some of these objects have
% delete functions that will disrupt the configuration of the Map Viewer
% itself if allowed to fire.)
set(findobj(ax),'DeleteFcn',[])

% Turn off axis labeling, etc.
axis(ax,'off')
