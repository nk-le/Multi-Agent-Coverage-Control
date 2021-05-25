function [Z,refvec,UHL,DSI,ACC] = dted(varargin)
%DTED Read U.S. Dept. of Defense Digital Terrain Elevation Data (DTED)
%
%   DTED will be removed in a future release. Use READGEORASTER instead.
%
%   [Z, REFVEC] = DTED returns all of the elevation data in a DTED file as
%   a regular data grid with elevations in meters.  The file is selected
%   interactively.  This function reads the DTED elevation files, which
%   generally have filenames ending in ".dtN", where N is 0,1,2,3,...
%   REFVEC is the associated referencing vector.
%
%   [Z, REFVEC] = DTED(FILENAME) returns all of the elevation data in the
%   specified DTED file.  The file must be found on the MATLAB path. If not
%   found, the file may be selected interactively.
%
%   [Z, REFVEC] = DTED(FILENAME, SAMPLEFACTOR) subsamples data from the 
%   specified DTED file.  SAMPLEFACTOR is a scalar integer.  When
%   SAMPLEFACTOR is 1 (the default), DTED reads the data at its full
%   resolution.  When SAMPLEFACTOR is an integer n greater than one, every
%   n-th point is read.
% 
%   [Z, REFVEC] = DTED(FILENAME, SAMPLEFACTOR, LATLIM, LONLIM) reads the
%   data  for the part of the DTED file within the latitude and longitude
%   limits.  The limits must be two-element vectors in units of degrees. 
%
%   [Z, REFVEC] = DTED(DIRNAME, SAMPLEFACTOR, LATLIM, LONLIM) reads and 
%   concatenates data from multiple files within a DTED CD-ROM or directory 
%   structure.  The dirname input is the name of a directory containing 
%   the DTED directory.  Within the DTED directory are subdirectories 
%   for each degree of longitude, each of which contain files for each 
%   degree of latitude.  For DTED CD-ROMs, dirname is the device name of 
%   the CD-ROM drive.  LATLIM may not span 50 degrees North or South 
%   latitude.
%
%   [Z, REFVEC, UHL, DSI, ACC] = DTED(...) returns structures containing
%   the DTED User Header Label (UHL), Data Set Identification (DSI) and
%   ACCuracy metadata records.
%
%   Data Tiles and Resolution
%   -------------------------
%   DTED files contain digital elevation grids covering 1-by-1-degree
%   quadrangles at horizontal resolutions ranging from about 1 kilometer to
%   30 meters.
%
%   Latitude-Dependent Sampling
%   ---------------------------
%   In DTED files north of 50 degrees North and south of 50 degrees
%   South, where the meridians have converged significantly relative to
%   the equator, the longitude sampling interval is increased to twice
%   the latitude sampling interval, from 30" to 60" in the case of Level
%   0, for example.  In this case, in order to retain square output
%   cells, this function changes the latitude sampling to match the
%   longitude sampling. For example, it will return a 121-by-121
%   elevation grid for a DTED file covering 49 to 50 degrees north, but
%   a 61-by-61 grid for a file covering 50 to 51 degrees north.
%
%   If a directory name is supplied instead of a file name and LATLIM
%   spans either 50 degrees North or 50 degrees South, an error results.
%
%     LATLIM = [20 60];   <-- error    LATLIM = [-55 -45];   <-- error
%     LATLIM = [50 60];   <-- OK       LATLIM = [-55 -50];   <-- OK
%     LATLIM = [20 50];   <-- OK       LATLIM = [-50 -45];   <-- OK
%
%   Going north the longitude sampling interval increases further at the
%   latitudes of 70 degrees N, 75 N, and 80 N.  Likewise, going south,
%   there is a increase at 70 S, 75 S, and 80 S.  LATLIM must not span
%   any of these latitudes either.
%
%   Null Data Values
%   ----------------
%   Some DTED Level 1 and higher data tiles contain null data tiles, coded
%   with value -32767.  When encountered, these null data values are
%   converted to NaN.
%
%   Non-Conforming Data Encoding
%   ----------------------------
%   DTED files from some sources may depart from the specification by using
%   twos-complement encoding for binary elevation files instead of
%   "sign-bit" encoding.  This difference affects the decoding of negative
%   values, and incorrect decoding usually leads to nonsensical elevations.
%   Thus, if the DTED function determines that all the (non-null) negative
%   values in a file would otherwise be less than -12,000 meters, it issues
%   a warning and assumes twos-complement encoding.
%
%   See also DTEDS, READGEORASTER

