function setShowBoundingBox(this,b)
%SETSHOWBOUNDINGBOX Set ShowBoundingBox property
%

%   Copyright 1996-2003 The MathWorks, Inc.

if islogical(b)
  if b
    b = 'On';
  else
    b = 'Off';
  end
end

this.ShowBoundingBox = b;

