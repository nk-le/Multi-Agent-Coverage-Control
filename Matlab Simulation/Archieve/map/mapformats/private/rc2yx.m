function [ygrat,xgrat] = rc2yx(rowgrat,colgrat,y1,x1,yperrow,xpercol)
%RC2YX Row and column indices to x and y coordinates
%
%   [ygrat,xgrat] = RC2YX(rowgrat,colgrat,y1,x1,yperrow,xpercol) computes y
%   and x coordinates from row and column indices. rowgrat and colgrat are
%   matrices of the same size containing integer row and column indices for
%   a grid with the upper left corner at the map coordinates x1 and
%   y1. yperrow and xpercol are the y and x increment per row and column.
%   The outputs ygrat and xgrat are the map coordinates corresponding
%   to matrix locations rowgrat and colgrat.
%
% See also YX2RC, READMTX.

% Copyright 1996-2011 The MathWorks, Inc.

ygrat = (rowgrat-1)*yperrow + y1;
xgrat = (colgrat-1)*xpercol + x1;
