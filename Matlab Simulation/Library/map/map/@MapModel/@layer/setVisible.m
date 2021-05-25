function setVisible(this,value)
%SETVISIBLE Set the visible property of layer.
%
%   SETVISIBLE(VALUE) Sets the visible property of the layer to 'on' or 'off'.

%   Copyright 1996-2003 The MathWorks, Inc.

if islogical(value)
  if value
    value = 'On';
  else
    value = 'Off';
  end
end

this.Visible = value;
