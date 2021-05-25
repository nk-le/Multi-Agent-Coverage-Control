function [z,refvec] = gtopo30(varargin)
%GTOPO30 Read 30-arc-second global digital elevation data (GTOPO30)
%
%   GTOPO30 will be removed in a future release. Use READGEORASTER instead.
%
%   [Z, REFVEC] = GTOPO30(TILENAME) reads the GTOPO30 tile specified by
%   TILENAME and returns the result as a regular data grid.  TILENAME does 
%   not include an extension and indicates a GTOPO30 tile in the current 
%   directory or on the MATLAB path.  If TILENAME is empty or omitted, a 
%   file browser will open for interactive selection of the GTOPO30 header 
%   file.  The data is returned at full resolution with the latitude and 
%   longitude limits determined from the GTOPO30 tile.  The data grid, Z, 
%   is returned as an array of elevations.  Elevations are given in meters 
%   above mean sea level using WGS84 as a horizontal datum.  REFVEC is the 
%   associated referencing vector.
%
%   [Z, REFVEC] = GTOPO30(TILENAME, SAMPLEFACTOR) reads a subset of the
%   elevation data from TILENAME.  SAMPLEFACTOR is a scalar integer, which
%   when equal to 1 reads the data at its full resolution.  When
%   SAMPLEFACTOR is an integer n greater than one, every n-th point is read.
%   If SAMPLEFACTOR is omitted or empty, it defaults to 1. 
%   
%   [Z, REFVEC] = GTOPO30(TILENAME, SAMPLEFACTOR, LATLIM, LONLIM) reads a
%   subset of the elevation data from TILENAME using the latitude and
%   longitude limits LATLIM and LONLIM specified in degrees. LATLIM is a
%   two-element vector of the form:
%
%                 [southern_limit northern_limit]
%
%   Likewise, LONLIM has the form:
%
%                  [western_limit eastern_limit]
%
%   If LATLIM and LONLIM are omitted, the coordinate limits are determined
%   from the file.  The latitude and longitude limits are snapped outward
%   to define the smallest possible rectangular grid of GTOPO30 cells that
%   fully encloses the area defined by the input limits.  Any cells in this
%   grid that fall outside the extent of the tile are filled with NaN.
%  
%   [Z, REFVEC] = GTOPO30(DIRNAME, ...) is similar to the syntaxes above
%   except that GTOPO30 data are read and concatenated from multiple tiles
%   within a GTOPO30 CD-ROM or directory structure. The DIRNAME input is
%   the name of the directory which contains the GTOPO30 tile directories
%   or GTOPO30 tiles.  Within the tile directories are the uncompressed
%   data files.  The DIRNAME for CD-ROMs distributed by the USGS is the
%   device name of the CD-ROM drive.  As with the case with a single tile,
%   any cells in the grid specified by LATLIM and LONLIM are NaN filled if
%   they are not covered by a tile within DIRNAME. SAMPLEFACTOR if omitted
%   or empty defaults to 1. LATLIM if omitted or empty defaults to [-90
%   90]. LONLIM if omitted or empty defaults to [-180 180].
% 
%   Example 1
%   ---------
%   % Extract and display a subset of full resolution data for the state of
%   % Massachusetts.
%   % Read the stateline polygon boundary and calculate boundary limits.
%   Massachusetts = shaperead('usastatehi', 'UseGeoCoords', true, ...
%       'Selector',{@(name) strcmpi(name,'Massachusetts'), 'Name'});
%   latlim = [min(Massachusetts.Lat(:)) max(Massachusetts.Lat(:))];
%   lonlim = [min(Massachusetts.Lon(:)) max(Massachusetts.Lon(:))];
%   
%   % Read the GTOPO30 data at full resolution.
%   [Z,refvec] = gtopo30('W100N90',1,latlim,lonlim);
%
%   % Display the data grid and overlay the stateline boundary.
%   figure
%   usamap('Massachusetts');
%   geoshow(Z, refvec, 'DisplayType', 'surface')
%   geoshow([Massachusetts.Lat],[Massachusetts.Lon],'Color','magenta')
%   demcmap(Z)
%
%   Example 2
%   ---------
%   % Extract every 20th point from a tile. 
%   % Provide an empty filename and select the file interactively. 
%   [z,refvec] = gtopo30([],20);
%
%   Example 3
%   ---------
%   % Extract data for Thailand, an area which straddles two tiles. 
%   % The data is on CD number 3 distributed by the USGS.
%   % The CD-device is 'F:\'
%   latlim = [5.22 20.90]; 
%   lonlim = [96.72 106.38];
%   gtopo30s(latlim,lonlim)
%   % Extract every fifth data point for Thailand.
%   [Z,refvec] = gtopo30('F:\',5,latlim,lonlim);
%
%   Example 4
%   ---------
%   % Extract every 10th point from a column of data 5 degrees around the 
%   % prime meridian. The current directory contains GTOPO30 data.
%   [Z, refvec] = gtopo30(pwd, 10, [], [-5 5]);
%
%   See also READGEORASTER

% Copyright 1996-2021 The MathWorks, Inc.

%   Ascii header file, binary
%   Data arranged in W-E columns by N-S rows
%   Elevation in meters
%   GTOPO30 files are binary. No line ending conversion should be performed
%   during transfer or decompression.

% Check number of inputs.
narginchk(0,4)

% Parse input arguments.
[filename, samplefactor, latlim, lonlim] = parseInputs(varargin{:});

% Snap the limits to cell boundaries within the grid.
[latlim, lonlim] = snapLimitsToGrid(latlim, lonlim);

% Read the data from a single file or a directory.
if exist([filename '.DEM'],'file') == 2
    % filename is a single GTOPO30 DEM filename.
    [z,refvec] = gtopo30FileRead(filename, samplefactor, latlim, lonlim);
    
elseif exist(filename, 'dir') == 7
    % filename is a directory.
    [z,refvec] = gtopo30DirRead(filename, samplefactor, latlim, lonlim);
    
else
    % filename is unknown. Assume it points to a single tile.
    [z,refvec] = gtopo30FileRead(filename, samplefactor, latlim, lonlim);
end

%--------------------------------------------------------------------------

function [filename, samplefactor, latlim, lonlim] = parseInputs(varargin)
% Parse the command line inputs.

% Set default values.
filename = '';
samplefactor = [];

% Allow empty values for latitude and longitude limits.
latlim = [];
lonlim = [];

% Obtain input arguments from varargin.
switch nargin
    case 1
        filename = varargin{1};
    case 2
        filename = varargin{1};
        samplefactor = varargin{2};
    case 3
        filename = varargin{1};
        samplefactor = varargin{2};
        latlim = varargin{3};
    case 4
        filename = varargin{1};
        samplefactor = varargin{2};
        latlim = varargin{3};
        lonlim = varargin{4};
end

% Validate SAMPLEFACTOR.
if isempty(samplefactor)
    samplefactor = 1;
else
    validateattributes(samplefactor, {'double'}, {'scalar','integer','finite'}, ...
               mfilename, 'SAMPLEFACTOR' ,2);
end

% Validate FILENAME and permit it to be empty.
filename = convertStringsToChars(filename);
if ~isempty(filename)
    validateattributes(filename, {'char','string'}, {'scalartext'}, mfilename, ...
        'TILENAME (or DIRNAME)', 1)
else
    % Ensure that filename is an empty character vector.
    filename = '';
end

%--------------------------------------------------------------------------

function [latlim, lonlim] = snapLimitsToGrid(latlim, lonlim)
% Unless latlim and/or lonlim is empty, snap the latitude and/or longitude
% limits to coincide with the edges of the GTOPO30 grid cells. If latlim is
% empty, then leave it empty. If lonlim is empty, then leave it empty.

% Cellsize is 30 arc-seconds so there are 120 cells per degree.
cellDensity = cellsPerDegree;

if ~isempty(lonlim)
    % Validate the longitude limits.
    checklonlim(lonlim, 4);
    
    % Snap lonlim outward to the limits of the nearest tile cell by
    % converting the limits to intrinsic coordinates. Snap the row and col
    % limits, then convert back to geographic coordinates. Wrap the
    % longitude to 180 since the GTOPO30 tiles range from [-180 180]. The
    % wrapping may cause the western and eastern limits to be equal. In
    % this case, the function will read from the full set of tiles for a
    % given latitude.
    intrinsic = lonlim*cellDensity;
    intrinsic = [floor(intrinsic(1)) ceil(intrinsic(2))];
    intrinsic(2) = min([intrinsic(2), intrinsic(1) + cellDensity*360]);
    lonlim = wrapTo180(intrinsic/cellDensity);
end

if ~isempty(latlim)
    % Validate the latitude limits.
    checklatlim(latlim, 3);
    
    % Snap latlim outward to the limits of the nearest tile cell by
    % converting the limits to intrinsic coordinates. Snap the row and col
    % coordinates, then convert back to geographic coordinates.
    intrinsic = latlim*cellDensity;
    latlim = [floor(intrinsic(1)) ceil(intrinsic(2))]/cellDensity;
end

%--------------------------------------------------------------------------

function checklatlim(lat, lat_pos)
% Validate LATLIM.

lat_var_name = 'LATLIM';
validateattributes(lat, {'double'}, {'real', 'vector', 'finite', 'numel', 2},  ...
    mfilename, lat_var_name, lat_pos);

if lat(1) > lat(2)
    error(message('map:validate:expectedAscendingOrder', lat_var_name));
end

%--------------------------------------------------------------------------

function checklonlim(lon, lon_pos)
% Validate LONLIM

lon_var_name = 'LONLIM';
validateattributes(lon, {'double'}, {'real', 'vector', 'finite', 'numel', 2},  ...
    mfilename, lon_var_name, lon_pos);

%--------------------------------------------------------------------------

function [Z, refvec] = gtopo30FileRead( ...
    tilePathName, samplefactor, latlim, lonlim)
% Read data from a GTOPO30 file.

% If the requested tilePathName is empty, use the filebrowser to obtain it.
if isempty(tilePathName)
    [tilePathName, path] = uigetfile('*.HDR', ...
        'Select the GTOPO30 header file (*.HDR)');
    if tilePathName == 0
        Z = [];
        refvec = [];
        return
    end
    tilePathName = ([path tilePathName]);
    tilePathName = tilePathName(1:length(tilePathName)-4);
end

% Does the DEM file exist?
if ~exist([tilePathName, '.DEM'], 'file')
    error(message('map:gtopo30:fileNotFound', [tilePathName '.DEM']));
end

% Obtain the tileName from the tilePathName.
[~, tileName] = fileparts(tilePathName);

% The latitude and longitude limits may be empty. If so, obtain the limits
% from the corresponding tile. If the limits contain the tile, then set
% limitsContainTile to true. If the limits are contained within the tile
% limits, then set limitsInTile to true.
[latlim, lonlim, limitsContainTile, limitsInTile] = getTileLimits( ...
    tileName, latlim, lonlim);

if ~limitsContainTile
    % The request tile does not contain data within the specified limits.
    Z = NaN;
    refvec = calcRefVec(latlim, lonlim, samplefactor);
    
elseif limitsInTile
    % Read the data from the tile.
    [Z, refvec] = readSingleTile(tilePathName, samplefactor, latlim, lonlim);
    
else
    % Create a data grid with NaN values and fill the grid with data read
    % from the tile.
    tilePathName = {tilePathName};
    [Z, refvec] = readMultipleTiles(tilePathName, samplefactor, latlim, lonlim);
end

%-------------------------------------------------------------------------- 

function [Z, refvec] = gtopo30DirRead(dirname, samplefactor, latlim, lonlim)
% Read and concatenate GTOPO30 (30-arc-sec resolution) digital
% elevation files from a directory.

% Update the latitude and longitude limits if empty.
if isempty(latlim)
    latlim = [-90 90];
end
if isempty(lonlim)
    lonlim = [-180 180];
end

% Check the current directory and dirname for GTOPO30 files. Return a cell
% array of tile names and a cell array of fully qualified path names.
% (The tilePathNames do not contain file extensions.)
[tileNames, tilePathNames] = dirDemFiles(dirname, latlim, lonlim);

% Check to see if any tiles are found. 
if isempty(tileNames)
    % No tiles exist. Return a single NaN for Z and calculate a
    % corresponding refvec based on the specified limits and samplefactor
    % and issue a warning.
    Z = NaN;
    refvec = calcRefVec(latlim, lonlim, samplefactor);
    warning(message('map:gtopo30:noDataInDir', 'GTOPO30', dirname));
else
    % Read the data from a set of tiles. Create a data grid with NaNs, then
    % read each tile and fill the grid.
    [Z, refvec] = readMultipleTiles(tilePathNames, samplefactor, latlim, lonlim);
end
   
%--------------------------------------------------------------------------

function [Z, refvec] = readMultipleTiles(...
    tilePathNames, samplefactor, latlim, lonlim)
% Create a data grid with NaN values and fill the data grid with the data
% read from the tiles specified in tilePathNames.

% Calculate the referencing vector.
refvec = calcRefVec(latlim, lonlim, samplefactor);

% Calculate the size of the data grid.
cellDensity = cellsPerDegree;
[nrows, ncols] = calcDataGridSize(latlim, lonlim, samplefactor, cellDensity);

% Construct a grid with NaN values. 
Z = nanDataGrid(nrows, ncols);

% Read the data from a set of tiles and fill the grid.
for k = 1:numel(tilePathNames)
    Z = fillDataGrid(Z, refvec, tilePathNames{k}, ...
        samplefactor, latlim, lonlim);
end

%--------------------------------------------------------------------------

function Z  = nanDataGrid(nrows, ncols)
% Construct a grid full of NaNs.

try
    Z = nan(nrows, ncols);
catch e
    error(message('map:gtopo30:nanError', nrows, ncols, e.message));
end

%--------------------------------------------------------------------------

function Z  = fillDataGrid( ...
    Z, refvec, tilePathName, samplefactor, latlim, lonlim)
% Fill the data grid with values from tilePathName.

% Read the data from the file.
if longitudesWrap(lonlim)
    [tz, trefvec] = readAcross180( ...
        tilePathName, samplefactor, latlim, lonlim);
else
    [tz, trefvec] = readSingleTile( ...
        tilePathName, samplefactor, latlim, lonlim);
end

% Find the row and column index of Z that places the [1,1] element of the
% data grid read from the file, tz, (spatially referenced by trefvec), into
% Z, (spatially referenced by refvec).
[row, col] = findFirstRowCol(trefvec, size(tz), refvec, size(Z));
row = max(row, 1);
col = max(col, 1);

% Insert the data read from the file, tz, into Z.
if ~isempty(row) && ~isempty(col)
    endRow = row + size(tz,1) - 1;
    endCol = col + size(tz,2) - 1;
    if endCol <= size(Z, 2)
        % All the data in tz fits into Z.
        Z(row:endRow, col:endCol) = tz;
    else
        % The data in tz wraps.
        numWestCols = endCol - size(Z,2);
        numEastCols = size(tz, 2) - numWestCols;
        endCol = size(Z, 2);
        Z(row:endRow, col:endCol) = tz(:, 1:numEastCols);
        Z(row:endRow, 1:numWestCols) = tz(:, numEastCols+1:end);
    end
end

%--------------------------------------------------------------------------

function [Z, refvec] = readAcross180(...
    tilePathName, samplefactor, latlim, lonlim)
% Read data across the 180 degree meridian. 
% In this case, lonlim(2) >= lonlim(1).

lon_west = lonlim(1);
lon_east = lonlim(2);

% -180 to lon_east
lonlim(1) = -180;
lonlim(2) = lon_east;

% Read western part of data grid: -180 to lon_east.
[west_Z, refvec_west] = readSingleTile( ...
    tilePathName, samplefactor, latlim, lonlim);

% lon_west to 180
lonlim(1) = lon_west;
lonlim(2) = 180;
% Read eastern part of data grid: lon_west to 180.
[east_Z, refvec_right] = readSingleTile( ...
    tilePathName, samplefactor, latlim, lonlim);

% Concatenate Z.
Z = [west_Z east_Z];

if ~isempty(refvec_west)
    refvec = refvec_west;
elseif ~isempty(refvec_right)
    refvec = refvec_right;
else
    refvec = [];
end

%--------------------------------------------------------------------------

function [Z, refvec] = readSingleTile( ...
    tilePathName, samplefactor, latlim, lonlim)
% Read the various files (header, world file, and DEM) for a single GTOPO30
% tile.

% Read header information.
[nrows, ncols, nodata, ulxmap, ulymap] = readHeaderFiles(tilePathName);

% Prevent round-off errors from ASCII data in headers.
cellSize = 1/cellsPerDegree;
dlat = -cellSize;
dlon = cellSize;
ulxmap = round(ulxmap - cellSize/2);
ulxmap = ulxmap + cellSize/2;
ulymap = round(ulymap + cellSize/2);
ulymap = ulymap - cellSize/2;

% Convert lat and lonlim to column and row indices.
[rlim, clim] = rowAndColLimits(latlim(:),lonlim(:),ulymap,ulxmap,dlat,dlon);

% Ensure image coordinates are within limits.
rlim = intersectImageLimits(rlim, nrows);
clim = intersectImageLimits(clim, ncols);
if isempty(rlim) || isempty(clim)
    % There is no overlapping row, column indices with image limits.
    Z = [];
    refvec = [];
else
    % Assign readrows and readcols.
    readrows = rlim(1):samplefactor:rlim(2);
    readcols = clim(1):samplefactor:clim(2);
    readcols = mod(readcols,ncols); 
    readcols(readcols == 0) = ncols;
    
    % Extract the Z matrix from the file.
    filename = [tilePathName '.DEM'];
    format.NumRows = nrows;
    format.NumCols = ncols;
    format.NumberType = 'int16';
    format.ByteOrder  = 'ieee-be';
    format.NoDataValue = nodata;
    Z = singlebandread(format, filename, readrows, readcols);
    
    % Construct the referencing vector.
    refvec = constructRefvec( ...
        rlim, clim, ulymap, ulxmap, dlat, dlon, samplefactor);
end

%--------------------------------------------------------------------------

function Z = singlebandread(format, filename, readrows, readcols)
% Read a single band from FILENAME based on the specified FORMAT.

% Assign variables from format information.
dataSize = [format.NumRows, format.NumCols, 1];
precision = format.NumberType;
offset = 0;
interleave = 'bsq';
byteOrder = format.ByteOrder;

% Flip the rows so that the output runs from south to north.
readrows = readrows(end:-1:1);

% Read the data.
Z = multibandread(filename, dataSize, precision, offset, interleave, ...
    byteOrder, {'Row','Direct', readrows}, {'Column', 'Direct', readcols});

% Set no data values.
Z(Z==format.NoDataValue) = NaN;

%--------------------------------------------------------------------------

function lim = intersectImageLimits(lim, maxlim)
% Intersect a two-element vector, lim, with [1, maxlim] and return the new
% limits. If there is no intersection, return [].

a = min(lim);
b = max(lim);
c = 1;
d = maxlim;

limitsInImage = ~((a > d) || (b < c));
if limitsInImage
    lim = [max(a,c), min(b, d)];
else
    lim = [];
end

%--------------------------------------------------------------------------

function [nrows, ncols, nodata, ulxmap, ulymap, xdim, ydim] = ...
    readHeaderFiles(tilePathName)
% Read header files and return meta data.

%  Open ascii header file and read information
filename = [tilePathName '.HDR'];
fid = fopen(filename,'r');
if fid==-1
    error(message('map:gtopo30:fileNotFound', filename))
end

nrows = [];
ncols = [];
nodata = [];
ulxmap = [];
ulymap = [];
xdim = [];
ydim = [];

eof = false;
while ~eof
    str = fscanf(fid,'%s',1);
    switch lower(str)
        case 'nrows'
            nrows = fscanf(fid,'%d',1);
        case 'ncols'
            ncols = fscanf(fid,'%d',1);
        case 'nodata'
            nodata = fscanf(fid,'%d',1);
        case 'ulxmap'
            ulxmap = fscanf(fid,'%f',1);
        case 'ulymap'
            ulymap = fscanf(fid,'%f',1);
        case 'xdim'
            xdim = fscanf(fid,'%f',1);
        case 'ydim'
            ydim = fscanf(fid,'%f',1);
        case ''
            eof = true;
        otherwise
            fscanf(fid,'%s',1);
    end
end
fclose(fid);

% Some of the data we wanted wasn't in the HDR file.
% Read the world files to retrieve it.
if any([isempty(ulxmap), isempty(ulymap), isempty(xdim), isempty(ydim)]) 
    try
        [xdim, ydim, ulxmap, ulymap] = readWorldFiles(tilePathName);
    catch e
        if isequal(e.identifier,'map:fileio:expectedSixNumbers')
            error(message('map:gtopo30:incompleteHeader', tilePathName));
        else
            rethrow(e)
        end
    end 
end

% Any information still missing?
if any([isempty(nrows), isempty(ncols), isempty(nodata)]) 
    error(message('map:gtopo30:incompleteHeader', tilePathName));
end

%--------------------------------------------------------------------------

function [xdim, ydim, ulxmap, ulymap] = readWorldFiles(tilePathName)
% Read the world files (BLW and DMW).

filename = [tilePathName '.BLW'];
fid = fopen(filename,'r');
if fid==-1
    filename = [tilePathName '.DMW'];
    fid = fopen(filename,'r');
    if fid==-1
        error(message('map:gtopo30:ancillaryFileNotFound', tilePathName))
    end
end

[W, count] = fscanf(fid,'%f',6);
if count ~= 6 
    fclose(fid);
    error(message('map:fileio:expectedSixNumbers'));
end
fclose(fid);

xdim   =  W(1);
ydim   = -W(4);
ulxmap =  W(5);
ulymap =  W(6);

%--------------------------------------------------------------------------

function [row, col] = findFirstRowCol(refvec1, sizeZ1, refvec2, sizeZ2)
% Find the row and column index that places the [1,1] element of the first
% grid, spatially referenced by refvec1, into the second grid, spatially
% referenced by refvec2.

lat = refvec1(2) - (sizeZ1(1) - 0.5)/refvec1(1);
lon = refvec1(3) + 0.5/refvec1(1);
refmat = map.internal.referencingVectorToMatrix(refvec2, sizeZ2);
[row, col] = latlon2pix(refmat, lat, lon);
row = round(row);
col = round(col);

%--------------------------------------------------------------------------

function [tileNames, tilePathNames] = dirDemFiles(dirname, latlim, lonlim)
% Obtain a list of tileNames that are found in either the directory
% specified by DIRNAME or found in directories DIRNAME/tileNames{k}.
% tilePathNames contains the full path to the tile. The bounding box of
% defined by each tile in tileNames intersects the geographic quadrangle
% defined by latlim and lonlim.

% Obtain the list of all GTOPO30 tile names and their corresponding limits.
[tileNames, lonlimW, lonlimE, latlimS, latlimN] = getTileNamesAndLimits;

% Trim the list of all tile names to match only those that match the
% requested limits.
tileNames = intersectTilesWithGeoQuad( ...
    latlim, lonlim, tileNames, lonlimW, lonlimE, latlimS, latlimN);

% If there is no intersection, throw an error.
if isempty(tileNames)
    error(message('map:gtopo30:noMatchingTiles'));
end

% Add filesep to directory input if needed.
if ~isequal(dirname(end),filesep)
    dirname(end+1) = filesep;
end

ext = '.DEM';
d = dir([dirname '*' ext]);
if ~isempty(d)
    % Found files in current directory.    
    % Create a cell array of all the files found in the directory.
    [filenames{1:numel(d)}] = deal(d(:).name);
    
    % Remove the extension from the list of file names.
    filenames = strrep(filenames, ext, '');
    
    % Create an index of tileNames that do not match names found in the
    % directory.
    fileNotFound = ~ismember(tileNames, filenames);
    
    % Create a function to prepend the directory name to each tileName.
    makeName = @(x)( fullfile(dirname, x));
else
    % DEM files do not exist in current directory. Prepend the root
    % directory and check to see if required files exist.
    fileNotFound = false(1, numel(tileNames));
    for k = 1:numel(tileNames)
        filename = fullfile(dirname, tileNames{k}, [tileNames{k}, ext]);
        if exist(filename, 'file') ~= 2
            fileNotFound(k) = true;
        end
    end
    
    % Create a function to prepend and append the directory name to each
    % tileName.
    makeName = @(x)( fullfile(dirname, x, x));
end

% Remove those tileNames that are not found in the directory.
tileNames(fileNotFound) = [];

% Create the fully-qualified path names.
tilePathNames = cellfun(makeName, tileNames, 'UniformOutput', false);

%--------------------------------------------------------------------------

function [tileNames, lonlimW, lonlimE, latlimS, latlimN] ...
    = getTileNamesAndLimits
% Return a cell array of the names of all the GTOPO30 tiles and their
% corresponding longitude and latitude limits.

[tileNames, latlimS, latlimN, lonlimW, lonlimE] = gtopo30tiles();
tileNames = upper(tileNames);

%--------------------------------------------------------------------------

function tf = longitudesWrap(lonlim)
% Return true if the longitudes specified in lonlim wrap, including the
% case where the limits are identical.

if lonlim(1) < lonlim(2)
    tf = false;
else
    tf = true;
end

%--------------------------------------------------------------------------
function [latlim, lonlim, limitsContainTile, limitsInTile] = ...
    getTileLimits(tileName, latlim, lonlim)

% Obtain the list of all GTOPO30 tile names and their corresponding limits.
[tileNames, lonlimW, lonlimE, latlimS, latlimN] = getTileNamesAndLimits;

% Match the tileName to the list of all GTOPO30 tile names.
index = strcmp(tileName, tileNames);
if any(index)
    tileLatlim = [latlimS(index) latlimN(index)];
    tileLonlim = [lonlimW(index) lonlimE(index)];
else
    error(message('map:gtopo30:noMatchingTile', 'TILENAME', tileName, 'GTOPO30'));
end

% Update latlim and lonlim if empty and compute whether the limits are
% contained within the tile's limits.
if isempty(latlim)
    latlim = tileLatlim;
    latlimInTile = true;
elseif tileLatlim(1) <= latlim(1) && latlim(2) <= tileLatlim(2)
    latlimInTile = true;
else
    latlimInTile = false;   
end

if isempty(lonlim)
    lonlim = tileLonlim;
    lonlimInTile = true;
elseif ~longitudesWrap(lonlim) && ...
        tileLonlim(1) <= lonlim(1) && lonlim(2) <= tileLonlim(2)
    lonlimInTile = true;
else
    lonlimInTile = false;
end
limitsInTile = latlimInTile && lonlimInTile;

% Trim the list of all tile names to match only those that match the
% requested limits.
tileNames = intersectTilesWithGeoQuad( ...
    latlim, lonlim, tileNames, lonlimW, lonlimE, latlimS, latlimN);

% If there is no intersection, throw an error.
if isempty(tileNames)
    error(message('map:gtopo30:noMatchingTiles'));
end

limitsContainTile = any(strcmp(tileName, tileNames));
if ~limitsContainTile
    files = sprintf('%s\n', tileNames{:});
    warning(message('map:gtopo30:noDataInTile', tileName, files));
end

%--------------------------------------------------------------------------

function refvec = calcRefVec(latlim, lonlim, samplefactor)
% Calculate the referencing vector

% 30 arc-seconds expressed in degrees.
cellDensity = cellsPerDegree;

% Maximum size of GTOPO30 data.
nrows = 180*cellDensity; 
ncols = 360*cellDensity; 

dlat = -1/cellDensity;
dlon =  1/cellDensity;

% Use center of pixel
ulLat = latlim(2);
ulLon = lonlim(1);
lonNW = ulLon + dlon/2;
latNW = ulLat + dlat/2;

% Convert lat and lonlim to column and row indices
[rlim, clim] = rowAndColLimits(latlim(:), lonlim(:), latNW, lonNW, dlat, dlon);

% Ensure matrix coordinates are within limits
rlim = [max([1,min(rlim)]) min([max(rlim),nrows])];
rlim = sort(rlim(:))';
clim = [max([1,min(clim)]) min([max(clim),ncols])];

% Construct the referencing vector.
refvec = constructRefvec(rlim, clim, latNW, lonNW, dlat, dlon, samplefactor);

%--------------------------------------------------------------------------

function [nrows, ncols] = calcDataGridSize( ...
    latlim, lonlim, samplefactor, cellDensity)
% Calculate the size of the data grid, given the latitude and longitude
% bounds, sample factor and cell density.

% Calculate the grid size.
startlat = min(latlim);
endlat   = max(latlim);
startlon = lonlim(1);
endlon   = lonlim(2);
if endlon <= startlon
   endlon = endlon + 360;
end

nrows = round((endlat - startlat)*cellDensity/samplefactor);
ncols = round((endlon - startlon)*cellDensity/samplefactor);

%--------------------------------------------------------------------------

function [rlim, clim] = rowAndColLimits( ...
    latlim, lonlim, latNW, lonNW, dlat, dlon)
% Convert world coordinates to intrinsic coordinates.

rlim = round((latlim - latNW)/dlat + [0.5 1.5]');
clim = round((lonlim - lonNW)/dlon + [1.5 0.5]');

%--------------------------------------------------------------------------

function refvec = constructRefvec( ...
    rlim, clim, latNW, lonNW, dlat, dlon, samplefactor)
% Construct the referencing vector. 

% Try to ensure that terms are integer-valued before combining them.
cellDensity = cellsPerDegree;
dlat = cellDensity * dlat;
dlon = cellDensity * dlon;
northernEdge = (cellDensity*latNW + (rlim(1)-1)*dlat - dlat/2) / cellDensity;
westernEdge  = (cellDensity*lonNW + (clim(1)-1)*dlon - dlon/2) / cellDensity;
refvec = [abs(cellDensity/(dlat*samplefactor)) northernEdge westernEdge];

%--------------------------------------------------------------------------

function cellDensity = cellsPerDegree
cellDensity = 120;
