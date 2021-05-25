function [h,msg] = patchesm(varargin)
%PATCHESM Project patches on map axes as individual objects
%
%   PATCHESM(lat,lon,cdata) projects 2-D patch objects onto the current map
%   axes.  The input latitude and longitude data must be in the same units
%   as specified in the current map axes.  The input cdata defines the
%   patch face color.  If the input vectors are NaN-separated, then
%   multiple patches are drawn each with a single face.  Unlike FILLM and
%   FILL3M, PATCHESM will always add the patches to the current map,
%   regardless of the current hold state.
%
%   PATCHESM(lat,lon,z,cdata) projects 3-D planar patches at the uniform
%   elevation given by scalar z.
%
%   PATCHESM(...,'PropertyName',PropertyValue,...) uses the patch
%   properties supplied to display the patch.  Except for xdata, ydata and
%   zdata, all patch properties available through PATCH are supported by
%   PATCHESM.
%
%   h = PATCHESM(...) returns the handles to the patch objects drawn.
%
%  See also GEOSHOW, FILLM, FILL3M, PATCHM

% Copyright 1996-2017 The MathWorks, Inc.

% Obsolete syntax
% ---------------
% [h,msg] = PATCHESM(...) returns a string indicating any error encountered.
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

narginchk(3, inf)

[varargin{:}] = convertStringsToChars(varargin{:});
lat = varargin{1};
lon = varargin{2};
if nargin == 3
    z = 0;
    cdata = varargin{3};
    varargin(1:3) = [];
elseif ischar(varargin{3})
    if rem(nargin,2)        % patchesm(lat,lon,'cdata','prop',val,...)
        z = 0;
        cdata = varargin{3};
        varargin(1:3) = [];
    else                    % patchesm(lat,lon,'prop',val,...)
        z = 0;
        cdata = 'red';
        varargin(1:2) = [];
    end
elseif ~ischar(varargin{3})
    if rem(nargin,2)        % patchesm(lat,lon,z,'prop',val,...)
        z = varargin{3};
        cdata = 'red';
        varargin(1:3) = [];
    else                    % patchesm(lat,lon,z,'cdata','prop',val,...)
        z = varargin{3};
        cdata = varargin{4};
        varargin(1:4) = [];
    end
end

%  Check argument sizes
validateattributes(lat, {'double'}, {'2d'}, 'PATCHESM', 'LAT', 1)
validateattributes(lon, {'double'}, {'2d'}, 'PATCHESM', 'LON', 2)
validateattributes(z,   {'double'}, {'scalar'}, 'PATCHESM', 'Z', 3)
if ~isequal(size(lat),size(lon))
    error(message('map:validate:inconsistentSizes2','PATCHESM','LAT','LON'))
end

% Handle matrix inputs (like from scircle1)
if min(size(lat))~=1
    lat(size(lat,1)+1,:) = NaN;
    lon(size(lon,1)+1,:) = NaN;
end

%  Ensure that the input vectors are in column format
lat = lat(:);
lon = lon(:);

%  Validate map axes
ax = getParentAxesFromArgList(varargin);
if ~isempty(ax)
    mstruct = gcm(ax);
else
    mstruct = gcm;
end

%  Clean up, then locate the NaN separators.
[lat, lon] = removeExtraNanSeparators(lat, lon);
[lat, lon] = closePolygonParts(lat, lon, mstruct.angleunits);
indx = find(isnan(lat));

% Simulate the trailing NaN if there is none.
if ~isempty(lat) && ~isnan(lat(end))
    indx(end+1,1) = 1 + numel(lat);
end

%  Display each NaN-separated part as a separate patch,
%  unless it is completely trimmed away.
numParts = numel(indx);
h0 = gobjects(0);

nPatches = 0;
indx = [0; indx];
for k = 1:numParts
    iStart = indx(k)   + 1;
    iEnd   = indx(k+1) - 1;
    [x,y,zout,userdata] = ...
        projectpatch(mstruct, lat(iStart:iEnd), lon(iStart:iEnd), z);
    if ~isempty(x)
        faces = setfaces(x,y);
        if ~isempty(ax)
            h0(nPatches+1) = patch(...
                'Faces', faces, 'Vertices', [x y zout], 'FaceColor', cdata, ...
                'UserData', userdata, 'Parent',ax, ...
                'ButtonDownFcn', @uimaptbx);
            nPatches = nPatches + 1;
        else
            h0(nPatches+1) = patch(...
                'Faces', faces, 'Vertices', [x y zout], 'FaceColor', cdata, ...
                'UserData', userdata, 'ButtonDownFcn', @uimaptbx);
            nPatches = nPatches + 1;
        end
    end
end

% Restack to ensure standard child order in the map axes.
map.graphics.internal.restackMapAxes(h0)

%  Set properties, if necessary.
if ~isempty(varargin) && ~isempty(h0)
    set(h0,varargin{:});
end

% Assign output arguments if specified
if nargout > 0
    h = h0;
end