% Copyright 1996-2021 The MathWorks, Inc.

% error checking for input arguments
narginchk(0,4)

if nargin < 1 
    [Z,refvec,UHL,DSI,ACC] = dtedf; 
    return
end

name = varargin{1};
if exist(name,'dir') == 7
    if nargin < 4
        error(message('map:dted:expectedLimits'))
    end
    [Z,refvec,UHL,DSI,ACC] = dtedc(varargin{:});
else
    [Z,refvec,UHL,DSI,ACC] = dtedf(varargin{:});
end

%--------------------------------------------------------------------------

function [Z,refvec,UHL,DSI,ACC] = dtedc(rd,samplefactor,latlim,lonlim)

% Concatenate adjacent DTED tiles, accounting for the fact that the
% edges of adjacent tiles contain redundant data.

rd = convertStringsToChars(rd);

% add file separator to root directory if necessary
if ~strcmp(rd(end),filesep)
    rd(end+1) = filesep;
end

% If request just touches edge of the next tile, don't read it
tol = 1e-6;
if mod(latlim(2),1) == 0
    latlim(2) = latlim(2) - tol;
end

if mod(lonlim(2),1) == 0
    lonlim(2) = lonlim(2) - tol;
end

% round the limits since DTED is read in 1 deg x 1 deg square tiles
latmin = floor(latlim(1));
latmax = floor(latlim(2));
lonmin = floor(lonlim(1));
lonmax = floor(lonlim(2));

% LATLIM must not span +/- 50 degrees
if (latmin < -50 && latmax > -50) || (latmin < 50 && latmax > 50)
    error(message('map:dted:latlimSpans50'))
end

% LATLIM must be ascending
if latlim(1) > latlim(2)
   error(message('map:dted:latlimReversed'))
end

% define columns and rows for tiles to be read
uniquelons = lonmin:lonmax;
uniquelats = latmin:latmax;
dtedfile = cell(numel(uniquelats), numel(uniquelons));
levels   = cell(numel(uniquelats), numel(uniquelons));

% redefine uniquelons if lonlim extends across the International Dateline
if lonmin > lonmax
    indx1 = lonmin:179;
    indx2 = -180:lonmax;
    uniquelons = [indx1 indx2];
end

[latdir,londir] = dteddirs(uniquelons,uniquelats,'');

% check to see if the files exist
for k = 1:length(uniquelats)
    for j = 1:length(uniquelons)
        for n = 0:3
            filename = [rd londir{j} latdir{k} 'dt' num2str(n)];
            if exist(filename,'file') == 2
                dtedfile{k,j} = filename;
                levels{k,j} = n;
                break
            end
            filename(end) = '*';
            dtedfile{k,j} = filename;
        end
    end
end

% trim off requests for missing files around edges
changed = 1;
while changed
   changed = 0;
   if ~isempty(levels) && isempty([ levels{:,1} ])
      dtedfile(:,1) = [];
      levels(:,1) = [];
      changed = 1;
   end
   if ~isempty(levels) && isempty([ levels{:,end} ])
      dtedfile(:,end) = [];
      levels(:,end) = [];
      changed = 1;
   end
   if ~isempty(levels) && isempty([ levels{1,:} ])
      dtedfile(1,:) = [];
      levels(1,:) = [];
      changed = 1;
   end
   if ~isempty(levels) && isempty([ levels{end,:} ])
      dtedfile(end,:) = [];
      levels(end,:) = [];
      changed = 1;
   end
