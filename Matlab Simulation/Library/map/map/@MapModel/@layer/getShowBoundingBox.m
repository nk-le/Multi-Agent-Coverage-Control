function b = getShowBoundingBox(this)
%GETSHOWBOUNDINGBOX

%   Copyright 1996-2003 The MathWorks, Inc.

b = this.ShowBoundingBox;

%if strcmp(lower(this.ShowBoundingBox),'on')
%  b = true;
%elseif strcmp(lower(this.ShowBoundingBox),'off')
%  b = false;
%end