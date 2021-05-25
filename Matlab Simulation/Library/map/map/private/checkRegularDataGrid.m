function [Z, R] = checkRegularDataGrid(Z, R, fcnName)
%CHECKREGULARDATAGRID Check regular data grid inputs
%
%   [Z, R] = checkRegularDataGrid(Z, R, fcnName) validates the regular data
%   grid, defined by the inputs, Z and R. A referencing matrix is returned
%   in R. fcnName is used for constructing an error message. 

% Copyright 2010-2018 The MathWorks, Inc.

if isobject(R) && isprop(R,'RasterSize')
    expectedSize = R.RasterSize;
else
    expectedSize = size(Z);
end
validateattributes(Z, {'double', 'single'}, ...
    {'real', '2d', 'nonempty', 'size', expectedSize}, fcnName, 'Z' ,1);
R = checkRefObj(fcnName, R, size(Z), 2);