end

% Stop if missing files
if isempty(dtedfile)
    error(message('map:dted:noData'))
end

% break out if only 1 tile is required
if numel(dtedfile) == 1
    [Z,refvec,UHL,DSI,ACC] = ...
        dtedf(dtedfile{1,1},samplefactor,latlim,lonlim);
   return
end

level = unique([levels{:}]);
if length(level)>1
    error(message('map:dted:inconsistentLevels'))
end

nrowMat = NaN(size(dtedfile));  
ncolMat = nrowMat;
% read all files to compute number of rows and number of columns in each tile
for k = 1:size(dtedfile,1) 
    for j = 1:size(dtedfile,2)
        if exist(dtedfile{k,j}, 'file') == 2
            tmap = dtedf(dtedfile{k,j},samplefactor,latlim,lonlim);  
            nrowMat(k,j) = size(tmap,1);
            ncolMat(k,j) = size(tmap,2);
        end
    end
end

% replace nans with the values required for correct concatenation
nrows = max(nrowMat,[],2);  nrows(isnan(nrows)) = max(nrows);
ncols = max(ncolMat,[],1);  ncols(isnan(ncols)) = max(ncols);

Z = cell(size(dtedfile,1),1);
refvec = cell(size(dtedfile,1),1);

% read the first file (bottom left hand corner of grid)
if exist(dtedfile{1,1}, 'file') == 2
    [Z{1},refvec{1},UHL(1,1),DSI(1,1),ACC(1,1)] = ...
        dtedf(dtedfile{1,1},samplefactor,latlim,lonlim);
else
    % If the first file does not exist, determine what the refvec would
    % be if it did exist.  Also assign metadata structures just to get the
    % structure field names.
    [Z{1},refvec{1},UHL(1,1),DSI(1,1),ACC(1,1)] =...
        readFirstNonEmpty(dtedfile,samplefactor,latlim,lonlim);
    Z{1} = NaN(nrows(1), ncols(1));
end

% Create structures with fields that contain no data. We'll use it if we're
% missing a data file.
UHLempty = UHL(1,1);
fdnames = fieldnames(UHLempty);
for i = 1:length(fdnames)
    UHLempty.(fdnames{i}) = '';
end
DSIempty = DSI(1,1);
fdnames = fieldnames(DSIempty);
for i = 1:length(fdnames)
    DSIempty.(fdnames{i}) = '';
end
ACCempty = ACC(1,1);
fdnames = fieldnames(ACCempty);
for i = 1:length(fdnames)
    ACCempty.(fdnames{i}) = '';
end

if size(dtedfile,1) > 1
    % read remaining files in 1-st column (same longitude, increasing latitudes)
    for k = 2:size(dtedfile,1)
        if exist(dtedfile{k,1}, 'file') == 2
            [Z{k},refvec{k},UHL(k,1),DSI(k,1),ACC(k,1)] ...
                = dtedf(dtedfile{k,1},samplefactor,latlim,lonlim);
        else
            Z{k} = NaN(nrows(k), ncols(1));
            refvec{k} = refvec{k-1} ...
                + [0 (nrows(k)-1) 0]/refvec{k-1}(1);
            UHL(k,1) = UHLempty;
            DSI(k,1) = DSIempty;
            ACC(k,1) = ACCempty;
        end
        % Strip the first row off each tile, because it's
        % already contained in the preceding tile.
        Z{k}(1,:) = [];
    end
    frefvec = refvec{k};
else
    frefvec = refvec{1};
end

fZ = cell(size(dtedfile,2),1);

% concatenate tiles in the first column
fZ{1} = cat(1,Z{:});

