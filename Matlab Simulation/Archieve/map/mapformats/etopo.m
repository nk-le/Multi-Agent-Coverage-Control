function [Z,refvec] = etopo(varargin)
%ETOPO Read gridded global relief data (ETOPO products)
%
%    ETOPO will be removed in a future release. Use READGEORASTER instead.
%    The ETOPO2 and ETOPO5 models read by ETOPO (2- and 5-minute gridded
%    elevation data, respectively) have been superseded by the ETOPO1 model
%    (1-minute gridded elevation data). Read ETOPO1 using READGEORASTER. If
%    necessary, reduce the resolution using GEORESIZE.
%
%  [Z, REFVEC] = ETOPO reads the ETOPO data for the entire world from the
%  ETOPO data in the current directory. The current directory is searched
%  first for ETOPO1c binary data, followed by ETOPO2V2c binary data,
%  followed by ETOPO2 (2001) binary data, followed by ETOPO5 binary data,
%  followed by ETOPO5 ASCII data. Once a case-insensitive filename match is
%  found, from the table of filenames listed below, the data is read. The
%  data grid, Z, is returned as an array of elevations. Data values are in
%  whole meters, representing the elevation of the center of each cell.
%  REFVEC is the associated referencing vector.
%
%  The table below lists the supported ETOPO data filenames:
%
%  Format               Filenames
%  ------               ---------
%  ETOPO1c (cell)       etopo1_ice_c.flt,    etopo1_bed_c.flt,
%                       etopo1_ice_c_f4.flt, etopo1_bed_c_f4.flt,
%                       etopo1_ice_c_i2.bin, etopo1_bed_c_i2.bin                       
%
%  ETOPO2V2c (cell)     ETOPO2V2c_i2_MSB.bin, ETOPO2V2c_i2_LSB.bin, 
%                       ETOPO2V2c_f4_MSB.flt, ETOPO2V2c_f4_LSB.flt
%                       ETOPO2V2c.hdf
%
%  ETOPO2 (2001)        ETOPO2.dos.bin, ETOPO2.raw.bin
%
%  ETOPO5 (binary)      ETOPO5.DOS, ETOPO5.DAT 
%
%  ETOPO5 (ASCII)       etopo5.northern.bat, etopo5.southern.bat
%
%  [Z, REFVEC] = ETOPO(SAMPLEFACTOR) reads the data for the entire world,
%  downsampling the data by SAMPLEFACTOR.  SAMPLEFACTOR is a scalar
%  integer, which when equal to 1 gives the data at its full resolution
%  (2160 by 4320 values for ETOPO5 data, 5400 by 10800 values for ETOPO2
%  data, and 10800 by 21600 values for ETOPO1 data).  When SAMPLEFACTOR is
%  an integer n greater than one, every n-th point is returned. If
%  SAMPLEFACTOR is omitted or empty, it defaults to 1. (If the older ASCII
%  ETOPO5 data set is read, then SAMPLEFACTOR must divide evenly into the
%  number of rows and columns of the data file.)
%
%  [Z, REFVEC] = ETOPO(SAMPLEFACTOR, LATLIM, LONLIM) reads the data for the
%  part of the world within the specified latitude and longitude limits.
%  The limits of the desired data are specified as two element vectors of
%  latitude, LATLIM, and longitude, LONLIM, in degrees. The elements of
%  LATLIM and LONLIM must be in ascending order.  LONLIM must be specified
%  in the range [0 360] for ETOPO5 data and [-180 180] for ETOPO2 and
%  ETOPO1 data. If LATLIM is empty the latitude limits are [-90 90]. If
%  LONLIM is empty, the longitude limits are determined by the file type.
%
%  [Z, REFVEC] = ETOPO(DIRECTORY, ...) allows the path for the ETOPO data
%  file to be specified by DIRECTORY rather than the current directory. 
%
%  [Z, REFVEC] = ETOPO(FILENAME, ...) reads the ETOPO data from FILENAME,
%  where FILENAME is a case-insensitive string scalar or character vector
%  that specifies the name of the ETOPO file, as referenced in the ETOPO
%  data filenames table above. FILENAME may include the directory name;
%  otherwise, the file must be in the current directory or in a directory
%  on the MATLAB path.
%
%  [Z, REFVEC] = ETOPO({'etopo5.northern.bat', 'etopo5.southern.bat'}, ...)
%  reads the ETOPO data from the specified case-insensitive ETOPO5 ASCII
%  data files.  The files must be in the current directory or in a
%  directory on the MATLAB path.
%
%  Example 1
%  ---------
%  % Read and display ETOPO2V2c data from the file 'ETOPO2V2c_i2_LSB.bin'
%  % downsampled to 1/2 degree cell size and display the landareas boundary
%  samplefactor = 15;
%  [Z, refvec] = etopo('ETOPO2V2c_i2_LSB.bin', samplefactor);
%  figure
%  worldmap world
%  geoshow(Z, refvec, 'DisplayType', 'texturemap');
%  demcmap(Z, 256);
%  geoshow('landareas.shp', 'FaceColor', 'none', 'EdgeColor', 'black');
%
%  Example 2
%  ---------
%  % Read and display ETOPO1 data for a region around Australia
%  figure
%  worldmap australia
%  mstruct = gcm;
%  latlim = mstruct.maplatlimit;
%  lonlim = mstruct.maplonlimit;
%  [Z, refvec] = etopo('etopo1_ice_c.flt', 1, latlim, lonlim);
%  geoshow(Z, refvec, 'DisplayType', 'surface');
%  demcmap(Z, 256);
%
%  See also GEORESIZE, READGEORASTER

