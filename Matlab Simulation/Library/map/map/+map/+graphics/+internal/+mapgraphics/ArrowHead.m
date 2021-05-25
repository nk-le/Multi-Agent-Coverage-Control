%ARROWHEAD Arrow head class for Map Viewer

% Copyright 2012-2020 The MathWorks, Inc.

classdef ArrowHead < matlab.mixin.SetGetExactNames

    properties
        hPatch
        line
        ArrowWidth = 16/3;
        ArrowHeight = 24;
    end
    
    methods
        function this = ArrowHead(hLine)
            %ARROWHEAD
            %
            %   H = ArrowHead(hLine)
                        
            ax = ancestor(hLine,'axes');
            this.line = hLine;
            
            % Listen and move the arrow head if the limits change on the master axes.
            mAxes = getappdata(ax,'MasterAxes');
            hListeners{6} = addlistener(mAxes, 'XLim', 'PostSet', @moveArrow);
            hListeners{5} = addlistener(mAxes, 'YLim', 'PostSet', @moveArrow);
            
            [xt,yt] = buildarrow(this.ArrowHeight,this.line,ax);
            c = get(this.line,'Color');
            
            this.hPatch = patch('Parent',ax, ...
                'XData',xt,'YData',yt,'ZData',ones(size(xt)),'FaceColor',c, ...
                'EdgeColor','None','Visible',get(this.line,'Visible'),...
                'DeleteFcn',@deleteArrowHead);
            
            % Listen and adjust the arrow head if its line moves.
            hListeners{4} = addlistener(hLine, 'XData',   'PostSet', @moveArrow);
            hListeners{3} = addlistener(hLine, 'YData',   'PostSet', @moveArrow);
            hListeners{2} = addlistener(hLine, 'Color',   'PostSet', @setColor);
            hListeners{1} = addlistener(hLine, 'Visible', 'PostSet', @setVisible);
            
            fig = ancestor(ax,'Figure');
            toolbar = findall(fig,'type','uitoolbar');
            toolButton = findall(toolbar,'ToolTipString','Insert Arrow');
            set(toolButton,'State','off');
            
            drawnow
            
            %-------------- Nested Callback Functions ------------------
            
            function setVisible(~,~)
                set(this.hPatch,'Visible',get(this.line,'Visible'))
            end
            
            function setColor(~,~)
                set(this.hPatch,'FaceColor',get(this.line,'Color'))
            end
            
            function moveArrow(~,~)
                [ah,aw] = getArrowheadSize(this.ArrowHeight,this.line,ax);
                
                [co,si] = getCosSin(this.line);
                
                [xend, yend] = getEndpoint(this.line);
                
                xt = [ -ah,  -ah, 0,   -ah, -ah ];
                yt = [   0, aw/2, 0, -aw/2,   0 ];
                
                [xt,yt] = rotateArrowhead(xt,yt,co,si);
                
                xt = xt + xend;
                yt = yt + yend;
                set(this.hPatch,'XData',xt,'YData',yt);
            end
            
            function deleteArrowHead(hSrc,event) %#ok<INUSD>
                if isvalid(this)
                    delete(this)
                    
                    % Stop listening for events from the line and axes objects
                    cellfun(@(h) delete(h), hListeners)
                end
            end
        end
        
        
        function delete(this)
            if ishghandle(this.hPatch) && strcmp(get(this.hPatch, 'BeingDeleted'), 'on')
                delete(this.hPatch)
            end
        end
        
    end
    
end

%-----------------------------------------------------------------------

function [xt, yt] = buildarrow(ah,lh, ax)
% returns x and y coord vectors for an arrow head

[ah,aw] = getArrowheadSize(ah,lh,ax);

[co,si] = getCosSin(lh);

[xend, yend] = getEndpoint(lh);

xt = [ -ah,  -ah, 0,   -ah, -ah ];
yt = [   0, aw/2, 0, -aw/2,   0 ];

[xt,yt] = rotateArrowhead(xt,yt,co,si);

xt = xt + xend;
yt = yt + yend;
end

%-----------------------------------------------------------------------

function [x, y] = getEndpoint(lh)
% Get the end point of the line.
X = get(lh, 'XData');
Y = get(lh, 'YData');
x = X(end);
y = Y(end);
end

%-----------------------------------------------------------------------

function [co,si] = getCosSin(lh)
% Determine the slope of the line.
% Use the last two points of the curve.
X = get(lh, 'XData');
Y = get(lh, 'YData');
x1 = X(end - 1);
x2 = X(end);
y1 = Y(end - 1);
y2 = Y(end);
xl = x2 - x1;
yl = y2 - y1;
hy = (xl^2 + yl^2)^.5;

% calculate the cosine and sine
co =  xl / hy;
si =  yl / hy;
end

%-----------------------------------------------------------------------

function [xt,yt] = rotateArrowhead(xt,yt,co,si)
% rotate the triangle based on the slope of the last line
foo = [co -si; si  co] * [xt; yt];

% convert points back to data units and add in the offset
xt = foo(1,:);
yt = foo(2,:);
end

%-----------------------------------------------------------------------

function [ah,aw] = getArrowheadSize(ah,lh,ax)
% Get axis width and height in points
oldUnits = get(ax,'Units');
set(ax,'Units','points');
Pos = get(ax,'Position');
set(ax,'Units',oldUnits);
w = Pos(3);
h = Pos(4);

% Get axis limits
xlim = get(ax,'XLim');
ylim = get(ax,'YLim');

% Calculate number of data units/point
xres = diff(xlim) / w;
yres = diff(ylim) / h;

% get the line width
lw = get(lh, 'LineWidth');
if (iscell(lw))
    lw = lw{end};
end

% scale arrow height by line width
ah = ah * lw/2;

% 3 : 2 aspect ratio
aw = ah * .66;

% Scale w,h by data units per point
ah = ah * yres;
aw = aw * xres;

% rescales the arrow height and width to retain original
% size.
mAxes = getappdata(getappdata(ax,'MasterAxes'),'MapGraphicsAxesObject');

origYlim = get(mAxes,'OrigYLim');
ah = ah * origYlim/ylim;
aw = aw * origYlim/ylim;
end
