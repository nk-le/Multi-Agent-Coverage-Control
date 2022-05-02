function [cmap,clim] = demcmap(varargin)
%DEMCMAP Colormaps appropriate to terrain elevation data
%
%   DEMCMAP(ZLIMITS) creates a colormap matrix for use in displaying
%   digital elevation models (DEMs). ZLIMITS is a 1-by-2 numeric vector
%   containing the minimum and maximum elevations to be represented by the
%   colormap. By default, the colormap has 64 colors. Shades of green and
%   brown are provided for positive elevations, and various shades of blue
%   are provided for elevations below sea level. The relative number of
%   colors assigned to land and sea are proportional to the ranges in
%   terrain elevation and bathymetric depth. DEMCMAP also determines color
%   axis limits that will place the interface between land and sea on the
%   zero elevation contour. The colormap is applied to the current figure
%   and the color axis limits are applied to the current axes, unless
%   output arguments are provided (as shown in the last syntax below).
%
%   DEMCMAP(ZLIMITS, NCOLORS) creates a colormap with length NCOLORS.
%
%   DEMCMAP(ZLIMITS, NCOLORS, CMAPSEA, CMAPLAND) allows the default
%   colormaps for sea and land to be replaced with the colormaps specified
%   by CMAPSEA and CMAPLAND, which are RGB colormap matrices of any length.
%   Alternatively, you can retain the default colors for either land or sea
%   by providing an empty matrix in place of either colormap matrix.
%
%   DEMCMAP('inc', ZLIMITS, DELTAZ, ...) controls the color quantization by
%   choosing the number of colors in the colormap such that each color
%   represents an increment of elevation roughly equal to DELTAZ.
%
%   [CMAP, CLIM] = DEMCMAP(...) returns the colormap matrix and color axis
%   limit vector, but does not apply them to the current figure and axes.
%
%   Remark
%   ------
%   As a convenience, DEMCMAP will compute the extrema automatically if you
%   provide a complete elevation grid in place of ZLIMITS. Therefore,
%   DEMCMAP(Z, ...) is equivalent to DEMCMAP([min(Z(:)) max(Z(:))], ...).
%
%   Example
%   -------
%   load topo60c
%   figure('Color','white')
%   worldmap world
%   geoshow(topo60c,topo60cR,'DisplayType','texturemap')
%   demcmap(topo60c,16)
%   colorbar

% Copyright 1996-2020 The MathWorks, Inc.

% Additional remarks (for function reference)
% 
%   DEMCMAP constructs a colormap matrix with the number of colors
%   specified by the ncolors input, as noted previously. The colormap has a
%   "sea" partition of length nsea and "land" partition of length nland,
%   such that nsea + nland = ncolors. The sea partition consists of rows 1
%   through nsea, and the land partition consists of rows nsea + 1 through
%   the end.
%
%   The land partition is populated with colors copied or interpolated from
%   the CMAPLAND in input, if provided. If CMAPLAND contains fewer than
%   nland colors, then additional colors are interpolated. And if CMAPLAND
%   contains more than nland colors, then the first nland colors are used.
%   In this case, colors near the end of the CMAPLAND colormap are ignored.
%   The nsea colors in the sea partition comes from the cmapsea input in
%   the same way, except that if CMAPSEA contains more than nsea colors,
%   the last nsea colors (not the first) are used. In this case, colors
%   near the beginning of the CMAPSEA colormap are ignored.
%
%   To use the current figure colormap, you can nest a call to the colormap
%   function in place of either the CMAPSEA or CMAPLAND colormap matrix
%   input. For example, to use the current figure colormap for areas below
%   sea level and the default colormap for land areas, use something like
%   this:
%
%   demcmap(zlimits, n, colormap, [])
%
%   The same thing can be accomplished by providing the string 'window' in
%   place of either these inputs, but this usage is not recommended.