% Copyright 1996-2021 The MathWorks, Inc.

% Check number of inputs.
narginchk(0, 4);

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

% Parse input arguments.
[filename, samplefactor, latlim, lonlim] = parseInputs(varargin{:});

% Read the data from filename and construct a referencing vector.
[Z, refvec] = etopoRead(filename, samplefactor, latlim, lonlim);

%--------------------------------------------------------------------------

function [filename, samplefactor, latlim, lonlim] = parseInputs(varargin)
% Parse the command line inputs.

% Parse filename.
[filename, params] = parseFilename(varargin);

% Parse samplefactor, latlim, lonlim.
latlim = [-90 90];
lonlim = [0 360];
switch numel(params)
    case 0
        samplefactor = 1;
    case 1
        samplefactor = params{1};
    case 2
        [samplefactor, latlim] = deal(params{1:2});
    case 3
        [samplefactor, latlim, lonlim] = deal(params{1:3});
end

% Validate samplefactor.
if isempty(samplefactor)
    samplefactor = 1;
else
    validateattributes(samplefactor, {'numeric'}, ...
        {'scalar', 'integer', 'finite', 'positive'}, ...
        mfilename, 'SAMPLEFACTOR')
end

% Validate latlim and lonlim.
[latlim, lonlim] = checklatlonlim(latlim, lonlim);

%--------------------------------------------------------------------------

function [filename, params] = parseFilename(params)
% Parse the inputs for FILENAME parameter. FILENAME is returned as a cell
% array.

if numel(params) > 0 && (iscell(params{1}) || ischar(params{1}))
    % [Z,R] = ETOPO(FILENAME)
    % [Z,R] = ETOPO(DIRECTORY)
    % [Z,R] = ETOPO({FILENAMES})
    if iscell(params{1})
        filename = params{1};
    else
        filename = params(1);
    end
    checkfilename(filename);
    params(1) = [];
else
    % [Z,R] = ETOPO()
    % [Z,R] = ETOPO(SAMPLEFACTOR)
    filename = {pwd};
end
    
%--------------------------------------------------------------------------

function checkcell(filename)
% Verify that FILENAME parameter contains correct number of elements and
% class type.

index = cellfun(@ischar, filename);
map.internal.assert(all(index), ...
    'map:validate:expectedNonEmptyStrings', 'FILENAME');

switch numel(filename)
    case 0
        error(message('map:etopo:tooFewFiles'))
        
    case 1
        % Valid number of elements (single filename or directory name)
        
    case 2
        % ETOPO5 ASCII data.
        % Expecting two etopo5*bat files in cell array.
        [~, ~, ext1] = fileparts(filename{1});
        [~, ~, ext2] = fileparts(filename{2});
        if ~isequal(ext1, ext2) || ~isequal(lower(ext1),'.bat')
            error(message('map:etopo:invalidExtensions', '.bat'));
        end
        
    otherwise
        error(message('map:etopo:tooManyFiles'))
