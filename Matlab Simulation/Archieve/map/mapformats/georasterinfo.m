function info = georasterinfo(filename)
%GEORASTERINFO Information about geospatial raster data file
%   georasterinfo gets information about geographic and projected raster
%   data files. Supported formats include Esri Binary Grid, Esri
%   GridFloat, GeoTIFF, and DTED.
%   
%   INFO = georasterinfo(FILENAME) returns a RasterInfo object INFO for the
%   raster data file specified by FILENAME.  FILENAME must be in the
%   current directory, in a directory on the MATLAB path, or include a full
%   or relative path to a file.
%   
%   Example:
%   --------
%   % Get information about the Boston GeoTIFF image. 
%   % Includes material (c) GeoEye, all rights reserved.
%   info = georasterinfo('boston.tif');
%   info.NumBands
%   
%   See also readgeoraster

% Copyright 2019-2020 The MathWorks, Inc.
    
    arguments
        filename (1,1) string
    end
    
    % Check filename
    try
        filename = matlab.io.internal.validators.validateFileName(filename);
        % Choose the first match from the list of valid file names.
        filename = filename{1};
    catch err
        throw(err)
    end
    
    try
        refinfo = map.internal.io.getRasterDataInfo(filename);
        refinfo.Colormap = refinfo.Colormap./255;
        if ~isempty(refinfo.WKT)
            if startsWith(refinfo.WKT, "BOUNDCRS")
                % Strip the source CRS out of a bound CRS.
                refinfo.WKT = extractBetween(string(refinfo.WKT),...
                    "SOURCECRS[" + whitespacePattern,...
                    "," + whitespacePattern + "TARGETCRS[");
            end
            if refinfo.IsGeographic
                refinfo.CoordinateReferenceSystem = geocrs(refinfo.WKT);
            elseif refinfo.IsProjected
                refinfo.CoordinateReferenceSystem = projcrs(refinfo.WKT);
            end
        end
        refinfo.RasterReference = constructRasterReference(refinfo, filename);
        refinfo.FileFormat = standardizeFileFormatName(refinfo.FileFormat, filename);
        refinfo.FileModifiedDate = datetime(fileModDates(refinfo.Filename),'ConvertFrom','datenum');
        refinfo.Filename = refinfo.Filename';
        if ~isempty(refinfo.MetadataFields)
            % Only create and add the Metadata struct to refinfo if there
            % is additional metadata in the file. Otherwise, do not create
            % the Metadata field in the refinfo struct. The refinfo struct
            % is handed to map.io.RasterInfo. Without the Metadata field,
            % the RasterInfo Metadata property will be empty.
            s = struct;
            mfields = matlab.lang.makeValidName(refinfo.MetadataFields);
            for fieldidx = 1:length(refinfo.MetadataFields)
                s.(mfields(fieldidx)) = refinfo.MetadataValues(fieldidx);
            end
            refinfo.Metadata = s;
        end
    catch err
        throw(err)
    end
    
    info = map.io.RasterInfo(refinfo);
end


function datenums = fileModDates(fnames)
% Return datenums corresponding to file names. Use datenum instead of date
% to have consistent behavior on all locales.
    if ~isempty(fnames)
        try
            numnames = length(fnames);
            datenums = nan(1,numnames,'double');
            for idx = 1:numnames
                d = dir(fnames(idx));
                datenums(idx) = d(1).datenum;
            end
        catch
            datenums = [];
        end
    else
        datenums = [];
    end
end


function R = constructRasterReference(refinfo, filename)
% Determine spatial referencing information and construct a corresponding
% raster reference object

    cellsOrPostings = "cells";
    if strcmpi(refinfo.RasterInterpretation,'Point')
        cellsOrPostings = "postings";
    end
    
    hasTransform = ~isempty(refinfo.AffineTransformation);
    isGeocentric = refinfo.IsGeocentric;
    isGeographic = refinfo.IsGeographic;
    isProjected = refinfo.IsProjected;
    isLocal = refinfo.IsLocal;
    
    if hasTransform && isGeographic
        % Geographic raster reference
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
                refinfo.RasterSize, cellsOrPostings, firstCornerLat, firstCornerLon, ...
                deltaLat, 1, deltaLon, 1);
            
            if isfield(refinfo,'CoordinateReferenceSystem')
               R = map.rasterref.internal.setRasterReferenceCRS(R, refinfo.CoordinateReferenceSystem);
            end
        catch
            % Unable to generate a valid raster reference object with the
            % provided information. The other metadata may still have
            % value, so allow the function to continue by returning empty.
            R = [];
        end
        
    elseif hasTransform && ~isGeocentric
        % Map raster reference
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
                refinfo.RasterSize, cellsOrPostings, firstCornerX, firstCornerY, ...
                refinfo.AffineTransformation(1:2,1:2), ones(2));
            
            if (~isProjected && ~isLocal && ...
                    ~(R.YWorldLimits(1) < -90 || R.YWorldLimits(2) > 90) && ...
                    ~(R.XWorldLimits(1) < -540 || R.XWorldLimits(2) > 540))
                % Warn that the coordinate system type is ambiguous. The
                % coordinate system information is not detected and the
                % limits are within an ambiguous range.
                [~, fname, fext] = fileparts(filename);
                warning(message('map:io:UnableToDetermineCoordinateSystemType',strcat(fname,fext)))
            end
            
            if isfield(refinfo,'CoordinateReferenceSystem')
               R = map.rasterref.internal.setRasterReferenceCRS(R, refinfo.CoordinateReferenceSystem);
            end
        catch
            % Unable to generate a valid raster reference object with the
            % provided information. The other metadata may still have
            % value, so allow the function to continue by returning empty.
            R = [];
        end
    else
        % No referencing information detected
        R = [];
    end
end


function newName = standardizeFileFormatName(oldName, filename)
    % Convert file format names to standardized ones
    switch oldName
        case "GTiff"
            % Determine if the file is a GeoTIFF or a regular TIFF.
            try
                T = Tiff(filename);
                Tobj = onCleanup(@()close(T));
                
                % The GeoKeyDirectoryTag is mandatory for GeoTIFF files. If
                % there is no GeoKeyDirectoryTag, getTag will error.
                getTag(T,'GeoKeyDirectoryTag');
                
                newName = "GeoTIFF";
            catch
                newName = "TIFF";
            end
        case "HFA"
            newName = "ERDAS IMAGINE";
        case "ERS"
            newName = "ER Mapper ERS";
        case "AIG"
            newName = "Esri Binary Grid";
        case "AAIGrid"
            newName = "Esri ASCII Grid";
        case "EHdr"
            newName = "Esri GridFloat";
        case "NWT_GRD"
            newName = "Vertical Mapper Numeric Grid";
        case "NWT_GRC"
            newName = "Vertical Mapper Classified Grid";
        case "USGSDEM"
            newName = "USGS DEM";
        otherwise
            newName = oldName;
    end
end
