function [A, headerLength] = usgsdeminfo(fileOrURL)
%USGSDEMINFO Information about USGS DEM file
%
%   [A, headerLength] = USGSDEMINFO(fileOrURL) returns a structure in A
%   whose fields contain the A record information from a USGS DEM file,
%   specified by the file name or URL, fileOrURL. headerLength is a scalar
%   double and is the length of the header in bytes. Refer to the on-line
%   documentation for a description of the fields in A.
%
%   The documentation for the format and the A header record is found in 
%   DATA USERS GUIDES Appendix A  -- Digital Elevation Model Data Elements
%   Logical Record Type A on pages 28 - 35
%   referenced at: http://agdc.usgs.gov/data/usgs/geodata/dem/dugdem.pdf

% Copyright 2012-2014 The MathWorks, Inc.

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

% Create the information structure from the A record in the file.
A = readRecordA(fid);

% Obtain the header length.
headerLength = ftell(fid);

%--------------------------------------------------------------------------

function A = readRecordA(fid)
% Read USGS DEM logical record A.
%
%   Documentation is found in DATA USERS GUIDES
%   Appendix A  -- Digital Elevation Model Data Elements
%   Logical Record Type A on pages 28 - 35
%   referenced at: http://agdc.usgs.gov/data/usgs/geodata/dem/dugdem.pdf

% Start at the beginning of the file.
fseek(fid, 0, 'bof');

% Set header record length (in bytes) based on specification in 
% http://agdc.usgs.gov/data/usgs/geodata/dem/dugdem.pdf
recordLength = 900;

% Read the header and return a character array. Stop at either the end of
% the header or the first newline character.
header = fgets(fid, recordLength);

