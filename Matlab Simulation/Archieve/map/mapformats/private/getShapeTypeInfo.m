function result = getShapeTypeInfo(shapeTypeCode,requestOrQuery)
%GETSHAPETYPEINFO   Get information about a shape type.
%   Returns a single value, based on the second argument:
%     'TypeString'             -- Return a string
%     'IsValid'                -- Return a scalar logical
%     'IsSupported'            -- Return a scalar logical
%     'BoundingBoxSubscripts'  -- Return a 1-by-n double array
%     'ShapeRecordReadFcn'     -- Return a function handle
%     'ShapeDataFieldNames'    -- Return a cell array of string.

%   Copyright 1996-2016 The MathWorks, Inc.

lutFields = { 'TypeCode',...
              'TypeString',...
              'IsValid',...
              'IsSupported',...
              'BoundingBoxSubscripts',...
              'ShapeRecordReadFcn',...
              'ShapeDataFieldNames' };

% Three kinds of bounding box subscripts
bbs2D = [1 2; 3 4];
bbsZ  = [1 2 5; 3 4 6]; % Ignore M for now, otherwise use [1 2 5 7; 3 4 6 8]
bbsM  = [1 2 7; 3 4 8];

typeLUT = {...
   -1, 'Not Valid',   false, false, [],    [], {''};... 
    0, 'Null Shape',  true,  true,  [],    [], {''};... 
    1, 'Point',       true,  true,  bbs2D, @readPoint,      {'Geometry','X','Y'};... 
    3, 'PolyLine',    true,  true,  bbs2D, @readPolyLine,   {'Geometry','BoundingBox','X','Y'};...
    5, 'Polygon',     true,  true,  bbs2D, @readPolygon,    {'Geometry','BoundingBox','X','Y'};...
    8, 'MultiPoint',  true,  true,  bbs2D, @readMultiPoint, {'Geometry','BoundingBox','X','Y'};...
   11, 'PointZ',      true,  false, bbsZ,  [], {''};...
   13, 'PolyLineZ',   true,  false, bbsZ,  [], {''};... 
   15, 'PolygonZ',    true,  false, bbsZ,  [], {''};... 
   18, 'MultiPointZ', true,  false, bbsZ,  [], {''};... 
   21, 'PointM',      true,  false, bbsM,  [], {''};... 
   23, 'PolyLineM',   true,  false, bbsM,  [], {''};... 
   25, 'PolygonM',    true,  false, bbsM,  [], {''};... 
   28, 'MultiPointM', true,  false, bbsM,  [], {''};... 
   31, 'MultiPatch',  true,  false, bbsZ,  [], {''};... 
  };
notValidRow = 1;
types = [typeLUT{:,1}];

% MAINTENANCE NOTE: To add support for additional types, add more rows
% to the type look up table (typeLUT), but be sure to keep 'Not Valid'
% in the first row.

row = find(shapeTypeCode == types);
if length(row) ~= 1
    row = notValidRow;
end

col = strmatch(lower(requestOrQuery),lower(lutFields));
if length(col) ~= 1
    error(message('map:internalProblem:invalidSecondArgument'));
end

result = typeLUT{row,col};

%---------------------------------------------------------------------------
function shp = readPoint(fid)

point = fread(fid,[2 1],'double','ieee-le');
shp = {'Point', point(1), point(2)};

%---------------------------------------------------------------------------
function shp = readMultiPoint(fid)

boundingBox    = fread(fid,4,'double','ieee-le');
numPoints      = fread(fid,1,'uint32','ieee-le');
points         = fread(fid,[2 numPoints],'double','ieee-le')';
shp = {'MultiPoint', boundingBox([1 2; 3 4]), points(:,1)', points(:,2)'};

%---------------------------------------------------------------------------
function shp = readPolyLine(fid)

boundingBox    = fread(fid,4,'double','ieee-le');
numPartsPoints = fread(fid,2,'uint32','ieee-le');
partOffsets    = fread(fid,[1 numPartsPoints(1)],'uint32','ieee-le');
points         = fread(fid,[2 numPartsPoints(2)],'double','ieee-le')';
[x,y] = organizeParts2D(partOffsets,points);
shp = {'Line', boundingBox([1 2; 3 4]), x, y};

%---------------------------------------------------------------------------
function shp = readPolygon(fid)

boundingBox    = fread(fid,4,'double','ieee-le');
numPartsPoints = fread(fid,2,'uint32','ieee-le');
partOffsets    = fread(fid,[1 numPartsPoints(1)],'uint32','ieee-le');
points         = fread(fid,[2 numPartsPoints(2)],'double','ieee-le')';
[x,y] = organizeParts2D(partOffsets,points);
shp = {'Polygon', boundingBox([1 2; 3 4]), x, y};

%---------------------------------------------------------------------------
function [x,y] = organizeParts2D(partOffsets,points)

numParts  = size(partOffsets,2);
numPoints = size(points,1);
% Initialize x and y to be row vectors of NaN
% with length numPoints * numParts
x = NaN + zeros(1, numPoints + numParts);
y = x;
if numParts == 1
    x(1, 1:numPoints) = points(:,1);
    y(1, 1:numPoints) = points(:,2);
else
    partStart = 1 + partOffsets;
    partEnd   = [partOffsets(2:end) numPoints];
    for k = 1:numParts
        xyStart = partStart(k) + (k - 1);
        xyEnd   = partEnd(k)   + (k - 1);
        x(1, xyStart:xyEnd) = points(partStart(k):partEnd(k), 1);
        y(1, xyStart:xyEnd) = points(partStart(k):partEnd(k), 2);
    end
end
