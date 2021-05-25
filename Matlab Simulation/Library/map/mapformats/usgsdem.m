function [Z, refvec, header] = usgsdem(filename, samplefactor, varargin)
%USGSDEM  Read USGS 1-degree (3-arc-second) Digital Elevation Model
%
%  USGSDEM will be removed in a future release. Use READGEORASTER instead.
%
%  [Z, REFVEC] = USGSDEM(FILENAME, SAMPLEFACTOR) reads the specified file
%  and returns the elevation data in the regular data grid, Z, along with
%  referencing vector REFVEC.  REFVEC is a 1-by-3 vector containing
%  elements [cells/degree north-latitude west-longitude] with latitude and
%  longitude limits in degrees.  The data can be read at full resolution
%  (SAMPLEFACTOR = 1), or can be downsampled by SAMPLEFACTOR. A
%  SAMPLEFACTOR of 3 returns every third point, for example, giving 1/3 of
%  the full resolution.  The grid for the digital elevation maps is based
%  on World Geodetic System 1984 (WGS84). Older DEMs were based on WGS72.
%
%  [Z, REFVEC] = USGSDEM(FILENAME, SAMPLEFACTOR, LATLIM, LONLIM) reads a
%  subset of the elevation data from FILENAME. The limits of the desired
%  data are specified as two element vectors of latitude, LATLIM, and
%  longitude, LONLIM, in degrees. The elements of LATLIM and LONLIM must be
%  in ascending order.  The data will extend somewhat outside the requested
%  area. If omitted, the entire area covered by the DEM file is returned.
%
%  [Z, REFVEC, HEADER] = USGSDEM(...) returns file header in a structure,
%  HEADER.
%
%  See also DEMDATAUI, READGEORASTER, USGSDEMS

% Copyright 1996-2021 The MathWorks, Inc.

%  Ascii data file
%  Data arranged in S-N rows by W-E columns
%  Elevation in meters

% Check to ensure that the filename can be opened. If filename is empty,
% then the user has canceled the file dialog.
if nargin > 0
    filename = convertStringsToChars(filename);
end
filename = checkfilename(filename);
if isempty(filename)
    Z = [];
    refvec = [];
    header = [];
    return;
end

% Validate samplefactor.
validateattributes(samplefactor, {'numeric'}, {'nonempty', 'positive'}, ...
    mfilename, 'SAMPLEFACTOR', 2);

% Read the header record, documented in the DEM Data User's Guide 5 (1993).
[A, headerPosition] = usgsdeminfo(filename);

% Issue an error if the coordinates are not in a geographic system.
if A.PlanimetricReferenceSystemCode==1
    error(message('map:usgsdem:expectedGeographicCoordinates'))
elseif A.PlanimetricReferenceSystemCode~=0
    error(message('map:usgsdem:invalidGeographicCoordinates'))
end

% Compute referencing information.
[refvec, columnIndex, rowIndex] = computeReferencingInformation( ...
    A, samplefactor, varargin{:});
if isempty(refvec)
    % The requested limits are outside of the data limits and a warning was
    % issued. Return [] as values for all outputs.
    Z = [];
    header = [];
    return
end

% Read all the profiles and skip the ancillary header information.
skipHeader = true;
B = usgsdemprofile(filename, A, headerPosition, skipHeader);

% Construct the DEM datagrid.
Z = constructDataGrid(B, columnIndex, rowIndex);

if nargout == 3
    % Copy specific fields from header A to output structure and rename
    % fields to match interface.
    header = copyHeaderToOutputStructure(A);
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

function [refvec, columnIndex, rowIndex] = ...
    computeReferencingInformation(A, samplefactor, latlim, lonlim)
% Validate the latitude and longitude limits and compute the referencing
% information. The input A contains the header information. SAMPLEFACTOR is
% the requested sample factor. LATLIM and LONLIM are the latitude and 
% longitude limits and are permitted to be not supplied.
%
% REFEC is the referencing vector for the output data grid. COLUMNINDEX is
% a vector of doubles and contains the index values for the profile
% columns. ROWINDEX is a vector of doubles and contains the index values
% for the profile rows.

if ~exist('latlim', 'var') || ~exist('lonlim', 'var')
    subset = 0;
else
    subset = 1;
end

sf = samplefactor;

% Determine number of rows and columns for the entire set of profiles.
% According to the specification, "The row value m is usually set to 1 as
% an indication that the arrays are actually one-dimensional profiles." If
% NumberOfRowsAndColumns(1) is 1 (the value for the number of rows), then
% set both rows and columns to be identical.
ncols = A.NumberOfRowsAndColumns(2);
if A.NumberOfRowsAndColumns(1) == 1
    nrows = ncols;
else
    nrows = A.NumberOfRowsAndColumns(1);
end

if ~subset
    % Check to see if ncols fit samplefactor
    if mod((ncols-1),sf) ~= 0
        strcols = num2str( ncols );
        error(message('map:validate:samplefactorNotDivisibleIntoCols', strcols))
    end
end

arcsec3 = 3/60^2;
dy = arcsec3;
switch ncols
    case 1201, dx = arcsec3;
    case 601,  dx = 2*arcsec3;
    case 401,  dx = 3*arcsec3;
    otherwise
        error(message('map:usgsdem:invalidNcols'))
