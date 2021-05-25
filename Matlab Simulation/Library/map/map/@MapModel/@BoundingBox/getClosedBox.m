function box = getClosedBox(this)
%GETBOXCORNERS Return 5 Box Corners
%
%  BOX = GETCLOSEDBOX returns all 5 bos corners.  The corners are orders
%  counter-clockwise starting in the lower-left.

%   Copyright 1996-2003 The MathWorks, Inc.

bb = this.Corners;

box = [bb(1,1) bb(1,2);...
       bb(2,1) bb(1,2);...
       bb(2,1) bb(2,2);...
       bb(1,1) bb(2,2);...
       bb(1,1) bb(1,2)];

