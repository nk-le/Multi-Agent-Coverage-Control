function [latgrat,longrat, Z] = avhrrgoode(varargin)
%AVHRRGOODE Read AVHRR data product stored in Goode projection
%
%   [LATGRAT, LONGRAT, Z] = AVHRRGOODE(REGION, FILENAME) reads data from an
%   Advanced Very High Resolution Radiometer (AVHRR) dataset with a nominal
%   resolution of 1 km that is stored in the Goode projection.  Data of
%   this type includes a nondimensional vegetation index (NDVI) and Global
%   Land Cover Characteristics (GLCC).  REGION specifies the geographic 
%   coverage of the file.  Valid regions are:
%     'g'  or 'global'
%     'af' or 'africa',
%     'ap' or 'australia/pacific',
%     'ea' or 'eurasia',
%     'na' or 'north america',
%     'sa' or 'south america'.
%   FILENAME specifies the name of the data file. Z is a geolocated data 
%   grid with coordinates LATGRAT and LONGRAT in units of degrees. 
%   Z, LATGRAT, and LONGRAT have class double.  The coordinates for data 
%   that lies in the interrupted area of the projection is set to NaN.  
%   A scale factor of 100 is applied to the original dataset such
%   that Z contains every 100th point in both X and Y.
%
%   [...] = AVHRRGOODE(REGION, FILENAME, SCALEFACTOR) uses the integer
%   scalefactor to downsample the data.  A scalefactor of 1 returns every
%   point.  A scalefactor of 10 returns every 10th point.  The default
%   value is 100.
%
%   [...] = AVHRRGOODE(REGION, FILENAME, SCALEFACTOR, LATLIM, LONLIM)
%   returns data for the specified region.  The returned data may extend
%   somewhat beyond the requested area. Limits are two-element vectors in
%   units of degrees, with LATLIM in the range [-90 90] and LONLIM in the
%   range [-180 180].  LATLIM and LONLIM must be ascending.  If LATLIM and
%   LONLIM are empty, the entire area covered by the data file is returned.
%   If the quadrangle defined by LATLIM and LONLIM (when projected to form
%   a polygon in the appropriate Goode projection) fails to intersect the
%   bounding box of the data in the projected coordinates, then LATGRAT,
%   LONGRAT, and Z are empty.
%
%   [...] = AVHRRGOODE(REGION, FILENAME, SCALEFACTOR, LATLIM, LONLIM,
%   GSIZE) controls the size of the graticule matrices.  GSIZE is a
%   two-element vector containing the number of rows and columns desired.
%   By default, LATGRAT and LONGRAT have the same size as Z.
%
%   [...] = AVHRRGOODE(REGION, FILENAME, SCALEFACTOR, LATLIM, LONLIM,
%   GSIZE, NROWS, NCOLS)  overrides the standard file format for the
%   selected region.  This is useful for data stored on CD-ROM, which may
%   have been truncated to fit.  Some global datasets were distributed with
%   16347 rows and 40031 columns of data on CD-ROMs. The default size for
%   global data sets is 17347 rows and 40031 columns of data.
%
%   [...] = AVHRRGOODE(REGION, FILENAME, SCALEFACTOR, LATLIM, LONLIM,
%   GSIZE, NROWS, COLS, RESOLUTION) reads a dataset with the spatial
%   resolution specified in meters.  If empty, the full resolution of 1000
%   meters is assumed.  Data is also available at 8000-meter resolution.
%   Nondimensional vegetation index data at 8-km spatial resolution has
%   2168 rows and 5004 columns. 
%
%   [...] = AVHRRGOODE(REGION, FILENAME, SCALEFACTOR, LATLIM, LONLIM,
%   GSIZE, NROWS, NCOLS, RESOLUTION, PRECISION) reads a dataset with the
%   integer precision specified.  If empty, 'uint8' is assumed. 'uint16'
%   is  appropriate for some files.  Check the data's README file for
%   specification of the file format and contents.  In either case, Z is
%   converted to class double.
%
%   Example 1
%   ---------
%   % Read and display every 50th point from the Global Land Cover
%   % Characteristics (GLCC) file covering the entire globe with the USGS
%   % classification scheme, named gusgs2_0g.img. (To run the example, you
%   % must first download the file.)
%   [latgrat, longrat, Z] = avhrrgoode('global','gusgs2_0g.img',50);
%
%   % Display the data using the Goode projection.
%   origin = [0 0 0]; 
%   ellipsoid = [6370997 0];
%   figure
%   axesm('MapProjection', 'goode', 'Origin', origin, 'Geoid', ellipsoid)
%   geoshow(latgrat, longrat, Z, 'DisplayType', 'texturemap'); 
%
%   Example 2
%   ---------
%   % Read and display every point from the Global Land Cover
%   % Characteristics (GLCC) file covering California with the USGS
%   % classification scheme, named nausgs1_2g.img. 
%   figure
%   usamap california
%   mstruct = gcm;
%   latlim = mstruct.maplatlimit;
%   lonlim = mstruct.maplonlimit;
%   scalefactor = 1;
%   [latgrat, longrat, Z] = ...
%      avhrrgoode('na', 'nausgs1_2g.img', scalefactor, latlim, lonlim);
%   geoshow(latgrat, longrat, Z, 'DisplayType', 'texturemap'); 
%
%   % Overlay vector data from usastatehi.shp.
%   california = shaperead('usastatehi', 'UseGeoCoords', true,...
%      'BoundingBox', [lonlim;latlim]);
%   geoshow([california.Lat], [california.Lon], 'Color', 'black');
%
%  See also AVHRRLAMBERT

