function info = dbfinfo(fid)
%DBFINFO Read header information from DBF file.
%   FID File identifier for an open DBF file.
%   INFO is a structure with the following fields:
%      Filename       Char array containing the name of the file that was read
%      DBFVersion     Number specifying the file format version
%      FileModDate    A string containing the modification date of the file
%      NumRecords     A number specifying the number of records in the table
%      NumFields      A number specifying the number of fields in the table
%      FieldInfo      A 1-by-numFields structure array with fields:
%         Name        A string containing the field name 
%         Type        A string containing the field type 
%         ConvFunc    A function handle to convert from DBF to MATLAB type
%         Length      A number of bytes in the field
%      HeaderLength   A number specifying length of the file header in bytes
%      RecordLength   A number specifying length of each record in bytes

% Copyright 1996-2009 The MathWorks, Inc.

[version, date, numRecords, headerLength, recordLength] = readFileInfo(fid);
fieldInfo = getFieldInfo(fid);

info.Filename     = fopen(fid);
info.DBFVersion   = version;
info.FileModDate  = date;
info.NumRecords   = numRecords;
info.NumFields    = length(fieldInfo);
info.FieldInfo    = fieldInfo;
info.HeaderLength = headerLength;
info.RecordLength = recordLength;

%--------------------------------------------------------------------------
function [version, date, numRecords, headerLength, recordLength] = readFileInfo(fid)
% Read from File Header.

fseek(fid,0,'bof');

version = fread(fid,1,'uint8');

year  = fread(fid,1,'uint8') + 1900;
month = fread(fid,1,'uint8');
day   = fread(fid,1,'uint8');

dateVector = datevec(sprintf('%d/%d/%d',month,day,year));
dateForm = 1;% dd-mmm-yyyy
date = datestr(dateVector,dateForm);

numRecords   = fread(fid,1,'uint32');
headerLength = fread(fid,1,'uint16');
recordLength = fread(fid,1,'uint16');

%--------------------------------------------------------------------------
function fieldInfo = getFieldInfo(fid)
% Form FieldInfo by reading Field Descriptor Array.
%
% FieldInfo is a 1-by-numFields structure array with the following fields:
%       Name      A string containing the field name 
%       Type      A string containing the field type 
%       ConvFunc  A function handle to convert from DBF to MATLAB type
%       Length    A number equal to the length of the field in bytes

lengthOfLeadingBlock    = 32;
lengthOfDescriptorBlock = 32;
lengthOfTerminator      =  1;
fieldNameOffset         = 16;  % Within table field descriptor
fieldNameLength         = 11;

% Get number of fields.
fseek(fid,8,'bof');
headerLength = fread(fid,1,'uint16');
numFields = (headerLength - lengthOfLeadingBlock - lengthOfTerminator)...
               / lengthOfDescriptorBlock;

% Read field lengths.
fseek(fid,lengthOfLeadingBlock + fieldNameOffset,'bof');
lengths = fread(fid,[1 numFields],'uint8',lengthOfDescriptorBlock - 1);

% Read the field names.
fseek(fid,lengthOfLeadingBlock,'bof');
data = fread(fid,[fieldNameLength numFields],...
             sprintf('%d*uint8=>char',fieldNameLength),...
             lengthOfDescriptorBlock - fieldNameLength);
