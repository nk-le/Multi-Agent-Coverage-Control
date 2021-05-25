function h = render(this,layerName,legend,ax,visibility) %#ok<INUSL>
%RENDER Render the IndexedComponent.
%
%   H = RENDER(LAYERNAME,LEGEND,AX,VISIBILITY) constructs an indexed
%   image in the axes AX, with the specified VISIBILITY. Input LEGEND is
%   ignored for this type of component.

% Copyright 1996-2008 The MathWorks, Inc.

R = this.ReferenceMatrix;
I = this.ImageData;
h = size(I,1);
w = size(I,2);
cc = pix2map(R,[1  1;...
                h  w]);

h = image('Parent',ax,'CData',I,'CDataMapping','scaled', ...
          'XData',cc(:,1),'YData',cc(:,2));
colormap(this.Colormap);
set(h,'Visible',visibility,'Tag',layerName)
