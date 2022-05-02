function c = getBoxCorners(this)
%GETBOXCORNERS Return Box Corners
%
%  C = GETBOXCORNERS returns the lower-left and upper-right corners of the
%  bounding box [lower-left-x,y; upper-right-x,y],
%
%  or equivalently,  [left      bottom;
%                     right        top]

%   Copyright 1996-2003 The MathWorks, Inc.

c = this.Corners;
