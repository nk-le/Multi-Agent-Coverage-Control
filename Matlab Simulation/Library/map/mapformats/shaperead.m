function varargout = shaperead(varargin)
%SHAPEREAD Read vector features and attributes from shapefile
%
%   S = SHAPEREAD(FILENAME) returns an N-by-1 structure array, S,
%   containing one element for each non-null geographic feature in the
%   shapefile.  S is a "mapstruct" geographic data structure array and
%   combines coordinates/geometry, expressed in terms of map X and Y,
%   with non-spatial feature attributes.
%
%   S = shaperead(FILENAME,PARAM1,VAL1,PARAM2,VAL2,...) returns a subset
%   of the shapefile contents in S, as determined by the parameters
%   'RecordNumbers','BoundingBox','Selector', or 'Attributes'. S is a
%   mapstruct unless the parameter 'UseGeoCoords' is provided with a
%   value of true.  In that case, the X and Y-coordinates within the
%   shapefile are interpreted as longitudes and latitudes, respectively,
%   and S is a "geostruct" with 'Lat' and 'Lon' fields rather than 'X'
%   and 'Y' fields.
%
%   [S, A] = SHAPEREAD(...) returns an N-by-1 mapstruct or geostruct, S,
%   omitting any non-spatial attributes, and a parallel N-by-1 attribute
%   structure array, A.  Each array contains an element for each
%   non-null feature in the shapefile.
%
%   The shapefile format was defined by the Environmental Systems Research
%   Institute (ESRI) to store nontopological geometry and attribute
%   information for spatial features. A shapefile consists of a main file,
%   an index file, and an xBASE table. All three files have the same base
%   name and are distinguished by the extensions 'SHP', 'SHX', and 'DBF',
%   respectively (e.g., base name 'concord_roads' and filenames
%   'concord_roads.SHP', 'concord_roads.SHX', and 'concord_roads.DBF').
%
%   FILENAME can be the base name, or the full name of any one of the
%   component files.  SHAPEREAD reads all three files as long as they
%   exist in the same directory and have valid file extensions. If the
%   main file (with extension SHP) is missing, SHAPEREAD returns an
%   error. If either of the other files is missing, SHAPEREAD returns a
%   warning.
%
%   Supported shape types
%   ---------------------
%   SHAPEREAD supports the ordinary 2D shape types: 'Point', 'Multipoint',
%   'PolyLine', and 'Polygon'. ('Null Shape' features are may also be
%   present in a Point, Multipoint, PolyLine, or Polygon shapefile, but
%   are ignored.) SHAPEREAD does not support any 3D or "measured" shape
%   types: 'PointZ', 'PointM', 'MultipointZ', 'MultipointM', 'PolyLineZ',
%   'PolyLineM', 'PolygonZ', 'PolylineM', or 'Multipatch'.
%
%   Output structure
%   ----------------
%   The fields in the output structure array S and A depend on (1) the type
%   of shape contained in the file and (2) the names and types of the
%   attributes included in the file:
%
%     Field name            Field contents          Comment
%     ----------            -----------------       -------
%     'Geometry'            Shape type
%
%     'BoundingBox'         [minX minY;             Omitted for shape type
%                            maxX maxY]             'Point'
%
%     'X' or 'Lon'          Coordinate vector       NaN-separators used
%                                                   in multi-part PolyLine
%     'Y' or 'Lat'          Coordinate vector       and Polygon shapes
%
%     Attr1                 Value of first          Included in output S
%                           attribute               if output A is omitted
%
%     Attr2                 Value of second         Included in output S
%                           attribute               if output A is omitted
%
%     ...                   ...                     ...
%
%   The names of the attribute fields (listed above as Attr1, Attr2, ...)
%   are determined at run-time from the xBASE table (with extension 'DBF')
%   and/or optional, user-specified parameters.  There may be many
%   attribute fields, or none at all.
%
%   'Geometry' field
%   -----------------
%   The 'Geometry' field will be one of the following values: 'Point',
%   MultiPoint', 'Line', or 'Polygon'.  (Note that these match the standard
%   shapefile types except for shapetype 'Polyline' the value of the
%   Geometry field is simply 'Line'.
%
%   'BoundingBox' field
%   -------------------
%   The 'BoundingBox' field contains a 2-by-2 numerical array specifying
%   the minimum and maximum feature coordinate values in each dimension
%   (min([x, y]); max([x, y] where x and y are N-by-1 and contain the
%   combined coordinates of all parts of the feature).
%
%   Coordinate vector fields ('X','Y' or 'Lon','Lat')
%   -------------------------------------------------
%   These are 1-by-N arrays of class double.  For 'Point' shapes, they
%   are 1-by-1.  In the case of multi-part 'Polyline' and 'Polygon' shapes,
%   NaN are added to separate the lines or polygon rings.  In addition,
%   terminating NaNs are added to support horizontal concatenation of the
%   coordinate data from multiple shapes.
%
%   Attribute fields
%   ----------------
%   Attribute names, types, and values are defined within a given
%   shapefile. The following four types are supported: Numeric, Floating,
%   Character, and Date. SHAPEREAD skips over other attribute types.
%   The field names in the output shape structure are taken directly from
%   the shapefile if they contain no spaces or other illegal characters,
%   and there is no duplication of field names (e.g., an attribute named
%   'BoundingBox', 'PointData', etc. or two attributes with the names).
%   Otherwise the following 'name mangling' is applied: Illegal characters
%   are replaced by '_'. If the first character in the attribute name is
%   illegal, a leading 'Z' is added. Numerals are appended if needed to
%   avoid duplicate names. The attribute values for a feature are taken
%   from the shapefile and stored as doubles or character arrays:
%
%   Attribute type in shapefile     MATLAB storage
%   ---------------------------     --------------
%       Numeric                     double (scalar)
%       Float                       double (scalar)
%       Character                   char array
%       Date                        char array
%
%   Parameter-Value Options
%   -----------------------
%   By default, shaperead returns an entry for every non-null feature and
%   creates a field for every attribute.  Use the first three parameters
%   below (RecordNumbers, BoundingBox, and Selector) to be selective about
%   which features to read.  Use the 4th parameter (Attributes) to control
%   which attributes to keep.  Use the 5th (UseGeoCoords) to control the
%   output field names.
% 
%   Name            Description of Value        Purpose
%   ----            --------------------        -------
%   
%   RecordNumbers   Integer-valued vector,      Screen out features whose
%                   class double                record numbers are not
%                                               listed.
% 
%   BoundingBox     2-by-(2,3, or 4) array,     Screen out features whose
%                   class double                bounding boxes fail to
%                                               intersect the selected box.
%                                             
%   Selector        Cell array containing       Screen out features for
%                   a function handle and       which the function, when
%                   one or more attribute       applied to the
%                   names.  Function must       corresponding attribute
%                   return a logical scalar.    values, returns false.
%                   
%   Attributes      Cell array of attribute     Omit attributes that are
%                   names                       not listed. Use {} to omit
%                                               all attributes. Also sets
%                                               the order of attributes in
%                                               the structure array.
%
%   UseGeoCoords    Scalar logical              If true, replace X and Y
%                                               field names with 'Lon' and
%                                               'Lat', respectively.
%                                               Defaults to false.
%
%   Examples
%   --------
%   % Read the entire concord_roads.shp shapefile, including the attributes
%   % in concord_roads.dbf.
%   S = shaperead('concord_roads.shp');
%
%   % Restrict output based on a bounding box and read only two
%   % of the feature attributes.
%   bbox = [2.08 9.11; 2.09 9.12] * 1e5;
%   S = shaperead('concord_roads','BoundingBox',bbox,...
%                 'Attributes',{'STREETNAME','CLASS'});
%
%   % Select the class 4 and higher road segments that are at least 200
%   % meters in length.  Note the use of an anonymous function in the
%   % selector.
%   S = shaperead('concord_roads.shp',...
%         'Selector',{@(v1,v2) (v1 >= 4) && (v2 >= 200),'CLASS','LENGTH'});
%   histcounts([S.CLASS],'BinLimits',[1 7],'BinMethod','integer')
%   figure
%   histogram([S.LENGTH])
%
%   % Read world-wide city names and locations in latitude and longitude.
%   % (Note presence of 'Lat' and 'Lon' fields.)
%   S = shaperead('worldcities.shp', 'UseGeoCoords', true)
%
%   See also SHAPEINFO, SHAPEWRITE, UPDATEGEOSTRUCT.

% Copyright 1996-2017 The MathWorks, Inc.

%   Reference
%   ---------
%   ESRI Shapefile Technical Description, White Paper, Environmental
%   Systems Research Institute, July 1998.
%   (http://arconline.esri.com/arconline/whitepapers/ao_/shapefile.pdf)

narginchk(1, Inf);
nargoutchk(0, 2);
switch(nargout)
    case {0,1}, separateAttributes = false;
    otherwise,  separateAttributes = true;
end

[varargin{:}] = convertStringsToChars(varargin{:});

% Parse function inputs.
[filename, recordNumbers, boundingBox, selector, attributes, useGeoCoords] ...
    = parseInputs(varargin{:});

% Try to open the SHP, SHX, and DBF files corresponding to  the filename
% provided. Selectively validate the header, including the shape type code.
[shpFileId, shxFileId, dbfFileId, headerTypeCode] ...
    = openShapeFiles(filename,'shaperead');

% Get the file offset for the content of each shape record.
if (shxFileId ~= -1)
    contentOffsets = readIndexFromSHX(shxFileId);
else
    contentOffsets = constructIndexFromSHP(shpFileId);
end

% Select which records to read.
records2read = selectRecords(shpFileId, dbfFileId, headerTypeCode,...
                   contentOffsets, recordNumbers, boundingBox, selector);
                   
% Read the shape coordinates from the SHP file into a cell array.
[shapeData, shapeDataFieldNames] ...
    = shpread(shpFileId, headerTypeCode, contentOffsets(records2read));
 
% Read the attribute data from the DBF file into a cell array.
[attributeData, attributeFieldNames] ...
    = dbfread(dbfFileId,records2read,attributes);

% Optionally rename coordinate field names.
if useGeoCoords
    shapeDataFieldNames{strcmp('X', shapeDataFieldNames)} = 'Lon';
    shapeDataFieldNames{strcmp('Y', shapeDataFieldNames)} = 'Lat';
end

% Concatenate the cell arrays, if necessary and convert to struct(s).
varargout = constructOutput(shapeData, attributeData,...
              shapeDataFieldNames, attributeFieldNames, separateAttributes);

% Clean up.
closeFiles([shpFileId, shxFileId, dbfFileId]);

%--------------------------------------------------------------------------
function outputs = constructOutput(shapeData, attributeData,...
              shapeDataFieldNames, attributeFieldNames, separateAttributes)

if separateAttributes
    if ~isempty(attributeData)
        A = cell2struct(attributeData,genvarname(attributeFieldNames),2);
    else
        A = [];
    end
    S = cell2struct(shapeData,shapeDataFieldNames,2);
    outputs = {S, A};
else
    if ~isempty(attributeData)
        % Concatenate the shape data field names for the current shape type
        % and the attribute field names from the DBF file (if available).
        % Ensure value, non-duplicate structure field names.
        reservedNames = {'Geometry', 'X', 'Y', 'Lat', 'Lon', ...
                 'BoundingBox', 'Height', 'INDEX'};
        featureFieldNames = [shapeDataFieldNames,...
           genvarname(attributeFieldNames,reservedNames)];
            
        S = cell2struct([shapeData, attributeData],featureFieldNames,2);
    else
        S = cell2struct(shapeData,shapeDataFieldNames,2);
    end
    outputs = {S};
end

%--------------------------------------------------------------------------
function records2read = selectRecords(shpFileId, dbfFileId, headerTypeCode, ...
                          contentOffsets, recordNumbers, boundingBox, selector)
% Select record numbers to read as constrained by shapefile record types,
% user-specified record numbers, user-specified bounding box, and
% user-specified attribute-based selector function.

% Initialize selection to include all non-null shape records.
records2read = recordsMatchingHeaderType(shpFileId,contentOffsets,headerTypeCode);

% Narrow selection based on user-specified record numbers.
if ~isempty(recordNumbers)
    records2read = intersect(recordNumbers,records2read);
end

% Narrow selection based on bounding box.
if ~isempty(boundingBox)
    
    if hasBoundingBox(headerTypeCode)
        bbSubscripts = getShapeTypeInfo(headerTypeCode,'BoundingBoxSubscripts');
        records2read = recordsIntersectingBox(shpFileId,...
            bbSubscripts,contentOffsets,boundingBox,records2read);
    else
        records2read = recordsWithPointsInbox(shpFileId,...
            contentOffsets,boundingBox,records2read);
    end
end

% Finalize selection based on selector function.
if (dbfFileId ~= -1) && ~isempty(selector)
    records2read = recordsMatchingSelector(dbfFileId,selector,records2read);
end

%---------------------------------------------------------------------------
function recs = recordsMatchingHeaderType(shpFileId,contentOffsets,headerTypeCode)
% Select the records that match the headerTypeCode.

totalNumRecords = length(contentOffsets);
recordMatchesHeaderType = false(1,totalNumRecords);
for n = 1:totalNumRecords
	fseek(shpFileId,contentOffsets(n),'bof');
	recordTypeCode = fread(shpFileId,1,'uint32','ieee-le');
	recordMatchesHeaderType(n) = (recordTypeCode == headerTypeCode);
end
recs = find(recordMatchesHeaderType);

%--------------------------------------------------------------------------
function answer = hasBoundingBox(shapeTypeCode)
fieldNames = getShapeTypeInfo(shapeTypeCode,'ShapeDataFieldNames');
answer = any(strcmp('BoundingBox', fieldNames));

%--------------------------------------------------------------------------
function recs = recordsIntersectingBox(...
    shpFileId, bbSubscripts, contentOffsets, box, recs)
% Select the records with bounding boxes intersecting the specified box.

currentNumberOfRecs = numel(recs);
intersectsBox = false(1,currentNumberOfRecs);
for k = 1:currentNumberOfRecs
    n = recs(k);
	fseek(shpFileId,contentOffsets(n) + 4,'bof');
    bbox = fread(shpFileId,8,'double','ieee-le');
    intersectsBox(k) = boxesIntersect(box,bbox(bbSubscripts));
end
recs(~intersectsBox) = [];

%--------------------------------------------------------------------------
function result = boxesIntersect(a,b)
result = ~(any(a(2,:) < b(1,:)) || any(b(2,:) < a(1,:)));

%--------------------------------------------------------------------------
function recs = recordsWithPointsInbox(...
    shpFileId, contentOffsets, box, recs)
% Select the point records for locations within the specified box.
% Note: This version assumes 2D-only.

currentNumberOfRecs = numel(recs);
insideBox = false(1,currentNumberOfRecs);
for k = 1:currentNumberOfRecs
    n = recs(k);
	fseek(shpFileId,contentOffsets(n) + 4,'bof');
    point = fread(shpFileId,[1 2],'double','ieee-le');
    insideBox(k) = all(box(1,:) <= point(1,:)) && all(point(1,:) <= box(2,:));
end
recs(~insideBox) = [];

%--------------------------------------------------------------------------
function recs = recordsMatchingSelector(fid,selector,recs)
% Apply selector to DBF file to refine list of records to read.

% The first byte in each record is a deletion indicator
lengthOfDeletionIndicator = 1;

% Initialize things...
info = dbfinfo(fid);
selectfcn  = selector{1};
fieldnames = selector(2:end);

% Determine the position, offset, and format string for each field 
% specified by the selector.  If any fieldnames fail to get a match,
% return without altering the list of records, and issue a warning.
allFieldNames = {info.FieldInfo.Name};
sz = size(fieldnames);
position = zeros(sz);
offset = zeros(sz);
formatstr = cell(sz);
for l = 1:numel(fieldnames)
    m = strcmp(fieldnames{l}, allFieldNames);
    if ~any(m)
        warning(message('map:shapefile:badSelectorFieldName', fieldnames{ l }))
        return;
    end
    m = find(m);
    position(l)  = m;
    offset(l)    = sum([info.FieldInfo(1:(m-1)).Length]) ...
                   + lengthOfDeletionIndicator;
   formatstr{l} = sprintf('%d*uint8=>char',info.FieldInfo(m).Length);
end

% Check each record in the current list to see if it satisfies the
% selector.
satisfiesSelector = false(1,numel(recs));
for k = 1:numel(recs)
    n = recs(k);
    values = cell(size(position));
    for l = 1:numel(position)
        m = position(l);
        fseek(fid,info.HeaderLength + (n-1)*info.RecordLength + offset(l),'bof');
        data = fread(fid,info.FieldInfo(m).Length,formatstr{l});
        values(l) = info.FieldInfo(m).ConvFunc(data');
    end
    satisfiesSelector(k) = selectfcn(values{:});
end

% Remove records that don't satisfy the selector.
recs(~satisfiesSelector) = [];

%--------------------------------------------------------------------------
function contentOffsets = readIndexFromSHX(shxFileId)
% Get record content offsets (in bytes) from shx file.

fileHeaderLength    = 100;
recordHeaderLength  =   8;
bytesPerWord        =   2;
contentLengthLength =   4;

fseek(shxFileId,fileHeaderLength,'bof');
contentOffsets = recordHeaderLength + ...
    bytesPerWord * fread(shxFileId,inf,'uint32',contentLengthLength);

%--------------------------------------------------------------------------
function contentOffsets = constructIndexFromSHP(shpFileId)
% Get record content offsets (in bytes) from shp file.

bytesPerWord        =   2;
fileHeaderLength    = 100;
recordHeaderLength  =   8;
contentLengthLength =   4;

fseek(shpFileId,24,'bof');
fileLength = bytesPerWord * fread(shpFileId,1,'uint32','ieee-be');
lengthArray = [];
recordOffset = fileHeaderLength;
while recordOffset < fileLength
    fseek(shpFileId,recordOffset + recordHeaderLength - contentLengthLength,'bof');
    contentLength = bytesPerWord * fread(shpFileId,1,'uint32','ieee-be');
    lengthArray(end + 1,1) = contentLength; %#ok<AGROW>
    recordOffset = recordOffset + recordHeaderLength + contentLength;
end
contentOffsets = fileHeaderLength ...
                 + cumsum([0;lengthArray(1:end-1)] + recordHeaderLength);

%--------------------------------------------------------------------------
function [shpdata, fieldnames] = ...
    shpread(shpFileId, headerTypeCode, contentOffsets)
% Read designated shape records.

shapeTypeLength = 4;
readfcn    = getShapeTypeInfo(headerTypeCode,'ShapeRecordReadFcn');
fieldnames = getShapeTypeInfo(headerTypeCode,'ShapeDataFieldNames');
shpdata = cell(numel(contentOffsets),numel(fieldnames));

for k = 1:numel(contentOffsets)
    fseek(shpFileId,contentOffsets(k) + shapeTypeLength,'bof');
    shpdata(k,:) = readfcn(shpFileId);
end

%--------------------------------------------------------------------------
function [attributeData, attributeFieldNames] ...
    = dbfread(fid, records2read, requestedFieldNames)
% Read specified records and fields from a DBF file.  Fields will follow
% the order given in REQUESTEDFIELDNAMES.

% Return empties if there's no DBF file.
if (fid == -1)
    attributeData = [];
    attributeFieldNames = {};
    return;
end

info = dbfinfo(fid);
fields2read = matchFieldNames(info,requestedFieldNames);
attributeFieldNames = {info.FieldInfo(fields2read).Name};

% The first byte in each record is a deletion indicator
lengthOfDeletionIndicator = 1;

% Loop over the requested fields, reading the attribute data.
attributeData = cell(numel(records2read),numel(fields2read));
for k = 1:numel(fields2read)
    n = fields2read(k);
    if info.FieldInfo(n).Length > 0
        fieldOffset = info.HeaderLength ...
            + sum([info.FieldInfo(1:(n-1)).Length]) ...
            + lengthOfDeletionIndicator;
        fseek(fid,fieldOffset,'bof');
        formatString = sprintf('%d*uint8=>char',info.FieldInfo(n).Length);
        skip = info.RecordLength - info.FieldInfo(n).Length;
        data = fread(fid,[info.FieldInfo(n).Length info.NumRecords],formatString,skip);
        attributeData(:,k) = info.FieldInfo(n).ConvFunc(data(:,records2read)');
    else
        % Field length is <= 0. 
        % For all features for this attribute, set the attributeData to 
        % the empty string ('').
        [attributeData(:,k)] = {''};
    end
end

%--------------------------------------------------------------------------
function fields2read = matchFieldNames(info, requestedFieldNames)
% Determine which fields to read.

allFieldNames = {info.FieldInfo.Name};
if isempty(requestedFieldNames)
    if ~iscell(requestedFieldNames)
        % Default case: User omitted the parameter, return all fields.
        fields2read = 1:info.NumFields;
    else
        % User supplied '{}', skip all fields.
        fields2read = [];
    end
else
    % Match up field names to see which to return.
    fields2read = [];
    for k = 1:numel(requestedFieldNames)
        index = find(strcmp(requestedFieldNames{k}, allFieldNames));
        if isempty(index)
            warning(message('map:shapefile:nonexistentAttributeName', requestedFieldNames{ k }))
        end
        for l = 1:numel(index)
            % Take them all in case of duplicate names.
            fields2read(end+1) = index(l); %#ok<AGROW>
        end
    end
end

%--------------------------------------------------------------------------
function [filename, recordNumbers, boundingBox, selector, attributes, useGeoCoords] ...
    = parseInputs(varargin)

validParameterNames = ...
    {'RecordNumbers','BoundingBox','Selector','Attributes','UseGeoCoords'};

% FILENAME is the only required input.
filename = varargin{1};
validateattributes(filename, {'char'},{'vector'},mfilename,'FILENAME',1);

% Assign defaults for optional inputs.
recordNumbers = [];
boundingBox = [];
selector = [];
attributes = [];
useGeoCoords = false;

% Identify and validate the parameter name-value pairs.
for k = 2:2:nargin
    parName = validatestring(varargin{k}, validParameterNames, mfilename, ...
        sprintf('PARAM%d',k/2), k);
    switch parName
        case 'RecordNumbers'
            checkExistence(k, nargin, 'vector of record numbers', parName);
            recordNumbers = checkRecordNumbers(varargin{k+1},k+1);
            
        case 'BoundingBox'
            checkExistence(k, nargin, 'bounding box', parName);
            checkboundingbox(varargin{k+1},mfilename,'BOUNDINGBOX',k+1);
            boundingBox = varargin{k+1};
            
        case 'Selector'
            checkExistence(k, nargin, 'selector', parName);
            selector = checkSelector(varargin{k+1},k+1);
            
        case 'Attributes'
            checkExistence(k, nargin, 'attribute field names', parName);
            attributes = checkAttributes(varargin{k+1},k+1);
            
        case 'UseGeoCoords'
            checkExistence(k, nargin, 'geo-coordinates flag (T/F)', parName);
            validateattributes(varargin{k+1}, {'logical'}, {'scalar'}, mfilename, 'USEGEOCOORDS', k+1);
            useGeoCoords = varargin{k+1};
            
        otherwise
            error(message('map:internalProblem:unrecognizedParameterName', parName));
    end
end

%--------------------------------------------------------------------------

function checkExistence(position, nargs, propertyDescription, propertyName)
% Error if missing the property value following a property name.

if (position + 1 > nargs)
    error(message('map:shapefile:missingParameterValue', propertyDescription, propertyName));
end

%--------------------------------------------------------------------------

function recordNumbers = checkRecordNumbers(recordNumbers, position)

validateattributes(recordNumbers, {'numeric'},...
              {'nonempty','real','nonnan','finite','positive','vector'},...
              mfilename, 'recordNumbers', position);

%--------------------------------------------------------------------------

function selector = checkSelector(selector, position)
% SELECTOR should be a cell array with a function handle followed by
% strings. Do NOT try to check the strings against actual attributes,
% because we won't know the attributes until we've read the DBF file.
% Instead, we issue a warning later on in matchFieldNames.

validateattributes(selector, {'cell'}, {}, mfilename, 'SELECTOR', position);

if numel(selector) < 2
    error(message('map:shapefile:selectorTooShort'));
end

if ~isa(selector{1},'function_handle')
    error(message('map:shapefile:selectorMissingFcnHandle'));
end

for k = 2:numel(selector)
    if ~(ischar(selector{k}) || isStringScalar(selector{k}))
        error(message('map:shapefile:selectorHasNonStrAttrs', num2ordinal( k )));
    end
end

%--------------------------------------------------------------------------

function attributes = checkAttributes(attributes, position)

validateattributes(attributes, {'cell'}, {}, mfilename, 'ATTRIBUTES', position);

for k = 1:numel(attributes)
    if ~ischar(attributes{k})
        error(message('map:shapefile:nonCharAttribute'));
    end
end
