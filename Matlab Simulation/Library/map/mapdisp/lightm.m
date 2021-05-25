function [h,msg] = lightm(varargin)
%LIGHTM Project light objects on map axes
%
%  LIGHTM(lat,lon) projects a light source positioned an infinite distance
%  above the specified geographic location onto the current map axes.  The
%  input latitude and longitude data must be in the same units as specified
%  in the current map axes.  If lat and lon are vectors, then a light is
%  projected at each element.
%
%  LIGHTM(lat,lon,'PropertyName',PropertyValue,...) uses the
%  properties specified to define the light source.  Except
%  for 'Position', all properties are supported.
%
%  LIGHTM(lat,lon,alt) and
%  LIGHTM(lat,lon,alt,'PropertyName',PropertyValue,...) project
%  a local light source at the altitude specified by alt.
%
%  h = LIGHTM(...) returns the handles to the light objects projected.
%
%  See also LIGHT

% Copyright 1996-2020 The MathWorks, Inc.

% Obsolete syntax
% ---------------
%  [h,msg] = LIGHTM(...) returns an text string indicating any error
%  condition encountered.
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

narginchk(2, Inf)

[varargin{:}] = convertStringsToChars(varargin{:});

if nargin == 2
    lat = varargin{1};
    lon = varargin{2};
    z = ones(size(lat));
    varargin = {'Style','Infinite'};
else
    lat = varargin{1};   lon = varargin{2};
    if ischar(varargin{3})
        z = ones(size(lat));
        varargin(1:2) = [];
        if  isempty(varargin)
            varargin = {'Style','Infinite'};
        else
            varargin = {varargin{:},'Style','Infinite'}; %#ok<CCAT>
        end
    else
        z = varargin{3};
        varargin(1:3) = [];
    end
end

%  Test for scalar z data
if length(z) == 1
    z = z(ones(size(lat)));
end

%  Ensure column vectors
lat = lat(:);
lon = lon(:);
z = z(:);

%  Argument size tests
if ~isequal(size(lat),size(lon),size(z))
    error(message('map:validate:inconsistentSizes3', ...
        'LIGHTM', 'LAT', 'LON', 'Z'))
end

%  Validate map axes, project lines, and display
ax = getParentAxesFromArgList(varargin);
if ~isempty(ax)
    mstruct = gcm(ax);
else
    mstruct = gcm;
end

[x,y,z,savepts] = map.crs.internal.mfwdtran(mstruct,lat,lon,z,'light');
for i = 1:length(x)
    h0(i,1) = light('Position', [x(i) y(i) z(i)], ...
        'UserData', savepts, varargin{:}); %#ok<AGROW>
end

%  Set light properties if necessary
if ~isempty(varargin)
    set(h0,varargin{:});
end

% Assign output arguments if specified
if nargout > 0
    h = h0;
end
