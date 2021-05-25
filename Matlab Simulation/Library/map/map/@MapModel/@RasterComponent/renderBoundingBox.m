function renderBoundingBox(this,layer,ax)
%RENDERBOUNDINGBOX Draw bounding box 

%   Copyright 1996-2012 The MathWorks, Inc.

bb = this.getBoundingBox;
box = bb.getClosedBox;
name = layer.getLayerName;

map.graphics.internal.mapgraphics.BoundingBox( ...
    [name '_BoundingBox'],name,box,ax);
