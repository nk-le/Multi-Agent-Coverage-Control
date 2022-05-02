function isemp = isempty(this)
%ISEMPTY True for empty layer
%

%   Copyright 1996-2003 The MathWorks, Inc.

isemp = numel(this.Components) == 0;
