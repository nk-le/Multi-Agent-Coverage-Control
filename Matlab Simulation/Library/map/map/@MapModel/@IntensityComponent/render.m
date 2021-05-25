function h = render(this,layerName,legend,ax,visibility) %#ok<INUSL>
%RENDER Render the IntensityComponent.
%
%   H = RENDER(LAYERNAME,LEGEND,AX,VISIBILITY) constructs an intensity
%   image in the axes AX, with the specified VISIBILITY. Input LEGEND is
%   ignored for this type of component.

% Copyright 1996-2008 The MathWorks, Inc.

R = this.ReferenceMatrix;
I = this.ImageData;
h = size(I,1);
w = size(I,2);
cc = pix2map(R,[1  1;...
                h  w]);

cdata = repmat(I,[1 1 3]);

h = image('Parent',ax,'CData',cdata,'XData',cc(:,1),'YData',cc(:,2));
set(h,'Visible',visibility,'Tag',layerName)
