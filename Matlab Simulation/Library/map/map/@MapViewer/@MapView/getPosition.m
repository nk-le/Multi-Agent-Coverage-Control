function p = getPosition(this,units)
%

%   Copyright 1996-2016 The MathWorks, Inc.

oldunits = get(this.Figure,'Units');
set(this.Figure,'Units',units);
p = get(this.Figure,'Position');
set(this.Figure,'Units',oldunits);