% Copyright 1996-2021 The MathWorks, Inc.

% Verify the number of inputs.
narginchk(2,10)

[varargin{:}] = convertStringsToChars(varargin{:});

% Verify the region and obtain the spatial dimensions of the image.
[nrows, ncols, xlim, ylim] = getSpatialParameters(varargin{1});

% Parse the inputs.
[filename, scalefactor, latlim, lonlim, gsize, nrows, ncols, ...
    resolution, precision] =  parseInputs(nrows, ncols, varargin{2:end});

% Calculate the image limits.
[rlim, clim] = calculateImageLimits( ...
    latlim, lonlim, xlim, ylim, nrows, ncols, resolution);

% If the image limits are invalid, return empty.
if diff(rlim) <= 0 || diff(clim) <= 0
    latgrat = [];
    longrat = [];
    Z = [];
else
    % Read the AVHRR raster image from the file.
    [rIndGrat, cIndGrat, Z] = flatRasterRead(filename, nrows, ncols, ...
        rlim, clim, precision, scalefactor, gsize);
    
    % Map row and column graticule to x and y values.
    % Unproject x and y graticule to lat and lon.
    [latgrat, longrat] = ...
        rc2gihll(rIndGrat, cIndGrat, resolution, xlim(1), ylim(1));
end

%--------------------------------------------------------------------------

function [nrows, ncols, xlim, ylim] = getSpatialParameters(region)
% Get the image spatial parameters given the region string.

% Verify REGION.
validateattributes(region, {'char','string'}, {'scalartext'}, mfilename, 'REGION', 1);

% The xlim and ylim refer to the upper left (1) lower right (2) coordinate.
% The image size and limits were obtained from:
% http://edcsns17.cr.usgs.gov/glcc/glcc_version1.html
% From the on-line documentation, the:
% "XY corner coordinates (center of pixel) in projection units (meters):"
switch lower(region)

    case {'g','global'}
        nrows = 17347;
        ncols = 40031;

        xlim = [-20015000, 20015000];
        ylim = [8673000,  -8673000];

    case {'af','africa'}
        nrows = 8676;
        ncols = 8350;

        xlim = [-1998000, 6351000];
        ylim = [4529000, -4146000];

    case {'ap','australia/pacific'}
        nrows = 7700;
        ncols = 9100;

        xlim = [10084000, 19183000];
        ylim = [2374000, -5325000];

    case {'sa','south america'}
        nrows = 8016;
        ncols = 5632;

        xlim = [-9276000, -3645000];
        ylim = [1630000, -6385000];

    case {'ea','eurasia'}
        nrows = 8570;
        ncols = 13800;
  
        xlim = [-215000, 13584000];
        ylim = [8673000, 104000];

    case {'na','north america'}
        nrows = 7793;
        ncols = 11329;

        xlim = [-17359000, -6031000];
        ylim = [8423000, 631000];

    otherwise
        error(message('map:avhrr:invalidRegionString', 'g', 'global', 'af', 'africa', 'ap', 'australia/pacific', 'ea', 'europe/asia', 'na', 'north america', 'sa', 'south america'));
end

map.internal.assert(1 + diff(xlim)/1000 == ncols ...
    && 1 - diff(ylim)/1000 == nrows, ...
    'map:internalProblem:inconsistentDimensions')

%--------------------------------------------------------------------------

function [filename, scalefactor, latlim, lonlim, gsize, nrows, ncols, ...
    resolution, precision] = parseInputs(nrows, ncols, varargin)

% Assign default values for output parameters.
defaults = { ...
    '', ...         % filename
    100, ...        % scalefactor
    [-90, 90], ...  % latlim
    [-180 180], ... % lonlim
    [], ...         % gsize
    nrows, ...      % nrows
    ncols, ...      % ncols
    1000, ...       % 1km resolution
    'uint8'};       % precision

