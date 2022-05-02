function [newlat,newlon,indx] = filterm(lat,lon,map,R,allowed)
%FILTERM  Filter latitudes/longitudes based on underlying data grid
%
%   [latout,lonout] = FILTERM(lat,lon,Z,R,allowed) filters a set of
%   latitudes and longitudes to include only those data points which
%   have a corresponding value in Z equal to allowed.  R can be a
%   geographic raster reference object, a referencing vector, or a
%   referencing matrix.
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
%   If R is a referencing matrix, it must define a (non-rotational,
%   non-skewed) relationship in which each column of the data grid falls
%   along a meridian and each row falls along a parallel. 
%
%   [latout,lonout,indx] = FILTERM(lat,lon,Z,R,allowed) also returns the
%   indices of the included points.
%
%  See also IMBEDM, HISTR, HISTA

% Copyright 1996-2013 The MathWorks, Inc.
% Written by:  E. Byrns, E. Brown

%  Validate inputs
checklatlon(lat, lon, 'filterm', 'LAT', 'LON', 1, 2)
validateattributes(lat, ...
    {'double','single'}, {'real','finite','vector'}, 'filterm', 'LAT', 1)
validateattributes(lon, ...
    {'double','single'}, {'real','finite','vector'}, 'filterm', 'LON', 2)
validateattributes(map, ...
    {'numeric','logical'}, {'real','2d'}, 'filterm', 'Z', 3)

%  Retrieve the code for each lat/lon data point

code = ltln2val(map, R, lat, lon);

%  Test for each allowed code

indx = [];
for i = 1:length(allowed)
    testindx = find(code == allowed(i));

    if ~isempty(testindx)           %  Save allowed indices
	   indx  = [indx;  testindx];
    end
end

%  Sort indices so as to NOT alter the data point ordering in the
%  original vectors.  Eliminate double counting of data points.

if numel(indx) > 1
	indx = sort(indx); 
	indx = [indx(diff(indx)~=0); indx(length(indx))];
end

%  Accept allowed data points

if ~isempty(indx)
	newlat = lat(indx);
    newlon = lon(indx);
else
    newlat = [];
    newlon = [];
end

%  Set output arguments if necessary

if nargout < 2
    newlat = [newlat newlon];
end
