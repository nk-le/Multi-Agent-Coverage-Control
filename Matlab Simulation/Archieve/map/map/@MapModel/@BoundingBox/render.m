function h = render(this,name,textstring,ax)
%RENDER Render bounding box
%
%   H = RENDER(NAME,AX) Renders a bounding box with the name NAME into the
%   axes AX.

%   Copyright 1996-2012 The MathWorks, Inc.

box = this.getClosedBox;
h = map.graphics.internal.mapgraphics.BoundingBox( ...
    [name '_BoundingBox'],textstring,box,ax);
