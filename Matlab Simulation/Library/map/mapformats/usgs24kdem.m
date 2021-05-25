function [lat, lon, Z, header, profile] = usgs24kdem( ...
    filename, samplefactor, latlim, lonlim, gsize)
% USGS24KDEM Read USGS 7.5-minute (30-m or 10-m) Digital Elevation Model
%
%     USGS24KDEM will be removed in a future release. Use READGEORASTER
%     instead. Note: when importing a USGS 24K DEM, READGEORASTER returns a
%     regular data grid referenced to UTM via a raster reference object,
%     rather than a pair of latitude-longitude geolocation arrays.
% 
%   [LAT, LON, Z] = USGS24KDEM reads a USGS 1:24,000 Digital Elevation Map
%   (DEM) file in standard format.  The file is selected interactively. The
%   entire file is read and subsampled by a factor of 5. A geolocated data
%   grid is returned with a latitude array, LAT, longitude array, LON, and
%   elevation array, Z. Horizontal units are in degrees, vertical units may
%   vary.  The 1:24,000 series of DEMs are stored as a grid of elevations
%   spaced either at 10 or 30 meters apart. The number of points in a file
%   will vary with the geographic location.
%   
%   [LAT, LON, Z] = USGS24KDEM(FILENAME) reads the USGS DEM specified by
%   FILENAME and returns the result as a geolocated data grid.
%   
%   [LAT, LON, Z] = USGS24KDEM(FILENAME, SAMPLEFACTOR) reads a subset of
%   the DEM data from FILENAME.  SAMPLEFACTOR is a scalar integer, which
%   when equal to 1 reads the data at its full resolution. When
%   SAMPLEFACTOR is an integer n greater than one, every nth point is read.
%   If SAMPLEFACTOR is omitted or empty, it defaults to 5. 
%   
%   [LAT, LON, Z] = USGS24KDEM(FILENAME, SAMPLEFACTOR, LATLIM, LONLIM)
%   reads a subset of the elevation data from FILENAME. The limits of the
%   desired data are specified as two element vectors of latitude, LATLIM,
%   and longitude, LONLIM, in degrees. The elements of LATLIM and LONLIM
%   must be in ascending order.  The data may extend somewhat outside the
%   requested area. If omitted, the entire area covered by the DEM file is
%   returned.
%   
%   [LAT, LON, Z] = USGS24KDEM(FILENAME, SAMPLEFACTOR, LATLIM, LONLIM,
%   GSIZE) specifies the graticule size in GSIZE. GSIZE is a two element
%   vector  specifying the number of rows and columns in the latitude and
%   longitude coordinate grid. If omitted, a graticule the same size as
%   the geolocated data grid is returned. Use empty matrices for LATLIM and
%   LONLIM to specify the coordinate grid size without specifying the
%   geographic limits.
% 
%   [LAT, LON, Z, HEADER, PROFILE] = USGS24KDEM(...) also returns the
%   contents of the header and raw profiles of the DEM file. The HEADER
%   structure contains descriptions of the data from the file header. The
%   PROFILE structure is the raw profile data from which the geolocated
%   data grid is constructed.
%
%   See also DEMDATAUI, GEORASTERINFO, READGEORASTER, USGSDEMS

% Copyright 1996-2021 The MathWorks, Inc.

% Assign default values.
if nargin < 1; filename = []; end
if nargin < 2; samplefactor=5; end
if nargin < 3; latlim = []; end
if nargin < 4; lonlim = []; end
if nargin < 5; gsize = [];  end

% Check to ensure that the filename can be opened. If filename is empty,
% then the user has canceled the file dialog.
if nargin > 0
    filename = convertStringsToChars(filename);
end
filename = checkfilename(filename);
if isempty(filename)
    lat = [];
    lon = [];
    Z = [];
    header = [];
    profile = [];
    return;
end

% Read the header record, documented in the DEM Data User's Guide 5 (1993).
[A, headerPosition] = usgsdeminfo(filename);

% Issue an error if the coordinates are not in a planar system.
if A.PlanimetricReferenceSystemCode == 0
    error(message('map:usgsdem:expectedPlanimetricCoordinates'))
elseif A.PlanimetricReferenceSystemCode ~= 1
    error(message('map:usgsdem:invalidPlanimetricCoordinates'))
end

% Read all the profiles.
B = usgsdemprofile(filename, A, headerPosition);
 
% Compute northing and easting values.
[B, minmax] = computeNorthingAndEasting(B, ...
     A.XYZ_SpatialResolution, A.RotationAngle);

% Construct the DEM datagrid.
[lat, lon, Z] = constructDataGrid( ...
    A, B, minmax, latlim, lonlim,  samplefactor, gsize);

if nargout > 3
    % Copy specific fields from header A to output structure and rename
    % fields to match interface.
    header = copyHeaderToOutputStructure(A);
end

if nargout > 4
    % Rename B fields to match interface.
    profile = renameBProfile(B);
end

%--------------------------------------------------------------------------

