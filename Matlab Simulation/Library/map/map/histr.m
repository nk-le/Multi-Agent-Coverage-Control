function [latbin,lonbin,count,wcount] = histr(lats,lons,bindensity,units)
%HISTR  Histogram for geographic points with equirectangular bins
%
%  [lat,lon,ct] = HISTR(lat0,lon0) computes a spatial histogram of
%  geographic data using equirectangular binning of one degree.  In
%  other words, one degree increments of latitude and longitude to
%  define the bins throughout the globe.  As a result, these bins are
%  not equal area.  The outputs are the location of bins in which the
%  data was accumulated, as well as the number of occurrences in these bins.
%
%  [lat,lon,ct] = HISTR(lat0,lon0,bindensity) sets the number of bins per
%  angular unit. This input must be in the same units as the lat and lon
%  input, which are in degrees by default. For example, a bindensity of 10
%  would be 10 bins per unit of latitude or longitude, resulting in 100
%  bins per square degree. The default is one cell per angular unit.
%
%  [lat,lon,ct] = HISTR(lat0,lon0,units) and
%  [lat,lon,ct] = HISTR(lat0,lon0,bindensity,units) use the input
%  units to define the angle units of the inputs and outputs.
%  If omitted, 'degrees' are assumed.
%
%  [lat,lon,ct,wt] = HISTR(...) returns the number of occurrences,
%  weighted by the area of each bin.  The weighting factors assume that
%  bins along the equator are given an area of 1.0.
%
%  See also HISTA.

% Copyright 1996-2020 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

narginchk(2,4)

if nargin == 2
    units = 'degrees';
    bindensity = 1;
elseif nargin == 3
    if ischar(bindensity) || isStringScalar(bindensity)
        units = bindensity;
        bindensity = 1;
    else
        units = 'degrees';
    end
end

if ~isequal(size(lats),size(lons))
    error(message('map:validate:inconsistentSizes','lats','lons'))
end
validateattributes(bindensity,{'numeric'},{'real','positive','scalar'},mfilename)

bindensity = ignoreComplex(bindensity, mfilename, 'bindensity');
bindensity = double(bindensity);

%  Convert to degrees and ensure column vectors
%  Ensure that the longitude data is between -180 and 180

[lats, lons] = toDegrees(units, lats(:), lons(:));
lons = wrapTo180(lons);

%  Construct a sparse matrix to bin the data into

latlim = [floor(min(lats)) ceil(max(lats))];
lonlim = [floor(min(lons)) ceil(max(lons))];
if lonlim(2) < lonlim(1)
    lonlim(2) = lonlim(1) + 360;
end
numrows = ceil(diff(latlim) * bindensity);
numcols = ceil(diff(lonlim) * bindensity);
V = sparse(numrows, numcols);
R = georefcells(latlim, lonlim, size(V));

%  Bin the data into the sparse matrix

[rows, cols] = geographicToDiscreteOmitOutside(R, lats, lons);
indx = (cols - 1) * R.RasterSize(1) + rows;
for i = 1:length(indx)
    V(indx(i)) = V(indx(i)) + 1;
end

%  Determine the locations of the binned data

[row, col, count] = find(V);
[latbin, lonbin] = intrinsicToGeographic(R, col, row);

%  Convert back to the proper units

[latbin, lonbin] = fromDegrees(units, latbin, lonbin);

%  Determine the data occurrences weighted by the bin area
%  If this output is not requested, don't waste time calculating it.

if nargout == 4
    [~, areavec] = areamat(V > 0, R);
    wcount = full(max(areavec(row)) * count ./ areavec(row) );
end
