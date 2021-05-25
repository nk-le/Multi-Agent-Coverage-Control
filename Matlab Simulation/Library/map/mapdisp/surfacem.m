function [h,msg] = surfacem(varargin)
%SURFACEM  Project and add geolocated data grid to current map axes
%
%   SURFACEM(LAT, LON, Z) constructs a surface to represent the data
%   grid Z in the current map axes.  The surface lies flat in the
%   horizontal plane with its CData property set to Z. LAT and LON are
%   vectors or 2-D arrays that define the latitude-longitude graticule
%   mesh on which Z is displayed. See SURFM for a complete description
%   of the various forms that LAT and LON can take.
%
%   SURFACEM(LATLIM, LONLIM, Z) defines the graticule using the latitude
%   and longitude limits LATLIM and LONLIM, which should match the
%   geographic extent of the data grid Z.  LATLIM is a two-element
%   vector of the form:
%
%               [southern_limit northern_limit]
% 
%   Likewise, LONLIM has the form:
%
%                [western_limit eastern_limit]
%
%   A latitude-longitude graticule of size 50-by-100 is constructed. The
%   surface 'FaceColor' property is 'texturemap' except when Z is
%   precisely 50-by-100, in which case it is 'flat'.
%
%   SURFACEM(LAT, LON, Z, ALT) sets the ZData property of the surface to
%   ALT, resulting in a 3-D surface.  LAT and LON must result in a
%   graticule mesh that matches ALT in size.  CData is set to Z.
%   'FaceColor' is 'texturemap' unless Z matches ALT in size, in which
%   case it is 'flat'.
%
%   SURFACEM(..., PROP1, VAL1, PROP2, VAL2,...) applies additional
%   MATLAB graphics properties to the surface, via property/value pairs.
%   Any property accepted by the SURFACE function may be specified,
%   except for XData, YData, and ZData.
%
%   H = SURFACEM(...) returns a handle to the surface object.
%
%   Note
%   ----
%   Unlike MESHM and SURFM, SURFACEM always adds a surface to the current
%   axes, regardless of the hold state.
%
%   Example
%   -------
%   load topo60c
%   latlim = topo60cR.LatitudeLimits;
%   lonlim = topo60cR.LongitudeLimits;
%   % Texture map in 6-by-6 chunks
%   gratsize = 1 + [diff(latlim), diff(wrapTo360(lonlim))]/6;
%   lat = linspace(latlim(1), latlim(2), size(topo60c,1));
%   lon = linspace(lonlim(1), lonlim(2), size(topo60c,2));
%   [lat, lon] = ndgrid(lat, lon);
%   worldmap world
%   surfacem(lat,lon,topo60c)
%   demcmap(topo60c)
%
%   See also GEOSHOW, MESHM, PCOLORM, SURFM

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(3, Inf)

% Obsolete syntax
% ---------------
% [h,msg] = SURFACEM(...) returns a string indicating any error encountered
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

[lat, lon, alt, grid, pvPairs] = parseInputs(varargin{:});

%  Validate map axes
ax = getParentAxesFromArgList(varargin);
if ~isempty(ax)
    mstruct = gcm(ax);
else
    mstruct = gcm;
end

%  Project the surface data
[x, y, z, savepts] = map.crs.internal.mfwdtran(mstruct, lat, lon, alt, 'surface');

%  Display the surface
if isequal(size(x),size(grid)) && (isa(grid,'double') || isa(grid,'single'))
    h0 = surface(x, y, z, 'Cdata', grid, 'LineStyle', 'none', ...
        'ButtonDownFcn', @uimaptbx, 'UserData', savepts, pvPairs{:});
else
    h0 = surface(x, y, z, 'Cdata', grid, 'LineStyle', 'none', ...
        'FaceColor', 'TextureMap', ...
        'ButtonDownFcn', @uimaptbx, 'UserData', savepts, pvPairs{:});
end

%  Restack to ensure standard child order in the map axes.
map.graphics.internal.restackMapAxes(h0)

%  Set handle return argument if necessary
if nargout ~= 0
    h = h0;
end

%--------------------------------------------------------------------------
function [lat, lon, alt, grid, pvPairs] ...
    = parseInputs(lat, lon, grid, varargin)

if numel(lat) == 2 && numel(lon) == 2
    % LAT and LON are actually the latlim & lonlim 2-vectors
    [lat,lon] = map.internal.graticuleMesh(lat,lon,[50 100]);
elseif isvector(lat) && isvector(lon)
    % LAT and LON are vectors that expand into graticule arrays
    [lat,lon] = ndgrid(lat,lon);
% else
    % LAT and LON are already graticule arrays
end

if numel(varargin) == 0 || ischar(varargin{1}) || isstring(varargin{1})
    alt = zeros(size(lat));
else
    alt = varargin{1};
    varargin(1) = [];

    % Check for scalar altitude
    if numel(alt) == 1
        alt = alt + zeros(size(lat));
    end
end

% Check input dimensions
validateattributes(lat, {'double'}, {'2d'}, 'SURFACEM', 'LAT')
validateattributes(lon, {'double'}, {'2d'}, 'SURFACEM', 'LON')
validateattributes(alt, {'double'}, {'2d'}, 'SURFACEM', 'ALT')
if ~isequal(size(lat),size(lon),size(alt))
    error(message('map:validate:inconsistentSizes3', ...
        'SURFACEM', 'LAT', 'LON', 'ALT'))
end

pvPairs = varargin;