function filename = checkfilename(filename)
% Check to ensure that the filename can be opened. If not, request a
% filename using a file dialog. Return empty if the user clicks cancel on
% the file dialog.

fid = -1;
if ~isempty(filename)
    fid = fopen(filename,'r');
end

if fid==-1
    [filename, path] = uigetfile('', 'Please select the USGS 1:24,000 DEM file');
    if filename == 0
        filename = [];
        return
    end
    filename = [path filename];
    fid = fopen(filename,'r');
end
fclose(fid);

%--------------------------------------------------------------------------

function [B, minmax] = computeNorthingAndEasting( ...
    B, spatialResolution, rotationAngle)
% Compute the northing and easting values for the profiles. B is a
% structure array containing the B profiles. spatialResolution is a double
% vector and contains the X, Y, and X spatial resolutions. rotationAngle is
% in radians.

% Compute max and min locations for the data grid.
maxn = -inf; minn = inf;
maxe = -inf; mine = inf;

% Spatial resolutions and rotation angle.
% unused: deltax = A.XYZ_SpatialResolutions(1);
deltay = spatialResolution(2);
deltaz = spatialResolution(3);

nprofiles = length(B);
for k = 1:nprofiles	
    
    % Compute the 24k DEM profile.
	B(k).Profile = B(k).Profile * deltaz + B(k).LocalDatumElevation;

	% Convert raw data to actual locations (UTM coordinates, elevations)
	% Locations in rotated coordinate system with origin at the first point
	% Profiles are lines south to north, first profile is west, profiles
	% move progressively east
	y = (0:B(k).NumberOfElevations(1)-1)' * deltay;
	originX = B(k).GroundPlanimetricCoordinates(1);
	B(k).Easting = originX - y*sin(rotationAngle);
	maxe = max(maxe, max(B(k).Easting));
	mine = min(mine, min(B(k).Easting));	
	
    originY = B(k).GroundPlanimetricCoordinates(2);
	B(k).Northing = originY + y*cos(rotationAngle);
	maxn = max(maxn, max(B(k).Northing));
	minn = min(minn, min(B(k).Northing));
end

minmax.NorthingMaximum = maxn;
minmax.NorthingMinimum = minn;
minmax.EastingMaximum = maxe;
minmax.EastingMinimum = mine;

%--------------------------------------------------------------------------

function [latgrat, longrat, Z] = constructDataGrid( ...
    A, B, minmax, latlim, lonlim, samplefactor, gsize)
% Construct the DEM data grid and the latitude and longitude graticule.

maxn = minmax.NorthingMaximum;
minn = minmax.NorthingMinimum;
mine = minmax.EastingMinimum;

% Fill in with NaNs to make a rectangular matrix.
yres = A.XYZ_SpatialResolution(2);
nrows = (maxn-minn)/yres+1;
nprofiles = length(B);
ncols = nprofiles;
Z = NaN(nrows,ncols);

% Fill in with profile values.
for i=1:nprofiles
    ntop = round((maxn-max(B(i).Northing))/yres);
    nbot = round((min(B(i).Northing)-minn)/yres);
    v = flipud([NaN([nbot 1]); B(i).Profile; NaN([ntop 1])]);
    ln = min([nrows, length(v)]);
    Z(1:ln,i) = v;
end

% Define a map projection structure for the UTM data
% Need to check that UTM updates values properly
mstruct = defaultm('utm');
mstruct.zone = [num2str(A.Zone) 'T'];  % remove extraneous 'T' when UTM modified
mstruct.geoid = A.ReferenceEllipsoid;
mstruct = defaultm(mstruct);

yperrow = -A.XYZ_SpatialResolution(2);
xpercol =  A.XYZ_SpatialResolution(1);
x1 = mine;
y1 = maxn;

% At this point we have a rectangular grid in projected coordinates.
if isempty(latlim) || isempty(lonlim) 	
    % Return the whole matrix.
	rlim = [1 nrows];
	clim = [1 ncols];
else
    % Map requested region into the matrix
	% Ensure that latlim and lonlim are within range.
	latlim = latlim(:)';
	lonlim = lonlim(:)';
	lonlim = wrapTo180(lonlim);

	% Construct a frame around desired region.
	[latfrm,lonfrm] = framemll(latlim,lonlim,10);

	% Transform the frame to projected coordinates and then to row and
	% column indices.
    [xfrm,yfrm] = map.crs.internal.mfwdtran(mstruct,latfrm,lonfrm);
    [rfrm,cfrm] = yx2rc(yfrm,xfrm,y1,x1,yperrow,xpercol);

    % Find the extent of the desired region in matrix indices. This is
    % necessary because the desired region is not rectangular in the
    % projected data. The returned data will extend beyond the requested
    % region.
    rlim = [max([1,min(rfrm)]) min([max(rfrm),nrows])];
    clim = [max([1,min(cfrm)]) min([max(cfrm),ncols])];
end

% Extract the map matrix.
readrows = rlim(1):samplefactor:rlim(2);
readcols = clim(1):samplefactor:clim(2);
Z = Z(readrows,readcols);