end

%--------------------------------------------------------------------------

function checkfilename(filename)
% Validate filename parameter.

% Validate the number of elements and element class type.
checkcell(filename);

% Verify files in cell array, FILENAME, exist.
fcn = @(x)exist(x, 'file');
filesExist = cellfun(fcn, filename);
map.internal.assert(all(filesExist), 'map:fileio:fileNotFound', ...
   filename{find(~filesExist, 1, 'first')});

%--------------------------------------------------------------------------

function [latlim, lonlim] = checklatlonlim(latlim, lonlim) 
% Validate latlim and lonlim inputs.

if isempty(latlim)
    latlim = [-90 90];
end
if isempty(lonlim)
    lonlim = [0 360];
end

validateattributes(latlim, {'double'}, {'real','vector','finite'}, ...
    mfilename, 'LATLIM', 3);

validateattributes(lonlim, {'double'}, {'real','vector','finite'}, ...
    mfilename, 'LONLIM', 4);

map.internal.assert(numel(latlim) == 2, ...
    'map:validate:expectedTwoElementVector', 'LATLIM');

map.internal.assert(numel(lonlim) == 2, ...
    'map:validate:expectedTwoElementVector', 'LONLIM');

map.internal.assert(latlim(1) <= latlim(2), ...
    'map:maplimits:expectedAscendingLatlim');

map.internal.assert(lonlim(1) <= lonlim(2), ...
    'map:maplimits:expectedAscendingLonlim');

map.internal.assert( -90 <= latlim(1) && latlim(2) <= 90, ...
    'map:validate:expectedRange', 'LATLIM', '-90', 'latlim', '90')

map.internal.assert(all(lonlim <= 360), ...
    'map:validate:expectedRange', 'LONLIM',  '0', 'lonlim', '360')

if any(lonlim<0) && (any(lonlim<-180) || any(lonlim>180))
    error(message('map:validate:expectedRange', ...
        'LONLIM', '-180', 'lonlim', '180'))
end

%--------------------------------------------------------------------------

function lonlim = checklonlim(lonlim, format)
% Validate LONLIM input based on the file's format.

if isequal(format.Lonlim, [0, 360])
    if any(lonlim < 0) || any (lonlim > 360)
        error(message('map:validate:expectedRange', ...
            'LONLIM', '0', 'lonlim', '360'))
    end
else
    if isequal(lonlim, [0 360])
        % Change default.
        lonlim = [-180 180];
    elseif any(lonlim<-180) || any(lonlim>180)
        error(message('map:validate:expectedRange', ...
            'LONLIM', '-180', 'lonlim', '180'))
    end
end

%--------------------------------------------------------------------------

function checksamplefactor(samplefactor, format)
% Validate the samplefactor based on file format.

validateattributes(samplefactor, {'numeric'}, ...
    {'<=', format.NumRows, '<=', format.NumCols}, ...
    mfilename, 'SAMPLEFACTOR')

%--------------------------------------------------------------------------

function checkFileSize(filename, format)
% Validate the file size based on the file's format information.

d = dir(filename);
map.internal.assert(isscalar(d), 'map:etopo:expectedScalarStructure', ...
    ['DIR(', filename, ')']);

expNumBytes = getFileSize(format);
actNumBytes = d.bytes;
map.internal.assert(actNumBytes == expNumBytes, 'map:etopo:unexpectedFileSize', ...
    num2str(actNumBytes), format.FormatVersion, filename, num2str(expNumBytes));

%--------------------------------------------------------------------------

function [Z, refvec] = etopoRead(filename, samplefactor, latlim, lonlim)
% Read ETOPO data from FILENAME and return the data grid and referencing 
% vector.

% Build the registry of ETOPO formats.
formats = buildRegistry();

% Determine if the ETOPO file needs to be obtained from a directory
% listing.
if exist(filename{1}, 'dir')
    % Filename{1} is a directory. Obtain the ETOPO file from the directory
    % listing and prepend the directory name to the file.
    filename = getFileFromDir(filename{1}, formats);
else
    % Filename contains the name of a file, but may not be a full filename.
    % Add the directory to the name, if required.
    filename = addDirectory(filename);
end

