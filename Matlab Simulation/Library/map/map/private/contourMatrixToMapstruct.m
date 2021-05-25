function S = contourMatrixToMapstruct(c)
% Convert a standard MATLAB 2-by-N "contour matrix" to a
% mapstruct with a geometry of 'Line' and one element per
% contour level.

% Copyright 2010 The MathWorks, Inc.

if isempty(c)
    % Return early if there are no contour lines.
    S = emptyContourStructures();
    return
end

% Number of columns in c
ncols = size(c,2);

% Count the number of contours
nContours = 0;
col = 1;
while col <= ncols
    nContours = nContours + 1;
    col = col + 1 + c(2,col);
end

% Collect three arrays:
%   levels(k) contains the level value of the k-th contour
%   count(k) contains the number of vertices of the k-th contour
%   cols(k) indicates the contour matrix column in which the level and
%      count information for the k-th contour are stored.
count = zeros(1,nContours);
levels = NaN + count;
col = 1;
for k = 1:nContours
    levels(k) = c(1,col);
    count(k)  = c(2,col);
    col = col + 1 + count(k);
end
cols = 1 + cumsum(1 + count);
cols = [1 cols(1:(end-1))];

% Sort levels, count, and cols in order of ascending levels
[levels, indx] = sort(levels);
count = count(indx);
cols = cols(indx);

% In the sorted arrays, find the first and
% last index for each distinct level
levelEnd = find(diff(levels) > 0);
levelStart = 1 + [0 levelEnd];
levelEnd = [levelEnd numel(levels)];

% Initialize the mapstruct
nLevels = numel(levelStart);
S(nLevels,1) = struct(...
    'Geometry', [], ...
    'BoundingBox', [], ...
    'X', [], ...
    'Y', [], ...
    'Level', []);

% Fill in the mapstruct
for j = 1:nLevels
    S(j).Geometry = 'Line';
    S(j).Level = levels(levelStart(j));
    [S(j).X, S(j).Y, S(j).BoundingBox] ...
        = getContourVertices(c, levelStart(j), levelEnd(j), count, cols);
end

%-----------------------------------------------------------------------

function [x, y, bbox] ...
    = getContourVertices(c, levelStart, levelEnd, count, cols)
% For a given contour level, concatenate the individual parts given in
% the contour matrix into a single pair of NaN-separated vectors, and
% compute the corresponding bounding box.

nVertices = sum(1 + count(levelStart:levelEnd));
x = NaN + zeros(1,nVertices);
y = x;

vs = 1;
for k = levelStart:levelEnd
    ve = vs + count(k) - 1;
    cs = cols(k) + 1;
    ce = cols(k) + count(k);
    x(vs:ve) = c(1,(cs:ce));
    y(vs:ve) = c(2,(cs:ce));
    vs = ve + 2;
end
bbox = [min(x) min(y); max(x) max(y)];
