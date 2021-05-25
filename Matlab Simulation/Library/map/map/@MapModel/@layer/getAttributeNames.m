function attrNames = getAttributeNames(this)
%

%   Copyright 1996-2003 The MathWorks, Inc.

% Assume only one component at this time.
attrNames = this.Components(1).getAttributeNames;