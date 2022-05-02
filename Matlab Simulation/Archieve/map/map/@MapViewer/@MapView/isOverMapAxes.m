function TF = isOverMapAxes(this)
%ISOVERMAPAXES Determine whether current mouse position is over map axes.
%
%   TF = isOverMapAxes() determines whether the current mouse position is
%   over the map axes region. TF is a logical value that is true if the
%   mouse is over the map axes and false otherwise.

% Copyright 2008 The MathWorks, Inc.

hit_obj = hittest(this.Figure);

% There are three overlapping axes within the overall map axes region.
mapAxes = [this.getAxes() this.AnnotationAxes this.UtilityAxes];

axesAncestorOfHitObj = ancestor(hit_obj,'axes');

% If the mouse is over an object which is a descendant of any of the axes
% that compose the map axes region, then we are over the map axes.
TF = ~isempty(axesAncestorOfHitObj) && ...
     any(axesAncestorOfHitObj == mapAxes);
