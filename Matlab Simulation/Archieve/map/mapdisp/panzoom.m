function panzoom(action)
%PANZOOM Zoom settings on 2-D map
%
%   PANZOOM will be removed in a future release. Use ZOOM instead.
%
%   PANZOOM with no arguments toggles the zoom state.
%
%   PANZOOM ON is equivalent to ZOOM ON.
%
%   PANZOOM OFF is equivalent to ZOOM OFF.
%
%   PANZOOM OUT is equivalent to ZOOM OUT.
%
%   PANZOOM SETLIMITS is equivalent to ZOOM RESET.
%
%   PANZOOM FULLVIEW sets the axes limit modes to 'auto' and resets zoom
%   to the resulting limits.
%
%   See also ZOOM

% Copyright 1996-2018 The MathWorks, Inc.

if nargin < 1
    % panzoom
    zoom
else
    if strcmp(action,'setlimits')
        % panzoom('setlimits')
        zoom('reset')
    elseif strcmp(action,'fullview')
        % panzoom('fullview')
        axis('auto')   % Reset the axes limits
        drawnow
        zoom('reset')  % Clear the zoom limit settings
        zoom('on')
    elseif any(strcmp(action,{'on','off','out'}))
        % panzoom('on'), panzoom('off'), or panzoom('out')
        zoom(action)
    else
        try
            % Pass action string through to zoom. (This will allow
            % panzoom('reset'), panzoom('xon'), panzoom('yon'), and
            % panzoom(factor) to work the same as zoom('reset'),
            % zoom('xon'), zoom('yon'), and zoom(factor) even though these
            % inputs are undocumented for panzoom.)
            zoom(action)
        catch exception
            % Action is not supported by zoom. Throw our own error, but
            % re-use the message string provided by MATLAB.
            error('map:panzoom:unknownActionString','%s',exception.message)
        end
    end
end
