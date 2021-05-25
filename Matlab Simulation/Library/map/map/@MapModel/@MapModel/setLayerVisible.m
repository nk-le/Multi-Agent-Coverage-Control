function setLayerVisible(this,layername,val)
%SETLAYERVISIBLE Set Visible property
%
%   SETLAYERVISIBLE(LAYER,VALUE) sets the Visible property of LAYER to VALUE.

%   Copyright 1996-2003 The MathWorks, Inc.

layer = this.getLayer(layername);

if islogical(val)
  if val
    val = 'On';
  else
    val = 'Off';
  end
end

layer.setVisible(val);
EventData = LayerEvent.Visible(this,layername,val);
this.send('Visible',EventData);
