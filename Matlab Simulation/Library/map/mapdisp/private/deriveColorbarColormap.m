function [bigmap, limits] = deriveColorbarColormap(h)
%deriveColorbarColormap Compute colormap matrix and limits
%
%   [BIGMAP, LIMITS] = deriveColorbarColormap(H) returns in BIGMAP a big
%   (2000-by-3) colormap matrix filled with sections of constant color,
%   with color changes located in proportion to the relative values of the
%   actual contour levels in the geographic contour object, H. LIMITS is a
%   two-element vector containing the colorbar limits.

% Copyright 2013 The MathWorks, Inc.

% The colorbar is for fill colors only, not line colors.
fill = true;
[clevels, fillColors] = colorbarContourLevelsAndColors(h, fill);

% Initialize a big colormap
m = 2000;
bigmap = zeros(m,3);

% Work the work out the numbers of the rows preceding each color change, r
relativeLevels = (clevels(2:end-1) - clevels(1))/(clevels(end) - clevels(1));

r = ceil(0.5 + m * relativeLevels);

% Assign row indices partition the big colormap into section of constant
% color. Each section is bounded by a(k) and b(k), for k = 1, ..., n.
n = size(fillColors,1);
a = ones(n,1);
b = m + zeros(n,1);
a(2:end) = r + 1;
b(1:end-1) = r;

% Copy the fill colors into the big colormap section by section.
for k = 1:n
    bigmap(a(k):b(k),1) = fillColors(k,1);
    bigmap(a(k):b(k),2) = fillColors(k,2);
    bigmap(a(k):b(k),3) = fillColors(k,3);
end

% Derive colorbar limits from the clevels vector.
limits = [clevels(1) clevels(end)];
