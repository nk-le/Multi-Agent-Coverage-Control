function p = getPositionInPoints(h)
% Return position of graphics object in units of points.

% Copyright 2015 The MathWorks, Inc.

    oldunits = h.Units;
    h.Units = 'points';
    p = h.Position;
    h.Units = oldunits;
end
