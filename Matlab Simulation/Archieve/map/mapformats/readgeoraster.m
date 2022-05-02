function [A,R,cmap] = readgeoraster(filename, namevalue)
%READGEORASTER Read geospatial raster data file
%   readgeoraster reads geographic and projected raster data files.
%   Supported formats include Esri Binary Grid, Esri GridFloat,
%   GeoTIFF, and DTED.
%   
%   [A,R] = readgeoraster(FILENAME) creates an array A by reading
%   geospatial raster data from a file.  R contains spatial referencing
%   information for A.  FILENAME must be in the current directory, in a
%   directory on the MATLAB path, or include a full or relative path to a
%   file.
%   
%   [A,R] = readgeoraster(___,'Bands',BANDNUMS) specifies which bands to
%   read from multi-band data. BANDNUMS is a scalar band number or an array
%   of band numbers.
%   
%   [A,R] = readgeoraster(___,'CoordinateSystemType',CTYPE) specifies
%   whether the raster is in geographic or projected coordinates. When
%   CTYPE is 'geographic', the raster is in geographic coordinates.  When
%   CTYPE is 'planar', the raster is in projected coordinates.  By default,
%   readgeoraster detects the CoordinateSystemType automatically.  Use this
%   name-value pair if readgeoraster is unable to detect the coordinate
%   system type.
%   
%   [A,R] = readgeoraster(___,'OutputType',OUTTYPE) specifies the data type
%   of A.  By default, readgeoraster returns A using the native data type
%   embedded in the file.  OUTTYPE can be a numeric type, such as
%   'uint16' or 'double', or 'logical'.
%   
%   [___,CMAP] = readgeoraster(___) returns the colormap of A. If A is not
%   an indexed image, CMAP is empty.
%   
%   Example:
%   --------
%   % Read and display the Boston GeoTIFF image. 
%   % Includes material (c) GeoEye, all rights reserved.
%   [A,R] = readgeoraster('boston.tif');
%   figure
%   mapshow(A,R)
%   axis image off
%   
%   See also georasterinfo

% Copyright 2019-2020 The MathWorks, Inc.

arguments
   filename (1,1) string
   namevalue.OutputType (1,1) string
   namevalue.Bands (:,1) {mustBeValidBands}
   namevalue.CoordinateSystemType (1,1) string
end

% Check filename
try
    filename = matlab.io.internal.validators.validateFileName(filename);
    % Choose the first match from the list of valid file names.
    filename = filename{1};
catch err
    throw(err)
end

% Check name-value pairs and pass them on to the internal reader if needed
args = {};

% CoordinateSystemType
coordinateSystemType = "auto";
if isfield(namevalue,'CoordinateSystemType')
    coordinateSystemType = validatestring(namevalue.CoordinateSystemType, ...
        ["auto", "geographic", "planar"]);
end

% OutputType
castToLogical = false;
if isfield(namevalue,'OutputType')
    validNumericTypes = ["native", "int16", "int32", "int64", ...
        "uint8", "uint16", "uint32", "uint64", "single", "double"];
    validNonNumericTypes = "logical";
    validTypes = [validNumericTypes validNonNumericTypes];
    outputFormat = validatestring(namevalue.OutputType, validTypes);
    args(end+1:end+2) = {'OutputType', outputFormat};
    
    % A non-numeric output was requested.
    castToLogical = matches(outputFormat,"logical");
end

% Read raster
try
    if isfield(namevalue,'Bands') && isnumeric(namevalue.Bands)
        % Read specific bands
        bands = namevalue.Bands;
        [A, refinfo] = readSpecifiedBands(filename, args, bands);
    else
        % Read all bands
        [A, refinfo] = readAllBands(filename, args);
    end
catch err
    throw(err)
end

if castToLogical
    A = logical(A);
end

% Create raster reference object
try
    R = constructRasterReference(refinfo, size(A,[1 2]), coordinateSystemType, filename);
catch err
    throw(err)
end

cmap = refinfo.Colormap./255;
end


function [A, refinfo] = readSpecifiedBands(filename, args, bands)
% Read raster data band-by-band and return a M x N x length(bands) matrix.
% refinfo is a struct containing raster reference information.
    
    if isscalar(bands)
        % No need to read multiple bands.
        [A, refinfo] = map.internal.io.readRasterData(...
            filename, args{:}, 'BandNumber', bands);
    else
        % More than one raster band is needed. Read each band and fill in
        % the returned raster A using these bands. Read the first band and
        % use refinfo to validate the remaining elements of bands.
        [Aband, refinfo] = map.internal.io.readRasterData(...
            filename, args{:}, 'BandNumber', bands(1));
        numBands = length(bands);
        if any(bands > refinfo.NumBands)
            idx = find(bands > refinfo.NumBands,1);
            error(message('map:io:OutOfRangeBand',bands(idx),refinfo.NumBands))
        end
        % Use the first band to determine the number of rows and columns
        A = zeros(size(Aband,1), size(Aband,2), numBands, 'like', Aband);
        A(:,:,1) = Aband;
        for iter = 2:numBands
            bandNumber = bands(iter);
            [Aband, refinfo] = map.internal.io.readRasterData(...
                filename, args{:}, 'BandNumber', bandNumber);
            A(:,:,iter) = Aband;
        end
    end
end