data(data == 0) = ' '; % Replace nulls with blanks
names = cellstr(data')';

% Read field types.
fseek(fid,lengthOfLeadingBlock + fieldNameLength,'bof');
dbftypes = fread(fid,[numFields 1],'uint8=>char',lengthOfDescriptorBlock - 1);

% Convert DBF field types to MATLAB types.
typeConv = dbftype2matlab(upper(dbftypes));

% Return a struct array.
fieldInfo = cell2struct(...
    [names;  {typeConv.MATLABType}; {typeConv.ConvFunc}; num2cell(lengths)],...
    {'Name', 'Type',                'ConvFunc',          'Length'},1)';

%--------------------------------------------------------------------------
function typeConv = dbftype2matlab(dbftypes)
% Construct struct array with MATLAB types & conversion function handles.

typeLUT = ...
    {'N', 'double', @str2double2cell;...    % DBF numeric
     'F', 'double', @str2double2cell;...    % DBF float
     'C', 'char',   @str2unicode2cell;...   % DBF character
     'D', 'char',   @cellstr};              % DBF date

unsupported = struct('MATLABType', 'unsupported', ...
                     'ConvFunc',   @cellstr);
                     
% Unsupported types: Logical,Memo,N/ANameVariable,Binary,General,Picture

numFields = length(dbftypes);
if numFields ~= 0
  typeConv(numFields) = struct('MATLABType',[],'ConvFunc',[]);
end
for k = 1:numFields
    idx = strmatch(dbftypes(k),typeLUT(:,1));
    if ~isempty(idx)
        typeConv(k).MATLABType = typeLUT{idx,2};
        typeConv(k).ConvFunc   = typeLUT{idx,3};
    else
        typeConv(k) = unsupported;
    end
end

%--------------------------------------------------------------------------
function out = str2double2cell(in)
% Translate IN, an M-by-N array of class char, to an M-by-1 column cell
% vector OUT, where each cell contains a double.  IN may be blank- or
% null-padded.  If IN(k,:) does not represent a valid scalar value, then
% OUT{k} contains NaN.

if isempty(in)
    out = {NaN};
else
    % Add a space to the beginning of each row of IN.
    in = [char(32 + zeros(size(in,1),1)) in];
    
    % Try to use ssscanf. (First transpose and reshape IN into a single
    % row vector with the values stored sequentially. There will be at
    % least one space character separating each pair of adjacent numbers.)
    [data count] = sscanf(reshape(in',[1 numel(in)]),'%f');
    if count == size(in,1)
        % sscanf succeeded; now use ARRAYFUN, specifying an anonymous
        % identify function and non-uniform output, to convert a numeric
        % array to a cell array having the same shape.
        out = arrayfun(@(x) x, data, 'UniformOutput', false);
    else
        % Otherwise fall back to str2double if necessary.
        out = num2cell(str2double(cellstr(in)));
    end
end

%--------------------------------------------------------------------------
function out = str2unicode2cell(in)
% Translate IN, an M-by-N array of class char, to an M-by-1 column cell
% vector OUT, where the elements of each cell are Unicode characters with
% any trailing blank characters removed. The values in IN are in assumed to
% be in native format (uint8), but contained in a char array, and are
% translated to unicode using MATLAB's default encoding scheme.

in = uint8(in);
numRows = size(in, 1);
out = cell(numRows, 1);
for k=1:numRows
    % Convert the native values to unicode representation. Trim away
    % ASCII-only blank characters.
    out{k} = trimTrailingBlanks(native2unicode(in(k, :)));
end

%--------------------------------------------------------------------------
function out = trimTrailingBlanks(in)
% Remove any trailing blank characters from string IN. IN may contain
% non-ASCII Unicode characters. A blank character is a space (' ') defined
% in 7-bit ASCII encoding only. (Note that we cannot use the standard
% MATLAB DEBLANK or STRTRIM functions, because in addition to removing
% white space characters in the 7-bit ASCII table, they also remove
% char(133) (horizontal ellipsis) and char(160) (non-breaking space) in the
% extended ASCII table.)

% Determine the representation of a blank character.
blank = char(' ');

% Find all occurrences of the blank character in IN. blankIndex is a
% logical which is true for all elements that contain a blank.
blankIndex = blank == in;
if any(blankIndex)
    % Find the last occurrence of a non-blank character.
    index = find(~blankIndex, 1, 'last');
    if ~isempty(index)
        % Return the characters that are not trailing blanks.
        out = in(1:index);
    else
        % All elements are blank characters since index is empty, return a
        % 0-by-0 empty character string.
        out = '';
    end
else
    % IN does not contain any ASCII blank characters.
    out = in;
end