% Find the ETOPO file format.
format = findFormat(filename, formats);

% Validate the longitude limits, based on the format.
lonlim = checklonlim(lonlim, format);

% Validate the samplefactor based on the format.
checksamplefactor(samplefactor, format);

% Read the image data and construct a referencing vector.
[Z,refvec] = format.ReadFcn(format, filename, samplefactor, latlim, lonlim);

%--------------------------------------------------------------------------

function formats = buildRegistry()
% Build the ETOPO format registry.

% ETOPO Template
% Construct a template structure to define the format of the ETOPO data.
%
% The format information for the ETOPO data files is found in the .hdr
% header file (excluding ETOPO5). A typical header file follows:
%
% NCOLS 10800
% NROWS 5400
% XLLCORNER -180.000000
% YLLCORNER -90.000000
% CELLSIZE 0.03333333333
% NODATA_VALUE 999999
% BYTEORDER LSBFIRST
% NUMBERTYPE 4_BYTE_FLOAT
% MIN_VALUE -10791.0
% MAX_VALUE 8440.0
%
% Note that the referencing information is for the lower left corner, which
% is not the (1,1) corner of the data.

template = struct( ...
    'FormatVersion', '', ...
    'Filename', '', ...
    'ReadFcn', [], ...
    'NumRows', [], ...
    'NumCols', [], ...
    'XLLCorner', [], ...
    'YLLCorner', [], ...
    'FirstCornerLat', [], ...
    'FirstCornerLon', [], ...
    'RowsRunWestToEast', [], ...
    'ColumnsRunSouthToNorth', [], ...
    'Latlim', [], ...
    'Lonlim', [], ...
    'CellSize', [], ...
    'NoDataValue', [], ...
    'ByteOrder', '', ...
    'NumberType', '');

% RowsRunWestToEast is true if the row direction of the raster runs from
% west to east; otherwise the value is false. ColumnsRunSouthToNorth is
% true if the column direction of the raster runs from south to north;
% otherwise the value is false.

% ETOPO5 Format Definition
% Datafiles:
%    'ETOPO5.DOS'
%    'ETOPO5.DAT'
%
% Original version ASCII data files. 
% (Note that these files are now difficult to find on the Internet.)
%    'etopo5.northern.bat'
%    'etopo5.southern.bat'

% Construct a template for the ETOPO5 format.
etopo5Format = template;
etopo5Format.FormatVersion = 'ETOPO5';
etopo5Format.ReadFcn = @etopoBinaryRead;
etopo5Format.NumRows = 2160;
etopo5Format.NumCols = 4320;
etopo5Format.XLLCorner = 0;
etopo5Format.YLLCorner = -90;
etopo5Format.FirstCornerLat = 90;
etopo5Format.FirstCornerLon = 0;
etopo5Format.RowsRunWestToEast = true;
etopo5Format.ColumnsRunSouthToNorth = false;
etopo5Format.Latlim = [-90, 90];
etopo5Format.Lonlim = [0, 360];
etopo5Format.CellSize = 5/60;
etopo5Format.NoDataValue = -32768;
etopo5Format.NumberType = 'int16';

% ETOPO2 Format Definition (v1 - 2001)
% Datafiles:
%    'ETOPO2.dos.bin'
%    'ETOPO2.raw.bin'

% Construct a template for the ETOPO2 format.
etopo2Format = template;
etopo2Format.FormatVersion = 'ETOPO2';
etopo2Format.ReadFcn = @etopoBinaryRead;
etopo2Format.NumRows = 5400;
etopo2Format.NumCols = 10800;
etopo2Format.XLLCorner = -180;
etopo2Format.YLLCorner = -90;
etopo2Format.FirstCornerLat = 90;
etopo2Format.FirstCornerLon = -180;
etopo2Format.RowsRunWestToEast = true;
etopo2Format.ColumnsRunSouthToNorth = false;
etopo2Format.Latlim = [ -90,  90];
etopo2Format.Lonlim = [-180, 180];
etopo2Format.CellSize = 2/60;
etopo2Format.NoDataValue = -32768;

% ETOPO2v2c Format Definition (v2c - 2006, cell-centered)
% Datafiles:
%    'ETOPO2V2c_i2_MSB.bin'
%    'ETOPO2V2c_i2_LSB.bin'
%    'ETOPO2V2c_f4_MSB.flt'
%    'ETOPO2V2c_f4_LSB.flt'

