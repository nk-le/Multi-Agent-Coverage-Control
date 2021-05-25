function tf = multipleDistinctLocations(lat,lon,angleunits)
% Return true if and only if the lat, lon arrays include more than one
% distinct location.

% Copyright 2007 The MathWorks, Inc.

% Merge lat, lon into a single complex array and see if it contains more
% than one unique, finite value.
lon = mod(toDegrees(angleunits, lon), 360);
s = lat(:) + i*lon(:);
s(~isfinite(s)) = [];
tf = (numel(unique(s)) > 1);