% Parse and validate the cmode string.
if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end
if ischar(varargin{1})
    cmode = validatestring(varargin{1}, {'size','inc'}, 'DEMCMAP', '', 1);
    varargin(1) = [];
else
    cmode = 'size';
end

nargs = numel(varargin);
if nargs < 1 || nargs > 4
    error(message('map:validate:invalidArgCount'))
end

% Parse and validate the zLimits vector (or Z matrix).
zlimits = varargin{1};
validateattributes(zlimits, {'numeric'}, {'nonempty'}, 'DEMCMAP', 'MAP')

% Parse the ncolors/deltaZ input. Defer validation, which is handled in the
% partitionColors function.
if nargs >= 2
    sizearg = varargin{2};
else
    sizearg = [];
end

% Parse and validate cmapsea.
if nargs >= 3
    cmapsea = varargin{3};
else
    cmapsea = [];
end

if isempty(cmapsea)
    cmapsea = seaColormap;
elseif strcmp(cmapsea,'window')
    cmapsea = colormap;
else
    validateColormap(cmapsea,'CMAPSEA')
end

% Parse and validate cmapland.
if nargs >= 4
    cmapland = varargin{4};
else
    cmapland = [];
end

if isempty(cmapland)
    cmapland = landColormap;
elseif strcmp(cmapland,'window')
    cmapland = colormap;
else
    validateColormap(cmapland,'CMAPLAND')
end

% Compute number of colors for land and sea, and color axis limits.
[nsea, nland, clim0] = partitionColors(cmode, zlimits, sizearg);

% Compute sea and land colormaps in HSV, concatenate, and convert to RGB.
hsvsea  = hsvColormapForSea(nsea, rgb2hsv(cmapsea));
hsvland = hsvColormapForLand(nland, rgb2hsv(cmapland));
cmap0 = hsv2rgb([hsvsea; hsvland]);

%  Set the output arguments, unless none are requested.
if nargout == 0
    caxis(clim0);
    colormap(cmap0)
else
    cmap = cmap0;
    clim = clim0;
end

%--------------------------------------------------------------------------

function [nsea, nland, clim] = partitionColors(cmode, zlimits, sizearg)
% Compute number of colors for land and sea, and color axis limits.

minZ = double(min(zlimits(:)));
maxZ = double(max(zlimits(:)));
if strcmp(cmode,'size')
    % cmode is 'size' ==> The input is ncolors.
    if isempty(sizearg)
        ncolors = 64;
    else
        ncolors = sizearg;
        validateattributes(ncolors, {'double'}, ...
            {'scalar','positive'}, 'DEMCMAP', 'NCOLORS')
        ncolors = max(2,floor(sizearg));
    end
    [nsea, nland, clim] = partitionGivenNColors(minZ, maxZ, ncolors);
else
    % cmode is 'inc' ==> The input is deltaz.
    deltaz = sizearg;
    if isempty(deltaz)
        deltaz = 64;
    end
    validateattributes(deltaz,{'numeric'}, ...
        {'nonempty','real','positive','finite'},'DEMCMAP','DELTAZ',3)
    deltaz = double(deltaz);
    [nsea, nland, clim] = partitionGivenDeltaZ(minZ, maxZ, deltaz);
end

%--------------------------------------------------------------------------

function [nsea, nland, clim] = partitionGivenNColors(minZ, maxZ, ncolors)
% Determine the lengths of the sea and land colormap partitions, given the
% total number of colors requested. Determine the appropriate color limits.

if minZ == maxZ   
    maxZ = minZ+1;  
end

cmn = minZ;
cmx = maxZ;

% determine appropriate number of sea and land colors
if minZ >= 0
    nsea = 0;
    nland = ncolors;
elseif maxZ <= 0
    nland = 0;
    nsea = ncolors;