% Construct a template for the ETOPO2v2c format.
etopo2v2cFormat = etopo2Format;
etopo2v2cFormat.FormatVersion = 'ETOPO2v2c';

% ETOPO1 Format Definition (cell-centered)
% Datafiles:
%    'etopo1_ice_c.flt'
%    'etopo1_bed_c.flt'
%    'etopo1_ice_c_f4.flt'
%    'etopo1_bed_c_f4.flt'
%    'etopo1_ice_c_i2.bin'
%    'etopo1_bed_c_i2.bin'                       

% Construct a template for the ETOPO1 format.
etopo1Format = etopo2v2cFormat;
etopo1Format.FormatVersion = 'ETOPO1';
etopo1Format.CellSize = 1/60;
etopo1Format.NumRows = 10800;
etopo1Format.NumCols = 21600;
etopo1Format.ByteOrder = 'ieee-le';
etopo1Format.NumberType = 'single';
etopo1Format.NoDataValue = -9999;

% Create a list of supported ETOPO filenames. The list is ordered by
% best data available.
etopoFilenames = { ...
    'etopo1_ice_c.flt', ...
    'etopo1_bed_c.flt', ...
    'etopo1_ice_c_f4.flt', ...
    'etopo1_bed_c_f4.flt', ...
    'etopo1_ice_c_i2.bin', ...
    'etopo1_bed_c_i2.bin', ...                      
    'ETOPO2V2c.hdf', ...
    'ETOPO2V2c_i2_MSB.bin', ...
    'ETOPO2V2c_i2_LSB.bin', ...
    'ETOPO2V2c_f4_MSB.flt', ...
    'ETOPO2V2c_f4_LSB.flt', ...
    'ETOPO2.dos.bin', ...
    'ETOPO2.raw.bin', ...
    'ETOPO5.DOS', ...
    'ETOPO5.DAT', ...
    'etopo5.northern.bat', ...
    'etopo5.southern.bat', ...
    'new_etopo5.bil'};

% Allocate the formats structure array.
formats(1:numel(etopoFilenames,1)) = template;
k = 0;

% Define the formats array for the specific filename elements.
k = k+1;   % etopo1_ice_c.flt
formats(k) = etopo1Format;
formats(k).Filename = etopoFilenames{k};

k = k+1;   % etopo1_bed_c.flt
formats(k) = etopo1Format;
formats(k).Filename = etopoFilenames{k};

k = k+1;   % etopo1_ice_c_f4.flt
formats(k) = etopo1Format;
formats(k).Filename = etopoFilenames{k};

k = k+1;   % etopo1_bed_c_f4.flt
formats(k) = etopo1Format;
formats(k).Filename = etopoFilenames{k};

k = k+1;   % etopo1_ice_c_i2.bin
formats(k) = etopo1Format;
formats(k).Filename = etopoFilenames{k};
formats(k).NumberType = 'int16';
formats(k).NoDataValue = -32768;

k = k+1;   % etopo1_bed_c_i2.bin  
formats(k) = etopo1Format;
formats(k).Filename = etopoFilenames{k};
formats(k).NumberType = 'int16';
formats(k).NoDataValue = -32768;

k = k+1;   % ETOPO2V2c.hdf
formats(k) = etopo2v2cFormat;
formats(k).ReadFcn = @etopoHDF5Read;
formats(k).Filename = etopoFilenames{k};

k = k+1;   % ETOPO2V2c_i2_MSB.bin
formats(k) = etopo2v2cFormat;
formats(k).Filename = etopoFilenames{k};
formats(k).ByteOrder = 'ieee-be';
formats(k).NumberType = 'int16';
formats(k).NoDataValue = -32768;

k = k+1;   % ETOPO2V2c_i2_LSB.bin
formats(k) = etopo2v2cFormat;
formats(k).Filename = etopoFilenames{k};
formats(k).ByteOrder = 'ieee-le';
formats(k).NumberType = 'int16';
formats(k).NoDataValue = -32768;

