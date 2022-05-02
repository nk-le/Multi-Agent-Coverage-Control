function ax = getParentAxesFromArgList(args)
% See if the cell array ARG contains the pair {'Parent', ax} where ax
% is an axes handle. If there's more than one axes handle, take the
% last one. If there's no {'Parent',ax} handle pair, return [].

% Copyright 2009 The MathWorks, Inc.

% Find all the axes handles in the cell array ARGS.
k = find(cellfun(@(h) isscalar(h) && ishghandle(h,'axes'), args));

% Determine if the last axes handle is preceded by a string that matches
% 'Parent'.
axesHandleIsPrecededByStringParent = ...
   ~isempty(k) && (k(end) > 1) ...
    && strncmpi('Parent', args{k(end)-1}, numel(args{k(end)-1}));

% If there's at least one axes handle and the last one is preceded by a
% string that matches 'Parent', return the last handle. Otherwise return
% empty.
if axesHandleIsPrecededByStringParent
    ax = args{k(end)};
else
    ax = [];
end
