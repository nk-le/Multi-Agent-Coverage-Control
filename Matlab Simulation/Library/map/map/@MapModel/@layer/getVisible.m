function v = getVisible(this)
%GETVISIBLE Return visible property of layer.
%
%   V = GETVISIBLE returns 'on' if the layer is visible or 'off' otherwise.

%   Copyright 1996-2003 The MathWorks, Inc.

v = this.Visible;


%if strcmp(lower(this.Visible),'on')
%  v = true;
%elseif strcmp(lower(this.Visible),'off')
%  v = false;
%end

