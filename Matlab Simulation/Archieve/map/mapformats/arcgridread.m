function [Z,R] = arcgridread(filename, coordinateSystemType)
%ARCGRIDREAD Read gridded data set in ArcGrid ASCII or GridFloat format
%
%       ARCGRIDREAD is not recommended. Use READGEORASTER instead.
%
%   [Z, R] = ARCGRIDREAD(FILENAME) imports a grid from one of the ArcGIS
%   formats described below. Z is a 2D array containing the data values. If
%   the input file is accompanied by a projection file (with extension .prj
%   or .PRJ), then R is a raster reference object whose type matches the
%   coordinate reference system defined in the projection file. Otherwise R
%   is a referencing matrix. NaN is assigned to elements of Z corresponding
%   to null data values in the grid file.
%
%   [Z, R] = ARCGRIDREAD(FILENAME, coordinateSystemType) returns R as a
%   raster reference object whose type is consistent with the value
%   specified by coordinateSystemType. The value 'geographic' results in a
%   geographic cells reference object appropriate to a latitude-longitude
%   system. The value 'planar' results in a map cells reference object
%   appropriate to a projected map coordinate system. This optional input
%   is helpful in the absence of a projection file. (The function throws an
%   error if a projection file is present and coordinateSystemType
%   contradicts the type of coordinate reference system defined in the
%   projection file.)
%
%   Example
%   -------
%   % Load and view Mount Washington terrain elevation
%   [Z,R] = arcgridread('MtWashington-ft.grd');
%   mapshow(Z,R,'DisplayType','surface')
%   xlabel('x (easting in meters)')
%   ylabel('y (northing in meters)')
%   demcmap(Z)
%
%   % View the terrain in 3D
%   axis normal
%   view(3)
%   axis equal
%   grid on
%   zlabel('elevation in feet')
%
%   Format Support
%   --------------
%   * ArcGrid ASCII
%       Also known as Arc ASCII Grid and ESRI ASCII raster format.
%       Created by the ArcGIS GRIDASCII command.
%       Data and header are in a single text file.
%       If a .prj file is present, it will be read also.
%       Grid values are read into MATLAB as a 2D array of class double.
%
%   * GridFloat
%       Also known as ESRI GridFloat.
%       Created by the ArcGIS GRIDFLOAT command.
%       Data and header are in separate (.flt and .hdr) files.
%       Pass the name of the .flt file (including extension) to ARCGRIDREAD.
%       If an optional .prj file is present, it will be read also.
%       Grid values are read into MATLAB as a 2D array of class single.
%
%   This function does not import data in the ArcGrid Binary format (also
%   known as ArcGrid, Arc/INFO Grid, and ESRI ArcInfo Grid) that is used
%   internally by ArcGIS and characterized by multiple files in a
%   directory with standard names such as hdr.adf and w001001.adf.
%
%   See also READGEORASTER

% Copyright 1996-2019 The MathWorks, Inc.

% Validate or initialize the coordinate system type.
if nargin > 0
    filename = convertStringsToChars(filename);
end
if nargin > 1
    coordinateSystemType = validatestring( ...
        coordinateSystemType, {'auto', 'geographic', 'planar'}, ...
        'ARCGRIDREAD', 'coordinateSystemType', 2);
else
    coordinateSystemType = 'auto';
end

% Verify the filename and check if it is a URL.
allowURL = true;
[fileToRead, isURL] = internal.map.checkfilename(filename, mfilename, [], allowURL);

% Open the file.
fileID = fopen(fileToRead,'r');
if fileID == -1
    error(message('map:fileio:unableToOpenFile', filename));
end

% Open the header in the case of GridFloat, which uses a separate ASCII
% header file. Otherwise the header is the first part of the data file.
headerFileID = openHeaderFile(filename, fileID, isURL);
gridFloatInput = (headerFileID ~= fileID);

% Try to import the data.
try
    hdr = readHeader(headerFileID);
    
    coordinateSystemType = resolveInputAndProjectionFile( ...
        coordinateSystemType, filename, isURL);
    
    [R, rasterSize] = arcGridHeaderToCellsReference(hdr, coordinateSystemType);
    
    if gridFloatInput
        ieeeByteOrder = decodeByteOrder(hdr.byteorder);
        Z = fread(fileID, fliplr(rasterSize), '*float32', ieeeByteOrder);
    else
        % ASCII format: Read the k-th row from the data file into the k-th
        % column of matrix Z.
        Z = fscanf(fileID, '%g', fliplr(rasterSize));
    end
catch e
    closeAll(fileID, headerFileID, isURL)
    throw(e)  
end

% Close the file(s).
closeAll(fileID, headerFileID, isURL)

% Replace each no-data value with NaN.
Z(Z == str2double(hdr.nodata_value)) = NaN;

% Transpose to column-major order.
Z = Z';

%--------------------------------------------------------------------------

function headerFileID = openHeaderFile(filename, fileID, isURL)

[pathstr,name,ext] = fileparts(filename);

if strcmp(ext,'.flt')
    headerExt = '.hdr';
elseif strcmp(ext,'.FLT')
    headerExt = '.HDR';
else
    headerExt = '';
end

if isempty(headerExt)
    headerFileID = fileID;