function [A, refinfo] = readAllBands(filename, args)
% Read raster data band-by-band and return a M x N x length(bands) matrix.
% refinfo is a struct containing raster reference information.
    
    % Read the first band and use refinfo to determine number of remaining bands.
    [Aband, refinfo] = map.internal.io.readRasterData(filename, args{:});
    numBands = refinfo.NumBands;
    
    if numBands > 1
        % More than one raster band is needed. Read each band and fill in
        % the returned raster A using these bands.
        
        % Use the first band to determine the number of rows and columns
        A = zeros(size(Aband,1), size(Aband,2), numBands, 'like', Aband);
        A(:,:,1) = Aband;
        
        for bandNumber = 2:numBands
            [Aband, refinfo] = map.internal.io.readRasterData(...
                filename, args{:}, 'BandNumber', bandNumber);
            A(:,:,bandNumber) = Aband;
        end
    else
        % No need to read multiple bands. The already read band is the only
        % band needed.
        A = Aband;
    end
end


function R = constructRasterReference(refinfo, sizeA, coordinateSystemType, filename)
% Determine spatial referencing information and construct a corresponding
% raster reference object

    cellsOrPostings = "cells";
    if strcmpi(refinfo.RasterInterpretation,'Point')
        cellsOrPostings = "postings";
    end
    
    hasTransform = ~isempty(refinfo.AffineTransformation);
    isGeocentric = refinfo.IsGeocentric;
    isLocal = refinfo.IsLocal;
    isProjected = refinfo.IsProjected;
    isGeographic = refinfo.IsGeographic;
    requestedGeographic = coordinateSystemType == "geographic";
    requestedPlanar = coordinateSystemType == "planar";
    
    if hasTransform && ~requestedPlanar && (isGeographic || requestedGeographic)
        % Geographic raster reference
        
        if requestedGeographic && (isLocal || isProjected || isGeocentric)
            [~, fname, fext] = fileparts(filename);
            error(message('map:io:InconsistentCRS','geographic', strcat(fname,fext)))
        end
        
        firstCornerLat = refinfo.AffineTransformation(2,3);
        firstCornerLon = refinfo.AffineTransformation(1,3);
        deltaLat = refinfo.AffineTransformation(2,2);
        deltaLon = refinfo.AffineTransformation(1,1);
        
        if cellsOrPostings == "postings"
            firstCornerLat = firstCornerLat + deltaLat/2;
            firstCornerLon = firstCornerLon + deltaLon/2;
        end
        
        try
            R = map.rasterref.internal.constructGeographicRasterReference(...
                sizeA, cellsOrPostings, firstCornerLat, firstCornerLon, ...
                deltaLat, 1, deltaLon, 1);
            
            if ~isempty(refinfo.WKT)
                if startsWith(refinfo.WKT, "BOUNDCRS")
                    % Strip the source CRS out of a bound CRS.
                    refinfo.WKT = extractBetween(string(refinfo.WKT),...
                        "SOURCECRS[" + whitespacePattern,...
                        "," + whitespacePattern + "TARGETCRS[");
                end
                R = map.rasterref.internal.setRasterReferenceCRS(R, refinfo.WKT);
            end
        catch
            % Unable to generate a valid raster reference object with the
            % provided information. The data in A may still have value, so
            % allow the function to continue by returning empty.
            R = [];
        end
        
    elseif hasTransform && (~isGeocentric || requestedPlanar)
        % Map raster reference
        
        if requestedPlanar && (isGeographic || isGeocentric)
            [~, fname, fext] = fileparts(filename);
            error(message('map:io:InconsistentCRS','planar',strcat(fname,fext)))
        end
        
        firstCornerX = refinfo.AffineTransformation(1,3);
        firstCornerY = refinfo.AffineTransformation(2,3);
        deltaX = refinfo.AffineTransformation(1,1);
        deltaY = refinfo.AffineTransformation(2,2);
        
        if cellsOrPostings == "postings"
            firstCornerX = firstCornerX + deltaX/2;
            firstCornerY = firstCornerY + deltaY/2;
        end
        
        try
            R = map.rasterref.internal.constructMapRasterReference(...
                sizeA, cellsOrPostings, firstCornerX, firstCornerY, ...
                refinfo.AffineTransformation(1:2,1:2), ones(2));
            
            if ~requestedPlanar && ...
                    (~isProjected && ~isLocal && ...
                    ~(R.YWorldLimits(1) < -90 || R.YWorldLimits(2) > 90) && ...
                    ~(R.XWorldLimits(1) < -540 || R.XWorldLimits(2) > 540))
                % If the CoordinateSystemType was not specified, the
                % coordinate system information not detected and the limits
                % within an ambiguous range, warn that the coordinate
                % system type is ambiguous and may need to be specified.
                [~, fname, fext] = fileparts(filename);
                warning(message('map:io:SpecifyCoordinateSystemType',strcat(fname,fext)))
            end
            
            if ~isempty(refinfo.WKT)
                if startsWith(refinfo.WKT, "BOUNDCRS")
                    % Strip the source CRS out of a bound CRS.
                    refinfo.WKT = extractBetween(string(refinfo.WKT),...
                    "SOURCECRS[" + whitespacePattern,...
                    "," + whitespacePattern + "TARGETCRS[");
                end
                R = map.rasterref.internal.setRasterReferenceCRS(R, refinfo.WKT);
            end
        catch
            % Unable to generate a valid raster reference object with the
            % provided information. The data in A may still have value, so
            % allow the function to continue by returning empty.
            R = [];
        end
    else
        % No referencing information detected
        R = [];
    end
end

function mustBeValidBands(bands)
    bands = convertStringsToChars(bands);
    mustBeNonempty(bands)
    if ~ischar(bands) || ~strncmpi(bands,'all',numel(bands)) 
        mustBeNumeric(bands)
        mustBePositive(bands)
        mustBeInteger(bands)
    end
end