k = k+1;   % ETOPO2V2c_f4_MSB.flt
formats(k) = etopo2v2cFormat;
formats(k).Filename = etopoFilenames{k};
formats(k).ByteOrder = 'ieee-be';
formats(k).NumberType = 'single';
formats(k).NoDataValue = 999999;

k = k+1;   % ETOPO2V2c_f4_LSB.flt
formats(k) = etopo2v2cFormat;
formats(k).Filename = etopoFilenames{k};
formats(k).ByteOrder = 'ieee-le';
formats(k).NumberType = 'single';
formats(k).NoDataValue = 999999;

k = k+1;   % etopo2.dos.bin
formats(k) = etopo2Format;
formats(k).Filename = etopoFilenames{k};
formats(k).ByteOrder = 'ieee-le';
formats(k).NumberType = 'int16';

k = k+1; % etopo2.raw.bin
formats(k) = etopo2Format;
formats(k).Filename = etopoFilenames{k};
formats(k).ByteOrder = 'ieee-be';
formats(k).NumberType = 'int16';

k = k+1; % etopo5.dos
formats(k) = etopo5Format;
formats(k).Filename = etopoFilenames{k};
formats(k).ByteOrder = 'ieee-le';

k = k+1; % etopo5.dat
formats(k) = etopo5Format;
formats(k).Filename = etopoFilenames{k};
formats(k).ByteOrder = 'ieee-be';

k = k+1; % etopo5.northern.bat
formats(k) = etopo5Format;
formats(k).Filename = etopoFilenames{k};
formats(k).ReadFcn = @etopo5AsciiRead;
formats(k).NumRows = 1080;
formats(k).NumCols = 4320;
formats(k).ByteOrder = 'native';

k = k+1; % etopo5.southern.bat
formats(k) = etopo5Format;
formats(k).Filename = etopoFilenames{k};
formats(k).ReadFcn = @etopo5AsciiRead;
formats(k).NumRows = 1080;
formats(k).NumCols = 4320;
formats(k).ByteOrder = 'native';

k = k+1; % new_etopo5.bil
formats(k) = etopo5Format;
formats(k).Filename = etopoFilenames{k};
formats(k).ReadFcn = @etopoUnsupportedRead;

%--------------------------------------------------------------------------

function fileSize = getFileSize(format)
% Obtain the expected file size in bytes based on the ETOPO format
% information.

switch format.NumberType
    case 'int16'
        numberOfBytes = 2;
    case 'single'
        numberOfBytes = 4;
end
fileSize = numberOfBytes * format.NumRows * format.NumCols;

%--------------------------------------------------------------------------

function format = findFormat(filename, formats)
% Obtain ETOPO format based on filename input.

% Obtain the list of supported ETOPO file names.
etopoFilenames = getSupportedFilenames(formats);

% Find a match based on the name of the file with the names of the
% supported ETOPO files.
[~, base, ext] = fileparts(filename{1});
etopoFilename = [base ext];
index = strcmpi(etopoFilename, etopoFilenames);
if any(index)
    % A match has been found.
    format = formats(index);
else
    % The filename is not found in the list of supported filenames.
    % Match the case for the expected names.
    etopoFilenames = {formats.Filename};
    % Remove the unsupported entry. 
    etopoFilenames(end) = [];
    % Create a space-separated list.
    etopoList = sprintf('\n  %s', etopoFilenames{:});
    error(message('map:etopo:unsupportedFilename', ...
        'FILENAME', etopoFilename, 'ETOPO', etopoList, 'ETOPO'));
end

%--------------------------------------------------------------------------

function  filename = getFileFromDir(dataDir, formats)
% Obtain the filename by searching the dataDir directory.

% Obtain the directory listing.
list = dir(dataDir);

% Find a supported ETOPO filename from the directory listing.
filename = findFileInList({list(:).name}, formats);

if ~isempty(filename)
    % Add the data directory to the filename.
    filename = {[dataDir filesep filename{1}]};
else
    % Error: no supported filename in directory.
    error(message('map:etopo:noDataFound', dataDir));
end

%--------------------------------------------------------------------------

function filename = addDirectory(filename)
% Prepend the file's directory to FILENAME if FILENAME is not expressed as
% a full filename.

pathstr = fileparts(filename{1});
if isempty(pathstr)
    % The file is on the path (but may not be in the current directory).
    % Use WHICH to determine the full filename.
    filename = {which(filename{1})};
