function [R, rasterSize] = arcGridHeaderToCellsReference(hdr, coordinateSystemType)
% arcGridHeaderToCellsReference Derive raster reference from ArcGRID header
%
%   Input Arguments
%   ---------------
%   hdr - Scalar struct with 6 string-valued fields: ncols, nrows, xllcorner
%         or xllcenter, yllcorner or yllcenter, and cellsize. Each string
%         contains a numeric value.
%
%   coordinateSystemType - String: 'geographic', 'planar', or 'unspecified'
%
%   Output Argument
%   ---------------
%   R - Geographic cells reference object, map cells reference object, or
%       referencing matrix, depending on the value of coordinateSystemType.
%
%   rasterSize - Numbers of rows and columns in the raster, returned as a
%       1-by-2 vector of class double.

% Copyright 2015-2020 The MathWorks, Inc.

    switch(coordinateSystemType)
        case 'geographic'
            R = headerToGeographicCellsReference(hdr);
            rasterSize = R.RasterSize;
            
        case 'planar'
            R = headerToMapCellsReference(hdr);
            rasterSize = R.RasterSize;
            
        otherwise
            [R, rasterSize] = headerToReferencingMatrix(hdr);    
    end
end


function R = headerToGeographicCellsReference(hdr)
% Construct a scalar map.rasterref.GeographicCellsReference object R with
% R.ColumnsStartFrom equal to 'north'.

    rasterSize = [str2double(hdr.nrows) str2double(hdr.ncols)];

    [cellsizenum, cellsizeden] = str2rat(hdr.cellsize);

    if isfield(hdr,'xllcorner')
        [num, den] = str2rat(hdr.xllcorner);
        firstCornerLon = num/den;
    else
        [num, den] = str2rat(hdr.xllcenter);
        firstCornerLon = (2*num/den - cellsizenum/cellsizeden)/2;
    end

    if isfield(hdr,'yllcorner')
        [num, den] = str2rat(hdr.yllcorner);
        firstCornerLat = num/den;
    else
        [num, den] = str2rat(hdr.yllcenter);
        firstCornerLat = (2*num/den - cellsizenum/cellsizeden)/2;
    end

    R = map.rasterref.GeographicCellsReference(rasterSize, ...
        firstCornerLat, firstCornerLon, ...
        cellsizenum, cellsizeden, cellsizenum, cellsizeden);

    R.ColumnsStartFrom = 'north'; 
end


function R = headerToMapCellsReference(hdr)
% Construct a scalar map.rasterref.MapCellsReference object R with
% R.ColumnsStartFrom equal to 'north'.

    rasterSize = [str2double(hdr.nrows) str2double(hdr.ncols)];

    [cellsizenum, cellsizeden] = str2rat(hdr.cellsize);

    if isfield(hdr,'xllcorner')
        [num, den] = str2rat(hdr.xllcorner);
        firstCornerX = num/den;
    else
        [num, den] = str2rat(hdr.xllcenter);
        firstCornerX = (2*num/den - cellsizenum/cellsizeden)/2;
    end

    if isfield(hdr,'yllcorner')
        [num, den] = str2rat(hdr.yllcorner);
        firstCornerY = num/den;
    else
        [num, den] = str2rat(hdr.yllcenter);
        firstCornerY = (2*num/den - cellsizenum/cellsizeden)/2;
    end
    
    jacobianNumerator   = [cellsizenum 0; 0 cellsizenum];
    jacobianDenominator = cellsizeden + zeros(2,2);

    R = map.rasterref.MapCellsReference(rasterSize, firstCornerX, ...
                firstCornerY, jacobianNumerator, jacobianDenominator);
            
    R.ColumnsStartFrom = 'north'; 
end


function [refmat, rasterSize] = headerToReferencingMatrix(hdr)
% Construct a 2-by-3 referencing matrix for a raster with columns running
% north to south.

    ncols = str2double(hdr.ncols);
    nrows = str2double(hdr.nrows);

    cellsize = str2double(hdr.cellsize);

    if isfield(hdr,'xllcorner')
        xllcorner = str2double(hdr.xllcorner);
        xllcenter = xllcorner + cellsize/2;
    else
        xllcenter = str2double(hdr.xllcenter);
    end

    if isfield(hdr,'yllcorner')
        yllcorner = str2double(hdr.yllcorner);
        yllcenter = yllcorner + cellsize/2;
    else
        yllcenter = str2double(hdr.yllcenter);
    end

    x11 = xllcenter;
    y11 = yllcenter + (nrows - 1) * cellsize;

    W = [cellsize      0       x11;
            0      -cellsize   y11];
    refmat = map.internal.referencingMatrix(W);
    rasterSize = [nrows ncols];
end
