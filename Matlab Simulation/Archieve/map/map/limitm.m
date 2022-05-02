function [latlim, lonlim] = limitm(Z,R)
%LIMITM  Latitude and longitude limits for regular data grid
%
%        LIMITM will be removed in a future release. Use the
%        LatitudeLimits and LongitudeLimits properties of a
%        geographic raster reference object instead.
%
%   [LATLIM, LONLIM] = LIMITM(Z,R) computes the latitude and longitude
%   limits of the geographic quadrangle bounding the regular data grid Z
%   spatially referenced by R. R can be a geographic raster reference
%   object, a referencing vector, or a referencing matrix.
%
%   If R is a geographic raster reference object, its RasterSize property
%   must be consistent with size(Z).
%
%   If R is a referencing vector, it must be a 1-by-3 with elements:
%
%     [cells/degree northern_latitude_limit western_longitude_limit]
%
%   If R is a referencing matrix, it must be 3-by-2 and transform raster
%   row and column indices to/from geographic coordinates according to:
% 
%                     [lon lat] = [row col 1] * R.
%
%   If R is a referencing matrix, it must also define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel. The output
%   LATLIM is a vector of the form [southern_limit northern_limit] and
%   LONLIM is a vector of the form [western_limit eastern_limit].  All
%   angles are in units of degrees.
%
%   LATLONLIM = LIMITM(Z,R) concatenates LATLIM and LONLIM into a
%   1-by-4 row vector of the form:
%
%     [southern_limit northern_limit western_limit eastern_limit].
%
%   See also GEOREFCELLS, GEOREFPOSTINGS, GEORASTERREF,
%            refmatToGeoRasterReference, refvecToGeoRasterReference

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(2,2)

R = internal.map.convertToGeoRasterRef( ...
    R, size(Z), 'degrees', 'LIMITM', 'R', 2);

latlim = R.LatitudeLimits;
lonlim = R.LongitudeLimits;

% If necessary, concatenate limits into a single 1-by-4 output vector.
if nargout ~= 2
    latlim = [latlim lonlim];
end
