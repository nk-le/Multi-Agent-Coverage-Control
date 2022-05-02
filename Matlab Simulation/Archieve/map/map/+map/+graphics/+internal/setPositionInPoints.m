function setPositionInPoints(h, pos)
% Set position of graphics object in units of points.

% Copyright 2015 The MathWorks, Inc.

    oldunits = h.Units;
    h.Units = 'points';
    h.Position = pos;
    h.Units = oldunits;
end