end

% Define border of map.
celldim = sf*arcsec3;
halfcell = celldim/2;
corners = ( reshape(A.BoundingBox,[2 4])' )/60^2;
maplatlim(1) = corners(1,2) - halfcell;
maplatlim(2) = corners(2,2) + halfcell;
maplonlim(1) = corners(1,1) - halfcell;
maplonlim(2) = corners(4,1) + halfcell;

if subset
    % Check to see if latlim and lonlim within map limits
    if latlim(1) > latlim(2)
        error(message('map:maplimits:expectedAscendingLatlim'))
    end
    if lonlim(1) > lonlim(2)
        error(message('map:maplimits:expectedAscendingLonlim'))
    end
    
    if latlim(1) > maplatlim(2) || latlim(2) < maplatlim(1) || ...
            lonlim(1) > maplonlim(2) || lonlim(2) < maplonlim(1)
        warning(message('map:usgsdem:limitsExcludeDataset',  ...
            sprintf('[%.4f %.4f]', maplatlim(1), maplatlim(2)), ...
            sprintf('[%.4f %.4f]', maplonlim(1), maplonlim(2)) ));
        
        refvec = [];
        columnIndex = [];
        rowIndex = [];
        return
    end
    
    clampLimits = false;
    if latlim(1) < maplatlim(1)
        latlim(1) = maplatlim(1);
        clampLimits = true;
    end
    if latlim(2) > maplatlim(2)
        latlim(2) = maplatlim(2);
        clampLimits = true;
    end
    if lonlim(1) < maplonlim(1)
        lonlim(1) = maplonlim(1);
        clampLimits = true;
    end
    if lonlim(2) > maplonlim(2)
        lonlim(2) = maplonlim(2);
        clampLimits = true;
    end
    if clampLimits
        warning(message('map:usgsdem:clampingLimits', ...
            sprintf('[%.4f %.4f]', maplatlim(1), maplatlim(2)), ...
            sprintf('[%.4f %.4f]', maplonlim(1), maplonlim(2)) ));
    end
    
    % Convert lat and lon limits to row and col limits
    halfdy = dy/2;
    halfdx = dx/2;
    ltlwr = corners(1,2)-halfdy:dy:corners(2,2)-halfdy;
    ltupr = corners(1,2)+halfdy:dy:corners(2,2)+halfdy;
    lnlwr = corners(1,1)-halfdx:dx:corners(4,1)-halfdx;
    lnupr = corners(1,1)+halfdx:dx:corners(4,1)+halfdx;
    if latlim(1)>=maplatlim(1) && latlim(1)<=ltlwr(1)
        rowlim(1) = 1;
    else
        rowlim(1) = find(ltlwr<=latlim(1) & ltupr>=latlim(1), 1 );
    end
    if latlim(2)<=maplatlim(2) && latlim(2)>=ltupr(length(ltupr))
        rowlim(2) = 1201;
    else
        rowlim(2) = find(ltlwr<=latlim(2) & ltupr>=latlim(2), 1, 'last' );
    end
    if lonlim(1)==maplonlim(1)
        collim(1) = 1;
    else
        collim(1) = find(lnlwr<=lonlim(1) & lnupr>=lonlim(1), 1 );
    end
    if lonlim(2)==maplonlim(2)
        collim(2) = ncols;
    else
        collim(2) = find(lnlwr<=lonlim(2) & lnupr>=lonlim(2), 1, 'last' );
    end
end

% Start profile position indicators
sfmin = 1200/(ncols-1);
if mod(sf,sfmin)~=0
    error(message('map:validate:samplefactorNotDivisible', num2str( sfmin )));
end

% Compute refvec.
if ~subset
    columnIndex = 1:sf/sfmin:ncols;
    maptop = maplatlim(2);
    mapleft = maplonlim(1);
else
    columnIndex = collim(1):sf/sfmin:collim(2);
    maptop  = corners(1,2) + dy*(rowlim(2)-1) + halfcell;
    mapleft = corners(1,1) + dx*(collim(1)-1) - halfcell;
end
cellsize = 1/celldim;
refvec = [cellsize maptop mapleft];

% Compute rowIndex.
if subset == 0
    rowIndex = 1:sf:nrows;
else
    rowIndex = rowlim(1):sf:rowlim(2);
end

%--------------------------------------------------------------------------

function Z = constructDataGrid(B, columnIndex, rowIndex)
% Construct the DEM data grid from the profiles in the B structure.
% numberOfColumns is the number of columns in the output grid. rowIndex is
% a vector of desired rows in the profile.

% Initialize Z as NaNs.
numberOfRows = length(rowIndex);
numberOfColumns = length(columnIndex);
Z = nan(numberOfRows, numberOfColumns);

% Copy the profile values to Z.
for n = 1:numberOfColumns
    profileColumn = columnIndex(n);
    profile = B(profileColumn).Profile;
    if length(profile) ~= 1201
        error(message('map:usgsdem:unableToReadProfile', filename));
    end
    Z(:, n) = profile(rowIndex);
end

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
    'DataEdition', 'DataEdition'; ...
    'PercentVoid', 'PercentVoid'};

% Copy the field values from headerA to Astruct.
n = length(names);
for k = 1:n
    Astruct.(names{k, 1}) = headerA.(names{k, 2});
end