% Construct a graticule of row and column indices.
if isempty(gsize) 			
    % size(grat) = size(mat)
	[rIndGrat,cIndGrat] = ndgrid(readrows,readcols);
else
    % texture map the data to a smaller graticule
    epsilon = 1.0E-10;
    [rIndGrat,cIndGrat] = ndgrid(...
        linspace(min(readrows) + epsilon, max(readrows) - epsilon, gsize(1)), ...
        linspace(min(readcols) + epsilon, max(readcols) - epsilon, gsize(2)));
end

% Map row and column graticule to x and y values.
[ygrat,xgrat] = rc2yx(rIndGrat,cIndGrat,y1,x1,yperrow,xpercol);

% Map x and y graticule to lat and long.
[latgrat,longrat] = map.crs.internal.minvtran(mstruct,xgrat,ygrat);

%--------------------------------------------------------------------------

function [latfrm,lonfrm] = framemll(framelat,framelon,fillpts)
%FRAMELL returns the unprojected frame points for lat and long limits

epsilon   = 1000*epsm('degrees');

% Construct the frame.
framelat = framelat + [epsilon -epsilon];    %  Avoid clipping at edge of
framelon = framelon + [epsilon -epsilon];    %  of map

lats = linspace(min(framelat),max(framelat),fillpts)';   %  Fill vectors with
lons = linspace(min(framelon),max(framelon),fillpts)';   %  frame limits

latfrm = [lats;           framelat(2)*ones(size(lats));  %  Construct
	      flipud(lats);   framelat(1)*ones(size(lats))]; %  complete frame
lonfrm = [framelon(1)*ones(size(lons));    lons;         %  vectors
          framelon(2)*ones(size(lons));    flipud(lons);];
  
%--------------------------------------------------------------------------

function Astruct = copyHeaderToOutputStructure(headerA)
% Copy the header structure, headerA, to a new output structure, Astruct,
% using the field names defined by the interface.

Astruct = struct;

% Astruct names are in column 1, headerA names are in column 2.
names = { ...
    'Quadranglename', 'QuadrangleName'; ...
    'TextualInfo',    'FreeFormText'; ...
    'Filler',         'Filler'; ...
    'ProcessCode',    'Process'; ...
    'Filler2',        'Filler2'; ...
    'SectionalIndicator',   'SectionalIndicator'; ...
    'MCoriginCode',         'MC_OriginCode'; ...
    'DEMlevelCode',         'DEM_LevelCode'; ...
    'ElevationPatternCode', 'ElevationPattern'; ...
    'PlanimetricReferenceSystemCode'  'PlanimetricReferenceSystem'; ...
    'Zone', 'Zone'; ...
    'ProjectionParameters', 'MapProjectionParameters'; ...
    'HorizontalUnits',      'HorizontalUnitOfMeasure'; ...
    'ElevationUnits',       'VerticalUnitOfMeasure'; ...
    'NsidesToBoundingBox',  'NumberOfBoundingBoxSides'; ...
    'BoundingBox',          'BoundingBox'; ...
    'MinMaxElevations',     'ElevationLimits'; ...
    'RotationAngle',        'RotationAngle'; ...
    'AccuracyCode',         'AccuracyInformation'; ...
    'XYZresolutions',       'XYZ_SpatialResolution'; ...
    'NrowsCols',            'NumberOfRowsAndColumns'; ...
    'MaxPcontourInt',       'PrimaryContourInterval'; ...
    'SourceMaxCintUnits',   'SourceMaxContourIntervalUnits'; ...
    'SmallestPrimary',      'SmallestPrimaryContourInterval'; ...
    'SourceMinCintUnits',   'SourceMinContourIntervalUnits'; ...
    'DataSourceDate',       'DataSourceDate'; ...
    'DataInspRevDate',      'DataInspectionRevisionDate'; ...
    'InspRevFlag',          'InspectionRevisionFlag'; ...
    'DataValidationFlag',   'DataValidation'; ...
    'SuspectVoidFlag',      'SuspectVoid'; ...
    'VerticalDatum',        'VerticalDatumName'; ...
    'HorizontalDatum',      'HorizontalDatumName'; ...
    'DataEdition',          'DataEdition'; ...
    'PercentVoid',          'PercentVoid'};

% Copy the field values from headerA to Astruct.
n = length(names);
for k = 1:n
    Astruct.(names{k, 1}) = headerA.(names{k, 2});
end

%--------------------------------------------------------------------------

function Bstruct = renameBProfile(B)
% Rename the fields of the B profiles to match the interface.

Bstruct = struct();
names = { ...
    'rowcol',     'RowColumn'; ...
    'nelev',      'NumberOfElevations'; ...
    'localdatum', 'LocalDatumElevation'; ...
    'minmaxelev', 'ElevationLimits'; ...
    'profile',    'Profile'; ...
    'easting',    'Easting'; ...
    'northing',   'Northing';};

% Copy the field values from B to Bstruct
Bstruct(1:length(B)) = Bstruct;
for k = 1:length(names)
    [Bstruct.(names{k, 1})] = B.(names{k, 2});
end
