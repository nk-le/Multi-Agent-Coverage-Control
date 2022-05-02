function [latgrat, longrat, Z] = avhrrlambert(varargin)
%AVHRRLAMBERT Read AVHRR data product stored in eqaazim projection
%
%   [LATGRAT, LONGRAT, Z] = AVHRRLAMBERT(REGION, FILENAME) reads data from
%   an Advanced Very High Resolution Radiometer (AVHRR) dataset with a
%   nominal resolution of 1 km that is stored in the Lambert Equal Area
%   Azimuthal projection (eqaazim).  Data of this type includes the Global
%   Land Cover Characteristics (GLCC). REGION specifies the geographic 
%   coverage of the file. Valid regions are:
%     'af' or 'africa',
%     'a'  or 'asia',
%     'ap' or 'australia/pacific',
%     'e'  or 'europe',
%     'na' or 'north america',
%     'sa' or 'south america'.
%   FILENAME specifies the name of the data file. Z is a geolocated data 
%   grid with coordinates LATGRAT and LONGRAT in units of degrees. 
%   A scale factor of 100 is applied to the original dataset such
%   that Z contains every 100th point in both X and Y.
%
%   [...] = AVHRRLAMBERT(REGION, FILENAME, SCALEFACTOR) uses the integer
%   SCALEFACTOR to downsample the data.  A SCALEFACTOR of 1 returns every
%   point.  A SCALEFACTOR of 10 returns every 10th point.  The default
%   value is 100.
%
%   [...] = AVHRRLAMBERT(REGION, FILENAME, SCALEFACTOR, LATLIM, LONLIM)
%   returns data for the specified region.  The result may extend somewhat
%   beyond the requested area.  The limits are two-element vectors in units
%   of degrees, with LATLIM in the range [-90 90] and LONLIM in the range
%   [-180 180].  If LATLIM and LONLIM are empty, the entire area covered by
%   the data file is returned. If the quadrangle defined by LATLIM and
%   LONLIM (when projected to form a polygon in the appropriate Lambert
%   equal area azimuthal projection) fails to intersect the bounding box of
%   the data in the projected coordinates, then LATGRAT, LONGRAT, and Z are
%   empty.
%
%   [...] = AVHRRLAMBERT(REGION, FILENAME, SCALEFACTOR, LATLIM, LONLIM,
%   GSIZE) controls the size of the graticule matrices.  GSIZE is a
%   two-element vector containing the number of rows and columns desired.
%   By default, LATGRAT and LONGRAT have the same size as Z.
%
%   [...] = AVHRRLAMBERT(REGION, FILENAME, SCALEFACTOR, LATLIM, LONLIM,
%   GSIZE, PRECISION) reads a dataset with the integer precision specified.
%   If omitted, 'uint8' is assumed.  'uint16' is appropriate for some
%   files. Check the metadata (.txt or README) file in the ftp directory
%   for specification of the file format and contents.
%
%   Example 1
%   ---------
%   % Read and display every 100th point from the Global Land Cover
%   % Characteristics (GLCC) file covering North America with the USGS
%   % classification scheme, named nausgs1_2l.img. 
%   [latgrat, longrat, Z] = avhrrlambert('na','nausgs1_2l.img');
%
%   % Display the data using the Lambert Equal Area Azimuthal projection.
%   origin = [50 -100 0]; 
%   ellipsoid = [6370997 0];
%   figure
%   axesm('MapProjection', 'eqaazim', 'Origin', origin, 'Geoid', ellipsoid)
%   geoshow(latgrat, longrat, Z, 'DisplayType', 'texturemap'); 
%
%   Example 2
%   ---------
%   % Read and display every other point from the Global Land Cover
%   % Characteristics (GLCC) file covering Europe with the USGS
%   % classification scheme, named eausgs1_2le.img. 
%   figure
%   worldmap france
%   mstruct = gcm;
%   latlim = mstruct.maplatlimit;
%   lonlim = mstruct.maplonlimit;
%   scalefactor = 2;
%   [latgrat, longrat, Z] = ...
%      avhrrlambert('e', 'eausgs1_2le.img', scalefactor, latlim, lonlim);
%   geoshow(latgrat, longrat, Z, 'DisplayType', 'texturemap'); 
%   geoshow('landareas.shp','FaceColor','none','EdgeColor','black')
%   
%   See also AVHRRGOODE

% Copyright 1996-2021 The MathWorks, Inc.

%  This function reads the binary files as-is. You should not use byte
%  swapping software on these files.

% Verify the number of inputs.
narginchk(2,7);

[varargin{:}] = convertStringsToChars(varargin{:});

% Parse the inputs.
[region, filename, scalefactor, latlim, lonlim, gsize, precision, ...
    isSpecified] = parseInputs(varargin{:});

% Obtain the projection and spatial parameters.
[mstruct, R, nrows, ncols, xfrm, yfrm] = ...
    getSpatialParameters(region, latlim, lonlim, isSpecified);