end

%--------------------------------------------------------------------------

function filename = findFileInList(list, formats)
% Find a supported ETOPO filename in the cell array, LIST.

% Obtain a cell array of supported filename.
etopoFilenames = getSupportedFilenames(formats);

% Determine if any supported file is in the list.
% Must match the file order in etopoFilenames.
lc_list = lower(list);
index = ismember(etopoFilenames, lc_list);
if any(index)
    % Found a match. Use only the first match.
    filename = etopoFilenames(index);
    filename = filename(1);
    % Match case of directory listing.
    index = ismember(lc_list, filename);
    filename = list(index);
else
    % A match was not found.
    filename = '';
end

%--------------------------------------------------------------------------

function etopoFilenames = getSupportedFilenames(formats)
% Create a list of supported ETOPO filenames. The list is ordered by
% best data available.

etopoFilenames = lower({formats.Filename});

%--------------------------------------------------------------------------

function [Z, refvec] = etopoUnsupportedRead(~, ~, ~, ~, ~) %#ok<STOUT>

error(message('map:removed:etopo5bil', 'new_etopo5.bil', 'ETOPO5'));

%--------------------------------------------------------------------------

function [Z, refvec] = etopoHDF5Read( ...
    format, filename, samplefactor, latlim, lonlim)
% Read HDF5 ETOPO data from FILENAME and return the data grid and
% referencing vector.

% Make the referencing object.
[R, rows, cols] = makeGeoRasterRef(format, samplefactor, latlim, lonlim);

% Read the ETOPO HDF5 data file.
Z = hdf5DataSetRead(format, filename{1}, samplefactor, rows, cols);

% Construct the referencing vector.
refvec = makerefvec(R);

%--------------------------------------------------------------------------

function Z = hdf5DataSetRead(format, filename, samplefactor, rows, cols)
% Read the ROWS and COLS from the HDF5 dataset found in FILENAME.

% Validate the HDF5 file and obtain the HDF5 dataset.
dataset = getETOPODataset(format, filename);

% Setup the bounding box selection.
startRow = min(rows);
startCol = min(cols);
numRows = numel(rows);
numCols = numel(cols);
rowSampleFactor = samplefactor;
colSampleFactor = samplefactor;

% Read the dataset from the HDF5 file. Transpose the rows and columns since
% the data stored in the HDF5 file is transposed. (Refer to the values in
% dataset.Dims). Flip the rows to go from south to north.
Z = h5varread(filename, dataset, startCol, startRow, numCols, numRows, ...
    colSampleFactor, rowSampleFactor);
