function p = getFigurePositionInPoints(this)
% Return the position of the map viewer figure in points.

% Copyright 2015 The MathWorks, Inc.

    f = this.Figure;
    oldUnits = f.Units;
    f.Units = 'points';
    p = f.Position;
    f.Units = oldUnits;
end
