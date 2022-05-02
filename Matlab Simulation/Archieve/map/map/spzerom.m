function [Z, refvec] = spzerom(latlim, lonlim, scale)
%SPZEROM  Construct sparse regular data grid of 0s
%
%   SPZEROM will removed in a future release.
%   Instead, create a geographic raster reference object using GEOREFCELLS
%   and then use SPARSE to create an array of the appropriate size:
%
%       R = georefcells(latlim,lonlim,1/scale,1/scale);
%       Z = sparse(R.RasterSize(1),R.RasterSize(2));
%
%   [Z, REFVEC] = SPZEROM(LATLIM, LONLIM, SCALE) constructs a sparse
%   regular data grid consisting entirely of 0s.  The two-element
%   vectors LATLIM and LONLIM define the latitude and longitude limits
%   of the grid, in degrees.  They should be of the form [south north]
%   and [west east], respectively.  The number of rows and columns per
%   degree is set by the scalar value SCALE.  REFVEC is the
%   three-element referencing vector for the data grid.
%
%   See also GEOREFCELLS, SPARSE

% Copyright 1996-2020 The MathWorks, Inc.

[nrows, ncols, refvec] = sizem(latlim, lonlim, scale);
Z = sparse(nrows, ncols);