Z = flipud(Z');

% Set no data values.
Z = double(Z);
Z(Z == format.NoDataValue) = NaN;

%--------------------------------------------------------------------------

function dataset = getETOPODataset(format, filename)
% Obtain the HDF5 dataset from FILENAME.

fileinfo = hdf5info(filename); %#ok<HDFI>
dataset = fileinfo.GroupHierarchy.Datasets;

% dataset must be scalar.
map.internal.assert(isscalar(dataset), ...
    'map:etopo:expectedScalarDataset', format.FormatVersion, filename);

% Validate the dimensions of the data in the file. The data stored in the
% file is transposed.
map.internal.assert(isequal(dataset.Dims, [format.NumCols format.NumRows]), ...
    'map:etopo:invalidHDF5Dimensions', format.FormatVersion, filename);

%--------------------------------------------------------------------------

function [Z, refvec] = etopoBinaryRead( ...
    format, filename, samplefactor, latlim,lonlim)
% Read binary ETOPO data from FILENAME and return the data grid and
% referencing vector.

% Validate the file size.
checkFileSize(filename{1}, format);

% Make the referencing object.
[R, rows, cols] = makeGeoRasterRef(format, samplefactor, latlim, lonlim);

% Read the ETOPO data file.
Z = singlebandread(format, filename{1}, rows, cols);

% Construct the referencing vector.
refvec = makerefvec(R);

%--------------------------------------------------------------------------

function Z = singlebandread(format, filename, readrows, readcols)
% Read a single band from FILANAME based on the specified FORMAT.

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

function [R, rows, cols] = makeGeoRasterRef( ...
    format, samplefactor, latlim, lonlim)
% Return output referencing object R and row and column index vectors for
% cropping/subsampling a cell-oriented raster.

% Construct input geographic raster referencing object, inputR, based on
% values in the structure, FORMAT, with RasterInterpretation 'cells'.
rasterSize = [format.NumRows, format.NumCols];

if format.ColumnsRunSouthToNorth
    deltaLatNumerator = 1;
else
    deltaLatNumerator = -1;
end

if format.RowsRunWestToEast
    deltaLonNumerator = 1;
else
    deltaLonNumerator = -1;
end

deltaLatDenominator = 1/format.CellSize;
deltaLonDenominator = deltaLatDenominator;

inputR = map.rasterref.GeographicCellsReference( ...
    rasterSize, format.FirstCornerLat, format.FirstCornerLon, ...
    deltaLatNumerator, deltaLatDenominator, ...
    deltaLonNumerator, deltaLonDenominator);

% Specify column and row directions for the output raster.
columnsRunSouthToNorth = false;
rowsRunWestToEast = true;

% Construct output referencing object and row and column index vectors.
[R, rows, cols] = setupCropAndSubsample(inputR, latlim, lonlim, ...
    samplefactor, samplefactor, columnsRunSouthToNorth, rowsRunWestToEast);

%--------------------------------------------------------------------------

function refvec = makerefvec(R)
% Create a referencing vector from a geographic raster reference object, R.

[sampleDensityInLatitude, sampleDensityInLongitude] = sampleDensity(R);

% Expect square pixels:
map.internal.assert(sampleDensityInLatitude == sampleDensityInLongitude, ...
    'map:etopo:expectedCellsWithEqualExtent');

% Create the referencing vector.
refvec = [sampleDensityInLatitude R.LatitudeLimits(2) R.LongitudeLimits(1)];

%--------------------------------------------------------------------------

function data = h5varread(hfile, dataset, startRow, startCol, ...
    numRows, numCols, rowSampleFactor, colSampleFactor)
% H5VARREAD reads data from an HDF5 file
%
%   DATA = H5VARREAD(HFILE, DATASET, STARTROW, STARTCOL, NUMROWS, NUMCOLS,
%   ROWSAMPLEFACTOR, COLSAMPLEFACTOR) reads a strided subset of data from
%   the HDF5 dataset, DATASET, in the file HFILE.  The strided subset will
%   begin at the index [STARTROW, STARTCOL], and have a length extent of
%   NUMROWS along the row dimension and NUMCOLS along the column dimension,
%   with an inter-element distance given by ROWSAMPLEFACTOR in the row
%   dimension and COLSAMPLEFACTOR in the column dimension. The parameters
%   are not validated.

% Just use the defaults for now.
flags = 'H5F_ACC_RDONLY';
plist_id = 'H5P_DEFAULT';
dataset_name = dataset.Name;

% Open the file and the dataset.
file_id     = H5F.open (hfile, flags, plist_id );
dataset_id  = H5D.open(file_id, dataset_name);
datatype_id = H5D.get_type(dataset_id);

% The offset must be zero-based.
offset = [startRow, startCol] - 1;
count  = fliplr([numRows, numCols]);
stride = [rowSampleFactor, colSampleFactor];

% Create the dataspace and filespace ids.
dataspace_id = H5S.create_simple(length(offset), count, count);
filespace_id = create_filespace_id(dataset_id, offset, count, stride);

% The default setting should do for the memory type.
memtype_id = 'H5ML_DEFAULT';

% Read the dataset.
data = H5D.read(dataset_id, memtype_id, dataspace_id, filespace_id, plist_id);

% Remove singleton dimensions.
data = squeeze(data);

% Close the file.
H5T.close(datatype_id);
H5D.close(dataset_id);
H5F.close(file_id);

%--------------------------------------------------------------------------

function filespace = create_filespace_id(dataset_id, offset, count, stride)
% Create the dataspace that corresponds to the given selection.

% Create the appropriate mem dataspace.
% Define the memory hyperslab.
filespace = H5D.get_space(dataset_id);

% Create the hyperslab, validation of the bounding box is presumed by the
% calling function.
H5S.select_hyperslab(filespace, 'H5S_SELECT_SET', ...
    fliplr(offset), fliplr(stride), count, ...
    ones(1,length(offset)));