% Assign default values to the unspecified input parameters.
varargin(end+1:numel(defaults)) = defaults(numel(varargin)+1:end);

% If any inputs are empty, set to their default value.
emptyIndex = cellfun('isempty',varargin);
varargin(emptyIndex) = defaults(emptyIndex);

% Assign output variables from input parameters.
[filename, scalefactor, latlim, lonlim, gsize, nrows, ncols, ...
    resolution, precision] = deal(varargin{:});

% Verify FILENAME and obtain the full pathname.
filename = internal.map.checkfilename(filename, {'img'}, mfilename, 2, false);

% Verify SCALEFACTOR.
validateattributes(scalefactor, {'numeric'}, {'scalar','positive'}, mfilename, ...
    'SCALEFACTOR',3);

% Verify LATLIM, LONLIM.
checklatlonlim(latlim, lonlim, 'LATLIM', 'LONLIM', 4, 5);

% Ensure row vectors.
latlim = latlim(:)';
lonlim = lonlim(:)';

% Verify GSIZE.
if ~isempty(gsize) 
  validateattributes(gsize, {'numeric'}, {'size',[1,2]}, mfilename, 'GSIZE', 6);
end

% Verify NROWS.
validateattributes(nrows, {'numeric'}, {'scalar'}, mfilename,'NROWS', 7);

% Verify NCOLS.
validateattributes(ncols, {'numeric'}, {'scalar'}, mfilename,'NCOLS', 8);

% Verify RESOLUTION.
validateattributes(resolution,{'numeric'}, {}, mfilename,'RESOLUTION',9);

% Verify PRECISION.
validateattributes(precision, {'char','string'}, {'scalartext'}, mfilename, 'PRECISION', 10);

%--------------------------------------------------------------------------

function checklatlonlim( latlim, lonlim, lat_var_name, lon_var_name, ...
                         lat_pos, lon_pos)
                     
% Check latitude and longitude limits.
checkgeoquad(latlim, lonlim, mfilename, lat_var_name, lon_var_name, ...
    lat_pos, lon_pos);

% Verify longitude range and limits.
map.internal.assert(lonlim(1) <= lonlim(2), ...
    'map:validate:expectedAscendingOrder', 'LONLIM'); 

map.internal.assert(-180 <= lonlim(1) && lonlim(2) <= 180, ...
    'map:validate:expectedRange', 'LONLIM', '-180', 'lonlim', '180');

%--------------------------------------------------------------------------

function [rlim, clim] = calculateImageLimits(...
    latlim, lonlim, xlim, ylim, nrows, ncols, resolution)
% Calculate row and column limits.

% Construct a frame given the latitude and longitude limits.
[latfrm, lonfrm] = framegll(latlim,lonlim,100);

% Convert the frame limits to row and column limits.
[rfrm, cfrm] = ...
    gihll2rc(latfrm, lonfrm, resolution, xlim(1), ylim(1));

% Find the extent of the desired region in matrix indices.
rlim = [max([1,min(rfrm)]) min([max(rfrm),nrows])];
clim = [max([1,min(cfrm)]) min([max(cfrm),ncols])];

%--------------------------------------------------------------------------

function [latfrm,lonfrm] = framegll(framelat,framelon,fillpts)
% Construct a frame given limits and number of points between limits.

% Fill vectors with frame limits.
lats = linspace(min(framelat),max(framelat),fillpts)';
lons = linspace(min(framelon),max(framelon),fillpts)';

% Construct complete frame vectors.
latfrm = [lats; ...
    framelat(2)*ones(size(lats)); ...
    flipud(lats); ...
    framelat(1)*ones(size(lats))];

lonfrm = [framelon(1)*ones(size(lons));...
    lons; ...
    framelon(2)*ones(size(lons)); ...
    flipud(lons);];

%--------------------------------------------------------------------------

function [row, col] = gihll2rc(lat, lon, pixsize, ulx, uly)
% Calculate row and column indices given latitude and longitude
% coordinates.  PIXSIZE, ULX, and ULY are in map coordinates.

% Forward project the lat and lon values to x and y.
[x,y] = goodeih('fwd', lat, lon);

% Calculate row and column indices.
row = floor((uly - y) / pixsize + 1.0);
col = floor((x - ulx) / pixsize + 1.0);

%--------------------------------------------------------------------------

function [lat, lon] = rc2gihll(row, col, pixsize, ulx, uly)
% Calculate latitude and longitude coordinates given row and column
% indices.

% Convert row and column to map coordinates.
y = uly - ((row - 1) * pixsize);
x = ulx + ((col - 1) * pixsize);

% Inverse project the map coordinates to latitude and longitude.
[lat, lon] = goodeih('inv', x, y);
