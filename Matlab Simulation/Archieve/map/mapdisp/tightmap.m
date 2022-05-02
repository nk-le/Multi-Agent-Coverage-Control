function tightmap(style)
%TIGHTMAP Remove white space around map
% 
%   TIGHTMAP ON sets the MATLAB axis limits to be tight around the map in
%   the current axes.  This eliminates or reduces the white border
%   between the map frame and the axes box.
%
%   TIGHTMAP TIGHT is the same as TIGHTMAP ON.
%
%   TIGHTMAP LOOSE allows slightly more space around the map.
%
%   TIGHTMAP OFF sets the axes limit modes back to 'auto' (equivalent
%   to AXIS AUTO).
%
%   TIGHTMAP performs no action on a 'globe' map axes. Note that
%   TIGHTMAP needs to be re-applied following any call to SETM that
%   causes projected map objects to be re-projected.
%   
%   See also PAPERSCALE, AXESSCALE

% Copyright 1996-2014 The MathWorks, Inc.

if nargin == 0
   style = 'tight';
else
    style = validatestring(style, ...
        {'on','off','tight','loose'}, 'TIGHTMAP', 'STYLE');
end

switch style
    case {'tight','on'}
        tightmapOn(0.002)
    case 'loose'
        tightmapOn(0.01)
    case 'off'
        set(gca,'XLimMode','auto','YLimMode','auto')
end

%-----------------------------------------------------------------------

function tightmapOn(param)

hframe = handlem('Frame');
if ~isglobe(hframe)
    newframe = 0;
    if isempty(hframe)
        hframe = framem;
        newframe = true;
    end
    
    xframe = get(hframe,'Xdata');
    yframe = get(hframe,'Ydata');
    
    xdiff = max(xframe) - min(xframe);
    ydiff = max(yframe) - min(yframe);
    
    xLimits = [min(xframe) max(xframe)] + param*xdiff*[-1 1];
    yLimits = [min(yframe) max(yframe)] + param*ydiff*[-1 1];
    
    set(gca,'XLim',xLimits,'YLim',yLimits)
    
    if newframe
        delete(hframe);
    end
end

%-----------------------------------------------------------------------

function tf = isglobe(hframe)
% True if axes ancestor of hframe is a 'globe' map axes.

if isempty(hframe)
    ax = gca;
else
    ax = ancestor(hframe,'axes');
end

if ismap(ax)
    % Map axes, might or might not be 'globe'
    tf = strcmp(getm(ax,'MapProjection'),'globe');
else
    % Not a map axes
    tf = false;
end