else
    % find optimal ratio of land to sea colors
    maxminratio = maxZ/abs(minZ);
    n1 = floor(ncolors/2);
    n2 = ceil(ncolors/2);
    if maxminratio>1
        sea = (1:n1)';
        land = (ncolors-1:-1:n2)';
    else
        land = (1:n1)';
        sea = (ncolors-1:-1:n2)';
    end
    ratio = land./sea;
    errors = abs(ratio - maxminratio) / maxminratio;
    indx = find(errors == min(min(errors)));
    nsea = sea(indx);
    nland = land(indx);

    % determine color limits
    seaint = abs(minZ)/nsea;
    landint = maxZ/nland;
    if seaint >= landint
        interval = seaint;
    else
        interval = landint;
    end
    cmn = -nsea*interval*(1 + 1e-9);		% zero values treated as land
    cmx = nland*interval;
end

clim = [cmn cmx];

%--------------------------------------------------------------------------

function [nsea, nland, clim] = partitionGivenDeltaZ(minZ, maxZ, deltaZ)
% Determine the lengths of the sea and land colormap partitions, given an
% elevation increment to use. Determine the appropriate color limits.

if minZ == maxZ  
    maxZ = minZ+1; 
end

% determine appropriate number of sea and land colors
% determine color limits
if minZ >= 0
    nsea = 0;
    lowland = floor(minZ/deltaZ);
    highland = ceil(maxZ/deltaZ);
    nland = highland - lowland;

    cmn = lowland*deltaZ;
    cmx = highland*deltaZ;

elseif maxZ <= 0
    nland = 0;
    shallowsea = floor(abs(maxZ)/deltaZ);
    deepsea = ceil(abs(minZ)/deltaZ);
    nsea = deepsea - shallowsea;

    cmn = -deepsea*deltaZ;
    cmx = -shallowsea*deltaZ;

else
    nsea = ceil(abs(minZ)/deltaZ);
    nland = ceil(maxZ/deltaZ);

    % zero values treated as land
    cmn = -nsea*deltaZ*(1 + 1e-9);
    cmx = nland*deltaZ;

end

clim = [cmn cmx];

%--------------------------------------------------------------------------

function hsvsea = hsvColormapForSea(nsea, hsvseamat)
% Resample colormap for sea, working in HSV.

nseamat = size(hsvseamat,1);
if nsea == 0
    hsvsea = [];
elseif nsea <= nseamat
    % Last nsea colors
    temp = flipud(hsvseamat);
    hsvsea = flipud(temp(1:nsea,:));
else
    % Linear interpolation (in HSV)
    hsvsea = map.graphics.internal.interpcmap(hsvseamat,1,nsea,1:nsea);
end

%--------------------------------------------------------------------------

function hsvland = hsvColormapForLand(nland, hsvlandmat)
% Resample colormap for land, working in HSV.

nlandmat = size(hsvlandmat,1);
if nland == 0
    hsvland = [];
elseif nland <= nlandmat
    % First nland colors
    hsvland = hsvlandmat(1:nland,:);
else
    % Linear interpolation (in HSV)
    hsvland = map.graphics.internal.interpcmap(hsvlandmat,1,nland,1:nland);
end

%--------------------------------------------------------------------

function cmap = seaColormap()
% Default 3-by-3 color map for sea (negative elevations):
%
%   [dark blue
%    blue
%    cyan]

cmap = hsv2rgb([2/3 1 0.2; 2/3 1 1; 0.5 1 1]);

%--------------------------------------------------------------------

function cmap = landColormap()
% Default 3-by-3 color map for land (positive elevations):
%
%   [green-blue
%    light yellow-green
%    brown]

cmap = hsv2rgb([5/12 1 0.4; 0.25 0.2 1; 5/72 1 0.4]);

%--------------------------------------------------------------------

function validateColormap(cmap, var_name)

validateattributes(cmap, {'double'}, ...
    {'real','finite','nonnegative', '<=' 1, '2d', 'ncols', 3, 'nonempty'}, ...
    'DEMCMAP', var_name)
