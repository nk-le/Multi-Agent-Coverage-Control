function [clevels, colors] = colorbarContourLevelsAndColors(h, fill)
% Levels and colors for use in a contour color bar
%
%   Given the handle to an internal.mapgraph.ContourGroup object, H, and a
%   scalar logical, FILL, determine the levels, CLEVELS, and RGB colors,
%   COLORS, to use in a contour colorbar. If FILL is false (indicating
%   contour lines), then CLEVELS includes the values from h.LevelList that
%   are bounded by either the data limits (if the CLimMode is 'auto') or
%   the axes CLim (if CLimMode is 'manual'). If FILL is true (indicating
%   fill polygons), then CLEVELS includes either the data limits or the
%   axes CLim along with the contour levels that they bound. If there are N
%   elements in CLEVELS and FILL is false then the second output, COLORS,
%   is an N-by-3 array of RGB colors selected from h.LineColormap. If FILL
%   is TRUE, COLORS is (N+1)-by-3 and the colors are selected from
%   h.FillColormap.

% Copyright 2011 The MathWorks, Inc.

% Bound levels for which ticks will be needed.
ax = ancestor(h.HGGroup,'axes');
if strcmp(get(ax,'CLimMode'),'manual')
    % Take the limits from the axes.
    climits = get(ax,'CLim');
    cmin = climits(1);
    cmax = climits(2);
else
    % Take the limits from the data.
    cmin = min(h.ZData(:));
    cmax = max(h.ZData(:));
end

% Compute levels at which ticks are needed, and
% the RGB colors to use in the colorbar.
levels = h.LevelList;
if fill
    % Colorbar is for fill polygons. Given n contour levels,
    % return up to n + 2 levels and up to n + 1 colors.
    minLevels = [-Inf levels];
    maxLevels = [levels  Inf];
    keep = (cmin < maxLevels & minLevels < cmax);
    colors = h.FillColormap(keep,:);
    
    keep = find(keep);
    clevels = sort(unique( ...
        [cmin minLevels(1,keep(2:end)) maxLevels(1,keep(1:end-1)) cmax]));
else
    % Colorbar is for contour lines. Given n contour levels,
    % return up to n levels and n colors.
    keep = (cmin <= levels & levels <= cmax);
    colors = h.LineColormap(keep,:);
    clevels = levels(1,keep);
end

% Replace infinite values in the clevels vector.
clevels(clevels == -Inf) = min(clevels(clevels > -Inf));
clevels(clevels ==  Inf) = max(clevels(clevels <  Inf));

end
