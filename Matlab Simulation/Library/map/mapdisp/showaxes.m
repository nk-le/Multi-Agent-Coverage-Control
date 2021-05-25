function showaxes(action)
%SHOWAXES Toggle display of map coordinate axes
%
%  SHOWAXES(ACTION) modifies the Cartesian axes based on the value of the
%  ACTION, as defined in the following table:
%
%     VALUE      ACTION
%     -----      -------
%     ON         Displays the MATLAB Cartesian axes and default axes ticks
%     OFF        Removes the axes ticks from the MATLAB Cartesian axes
%     HIDE       Hides the Cartesian axes
%     SHOW       Shows the Cartesian axes
%     RESET      Sets the Cartesian axes to the default settings
%     BOXOFF     Removes axes ticks, color, and box from Cartesian axes
%
%  SHOWAXES toggles between ON and OFF.
%
%  SHOWAXES(COLORSTR) sets the Cartesian axes to the color specified by  
%  COLORSTR.
%
%  SHOWAXES(COLORVEC) uses the RGB triple, COLORVEC, to set the Cartesian
%  axes color.
%
%  See also AXESM, SET.

% Copyright 1996-2017 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

if nargin > 0
    action = convertStringsToChars(action);
end

if nargin == 0
    xtick = get(gca,'Xtick');
    
    if ~isempty(xtick)
        action = 'off';
    else
        action = 'on';
    end
    
elseif nargin == 1 && ischar(action)
    validstr = {'on','off','hide','show','reset','boxoff',...
        'white','black','red','green','blue','yellow',...
        'magenta','cyan'};
    
    action = lower(action);
    indx = strmatch(action, validstr);
    if isempty(indx)
        error(['map:' mfilename ':invalidActionString'], ...
            'Not a valid SHOWAXES string.')
    elseif length(indx) > 1
        error(['map:' mfilename ':nonUniqueActionString'], ...
            'Non-unique SHOWAXES string.  Supply more characters.')
    elseif indx <= 6
        action = validstr{indx};
    else
        action   = 'color';
        colorstr = validstr{indx};
    end
    
elseif nargin == 1 && ~ischar(action)
    colorstr = action(:)';
    action = 'color';
    if length(colorstr) ~= 3 || any(colorstr > 1) || any(colorstr < 0)
        error(['map:' mfilename ':invalidRGBValue'], ...
            'Invalid RGB triple.')
    end
end


%  Set the axes property to the appropriate state

switch action
    case 'off'
        set(gca, 'Xtick',[], 'Ytick',[], 'Ztick',[])
        
    case 'on'
        set(gca,'Visible','on', ...
            'XtickMode','auto', 'YtickMode','auto','ZtickMode','auto')
        
    case 'color'
        set(gca,'Visible','on',...
            'XtickMode','auto','Xcolor',colorstr,...
            'YtickMode','auto','Ycolor',colorstr,...
            'ZtickMode','auto','Zcolor',colorstr)
        
    case 'hide'
        set(gca,'Visible','off');
        
    case 'show'
        set(gca,'Visible','on');
        
    case 'reset'
        colorstr = get(gca,'Color');
        if strcmp(colorstr,'none')
            colorstr = get(gcf,'Color'); 
        end
        
        set(gca,'Visible','on',...
            'Xtick',[],'Xcolor',~colorstr,...
            'Ytick',[],'Ycolor',~colorstr,...
            'Ztick',[],'Zcolor',~colorstr,...
            'Box','on')
        
    case 'boxoff'
        colorstr = get(gca,'Color');
        if strcmp(colorstr,'none')
            colorstr = get(gcf,'Color');  
        end
        
        set(gca,'Visible','on',...
            'Xtick',[],'Xcolor',colorstr,...
            'Ytick',[],'Ycolor',colorstr,...
            'Ztick',[],'Zcolor',colorstr,...
            'Box','off')
end
