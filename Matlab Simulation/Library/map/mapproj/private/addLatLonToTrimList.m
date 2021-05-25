function [trimmed, indx] = addLatLonToTrimList(trimmed, lat, lon)

% Copyright 2006 The MathWorks, Inc.

% Note
% ----
% indx is always a column vector.  lat and lon may be either column
% vectors or row vectors. To select the elements of lat listed in indx
% and be assured that the result is always a column vector, use
% reshape(lat(indx),size(indx). Likewise for lon.

if size(trimmed,2) == 3
    indx = trimmed(:,1);
    trimmed(:, 2:3) = ...
        [reshape(lat(indx),size(indx)) reshape(lon(indx),size(indx))];
elseif size(trimmed,2) == 4
    indx = trimmed(:,1) + (trimmed(:,2) - 1) * size(lat,1);
    trimmed(:, 3:4) = ...
        [reshape(lat(indx),size(indx)) reshape(lon(indx),size(indx))];
else
    indx = [];
end
