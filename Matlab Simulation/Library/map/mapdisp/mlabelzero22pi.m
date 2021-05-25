function mlabelzero22pi
%MLABELZERO22PI Convert meridian labels to 0 to 360-degree range
% 
%   MLABELZERO22PI displays meridian labels in the range of 0 to 360
%   degrees east of the Prime Meridian.
%
%   Example
%   -------
%   figure
%   axesm('miller','Grid','on')
%   tightmap
%   mlabel
%   plabel
%   mlabelzero22pi
%
%   See also MLABEL

% Copyright 1996-2015 The MathWorks, Inc.

    % Check for current map axes.
    ax = get(get(0,'CurrentFigure'),'CurrentAxes');
    if ~isempty(ax) && ismap(ax)

        % Update meridian labels, if they exist.
        h = handlem('MLabel',ax);
        
        if ~isempty(h)
            switch getm(ax,'labelformat')
                case 'compass'
                    updater = @updateCompassString;
                case 'signed'
                    updater = @updateSignedOrUnformattedString;
                case 'none'
                    updater = @updateSignedOrUnformattedString;
            end
            
            for k = 1:numel(h)
                updateString(h(k), updater)
            end
        end
    end
end


function updateString(h, updater)
    str = h.String;
    if iscell(str)
        if isempty(str{2})
            % Labels at top of frame are followed by a blank line.
            str{1} = updater(str{1});
        else
            % Labels at bottom of frame are preceded by a blank line.
            str{2} = updater(str{2});
        end
    else
        str = updater(str);
    end
    h.String = str;
end


function valstr = updateCompassString(str)
    indx = strfind(str,'^');
    dir = lower(str(end));
    if dir == 'w'
        val = 360 - str2double(str(1:indx-1));
        valstr = [num2str(val) degchar ' E'];
    elseif dir == 'e'
        valstr = strtrim(str);
    else
        valstr = ['0' degchar ' E'];
    end
end


function valstr = updateSignedOrUnformattedString(str)
    indx = strfind(str,'^');
    valstr = rmspace(str(1:indx-1));
    val = str2double(valstr);
    if val < 0
        val = 360 + val;
    end
    valstr = [num2str(val) degchar];
end


function str = rmspace(str)
% Remove whitespace from string

    str(isspace(str)) = [];
end
