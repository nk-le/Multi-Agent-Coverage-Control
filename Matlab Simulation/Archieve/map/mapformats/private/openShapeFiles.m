function [shpFileId, shxFileId, dbfFileId, headerTypeCode, prjText] = ...
    openShapeFiles(filename,callingFcn)
%OPENSHAPEFILES Try to open .SHP, .SHX, and .DBF files.
%   Deconstruct a shapefile name that may include any of the standard
%   extensions (in either all lower of all upper case). Try to open the
%   corresponding SHP, SHX, and DBF files, returning a file ID for each one
%   if successful, -1 if not. Check the header file type, shapefile
%   version, and the shape type code found in the header. If requested and
%   available, return the text content of the .PRJ file.

%   Copyright 1996-2020 The MathWorks, Inc.
        
% See if filename has an extension and extract basename.
[basename, shapeExtensionProvided] = deconstruct(filename);

% Open the SHP file, check shapefile code and version, and construct a
% qualified basename to ensure consistency in the event of duplicate
% filenames on the path.
[basename, ext] = checkSHP(basename,shapeExtensionProvided);

% Open the SHP file with the qualified basename and read/check the shape
% type code in the file header.
shpFileId = fopen([basename ext]);
headerTypeCode = readHeaderTypeCode(shpFileId,callingFcn);

% Open the SHX and DBF files with the qualified basename.
shxFileId = openSHX(basename,callingFcn);
dbfFileId = openDBF(basename);

% Check for a PRJ file, if it exists attempt to read it.
if nargout > 4
    prjname = [basename '.prj'];
    if isfile(prjname)
        try
            prjText = fileread(prjname);
        catch
            prjText = '';
        end
    else
        prjText = '';
    end
end

%--------------------------------------------------------------------------
function [basename, shapeExtensionProvided] = deconstruct(filename)

shapefileExtensions = {'.shp','.shx','.dbf'};
[pathstr,name,ext] = fileparts(filename);

if isempty(ext)
    basename = filename;
    shapeExtensionProvided = false;
else
    if any(strcmpi(ext,shapefileExtensions))
        basename = fullfile(pathstr,name);
        shapeExtensionProvided = true;
    else
        % Make sure to allow filename  = 'test.jnk' where the full
        % shapefile name is actually 'test.jnk.shp'.
        basename = filename;
        shapeExtensionProvided = false;
    end
end

%--------------------------------------------------------------------------
function [basename, ext] = checkSHP(basename,shapeExtensionProvided)

shpFileId = fopen([basename '.shp']);
if (shpFileId == -1)
    shpFileId = fopen([basename '.SHP']);
end;

if (shpFileId == -1)
    if shapeExtensionProvided == false
        [~,~,ext] = fileparts(basename);
        if ~isempty(ext)
            error(message('map:shapefile:invalidExtension', basename))
        else
            error(message('map:shapefile:failedToOpenSHP', basename, basename))
        end
    else
        error(message('map:shapefile:failedToOpenSHP', basename, basename));
    end
end

standardShapefileCode = 9994;
fileCode = fread(shpFileId,1,'uint32','ieee-be');
if fileCode ~= standardShapefileCode
    fname = fopen(shpFileId);
    fclose(shpFileId);
    error(message('map:shapefile:notAShapefile', fname))
end

versionSupported = 1000;
fseek(shpFileId,28,'bof');
version = fread(shpFileId,1,'uint32','ieee-le');
if version ~= versionSupported
    fclose(shpFileId);
    error(message('map:shapefile:unsupportShapefileVersion', version));
end

% Construct fully qualified basename and get SHP extension.
[pathstr,name,ext] = fileparts(fopen(shpFileId));
if ~isempty(pathstr)
    basename = fullfile(pathstr,name);
else
    basename = fullfile('.',name);
end

fclose(shpFileId);

%--------------------------------------------------------------------------
function shxFileId = openSHX(basename,callingFcn)

shxFileId = fopen([basename '.shx'],'r','ieee-be');
if (shxFileId == -1)
    shxFileId = fopen([basename '.SHX'],'r','ieee-be');
end

if (shxFileId == -1)
    if strcmp(callingFcn,'shaperead')
        warning(message('map:shapefile:buildingIndexFromSHP', basename, basename));
    else
        warning(message('map:shapefile:missingSHX', basename, basename));
    end
end

%--------------------------------------------------------------------------
function dbfFileId = openDBF(basename)

dbfFileId = fopen([basename '.dbf'],'r','ieee-le');
if (dbfFileId == -1)
    dbfFileId = fopen([basename '.DBF'],'r','ieee-le');
end

if (dbfFileId == -1)
    warning(message('map:shapefile:missingDBF', basename, basename));
end

%--------------------------------------------------------------------------
function headerTypeCode = readHeaderTypeCode(shpFileId,callingFcn)

% Read the type code from a shapefile header and check to see if it's (1)
% valid and (2) supported by shaperead.  If it's not supported by
% shaperead, generate an error if called from shaperead but only a warning
% if called by shapeinfo.

fseek(shpFileId,32,'bof');
headerTypeCode = fread(shpFileId,1,'uint32','ieee-le');

if ~getShapeTypeInfo(headerTypeCode,'IsValid')
    fclose(shpFileId);
    error(message('map:shapefile:invalidShapeTypeCode', sprintf( '%g', headerTypeCode )));
end

if ~getShapeTypeInfo(headerTypeCode,'IsSupported')
    typeString = getShapeTypeInfo(headerTypeCode,'TypeString');
    if strcmp(callingFcn,'shaperead')
        fclose(shpFileId);
        error(message('map:shapefile:unsupportedType', typeString, sprintf( '%g', headerTypeCode )))
    else
        warning(message('map:shapefile:unsupportedType', typeString, sprintf( '%g', headerTypeCode )))
    end
end