% Calculate the image row and column limits.
[rlim, clim] = calculateImageLimits(R, xfrm, yfrm, nrows, ncols);

% If the image or frame limits are invalid, return empty.
invalidImageLimits = diff(rlim) <= 0 || diff(clim) <= 0;
invalidFrameLimits = isempty(xfrm) || isempty(yfrm);
if invalidImageLimits || invalidFrameLimits
    latgrat = [];
    longrat = [];
    Z = [];
else
    % Read the AVHRR raster image from the file.
    [rIndGrat, cIndGrat, Z] = flatRasterRead(filename, ...
        nrows, ncols, rlim, clim, precision, scalefactor, gsize);
    
    % Map row and column graticule to x and y values.
    [xgrat, ygrat] = pix2map(R, rIndGrat, cIndGrat);

    % Unproject x and y graticule to lat and lon.
    [latgrat,longrat] = map.crs.internal.minvtran(mstruct,xgrat,ygrat);
end
  
%--------------------------------------------------------------------------

function [region, filename, scalefactor, latlim, lonlim, gsize, ...
    precision, isSpecified] = parseInputs(varargin)

% Assign default values for output parameters.
defaults = { ...
    '', ...   % region
    '', ...   % filename
    100, ...  % scalefactor
    [-90 90], ...   % latlim
    [-180 180], ... % lonlim
    [], ...   % gsize
    'uint8'}; % precision

% Define isSpecified struct field to be true for each LATLIM and LONLIM
% parameter if the parameter is specified by the user with a non-empty
% value.
latlimIndx = 4;
lonlimIndx = 5;
isSpecified.latlim = ...
    (numel(varargin) >= latlimIndx && ~isempty(varargin{latlimIndx}));
isSpecified.lonlim = ...
    (numel(varargin) >= lonlimIndx && ~isempty(varargin{lonlimIndx}));

% Assign default values to the unspecified input parameters.
varargin(end+1:numel(defaults)) = defaults(nargin+1:end);

% If any inputs are empty, set to their default value.
emptyIndex = cellfun('isempty',varargin);
varargin(emptyIndex) = defaults(emptyIndex);

% Assign output variables from input parameters.
[region, filename, scalefactor, latlim, lonlim, gsize, precision] ...
    = deal(varargin{:});

% Verify REGION.
validateattributes(region, {'char','string'}, {'scalartext'}, mfilename, 'REGION', 1);

% Verify FILENAME and obtain the full pathname.
filename = internal.map.checkfilename(filename, {'img'}, mfilename, 2, false);

% Verify SCALEFACTOR.
validateattributes(scalefactor, {'numeric'}, {'scalar','positive'}, mfilename, ...
    'SCALEFACTOR', 3);

% Verify LATLIM, LONLIM.
checklatlonlim(latlim, lonlim, 'LATLIM', 'LONLIM', 4, 5);

% Ensure row vectors.
latlim = latlim(:)';
lonlim = lonlim(:)';

% Verify GSIZE.
if ~isempty(gsize) 
   validateattributes(gsize, {'numeric'}, {'size',[1,2]}, mfilename, 'GSIZE', 6);
end

% Verify PRECISION.
validateattributes(precision, {'char','string'}, {'scalartext'}, mfilename, 'PRECISION', 7);

%--------------------------------------------------------------------------

function checklatlonlim( latlim, lonlim, lat_var_name, lon_var_name, ...
                         lat_pos, lon_pos)
                     
% Check latitude and longitude limits.                    
checkgeoquad(latlim, lonlim, mfilename, lat_var_name, lon_var_name, ...
    lat_pos, lon_pos);

% Validate the longitude limits range.
map.internal.assert(-180 <= lonlim(1) && lonlim(2) <= 180, ...
    'map:validate:expectedRange', 'LONLIM', '-180', 'lonlim', '180');
                   
%--------------------------------------------------------------------------

function [mstruct, R, nrows, ncols, outputXlim, outputYlim] = ...
    getSpatialParameters(region, latlim, lonlim, isSpecified)

% The length units are meters.
% The units of the origin are in degrees.
yperrow = -1000; 		
xpercol =  1000; 		
ellipsoid = [6370997 0];	