% In case additional fields are in the header (as in the case of DEM data
% from the Norwegian Geodata Institute from http://data.kartverket.no/),
% read a header length of data again and discard all the data up until the
% beginning of record B, the next element in the file. To determine the
% start position of record B, find the ASCII value 1, indicating the row
% value of the first record, back off by 6 (the ASCII format is I6,
% indicating 6 spaces) which is the start of the next record. Refer to page
% 36 (Appendix B) of http://agdc.usgs.gov/data/usgs/geodata/dem/dugdem.pdf:
%   Data Element 1 
%      Starting byte 1, ending byte 12 
%      A two-element array INTEGER*2 (2I6) 
%      "The row/column numbers may range from 1 to m and 1 to n. The row
%      number is normally set to 1. The column identification is the
%      profile sequence number."
pos = ftell(fid);
nextRecord = fgets(fid, recordLength);
fseek(fid, pos, 'bof');
index = strfind(nextRecord, '1');
if ~isempty(index)
    lengthOfElement = 6;
    start = index(1) - lengthOfElement;
    fseek(fid, start, 'cof');
end
    
% Construct an output structure.
A = struct();

% Retrieve all the values from the header string.
A.QuadrangleName = getHeaderValue(header, 1, 40);
A.FreeFormText = getHeaderValue(header, 41, 80);
A.Filler = getHeaderValue(header, 81, 135);

A.ProcessCode = getHeaderValue(header, 136, 136);
switch (A.ProcessCode)
    case '1'
        value = 'GPM';
    case '2'
        value = 'Manual Profile';
    case '3'
        value = 'DLG2DEM';
    case '4'
        value = 'DCASS';
    otherwise
        value = '';
end
A.Process = value;

A.Filler2 = getHeaderValue(header, 137, 137);
A.SectionalIndicator = getHeaderValue(header, 138, 140);
A.MC_OriginCode = getHeaderValue(header, 141, 144);
A.DEM_LevelCode = str2double(getHeaderValue(header, 145, 150));

A.ElevationPatternCode = str2double(getHeaderValue(header, 151, 156));
if A.ElevationPatternCode == 1
    A.ElevationPattern = 'regular';
else
    A.ElevationPattern = 'random';
end

A.PlanimetricReferenceSystemCode = ...
    str2double(getHeaderValue(header, 157, 162));
switch (A.PlanimetricReferenceSystemCode)
    case 0
        value = 'Geographic';
    case 1
        value = 'UTM';
    case 2
        value = 'State Plane';
    otherwise
        value = 'unknown';
end
A.PlanimetricReferenceSystem = value;

A.Zone = str2double(getHeaderValue(header, 163, 168));
A.MapProjectionParameters = getHeaderFloatValue(header, 169, 528);

A.HorizontalUnitOfMeasureCode = str2double(getHeaderValue(header, 529, 534));
switch (A.HorizontalUnitOfMeasureCode)
    case 0
        value = 'radians';
    case 1
        value = 'feet';
    case 2
        value = 'meters';
    case 3
        value = 'arc-seconds';
    otherwise
        value = 'unknown';
end
A.HorizontalUnitOfMeasure = value;

A.VerticalUnitOfMeasureCode = str2double(getHeaderValue(header, 535, 540));
switch (A.VerticalUnitOfMeasureCode)
    case 1
        value = 'feet';
    case 2
        value = 'meters';
    otherwise
        value = 'unknown';
end
A.VerticalUnitOfMeasure = value;

A.NumberOfBoundingBoxSides = str2double(getHeaderValue(header, 541, 546));
A.BoundingBox = getHeaderFloatValue(header, 547, 738);
A.ElevationLimits = getHeaderFloatValue(header, 739, 786);
A.RotationAngle = getHeaderFloatValue(header, 787, 810);

A.AccuracyCode = str2double(getHeaderValue(header, 811, 816));
if A.AccuracyCode == 1
    A.AccuracyInformation = 'accuracy information in record C';
else
    A.AccuracyInformation = 'unknown accuracy';
end

value = getHeaderValue(header, 817, 852);
value = strrep(value, 'D', 'e');
value = strrep(value, 'E', 'e');
value = sscanf(value, '%12e')';
A.XYZ_SpatialResolution = value;

A.NumberOfRowsAndColumns = getHeaderFloatValue(header, 853, 864);

% Old format stops here

A.PrimaryContourInterval = str2double(getHeaderValue(header, 865, 869));
A.SourceMaxContourIntervalUnitsCode = str2double(getHeaderValue(header,  870, 870));
switch A.SourceMaxContourIntervalUnitsCode
    case 1
         value = 'feet';
    case 2
        value = 'meters';
    otherwise
        value = 'unknown';
end
A.SourceMaxContourIntervalUnits = value;

A.SmallestPrimaryContourInterval = str2double(getHeaderValue(header, 871, 875));

A.SourceMinContourIntervalUnitsCode = str2double(getHeaderValue(header, 876, 876));
switch A.SourceMinContourIntervalUnitsCode
    case 1
        value = 'feet';
    case 2
        value = 'meters';
    otherwise
        value = 'unknown';
end
A.SourceMinContourIntervalUnits = value;

A.DataSourceDate = str2double(getHeaderValue(header, 877, 880));
A.DataInspectionRevisionDate = str2double(getHeaderValue(header, 881, 884));
A.InspectionRevisionFlag = getHeaderValue(header, 885, 855);

A.DataValidationFlag = str2double(getHeaderValue(header, 886, 886));
switch A.DataValidationFlag
    case 0
        value = 'No validation performed';
    case 1
        value = 'TESDEM (record C added) no qualitative test (no DEM Edit System [DES] review)';
    case 2
        value = 'Water body edit and TESDEM run';
    case 3
        value = 'DES (includes water edit) no qualitative test (no TESDEM)';
    case 4
        value = 'DES with record C added, qualitative and quantitative tests for level 1 DEM';
    case 5
        value = 'DES and TESTDEM qualitative and quantitative tests for levels 2 and 3 DEMs';
    otherwise
        value = 'unknown';
end
A.DataValidation = value;

A.SuspectVoidFlag = str2double(getHeaderValue(header, 887, 888));
switch A.SuspectVoidFlag
    case 0
        value = 'none';
    case 1
        value = 'suspect areas';
    case 2
        value = 'void areas';
    case 3
        value = 'suspect and void areas';
    otherwise
        value = 'unknown';
end
A.SuspectVoid = value;

A.VerticalDatumCode = str2double(getHeaderValue(header, 889, 890));
switch A.VerticalDatumCode
    case 1
        value = 'local means sea level';
    case 2
        value = 'National Geodetic Vertical Datum 1929 (NGVD 29)';
    case 3
        value = 'North American Vertical Datum 1988 (NAVD 88)';
    otherwise
        value = 'unknown';
end
A.VerticalDatumName = value;

A.HorizontalDatumCode = str2double(getHeaderValue(header, 891, 892));
lengthUnit = A.HorizontalUnitOfMeasure;
if ~any(strcmp(lengthUnit, {'feet', 'meters'}))
    lengthUnit = 'meter';
end
switch A.HorizontalDatumCode
    case 1
        value = 'North American Datum 1927 (NAD27)';
        A.ReferenceEllipsoid = referenceEllipsoid('clarke66', lengthUnit);
    case 2
        value = 'World Geodetic System 1972 (WGS72)';
        A.ReferenceEllipsoid = referenceEllipsoid('wgs72', lengthUnit);
    case 3
        value = 'WGS84';
        A.ReferenceEllipsoid = referenceEllipsoid('wgs84', lengthUnit);
    case 4 
        value = 'NAD83';
        A.ReferenceEllipsoid = referenceEllipsoid('grs80', lengthUnit);
    case 5 
        value = 'Old Hawaii Datum';
        A.ReferenceEllipsoid = referenceEllipsoid('clarke66', lengthUnit);
    case 6
        value = 'Puerto Rico Datum';
        A.ReferenceEllipsoid = referenceEllipsoid('clarke66', lengthUnit);
    case 7
        value = 'NAD 83 Provisional';
        A.ReferenceEllipsoid = referenceEllipsoid('grs80', lengthUnit);
    otherwise
        value = 'unknown';
        A.ReferenceEllipsoid = referenceEllipsoid('clarke66', lengthUnit);
end
A.HorizontalDatumName = value;

A.DataEdition = str2double(getHeaderValue(header, 893, 896));
A.PercentVoid = str2double(getHeaderValue(header, 897, 900));

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
% Return a row vector of doubles from the string, header, beginning at
% startIndex and ending at endIndex.

value = getHeaderValue(header, startIndex, endIndex);
value = strrep(value, 'D', 'e');
if isempty(value)
    value = [];
else
    value = textscan(value, '%f');
    value = [value{:}]';
end
