function nextmap(ax)
%NEXTMAP  Readies a map axes for the next object
%
%   NEXTMAP readies the current axes (as returned by GCA) for the next
%   map object. If the hold state is off, NEXTMAP will also clear the
%   current map before the next object is displayed.
%
%   NEXTMAP(AX) readies the specified map axes for the next map object.
%   If the hold state is off, NEXTMAP will also clear the current map
%   before the next object is displayed.
%
%   NEXTMAP(ARGS) looks for an axes handle preceded by 'Parent' in the
%   cell array ARGS. If such a handle is found, it's passed in a second
%   call to NEXTMAP. If not, NEXTMAP is still called a second time, but
%   without any input arguments.
%
%   See also CLMA

% Copyright 1996-2011 The MathWorks, Inc.

%  Clear the map, but not the frame,
%  if a hold on has not been issued
if nargin == 0
    gcm; % Will error if gca is not a valid map axes
    if strcmp(get(gca,'NextPlot'),'replace')
        clmo('map')
    end
elseif ishghandle(ax,'axes')
    gcm(ax); % Will error if ax is not a valid map axes
    if strcmp(get(ax,'NextPlot'),'replace')
        clmo('map')
    end
elseif iscell(ax)
    % See if the cell array contains the pair {'Parent', ax} where ax is
    % an axes handle. If there's more than one axes handle, take the
    % last one, and call nextmap recursive on that handle. If there's no
    % {'Parent',ax} handle pair, call nextmap recursively with no input.
    args = ax;
    ax = getParentAxesFromArgList(args);
    if ~isempty(ax)
        nextmap(ax)
    else
        nextmap
    end
else
    validateattributes(ax,{'cell','handle'},{'scalar'},'NEXTMAP','AX')
end
