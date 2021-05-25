function cmap = interpcmap(cmapsource, cmin, cmax, clevels)
%interpcmap Interpolate rows of colormap matrix
%
%   CMAP = map.graphics.internal.interpcmap(CMAPSOURCE, CMIN, CMAX,
%   CLEVELS) constructs a linear mapping of the colors in the colormap
%   matrix CMAPSOURCE to the interval [CMIN CMAX], and interpolates it
%   using linear interpolation to assign a color value to each element in
%   the vector CLEVELS.  For elements of CLEVELS that are less than CMIN,
%   the color value is CMAPSOURCE(1,:).  For elements that exceed CMAX, the
%   color value is CMAPSOURCE(end,1:).
%
%   Inputs
%   ------
%   CMAPSOURCE -- N-by-3 colormap matrix (N >= 1)
%   CMIN       -- Lower data limit
%   CMAX       -- Upper data limit (CMAX > CMIN)
%   CLEVELS    -- Vector listing data values for which colors are needed
%
%   Output
%   ------
%   CMAP -- M-by-3 colormap matrix (interpolated from CMAPSOURCE)
%
%   Examples
%   --------
%   % Only one color in source colormap
%   cmapsource = [0 1 0]
%   cmap = map.graphics.internal.interpcmap(cmapsource, -100, 100, -150:50:150)
%   cmap = map.graphics.internal.interpcmap(cmapsource, -100, 100, -50:25:50)
%
%   % Two colors in source colormap
%   cmapsource = autumn(2)
%   cmap = map.graphics.internal.interpcmap(cmapsource, -100, 100, -150:25:150)
%   cmap = map.graphics.internal.interpcmap(cmapsource, -100, 100,  -50:25:50)
%
%   % Many colors in source colormap
%   cmapsource = jet(12)
%   cmap = map.graphics.internal.interpcmap(cmapsource, -100, 100, -150:25:150)
%   cmap = map.graphics.internal.interpcmap(cmapsource, -100, 100,  -50:25:50)
%   cmap = map.graphics.internal.interpcmap(cmapsource, -100, 100,    0:25:150)
%   cmap = map.graphics.internal.interpcmap(cmapsource, -100, 100, -150:25:0)

% Copyright 2012 The MathWorks, Inc.

% Number of source colors (assumed to 1 or greater)
n = size(cmapsource,1);

if n == 1
    % There is only one color; replicate it for use at all levels.
    cmap = cmapsource(ones(numel(clevels),1),:);
else
    % There's at least two colors. Map the levels linearly
    % to the colors, with a line defined by cmin and cmax.
    % Clamp the values in clevels
    clevels(clevels < cmin) = cmin;
    clevels(clevels > cmax) = cmax;
    
    % Compute a "generalized index" into the colormap, g. In general, g
    % will not be an integer. Instead its integer part will define a
    % pair of adjacent colors and its fractional part will define a
    % pair of weights. The weights will be used to interpolate linearly
    % between the colors. The values of g fall between 1 and n, inclusive.
    g = 1 + (n - 1) * (clevels - cmin) / (cmax - cmin);
    
    % Make sure g is a column vector.
    g = g(:);
    
    % Prepare for linear interpolation.
    k = floor(g);
    
    % Weight and value for the lower color.
    wLower = k + 1 - g;
    vLower = cmapsource(k,:);
    
    % Weight and value for the upper color.
    wUpper = g - k;
    vUpper = cmapsource(min(1 + k, n), :);
    
    % Compute the linearly interpolated values by taking weighted
    % combinations of vLower and vUpper. Here's one way:
    %
    %   cmap = wLower(:,[1 1 1]) .* vLower + wUpper(:,[1 1 1]) .* vUpper;
    %
    % Another is to use bsxfun:
    f = @times;
    cmap = bsxfun(f, wLower, vLower) + bsxfun(f, wUpper, vUpper);
end