else
    if isURL
        headerFileName = [pathstr, '/', name, headerExt];
        allowURL = true;
    else
        headerFileName = fullfile(pathstr, [name headerExt]);
        allowURL = false;
    end
    headerToRead = internal.map.checkfilename(headerFileName, mfilename, [], allowURL);
    headerFileID = fopen(headerToRead,'r');
    if headerFileID == -1
        closeFile(fileID, isURL)
        error(message('map:fileio:unableToOpenFile', headerFileName));
    end
end

%--------------------------------------------------------------------------

function hdr = readHeader(fileID)
% Read the header line-by-line.

valid_tags = {'ncols','nrows','xllcorner','xllcenter', ...
    'yllcorner','yllcenter','cellsize','nodata_value'};

% Read the first 6 tag-value pairs.
[t, position] = textscan(fileID,'%s',12);
data = reshape(t{1},2,6);
for k = 1:6
    tag = lower(data{1,k});
    value = data{2,k};
    
    % Check for an expected header tag.
    if ~any(strcmpi(tag,valid_tags))
        error(message('map:arcgridread:unexpectedItemInHeader', tag, k));
    end
    
    hdr.(tag) = value;
end

% Try to read a 7th tag-value pair, with a byteorder value.
t = textscan(fileID,'%s',2);
data = t{1};

if length(data) == 2
    tag = data{1};
    value = data{2};
else
    tag = '';
    value = '';
end

if strcmpi(tag, 'byteorder')
    hdr.byteorder = upper(strtrim(value));
else
    % It's not a GridFloat file and we've read the first line of data.
    % Back up so we can re-read that along with the rest of the data.
    fseek(fileID, position, 'bof');
end

%--------------------------------------------------------------------------

function coordinateSystemType = resolveInputAndProjectionFile( ...
    coordinateSystemTypeInput, filename, isURL)

coordinateSystemTypeFromPRJ = coordinateSystemTypeFromProjectionFile(filename, isURL);

if strcmp(coordinateSystemTypeInput, 'auto')
    coordinateSystemType = coordinateSystemTypeFromPRJ;
else
    consistentTypes = strcmp(coordinateSystemTypeFromPRJ, 'unspecified') ...
          || strcmp(coordinateSystemTypeInput, coordinateSystemTypeFromPRJ);
    if consistentTypes
        coordinateSystemType = coordinateSystemTypeInput;
    else
        error(message('map:arcgridread:inconsistentCRS',coordinateSystemTypeInput))
    end
end

%--------------------------------------------------------------------------

function coordinateSystemType = coordinateSystemTypeFromProjectionFile(filename, isURL)

% Determine the name of the PRJ file, if it exists.
[pathstr, name, ext] = fileparts(filename);
if isequal(lower(ext),ext)
    prjExtension = '.prj';
else
    prjExtension = '.PRJ';
end

if isURL
    prjfilename = [pathstr, '/', name, prjExtension];
else
    prjfilename = fullfile(pathstr, [name prjExtension]);
end

% Try to open the PRJ file.  If it's not there, that's OK.
try
    allowURL = isURL;
    [fileToRead, isURL] = internal.map.checkfilename(prjfilename, mfilename, [], allowURL);
    fileID = fopen(fileToRead,'r');
catch e
    if ~any(strcmp(e.identifier, {'map:checkfilename:invalidFilename','map:checkfilename:invalidURL'}))
        rethrow(e)
    else
        fileID = -1;
    end
end

% If the PRJ file was opened, determine coordinateSystemType from its first
% line.  Otherwise set coordinateSystemType to 'unspecified'.
if fileID ~= -1
    try
        coordinateSystemType = coordinateSystemTypeFromLine1(fileID);
    catch e
        closeFile(fileID, isURL)
        throw(e)  
    end
    closeFile(fileID, isURL)
else
    coordinateSystemType = 'unspecified';
end

%--------------------------------------------------------------------------

function coordinateSystemType = coordinateSystemTypeFromLine1(fileID)
% Use line 1 in the PRJ file to determine the coordinate system type.
% Return 'geographic' if we find something like this (ignoring case):
% 'Projection GEOGRAPHIC'.  If the tag 'Projection' is present with any
% other value, return 'planar'.  If the 'Projection' tag is missing, return
% 'unspecified'.

line1 = fgetl(fileID);
[tag, value] = strtok(line1);
if strcmpi(tag,'Projection')
    value = strtrim(deblank(value));
    if strcmpi(value, 'GEOGRAPHIC')
        coordinateSystemType = 'geographic';
    else
        coordinateSystemType = 'planar';
    end
else
    coordinateSystemType = 'unspecified';
end

%--------------------------------------------------------------------------

function ieeeByteOrder = decodeByteOrder(byteOrder)

switch byteOrder
    case 'LSBFIRST'
        ieeeByteOrder = 'ieee-le';
    case 'MSBFIRST'
        ieeeByteOrder = 'ieee-be';
    otherwise
        error(message('map:arcgridread:invalidByteOrder',byteOrder))
end

%--------------------------------------------------------------------------

function closeAll(fileID, headerFileID, isURL)

closeFile(fileID, isURL)
if headerFileID ~= fileID
    closeFile(headerFileID, isURL)
end

%--------------------------------------------------------------------------

function closeFile(fileID, isURL)

% Obtain the filename from the file ID.
filename = fopen(fileID);

% Close the file.
fclose(fileID);

% If the file was downloaded from a URL, then delete the temporary file.
if (isURL)
    deleteDownload(filename);
end
