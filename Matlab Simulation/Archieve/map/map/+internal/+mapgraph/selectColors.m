function cindex = selectColors(cmap, levels)
%selectColors Select colors from a color map
%
%   Select colors from a color map in a way that is consistent with
%   'FaceColor','flat' and 'EdgeColor','flat' in a MATLAB patch object.
%   Given an N-by-3 color map, CMAP, and a monotonically increasing
%   vector, LEVELS, select a color to represent each level. Return a
%   a numel(levels)-by-1 row index into the color map, CINDEX. Then
%   the colors themselves can be computed like this:
%
%      colors = cmap(cindex,:);

% Copyright 2010 The MathWorks, Inc.

% Replace infinite values in the levels vector.
levels(levels == -Inf) = min(levels(levels > -Inf));
levels(levels ==  Inf) = max(levels(levels <  Inf));

numcolors = size(cmap,1);
if numel(levels) > 1
    cindex = 1 + round((numcolors - 1) * (levels - levels(1)) ...
        ./ (levels(end) - levels(1)));
else
    cindex = round((1 + numcolors)/2);
end
