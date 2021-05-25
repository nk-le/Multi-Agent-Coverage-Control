function setAxesProperties(h)
%setAxesProperties Set the axes appearance properties
%
%   setAxesProperties(H) obtains the axes handle from the child handle H.
%   The axes appearance properties are set to 'image' if the handle H is an
%   image; otherwise the properties are set to 'equal'.

% Copyright 2006-2019 The MathWorks, Inc.

if ~isempty(h)
   ax = get(h(1),'Parent');
   allowAxesReset = ~ishold(ax) && ~ismapped(ax);
   if allowAxesReset
      imageType  = ishghandle(h(1),'image');
      if imageType
         xLimMode = get(ax, 'XLimMode');
         yLimMode = get(ax, 'YLimMode');
         axis(ax,'image');
         if ~isequal(xLimMode, get(ax,'XLimMode') ) || ...
               ~isequal(yLimMode, get(ax,'YLimMode') )
            % The mode for the limits has changed
            % Reset back to the original mode
            set(ax,'XLimMode', xLimMode, 'YLimMode', yLimMode);
         end
      else
         surfaceType = ishghandle(h(1),'surface');
         if surfaceType
            view(ax, 2);
         end
         set(ax, 'DataAspectRatio', [1 1 1]);
      end
      set(ax,'ClippingStyle','rectangle')
   end
end
