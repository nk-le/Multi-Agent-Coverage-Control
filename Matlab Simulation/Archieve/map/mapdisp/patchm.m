function [h,msg] = patchm(varargin)
%PATCHM Project patch objects on map axes
%
%  PATCHM(lat,lon,cdata) projects 2D patch objects onto the current map
%  axes.  The input latitude and longitude data must be in the same units
%  as specified in the current map axes.  The input cdata defines the patch
%  face color.  If the input vectors are NaN clipped, then a single patch
%  is drawn with multiple faces.  Unlike FILLM and FILL3M, PATCHM will
%  always add the patches to the current map, regardless of the current
%  hold state.
%
%  PATCHM(lat,lon,z,cdata) projects a 3D patch.
%
%  PATCHM(...,'PropertyName',PropertyValue,...) uses the patch properties
%  supplied to display the patch.  Except for xdata, ydata and zdata, all
%  patch properties available through PATCH are supported by PATCHM.
%
%  h = PATCHM(...) returns the handles to the patch objects drawn.
%
%  See also FILLM, FILL3M, PATCHESM, PATCH

% Copyright 1996-2018 The MathWorks, Inc.

% Obsolete syntax
% ---------------
% [h,msg] = PATCHM(...) returns a string indicating any error encountered.
if nargout > 1
    warnObsoleteMSGSyntax(mfilename)
    msg = '';
end

narginchk(3, inf)

[varargin{:}] = convertStringsToChars(varargin{:});
[lat, lon, cdata, z, param_pairs] = parseInputSyntax(varargin{:});
cdata = preprocessCData(cdata);
validateLatLonZ(lat, lon, z);

%  Validate map axes
ax = getParentAxesFromArgList(varargin);
if ~isempty(ax)
    mstruct = gcm(ax);
else
    mstruct = gcm;
end

[lat, lon] = preprocessLatLon(lat, lon);
[lat, lon] = closePolygonParts(lat, lon, mstruct.angleunits);

%  Get the vector of patch items and remove any NaN padding
%  at the beginning or end of the column.  This eliminates potential
%  multiple NaNs at the beginning and end of the patches.
non_nans = ~(isnan(lat) | isnan(lon));
first_nonnan = find(non_nans, 1, 'first'); 
last_nonnan  = find(non_nans, 1, 'last');
lat = lat(first_nonnan:last_nonnan);
lon = lon(first_nonnan:last_nonnan);

%  Add a NaN to the end of the data vector.  Necessary for processing
%  of multiple patches.
lat(end + 1) = NaN;
lon(end + 1) = NaN;

%  Project the patch data, using the new polygon trimming feature
[x, y, zout, userdata] = projectpatch(mstruct, lat, lon, z);

atLeastOnePointIsLeft = any(~isnan(x));
if atLeastOnePointIsLeft
    faces = setfaces(x,y);
    %  Validate map axes and display
    h0 = patch('Faces', faces, 'Vertices', [x y zout],...
        'FaceColor', cdata, param_pairs{:});
    
    %  Restack to ensure standard child order in the map axes.
    map.graphics.internal.restackMapAxes(h0)

    % Save the original data in the patch's UserData property
    set(findobj(h0), 'ButtonDownFcn', @uimaptbx);
    set(findobj(h0), 'UserData', userdata);
else
    h0 = reshape(gobjects(0),[0 1]);
end

% Assign output arguments if specified
if nargout > 0
    h = h0;
end

%----------------------------------------------------------------------
function tf = isOdd(n)

tf = rem(n, 2) == 1;

%----------------------------------------------------------------------
function [lat, lon, cdata, z, param_pairs] = parseInputSyntax(varargin)

param_pairs = varargin;

lat = varargin{1};
lon = varargin{2};
if nargin == 3
    z = 0;
    cdata = varargin{3};
    param_pairs(1:3) = [];
elseif ischar(varargin{3})
    if isOdd(nargin)
        % patchm(lat,lon,'cdata','prop',val,...)
        z = 0;
        cdata = varargin{3};
        param_pairs(1:3) = [];
    else
        % patchm(lat,lon,'prop',val,...)
        z = 0;
        cdata = 'red';
        param_pairs(1:2) = [];
    end
else
    if isOdd(nargin)
        % patchm(lat,lon,z,'prop',val,...)
        z = varargin{3};
        cdata = 'red';
        param_pairs(1:3) = [];
    else
        % patchm(lat,lon,z,'cdata','prop',val,...)
        z = varargin{3};
        cdata = varargin{4};
        param_pairs(1:4) = [];
    end
end

%----------------------------------------------------------------------
function validateLatLonZ(lat, lon, z)

validateattributes(lat, {'double'}, {'2d'}, 'PATCHM', 'LAT', 1)
validateattributes(lon, {'double'}, {'2d'}, 'PATCHM', 'LON', 2)
validateattributes(z,   {'double'}, {'scalar'}, 'PATCHM', 'Z', 3)
if ~isequal(size(lat),size(lon))
    error(message('map:validate:inconsistentSizes2','PATCHM','LAT','LON'))
end

%----------------------------------------------------------------------
function cdata_out = preprocessCData(cdata)

cdata_out = cdata;
if isnumeric(cdata_out) && numel(cdata_out) == 1
    cmap = colormap;
    cdata_out = cmap(floor((1 + size(cmap,1))/2),:);
end

%----------------------------------------------------------------------
function [lat_out, lon_out] = preprocessLatLon(lat, lon)

lat_out = lat;
lon_out = lon;

% Handle matrix inputs (like from scircle1)
if ~isvector(lat_out)
    lat_out(end + 1, :) = NaN;
    lon_out(end + 1, :) = NaN;
end

%  Ensure that the input vectors are in column format
lat_out = lat_out(:);
lon_out = lon_out(:);