switch lower(region)
    case {'af','africa'}
        nrows = 9276;
        ncols = 8350;
       
        xlim = [-4458000, 3891000];
        ylim = [-4795000, 4480000];
        origin = [5 20 0];	
        
        data.latlim = [-50,50];
        data.lonlim = [-40,70];
        
    case {'ap','australia/pacific'}
        nrows = 8000;
        ncols = 9300;
     
        xlim = [-5000000, 4299000];
        ylim = [-3944891, 4054109];
        origin = [-15 135 0];
        
        data.latlim = [-51,25];
        data.lonlim = [-180,180];
        
    case {'sa','south america'}
        nrows = 8000;
        ncols = 6000;
     
        xlim = [-3000000, 2999000];
        ylim = [-4899000, 3100000];
        origin = [-15 -60 0];	
        
        data.latlim = [-85,15];
        data.lonlim = [-110,-10];
        
    case {'e','europe'}
        nrows = 13000;
        ncols = 13000;
       
        xlim = [-3000000, 9999000];
        ylim = [-4999000, 8000000];
        origin = [55 20 0];	
         
        data.latlim = [-55, 90];
        data.lonlim = [-179,179];
      
    case {'a','asia'}
        nrows = 12000;
        ncols = 13000;
       
        xlim = [-8000000, 4999000];
        ylim = [-5499000, 6500000];
        origin = [45 100 0];
        
        data.latlim = [-30 90];
        data.lonlim = [-180,180];
        
    case {'na','north america'}
        nrows = 8996;
        ncols = 9223;
      
        xlim = [-4487000, 4735000];
        ylim = [-4515000, 4480000];
        origin = [50 -100 0];	
        
        data.latlim = [-10, 90];
        data.lonlim = [-179, 0];
              
    otherwise
        error(message('map:avhrr:invalidRegionString', 'af', 'africa', 'a', 'asia', 'ap', 'australia/pacific', 'e', 'europe', 'na', 'north america', 'sa', 'south america'));
end

% If the latitude or longitude limits are unspecified, then set to the data
% limits.
if ~isSpecified.latlim
    latlim = data.latlim;
end

if ~isSpecified.lonlim
    lonlim = data.lonlim;
end

% Define a map structure for the data in the Lambert equal area azimuthal
% projection.
mstruct = defaultm('eqaazim');
mstruct.origin = origin;
mstruct.geoid = ellipsoid;
mstruct = defaultm(mstruct);

% Compute the bounding box for the image in geographic and map coordinates.
[outputXlim, outputYlim] = computeImageBBox( ...
    mstruct, latlim, lonlim, data, xlim, ylim);

% Compute the referencing matrix.
W = [xpercol      0     xlim(1); ...
        0     yperrow   ylim(2)];
R = map.internal.referencingMatrix(W);

%--------------------------------------------------------------------------

function [outputXlim, outputYlim] = computeImageBBox( ...
    mstruct, latlim, lonlim, data, xlim, ylim)
% Compute the bounding box for the image in geographic and map coordinates.

if ~isequal(latlim,data.latlim) || ~isequal(lonlim,data.lonlim)

    % Latitude or longitude limits have been specified by the user. Find
    % the intersection of the bounding boxes of the user inputs with the
    % data.
    [latlim, lonlim] = ...
        intersectgeoquad(data.latlim, data.lonlim, latlim, lonlim);

    if isempty(latlim) || isempty(lonlim)
        % Bounding boxes do not intersect. Set the output limits to empty.
        outputYlim = [];
        outputXlim = [];
    else
        for k=1:size(latlim,1)
          [outputXlim(k,:), outputYlim(k,:)] = ...
              computeBBox(mstruct, latlim(k,:), lonlim(k,:)); %#ok<AGROW>
        end
        outputXlim = [min(outputXlim(:,1)) max(outputXlim(:,2))];
        outputYlim = [min(outputYlim(:,1)) max(outputYlim(:,2))];      
    end

else
    % Latitude and longitude limits have not been specified. Set the output
    % limits to the limits of the data.
    outputXlim = xlim;
    outputYlim = ylim;
end

%--------------------------------------------------------------------------

function [rlim, clim] = calculateImageLimits(R, xfrm, yfrm, nrows, ncols)
% Transform the x,y frame limits to row and column indices.
[rfrm,cfrm] = map2pix(R, xfrm, yfrm);
rfrm = floor(rfrm);
cfrm = floor(cfrm);

% Find the extent of the desired region in matrix indices. This is
% necessary because the desired region is not rectangular in the projected
% data. The returned data will extend beyond the requested region.
rlim = [max([1,min(rfrm)]) min([max(rfrm),nrows])];
clim = [max([1,min(cfrm)]) min([max(cfrm),ncols])];

%--------------------------------------------------------------------------

function [outputXlim, outputYlim] = computeBBox(mstruct, latlim, lonlim)

% Construct a bounding box for the latitude and longitude limits in
% projected coordinates.
[latfrm, lonfrm] = framemll(latlim, lonlim, 50);
[xfrm, yfrm] = map.crs.internal.mfwdtran(mstruct, latfrm, lonfrm);
xbox = [min(xfrm), max(xfrm), max(xfrm), min(xfrm)];
ybox = [min(yfrm), min(yfrm), max(yfrm), max(yfrm)];

% Set outputYlim (y-limits of the projected coordinates) based on
% the bounding box.
outputYlim = [min(ybox), max(ybox)];

% Set outputXlim (x-limits of the projected coordinates) based on
% the bounding box.
outputXlim = [min(xbox), max(xbox)];

%--------------------------------------------------------------------------

function [latfrm,lonfrm] = framemll(framelat,framelon,fillpts)
%FRAMEMLL Returns the unprojected frame points for lat and lon limits.

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
