function B = usgsdemprofile(fileOrURL, A, headerLength, skipHeader)
%USGSDEMPROFILE Read USGS DEM profiles from file
%
%   B = USGSDEMPROFILE(fileOrURL, A, headerLength, skipHeader) returns a
%   structure array in B whose fields contain the profile information from
%   the B records of a USGS DEM file.
%
%   Input Arguments
%   ---------------
%   fileOrURL        String indicating name of DEM file or URL
%
%   A                Scalar structure obtained from USGSDEMINFO containing
%                    the A records of the file.
%
%   headerLength     Scalar double indicating number of bytes in header
%
%   skipHeader       Scalar logical which if true skips the parsing of
%                    certain header fields (used for optimization).
%
%   Output Argument
%   ---------------
%   B                Structure array containing the B record

% Copyright 2012 The MathWorks, Inc.

% Determine number of profile records to read.
% The number of profile records is the same as the number of columns,
% defined in the A record.
if isempty(A.NumberOfRowsAndColumns)
    % The number of rows and columns aren't provided, issue an error.
    error(message('map:usgsdem:unableToReadProfile', fileOrURL));
else
	numberOfProfiles = A.NumberOfRowsAndColumns(2);
end

if ~exist('skipHeader', 'var')
    skipHeader = false;
end

% Validate the input. If it's a filename, return the full pathname. If it's
% a URL, download the URL to a temporary file and set isURL to true.
[filename, isURL] = internal.map.checkfilename( ...
    fileOrURL, {'dem'}, mfilename, 1, true);

if (isURL)
    % Be sure to delete the temporary file from the Internet download.
    clean = onCleanup(@() deleteDownload(filename));
end

% Open the file.
fid = fopen(filename,'r');
cleanFile = onCleanup(@() fclose(fid));

% Skip past the file header.
fseek(fid, headerLength, 'bof');

% Read all the B profiles.
B = readBProfiles(fid, numberOfProfiles, skipHeader);

%--------------------------------------------------------------------------

function B = readBProfiles(fid, numberOfProfiles, skipHeader)
% Read all the B profiles from the file and return a structure array.

% Construct an output structure for the data.
B(numberOfProfiles) = createBStructure;

% Assign a void value.
% Some files use -32767 (-intmax('int16')) as a void (null data) value.
voidValue = -intmax('int16');

% Read all the profiles in the B record.
for k = 1:numberOfProfiles    
    % Read the kth B profile.
    B(k) = readRecordB(fid, voidValue, skipHeader);
end

%--------------------------------------------------------------------------

function B = readRecordB(fid, voidValue, skipHeader)
% Read USGS DEM logical record B.
%
%   Documentation is found in DATA USERS GUIDES
%   Appendix AB -- Digital Elevation Model Data Elements
%   Logical Record Type B on pages 36-37
%   referenced at: http://agdc.usgs.gov/data/usgs/geodata/dem/dugdem.pdf

% Set profile header length (in bytes) based on specification.
headerLength = 144;

% Find the first value in the profile by reading the file until the first
% non-space character is found. Since the first value in the profile is an
% Integer*2 and takes 6 spaces, set the position of the reader to 6 spaces
% from the first non-space character.
index = [];
while isempty(index)
    pos = ftell(fid);
    line = fread(fid, headerLength, 'uint8=>char')';
    index = find(~isspace(line), 1);
end
start = index - 6;
fseek(fid, pos + start, 'bof');

% The file identifier is positioned at the start of the header. 
% Read the header and return a string.
line = fread(fid, headerLength, 'uint8=>char')';

% Create a B structure to contain the profile header and profile
% data.
B = createBStructure;

% Parse the header line and obtain the header information.
% Transpose RowColumn, NumberOfElevations, and LocalDatumElevation in order
% to create column vectors for consistency with the expected shape for the
% interface.
B.NumberOfElevations = getHeaderFloatValue(line, 13, 24)';
if ~skipHeader
    % skipHeader is false. Add all header values.
    B.RowColumn = getHeaderFloatValue(line, 1, 12)';
    B.GroundPlanimetricCoordinates = getHeaderFloatValue(line, 25, 72);
    B.LocalDatumElevation = getHeaderFloatValue(line, 73, 96)';
    B.ElevationLimits = getHeaderFloatValue(line, 97, 144)';
end

% elevationCount is the number of elevation values in the profile.
elevationCount = B.NumberOfElevations(1);

% Save the position of the reader.
pos = ftell(fid);

% Each elevation value is 6 bytes.
byteCount = 6;

% Read the file to obtain all the elevation values and return the results
% in a string. Each elevation value is byteCount in length and there is
% elevationCount values in the profile.
line = fread(fid, byteCount*elevationCount, 'uint8=>char')';

% Convert the string to double.
elevations = getHeaderFloatValue(line, 1, length(line));

% Determine if all the elevation values have been read.  The specification
% states that the first block of values should be 6x146 bytes and
% subsequent blocks are 6x170 bytes. However, some files do not conform to
% the specification and may have either extra spaces or line terminations
% within the elevation profile.
if length(elevations) < elevationCount
    % Determine how many values are missing.
    offset = elevationCount - length(elevations) + 1;
    if ~isspace(line(end))
        % If the last character in the string is not a space, we cannot
        % tell if the line contained all the values. Return to the
        % beginning of the elevation profile.
        fseek(fid, pos, 'bof');
        
        % Compute a new count, based on the old count plus the offset. This
        % ensures that all the values will be read.
        newCount = elevationCount + offset;
        
        % Read the file with the new count.
        line = fread(fid, byteCount*newCount, 'uint8=>char')';
        
        % Convert the string line to a double vector.
        elevations = getHeaderFloatValue(line, 1, length(line));
    else
        % The last character is a space. Read the missing values from this 
        % position. There is no need to move back to the beginning of the
        % profile.
        newCount = offset;
        line = fread(fid, byteCount*newCount, 'uint8=>char')';
        
        % Convert the new values to double and append them to the values
        % from the first read.
        e = getHeaderFloatValue(line, 1, length(line));
        elevations = [elevations e];
    end 
end

% Replace the elevation void (null data) values with NaN, since all
% elevation values are computed from the profile.
elevations(elevations == voidValue) = NaN;

% Set B.Profile to the elevation values and ensure that only elevationCount
% values are returned.
maxCount = min([elevationCount, length(elevations)]);
B.Profile = elevations(1:maxCount)';

%--------------------------------------------------------------------------

function B = createBStructure
% Create and initialize the B structure.

B = struct( ...
    'RowColumn', [], ...
    'NumberOfElevations', [], ...
    'GroundPlanimetricCoordinates', [], ...
    'LocalDatumElevation', [], ...
    'ElevationLimits', [], ...
    'Profile', []);

%--------------------------------------------------------------------------

function value = getHeaderValue(header, startIndex, endIndex)
% Return string values from the string, header, beginning at startIndex and
% ending at endIndex. Return '' if header contains only spaces or if the
% length of header is greater than startIndex.

if length(header) >= startIndex
    endIndex = min([length(header), endIndex]);
    value = header(startIndex:endIndex);
    if all(isspace(value))
        value = '';
    end
else
    value = '';
end

%--------------------------------------------------------------------------

function value = getHeaderFloatValue(header, startIndex, endIndex)
% Return a column vector of doubles from the string, header, beginning at
% startIndex and ending at endIndex.

value = getHeaderValue(header, startIndex, endIndex);
value = strrep(value, 'D', 'e');
value = textscan(value, '%f');
value = [value{:}]';