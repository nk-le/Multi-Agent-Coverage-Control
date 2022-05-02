function p = getMapCurrentPoint(this)
%

% Copyright 1996-2008 The MathWorks, Inc.

p = get(this.getAxes(),'CurrentPoint');
p = [p(1) p(3)];
