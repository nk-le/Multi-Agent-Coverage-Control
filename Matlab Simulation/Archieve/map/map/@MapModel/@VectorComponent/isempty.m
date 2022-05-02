function isemp = isempty(this)
%ISEMPTY True if component has no features.

%   Copyright 1996-2003 The MathWorks, Inc.

isemp = numel(this.Features) == 0;