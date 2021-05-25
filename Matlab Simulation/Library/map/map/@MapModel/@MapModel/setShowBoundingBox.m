function setShowBoundingBox(this,layername,val)
%SETSHOWBOUNDINGBOX Set ShowBoundingBox property
%
%   SETSHOWBOUNDINGBOX(LAYER,VALUE) sets the ShowBoundingBox property of
%   LAYER to VALUE.

%   Copyright 1996-2003 The MathWorks, Inc.

layer = this.getLayer(layername);
layer.setShowBoundingBox(val);

EventData = LayerEvent.ShowBoundingBox(this,layername,val);
this.send('ShowBoundingBox',EventData);
