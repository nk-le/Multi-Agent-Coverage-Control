function restackMapAxes(h,resetZ)
%restackMapAxes Restack the objects in a map axes
%
%   map.graphics.internal.restackMapAxes(h) ensures that objects in a map
%   axes are stacked in the following order, from top to bottom:
%
%     < ... text objects excluding graticule labels ...>
%     North Arrows (two patch objects per arrow)
%     Scale Rulers (one hgroup per ruler with multiple line and text objects)
%     Parallel Labels (one text object per label)
%     Meridian Labels (one text object per label)
%     Parallel  (a single line object)
%     Meridians (a single line object)
%     < ... map data objects excluding text ... >
%     Map Frame (a single patch object)
%
%   map.graphics.internal.restackMapAxes(h,resetZ), when resetZ is true,
%   ensures that each decoration (north arrow, scale ruler, parallel or
%   meridian label, parallel or meridian line (graticule), or map frame)
%   will be shifted into the X-Y (Z == 0) plane.
%
%   This shift is not necessary when working entirely within MATLAB
%   Graphics Version 2, because the object will have been placed in the
%   X-Y plane at the time it is created. But in figures saved from older
%   versions this will not be the case. Such figures can be "repaired" by
%   calling restackMapAxes(___,true), once per map axes, after they are
%   reopened.
%
%   Input Arguments
%   ---------------
%   h -- Handle to a map axes or to an object in a map axes. 
%        If h is empty, no action is performed. If h has more than one
%        element, the map axes is assumed to be the ancestor axes of the
%        first element.
%
%   resetZ -- Flag indicating whether to shift map axes decorations into
%        the Z == 0 plane, specified as a logical scalar. The value of
%        resetZ is false by default, so that the single-input form
%        map.graphics.internal.restackMapAxes(h) can be used if it is
%        known that the decorations are already in the X-Y plane.

% Copyright 2013-2014 The MathWorks, Inc.

ax = mapAxesAncestor(h);
if ~isempty(ax) && ~isappdata(ax,'HighLevelFunction')
    % Find all the decorations
    hMeridian = findobj(ax,'Type','line','Tag','Meridian');
    hParallel = findobj(ax,'Type','line','Tag','Parallel');
    hGraticule = [hParallel; hMeridian];
    
    hMeridianLabel = findobj(ax,'Type','text','Tag','MLabel');
    hParallelLabel = findobj(ax,'Type','text','Tag','PLabel');
    hGraticuleLabels = [hParallelLabel; hMeridianLabel];
    
    hScaleRuler = findobj(ax,'Type','hggroup','-regexp','Tag','scaleruler*');
    hNorthArrow = findobj(ax,'Type','patch','Tag','NorthArrow');
    
    if nargin > 1 && resetZ
        % Optionally, shift all the decorations into the Z == 0 plane.
        hFrame = findobj(ax,'Type','patch','Tag','Frame');
        shiftToZero(hFrame, hGraticule, ...
            hGraticuleLabels, hScaleRuler, hNorthArrow)
    end
    
    % Set the stacking order for the decorations (except for the frame,
    % which was placed on the bottom at the time it was constructed).
    moveToTop(ax, [hNorthArrow; hScaleRuler; hGraticuleLabels; hGraticule])
    
    % Stack all text map data objects above everything else. (All text
    % excluding the meridian and parallel labels, that is.)
    hUserText = setdiff(findobj(ax,'Type','text','Parent',ax),hGraticuleLabels,'stable');
    moveToTop(ax, hUserText)
end

%--------------------------------------------------------------------------

function moveToTop(ax,h)
% Move objects in handle array h to the top of the axes ax.

if ~isempty(h)
    c = allchild(ax);
    for k = 1:numel(h)
        c(c == h(k)) = [];
    end
    set(ax,'Children',[h(:); c])
end

%--------------------------------------------------------------------------

function ax = mapAxesAncestor(h)
% Find the map axes ancestor of the first element of handle array h. Return
% empty if h is empty or is not in a map axes.

if isempty(h)
    ax = gobjects(0);
else
    ax = ancestor(h(1),'axes');
    mstruct = get(ax,'UserData');
    if ~isstruct(mstruct) || ~all(isfield(mstruct,{'mapprojection','grid','frame'}))
        ax = gobjects(0);
    end
end 

%--------------------------------------------------------------------------

function shiftToZero(hFrame, hGraticule, ...
            hGraticuleLabels, hScaleRuler, hNorthArrow)

if ~isempty(hFrame)
    z = get(hFrame,'ZData');
    z(~isnan(z)) = 0;
    set(hFrame,'ZData',z);
end

if ~isempty(hGraticule)
    z = get(hGraticule,'ZData');
    z(~isnan(z)) = 0;
    set(hGraticule,'ZData',z);
end

for k = 1:numel(hGraticuleLabels)
    h = hGraticuleLabels(k);
    pos = get(h,'Position');
    pos(3) = 0;
    set(h,'Position',pos)
end

hScaleRulerLines = findobj(hScaleRuler,'Type','line');
for k = 1:numel(hScaleRulerLines)
    h = hScaleRulerLines(k);
    z = get(h,'ZData');
    z(~isnan(z)) = 0;
    set(h,'ZData',z);
end

hScaleRulerText  = findobj(hScaleRuler,'Type','text');
for k = 1:numel(hScaleRulerText)
    h = hScaleRulerText(k);
    pos = get(h,'Position');
    pos(3) = 0;
    set(h,'Position',pos)
end

for k = 1:numel(hNorthArrow)
    h = hNorthArrow(k);
    z = get(h,'ZData');
    z(:) = 0;
    set(h,'ZData',z);
end
