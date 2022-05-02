%BoundingBox Bounding box class for Map Viewer

% Copyright 2012-2020 The MathWorks, Inc.

classdef BoundingBox < matlab.mixin.SetGetExactNames
    
    properties (SetAccess = private)
        Name
        LineHandle
        TextHandle
        % Visible -- Appears in UDD schema but seems to be unused
    end
    
    methods
        function h = BoundingBox(name,textstring,box,ax)
        %BOUNDINGBOX Draw a bounding box
        %
        %   BOUNDINGBOX(NAME,BOX,AX) Draws a BoundingBox object, with the
        %   name NAME, into the axes AX.  BOX is a 5-by-2 array of
        %   coordinates, for the 5 corners of the bounding box, in
        %   clockwise or counterclockwise order.
            
            h.Name = name;
            
            h.LineHandle = line( ...
                'XData', box(:,1), ...
                'YData', box(:,2), ...
                'Parent', ax, ...
                'Color','Black', ...
                'Visible','On',...
                'Tag',name);
            
            h.TextHandle = text(...
                'Parent',ax,...
                'HorizontalAlignment','center',...
                'VerticalAlignment','middle',...
                'Position',getBoxCenter(box),...
                'Clipping','on',...
                'String',textstring,...
                'Color',[0 0 0],...
                'Interpreter','none',...
                'Visible','On',...
                'Tag',name);
        end        
        
        function setVisible(h,b)
        %SETVISIBLE
        %
        %   SETVISIBLE(B) Sets the graphics components to be visible 
        %   (B = 'On' or true) or invisible (B = 'Off' or false).

            if islogical(b)
                if b
                    b = 'on';
                else
                    b = 'off';
                end
            end
            
            set(h.LineHandle,'Visible',b)
            set(h.TextHandle,'Visible',b)
        end
    end
end

%--------------------------------------------------------------------------

function center = getBoxCenter(box)

corners = [min(box(:,1)) min(box(:,2));
    max(box(:,1)) max(box(:,2))];

center = (corners(1,:) + corners(2,:))/2;

end
