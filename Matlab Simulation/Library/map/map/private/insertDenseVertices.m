function [ilat, ilon] = insertDenseVertices(lat, lon, indx, steps, linspacefcn)
% Insert new, intermediate vertices when densifying a curve -- supports
% densifyGreatCircle, densifyRhumbline, and densifyLinear, each of which
% provides its own "linspacefcn" function handle.

% Copyright 2019 The MathWorks, Inc.

% Length of output vectors
N = numel(lat) + sum(steps) - numel(steps);

% Pre-allocate outputs.
ilat = zeros(N,1);
ilon = zeros(N,1);

s = 1;
sNew = 1;
for k = 1:numel(indx)
    % Insert vertices between lat(indx(k)), lon(indx(k))
    % and lat(1 + indx(k)), lon(1 + indx(k)).
    
    % Copy the elements that precede the current insertion point.
    e = indx(k);
    eNew = sNew + e - s;
    ilat(sNew:eNew) = lat(s:e);
    ilon(sNew:eNew) = lon(s:e);
    
    % Advance s to be ready for the next iteration (or final copy),
    % and also for use in the insertion step below.
    s = 1 + e;
    
    % Compute the new vertices that are to be inserted
    [latinsert, loninsert] = linspacefcn(lat, lon, e, steps(k));
    
    % Copy the new vertices into the output arrays.
    sNew = eNew + 1;
    eNew = eNew + numel(latinsert);
    ilat(sNew:eNew) = latinsert;
    ilon(sNew:eNew) = loninsert;
    
    % Advance sNew to be ready for the next iteration (or final copy).
    sNew = eNew + 1;
end

% Append any vertices that come after the last insertion point. Note
% that if indx is empty, we'll have skipped the loop, s will equal 1, and
% we'll be making an exact copy of the inputs.
ilat(sNew:end) = lat(s:end);
ilon(sNew:end) = lon(s:end);