% read remaining files for remaining columns and rows
% do one column on each pass through the outer loop.
for j = 2:size(dtedfile,2)
    
    % Clear out each cell so we can re-use the data and refvec arrays
    [Z{:}] = deal([]);
    [refvec{:}] = deal([]);
    
    if exist(dtedfile{1,j}, 'file') ~= 0
        % read file corresponding to the 1-st (bottom) tile in the j-th column
        [Z{1},refvec{1},UHL(1,j),DSI(1,j),ACC(1,j)] ...
            = dtedf(dtedfile{1,j},samplefactor,latlim,lonlim);
    else
        Z{1} = NaN(nrows(1), ncols(j));
        UHL(1,j) = UHLempty;
        DSI(1,j) = DSIempty;
        ACC(1,j) = ACCempty;
    end
    % Strip the first column off each tile, because it's
    % already contained preceding column of tiles.
    Z{1}(:,1) = [];
    % read the remaining files in the j-th column
    for k = 2:size(dtedfile,1)
        if exist(dtedfile{k,j}, 'file') == 2
            [Z{k},refvec{k},UHL(k,j),DSI(k,j),ACC(k,j)] ...
                = dtedf(dtedfile{k,j},samplefactor,latlim,lonlim);
        else
            Z{k} = NaN(nrows(k), ncols(j));
            UHL(k,j) = UHLempty;
            DSI(k,j) = DSIempty;
            ACC(k,j) = ACCempty;
        end
        Z{k}(1,:) = [];  % Strip off the first row
        Z{k}(:,1) = [];  % Strip off the first column
    end
    % concatenate the tiles in the j-th column
    fZ{j} = cat(1,Z{:});
end

% concatenate the columns
Z = cat(2,fZ{:});
refvec = frefvec;

%--------------------------------------------------------------------------

function [Z,refvec,UHL,DSI,ACC] = dtedf(filename,scalefactor,latlim,lonlim)

if nargin==0
   filename = [];
   scalefactor = 1;
   latlim = [];
   lonlim = [];
elseif nargin==1
   scalefactor = 1;
   latlim = [];
   lonlim = [];
elseif nargin==2
   latlim = [];
   lonlim = [];
elseif nargin==3
   lonlim = [];
end

% ensure row vectors

