function [r,c,refvec] = sizem(latlim,lonlim,scale)
%SIZEM  Row and column dimensions needed for regular data grid
%
%   SIZEM will be removed in a future release.
%   Instead, construct a geographic raster reference object using
%   GEOREFCELLS, then access its RasterSize property.
%
%       R = georefcells(latlim,lonlim,1/scale,1/scale);
%       NROWS = R.RasterSize(1);
%       NCOLS = R.RasterSize(2);
%
%   [NROWS,NCOLS] = SIZEM(LATLIM,LONLIM,SCALE) computes the row and column
%   dimensions needed for a regular data grid aligned with geographic
%   coordinates.  LATLIM and LONLIM are two-element vectors defining the
%   latitude and longitude limits in degrees. SCALE is a scalar specifying
%   the number of data samples per unit of latitude and longitude (e.g. 10
%   entries per degree).
%
%   SZ = SIZEM(...) returns a single output, where SZ = [NROWS NCOLS].
%
%   [NROWS,NCOLS,REFVEC] = SIZEM(...) returns the referencing vector for
%   the data grid.
%
%   See also GEOREFCELLS

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

validateattributes(latlim, {'double'}, ...
    {'finite','numel',2,'>=',-90,'<=',90}, '', 'latlim')

validateattributes(lonlim, ...
    {'double'}, {'finite','numel',2}, '', 'lonlim')

validateattributes(scale, {'double'}, {'scalar'}, '', 'scale')

latlim  = ignoreComplex(latlim,  mfilename, 'latlim');
lonlim  = ignoreComplex(lonlim,  mfilename, 'lonlim');
scale   = ignoreComplex(scale,   mfilename, 'scale');

%  Determine the starting and ending latitude and longitude

startlat = min(latlim);
endlat   = max(latlim);
startlon = lonlim(1);
endlon   = lonlim(2);
if endlon < startlon
    endlon = endlon + 360;
end

%  Compute the number of rows and columns needed

rows = ceil((endlat - startlat)*scale);
cols = ceil((endlon - startlon)*scale);

%  Set the output arguments

if nargout == 1
    r = [rows cols];
elseif nargout == 2
    r = rows;
    c = cols;
elseif nargout == 3
    r = rows;
    c = cols;
    refvec = [scale endlat startlon];
end
