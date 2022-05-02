function updateColorbarWithFillColors(cb,h)
%updateColorbarWithFillColors Update color bar with fill colors
%
%   updateColorbarWithFillColors(CB, H) updates the values of the
%   colorbar's Colormap and Limit properties with a new ones derived from
%   the contour's FillColormap and levels, with a region of solid color
%   corresponding to each contour interval. These regions will not
%   necessarily be all the same size, but will instead reflect the relative
%   sizes of the contour intervals themselves.

% Copyright 2013-2014 The MathWorks, Inc.

if ishghandle(cb)
    [bigmap, limits] = deriveColorbarColormap(h);
    set(cb,'Colormap',bigmap,'Limits',limits)
end
