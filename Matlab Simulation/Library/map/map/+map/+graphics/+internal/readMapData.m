function [dataArgs, displayType, info] = readMapData(funcname, filename)
%READMAPDATA Read map data from a file
%
%   [DATAARGS, DISPLAYTYPE, INFO] = READMAPDATA(FUNCNAME, FILENAME)
%   reads the  filename, FILENAME, and returns the map data in the cell
%   array DATAARGS, the type of map data in DISPLAYTPE, and the information
%   structure in INFO.
%
%   FILENAME must the name of a file in GeoTIFF, ESRI Shape, Arc ASCII
%   Grid, or SDTS DEM format.
%
%   DATAARGS is a cell array containing the data from the file.  DATAARGS
%   must conform to the output of PARSEMAPINPUTS.
%
%   DISPLAYTYPE is a string with name  'mesh', 'surface', 'contour', 
%   'point', 'line', 'polygon', or 'image', 

% Copyright 2003-2020 The MathWorks, Inc.

%-------------------------------------------------------------------------

[~, ~,extension] = fileparts(filename);
ext = lower(extension);
switch ext   
    case {'.tif','.tiff'}
        [dataArgs, displayType, info] = readFromTiffFile(filename);
 
    case {'.jpg','.jpeg','.png'}
        [dataArgs, displayType, info] = readFromJpegFile(filename);
        
    case {'.shp','.shx','.dbf'}
        [dataArgs, displayType, info] = readFromShapeFile(filename, funcname);
        
    case {'.grd','.ddf'}
        [dataArgs, displayType, info] = readFromDemFile(filename, ext);
      
    otherwise
        error('map:readMapData:unsupportedFileFormat', ...
            ['Function %s cannot read the file, ''%s''. ', ...
            'The format ''%s'' is not supported.'], ...
            upper(funcname), filename, ext)
end

%--------------------------------------------------------------------------

function [dataArgs, displayType, info] = readFromTiffFile(filename)

try
    info = geotiffinfo(filename);
    [A, cmap, R] = readFromGeoTiffFile(info, filename);
catch e
    if strcmp(e.identifier, 'map:geotiff:expectedGeoTIFFTags')
        % The file is not a GeoTIFF file. Expect TIFF with worldfile.
        [A, cmap, R, info] = readFromWorldfile(filename);
    else
        % Unexpected result.
        rethrow(e);
    end
end

if isempty(cmap)
    dataArgs = {A, R};
else
    dataArgs = {A, cmap, R};
end
displayType = 'image';

%--------------------------------------------------------------------------

function [I, cmap, R, info] = readFromWorldfile(filename)

worldfilename = getworldfilename(filename);
if ~exist(worldfilename,'file')
    [~, ~, tifext] = fileparts(filename);
    [~, ~, wldext] = fileparts(worldfilename);
    error('map:readMapData:needsWorldFile', ...
        'A worldfile with a ''%s'' extension must accompany the ''%s'' file.', ...
        wldext, tifext)
end

[I,cmap] = imread(filename);
info = imfinfo(filename);
W = load(worldfilename);
map.internal.assert(isnumeric(W) && numel(W) == 6, 'map:fileio:expectedSixNumbers');
W = reshape(W,[2 3]);
R = map.internal.referencingMatrix(W);

%--------------------------------------------------------------------------

function [I, cmap, R] = readFromGeoTiffFile(info, filename)

if strcmp(info.ColorType, 'indexed')
    [I, cmap, R] = geotiffread(filename);
else
    [I, R] = geotiffread(filename);
    cmap = [];
end

if isempty(R)
    if ~isempty(info.RefMatrix)
        R = info.RefMatrix;
    else
        error('map:readMapData:emptyRefMatrix', ...
            ['The referencing matrix is not defined by the GeoTIFF file. ',...
            'Consider using a worldfile to define the referencing matrix.']);
    end
end

%--------------------------------------------------------------------------

function [dataArgs, displayType, info] = readFromJpegFile(filename)

displayType = 'image';
[A, cmap, R, info] = readFromWorldfile(filename);
if isempty(cmap)
    dataArgs = {A, R};
else
    dataArgs= {A, cmap, R};
end

%--------------------------------------------------------------------------

function [dataArgs, displayType, info] = readFromShapeFile(filename, mapfilename)

if isequal(lower(mapfilename), 'geoshow')
    geoCoords = true;
else
    geoCoords = false;
end

% Turn off warning (if issued) about failure to read a .dbf file since the
% warning is not needed for display purposes and will be issued once for
% shaperead and once for shapeinfo.
warningState = warning('off', 'map:shapefile:missingDBF');
obj = onCleanup(@()(warning(warningState)));

dataArgs = {shaperead(filename, 'UseGeoCoords', geoCoords)};
displayType = lower(dataArgs{1}(1).Geometry);
info = shapeinfo(filename);

%--------------------------------------------------------------------------

function [dataArgs, displayType, info] = readFromDemFile(filename, ext)

if strcmp('.grd',ext)
    [Z,R]= arcgridread(filename);
    info = struct([]);
else
    [Z,R]= sdtsdemread(filename);
    info = sdtsinfo(filename);
end
dataArgs = {Z,R};
displayType = 'surface';
