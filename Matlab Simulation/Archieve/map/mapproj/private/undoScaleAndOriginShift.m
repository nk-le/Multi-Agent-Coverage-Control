function [x, y] = undoScaleAndOriginShift(mstruct, x, y)
% Remove origin shift and return to natural scale

% Copyright 2006 The MathWorks, Inc.

x = (x - mstruct.falseeasting )/(mstruct.scalefactor);
y = (y - mstruct.falsenorthing)/(mstruct.scalefactor);
