function h = surflm(lat, lon, Z, varargin)
%SURFLM 3-D shaded surface with lighting on map axes
%
%   SURFLM(LAT, LON, Z) and SURFLM(LATLIM, LONLIM, Z) are the same as
%   SURFM(...) except that they highlight the surface with a light
%   source. The default light source (45 degrees counterclockwise from
%   the current view) and reflectance constants are the same as in
%   SURFL.
%
%   SURFLM(...,S) and SURFLM(...,S,K) use a light source vector, S, and a
%   vector of reflectance constants, K.  See the help for SURFL for more
%   information on S and K.
%
%   H = SURFLM(...) returns a handle to the surface object.
%
%   See also SURFACE, SURFACEM, SURFL, SURFM

% Copyright 1996-2020 The MathWorks, Inc.

narginchk(3, Inf)

if numel(lat) == 2 && numel(lon) == 2
    % SURFLM(LATLIM, LONLIM, Z, ...)
    latlim = lat;
    lonlim = lon;
    [lat,lon] = map.internal.graticuleMesh(latlim,lonlim,size(Z));
else
    % SURFLM(LAT, LON, Z, ...)
    if ~isequal(size(lat),size(lon),size(Z))
        error(message('map:validate:inconsistentSizes3', ...
            'SURFLM', 'LAT', 'LON', 'Z'))
    end
end

if nargin > 3
    [varargin{:}] = convertStringsToChars(varargin{:});
end

%  Validate map axes
ax = getParentAxesFromArgList(varargin);
if ~isempty(ax)
    mstruct = gcm(ax);
else
    mstruct = gcm;
end

%  Project the surface data
if ~strcmp(mstruct.mapprojection,'globe')
    [x,y,~,savepts] = map.crs.internal.mfwdtran(mstruct,lat,lon,[],'surface');
else
    error('map:surflm:axesIsGlobe', ...
        '%s cannot be used with a GLOBE map axes.', 'SURFLM');
end

%  Display the map
nextmap(varargin);
h0 = surfl(x,y,Z,varargin{:});
otherprops = {...
    'ButtonDownFcn', @uimaptbx,...
    'UserData',       savepts,...
    'EdgeColor',     'none'};
set(h0,otherprops{:})

%  Set handle return argument if necessary
if nargout > 0
    h = h0;
end
