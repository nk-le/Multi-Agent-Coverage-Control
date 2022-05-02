function [ymat,xmat] = undotrim(ymat,xmat,trimpts,object)
%UNDOTRIM Remove object trims introduced by TRIMDATA
%
%  [ymat,xmat] = undotrim(ymat,xmat,trimpts,'object') will remove the
%  object trims introduced by TRIMDATA.  This function is necessary to
%  properly invert projected data from the map coordinates to the
%  original lat, long data points.  The input variable, trimpts, must
%  be constructed by the function TRIMDATA.
%
%  Allowable object string are:  'surface' for undoing trimmed graticules;
%  'light' for undoing trimmed lights; 'line' for undoing trimmed lines;
%  'patch' for undoing trimmed patches; and 'text' for undoing trimmed
%  text object location points.
%
%  See also CLIPDATA, TRIMDATA, UNDOCLIP.

% Copyright 1996-2011 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Return if nothing to undo
if isempty(trimpts)
    return
end

object = validatestring(object, ...
    {'surface','light','line','patch','text'},'UNDOTRIM','OBJECT', 4);

switch object
    case 'surface'
        ymat(trimpts(:,1)) = trimpts(:,2);
        xmat(trimpts(:,1)) = trimpts(:,3);
        
    case 'line'
        if size(trimpts,2) == 3
            ymat(trimpts(:,1)) = trimpts(:,2);
            xmat(trimpts(:,1)) = trimpts(:,3);
        elseif size(trimpts,2) == 4
            ymat(trimpts(:,1)) = trimpts(:,3);
            xmat(trimpts(:,1)) = trimpts(:,4);
        end
        
    case 'patch'
        % undo them in reverse order, important when off both bottom and side
        trimpts = flipud(trimpts);
        ymat(trimpts(:,1)) = trimpts(:,3);
        xmat(trimpts(:,1)) = trimpts(:,4);
        
    case 'text'
        if size(trimpts,2) == 3
            ymat(trimpts(:,1)) = trimpts(:,2);
            xmat(trimpts(:,1)) = trimpts(:,3);
        elseif size(trimpts,2) == 4
            ymat(trimpts(:,1)) = trimpts(:,3);
            xmat(trimpts(:,1)) = trimpts(:,4);
        end
end