latlim = latlim(:)';
lonlim = wrapTo180(lonlim(:)'); % No effort made (yet) to work across the dateline
if ~isempty(lonlim) && (lonlim(2) < lonlim(1))
    lonlim(2) = lonlim(2) + 360;
end

% check input arguments

filename = convertStringsToChars(filename);
if ~isempty(filename)
    validateattributes(filename, {'char','string'}, {'scalartext'}, mfilename, 'FILENAME', 1);
end

if ~isempty(scalefactor)
    validateattributes(scalefactor, {'numeric'}, {'positive', 'scalar'}, ...
        mfilename, 'SAMPLEFACTOR', 2);
end

if ~isempty(latlim) 
    validateattributes(latlim, {'numeric'}, {'size',[1,2]}, mfilename, 'LATLIM', 3);
end 

if ~isempty(lonlim) 
    validateattributes(lonlim, {'numeric'}, {'size',[1,2]}, mfilename, 'LONLIM', 4);
end 

% Open the file

if ~isempty(filename) 
   fileID = fopen(filename,'rb','ieee-be');
else
    fileID = -1;
end

if fileID == -1
    [filename, path] = uigetfile('*.*', 'Please select the DTED file');
    if filename ~= 0
        filename = [path filename];
        fileID = fopen(filename,'rb','ieee-be');
    end
end

if fileID == -1
    Z = [];
    refvec = [];
    UHL = [];
    DSI = [];
    ACC = [];
    return
else
    clean = onCleanup(@() fclose(fileID));
end


% Read the header records and close the file
[UHL, DSI, ACC] = terrain.internal.dted.readHeaders(fileID);

% Data records information
%
% True longitude = longitude count x data interval + origin (Offset from the SW corner longitude)
% 
% True latitude = latitude count x data interval + origin (Offset from the SW corner latitude)
%
% 1x1 degree tiles, including all edges, edges duplicated across files.

maplatlim = [ ...
    terrain.internal.dted.decodeDMS(DSI.LatitudeofSWcorner), ...
    terrain.internal.dted.decodeDMS(DSI.LatitudeofNWcorner)];

maplonlim = [ ...
    terrain.internal.dted.decodeDMS(DSI.LongitudeofSWcorner), ...
    terrain.internal.dted.decodeDMS(DSI.LongitudeofSEcorner)];

dlat = secstr2deg(DSI.Latitudeinterval);
dlon = secstr2deg(DSI.Longitudeinterval);

ncols = round(diff(maplatlim/dlat)) + 1;
nrows = round(diff(maplonlim/dlon)) + 1;

lato = terrain.internal.dted.decodeDMS(DSI.Latitudeoforigin);
lono = terrain.internal.dted.decodeDMS(DSI.Longitudeoforigin);

skipfactor = 1;
[dlat0,dlon0] = deal(dlat,dlon);
if dlat ~= dlon
   warning(message('map:dted:ignoringLatitudeSpacing'))
   skipfactor = dlon/dlat;
   dlat = max([dlat dlon]);
   dlon = dlat;
end

%  Check to see if latlim and lonlim within map limits

if isempty(latlim)
    latlim = maplatlim;
end

if isempty(lonlim)
    lonlim = maplonlim;
end

if latlim(1) > latlim(2)
   error(message('map:dted:latlimReversed'))
end

if (latlim(1) > maplatlim(2) || ...
    latlim(2) < maplatlim(1) || ...
    lonlim(1) > maplonlim(2) || ...
    lonlim(2) < maplonlim(1) )
    warning(message('map:dted:limitsOutsideDataset', ...
        mat2str( [maplatlim(1), maplatlim(2)], 3 ), ...
        mat2str( [maplonlim(1), maplonlim(2)], 3 )));
    Z = [];
    refvec = [];
    return
end

if latlim(1) < maplatlim(1)
    latlim(1) = maplatlim(1);
end

if latlim(2) > maplatlim(2)
    latlim(2) = maplatlim(2);
end

if lonlim(1) < maplonlim(1)
    lonlim(1) = maplonlim(1);
end

if lonlim(2) > maplonlim(2)
    lonlim(2) = maplonlim(2);
end

% convert lat and lonlim to column and row indices
% DTED used to do this:
%   [clim,rlim] = yx2rc(latlim,lonlim,lato,lono,dlat0,dlon0);
% which was equivalent to:
%   clim = ceil( 1 + (latlim - lato)/dlat0 );
%   rlim = ceil( 1 + (lonlim - lono)/dlon0 );
% But it's clear that we need to "snap down" with floor for the lower
% limits, rather than "snap up" with ceil:

clim = [floor(1.5 + (latlim(1) - lato)/dlat0) ...
         ceil(0.5 + (latlim(2) - lato)/dlat0)];
     
rlim = [floor(1.5 + (lonlim(1) - lono)/dlon0) ...
         ceil(0.5 + (lonlim(2) - lono)/dlon0)];

readrows = rlim(1):scalefactor:rlim(2);
readcols = clim(1):scalefactor*skipfactor:clim(2);

Z = readgrid(fileID, nrows, ncols, readrows, readcols);

% Construct the referencing vector:  Add a half a cell offset to
% account for the difference between elevation profiles, the paradigm in
% the DTED files, and grid cells with values at the middle, which is the
% model for regular data grids. This will lead to the grid extending a
% half a cell outside the nominal data limits.

readlat = (readcols - 1)*dlat0 + lato;
readlon = (readrows -1 )*dlon0 + lono;

refvec = [1/(dlat*scalefactor), ...
    max(readlat) + dlat * (scalefactor - 1/2), ...
    min(readlon) - dlon/2];

%--------------------------------------------------------------------------

function deg = secstr2deg(str)

% Convert text containing a latitude or longitude interval (offset) in
% tenths of seconds to a number in ("decimal") degrees.

deg = str2double(str)/36000;

%--------------------------------------------------------------------------

function [latdir,londir] = dteddirs(uniquelons,uniquelats,ext)

hWestEast = 'wee';
londir{length(uniquelons)} = [];
for i = 1:length(uniquelons)
    londir{i} = sprintf('dted%c%c%03d%c', filesep,...
        hWestEast(2+sign(uniquelons(i))), abs(uniquelons(i)), filesep);
end

hSouthNorth = 'snn';
latdir{length(uniquelats)} = [];
for i = 1:length(uniquelats)
    latdir{i} = sprintf( '%c%02d.%s',...
        hSouthNorth(2+sign(uniquelats(i))), abs(uniquelats(i)), ext);
end

%--------------------------------------------------------------------------

function [Z, refvec, UHL, DSI, ACC] = ...
    readFirstNonEmpty(dtedfile, samplefactor, latlim, lonlim)

% get the origin of the first file
[p,latStr] = fileparts(dtedfile{1,1});
[~,lonStr] = fileparts([p '.*']);
lat0 = str2double(latStr(2:end));
lon0 = str2double(lonStr(2:end));
if strcmp(latStr(1),'s') == 1 || strcmp(latStr(1),'S') == 1
    lat0 = -lat0;
end
if strcmp(lonStr(1),'w') == 1 || strcmp(lonStr(1),'W') == 1
    lon0 = -lon0;
end

% read first non-empty file
nonEmptyFileIndx = [];
for k = 1:numel(dtedfile)
    if exist(dtedfile{k},'file') == 2
        nonEmptyFileIndx = k;
        break;
    end
end
[Z, refvec, UHL, DSI, ACC] = ...
    dtedf(dtedfile{nonEmptyFileIndx(1)},samplefactor);

% latitude and longitude limits
dlat = secstr2deg(DSI.Latitudeinterval);
dlon = secstr2deg(DSI.Longitudeinterval);

% map limits for first file read
maplatlim = [ ...
    terrain.internal.dted.decodeDMS(DSI.LatitudeofSWcorner), ...
    terrain.internal.dted.decodeDMS(DSI.LatitudeofNWcorner)];

% adjust the refvec
topLat   = min([latlim(2) lat0 + diff(maplatlim)]);
leftLon  = max([lonlim(1) lon0]);
refvec(2) = topLat  + dlat * (samplefactor - 1/2);
refvec(3) = leftLon - dlon/2;

%--------------------------------------------------------------------------

function Z = readgrid(fileID, nrows, ncols, readrows, readcols)
% Read the elevation grid, checking to see if there's any padding at the
% end of the file.  Note that the data are read in transposed form, so
% nrows indicates the number of "longitude lines" and ncols indicates the
% number of "latitude points." readrows and readcols specify which rows and
% columns are to be read.  They can be vectors containing the row or column
% numbers, or two-element row vectors of the form [start end], which are
% expanded using the colon operator to start:1:end. To read just two
% noncontiguous rows or columns, provide the indices as a column matrix.

% Find end of file, then return to start
fseek(fileID,0,1);
eof = ftell(fileID);
fseek(fileID,0,-1);

precision = 'int16';
nheadbytes = 3428;
nRowHeadBytes  = 8;
nRowTrailBytes = 4;
dirlisting = dir(fopen(fileID));
expectedFileBytes ...
    = nheadbytes + nrows * (nRowHeadBytes + 2*ncols + nRowTrailBytes);
nFileTrailBytes = max(0, dirlisting.bytes - expectedFileBytes);

% Catch a case with readrows = n, which needs to be [n n];
if isscalar(readrows)
    readrows = [readrows readrows];
end

if isscalar(readcols)
    readcols = [readcols readcols];
end

if (length(readrows) == 2 && isequal(size(readrows), [1 2])) || ...
	(length(readrows) > 2 && max(diff(readrows)) == 1)
    % read every record sequentially
    rowstep = 1; 
else
    rowstep = NaN;
end

if (length(readcols) == 2 && isequal(size(readcols), [1 2]) ) || ...
    (length(readcols) > 2 && max(diff(readcols)) == 1)
    % read every field sequentially
    colstep = 1;
else
    colstep = NaN;
end

% Identify length of a field and record in bytes
fieldlen = 2;
recordlen = nRowHeadBytes + fieldlen*ncols + nRowTrailBytes;

% Sizes of steps between things
if length(readrows) == 2 && isequal(size(readrows), [1 2])
    rowskip = 1;
    nrowread = readrows(end) - readrows(1) + 1;
else
    rowskip = readrows(2) - readrows(1); % correct when used in vectorized read
    nrowread = length(readrows);
end

if length(readcols) == 2 && isequal(size(readcols), [1 2])
    ncolread = readcols(end) - readcols(1) + 1;
else
    ncolread = length(readcols);
end

% Check that the inputs square with the file size if fixed length records
expectedfilesize = nheadbytes + nrows*recordlen + nFileTrailBytes;
if (expectedfilesize ~= eof)
    error(message('map:fileio:inconsistentFileSize', ...
        num2str(expectedfilesize), num2str(eof)))
end

% every value OR runs of data fields, with constant skips in record number
if ((rowstep == 1 && colstep == 1) || ...
        (colstep == 1 && isequal(unique(diff(readrows)), [1 1])))
    % Vectorized read
    
    byteskip = 	nheadbytes + ...                       % skip header
        (readrows(1) - 1)*recordlen + ...              % skip undesired records
        nRowHeadBytes + fieldlen*(readcols(1) - 1);    % skip undesired fields in first desired field
    
    fseek(fileID,byteskip,'bof');   % reposition to just before the first desired record
    
    byteskip = fieldlen*(ncols-readcols(end)) + nRowTrailBytes + ...   % remainder of data in record
        (rowskip-1)*recordlen + ...                    % undesired records
        nRowHeadBytes + fieldlen*(readcols(1)-1);      % skip undesired fields in next desired record
    
    [Z,count] = fread(fileID,nrowread*ncolread,[num2str(ncolread) '*' precision], byteskip);
    if count ~= nrowread*ncolread
        error(message('map:fileio:unexpectedElementCount',  nrowread*ncolread, count));
    end
    
    Z = (reshape(Z, ncolread, length(Z)/ncolread))';
else
    % Unvectorized read
    Z = NaN*ones(nrowread,ncolread);
    for i = 1:nrowread
        offset = nheadbytes + (readrows(i) - 1)*recordlen + nRowHeadBytes;
        fseek(fileID, offset, 'bof');
        [rowdata,count] = fread(fileID,ncols,precision);
        if count ~= ncols
            error(message('map:fileio:unexpectedElementCount',  ncols, count));
        end
        rowdata = rowdata(readcols(:));
        Z(i,:) = rowdata(:)';
    end
end

% Transpose the data.
Z = Z';

% Correct data, if necessary.
Z = terrain.internal.dted.correctZData(Z);

%--------------------------------------------------------------------------
% Local copies ...
%--------------------------------------------------------------------------

function lon = wrapTo180(lon)
% Wrap angle in degrees to [-180 180]

q = (lon < -180) | (180 < lon);
lon(q) = wrapTo360(lon(q) + 180) - 180;

%--------------------------------------------------------------------------

function lon = wrapTo360(lon)
% Wrap angle in degrees to [0 360]

positiveInput = (lon > 0);
lon = mod(lon, 360);
lon((lon == 0) & positiveInput) = 360;
