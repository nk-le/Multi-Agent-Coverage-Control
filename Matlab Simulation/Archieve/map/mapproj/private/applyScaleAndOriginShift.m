function [x, y] = applyScaleAndOriginShift(mstruct, x, y)
% Apply scale factor, false easting, and false northing

% Copyright 2006 The MathWorks, Inc.

x = x * mstruct.scalefactor + mstruct.falseeasting;
y = y * mstruct.scalefactor + mstruct.falsenorthing;
