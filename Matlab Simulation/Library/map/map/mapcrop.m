function [B, RB] = mapcrop(A, RA, xlimits, ylimits)
%MAPCROP Crop a projected raster
%
%   [B,RB] = MAPCROP(A,RA,XLIMITS,YLIMITS) crops an input raster A to the
%   limits in world coordinates specified by the 1-by-2 vectors XLIMITS and
%   YLIMITS and returns the cropped result in B. A and B are numeric or
%   logical rasters, and B is the same type as A. RA is a map raster
%   reference object that specifies the location and extent of data in A.
%   RB is a map raster reference object associated with the output raster
%   B. If the specified limits do not intersect the input raster, then both
%   B and RB are empty.
%
%   Example
%   -------
%   [A,RA] = readgeoraster('boston.tif');
%   xlimits = [ 771660   773290];
%   ylimits = [2953410  2955240];
%   [B,RB] = mapcrop(A,RA,xlimits,ylimits);
%   figure
%   mapshow(B,RB)
%
%   See also geocrop, mapinterp, maprefcells, maprefpostings, mapresize

% Copyright 2019-2020 The MathWorks, Inc.

    % Validate arguments
    arguments
        A {mustBeNumericOrLogical, mustBeReal, mustBeNonsparse, mustBeNonempty, mustBe2Dor3DRaster}
        RA {mustBeMapRasterReference(RA, 1, "mapcrop", "geocrop")}  % Includes check for scalar
        xlimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
        ylimits (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits}
    end    
    validateRasterSizeConsistency(A,RA)
    
    % Input limits can be any numeric type; use double
    % to ensure that full precision is maintained.
    xlimits = double(xlimits);
    ylimits = double(ylimits);
    
    if limitsOverlap(RA, xlimits, ylimits)
        % Compute intrinsic limits. Note that xi and yi are unsorted.
        [xlimi, ylimi] = worldToIntrinsic(RA, xlimits, ylimits);
        
        % Snap intrinsic limits outward, defining row and column limits
        % that are constrained to fall within the input raster.
        
        [firstrow, lastrow] = rowLimitsFromYLimits(RA, ylimi);
        [firstcol, lastcol] = columnLimitsFromXLimits(RA, xlimi);
        
        % Extract a sub-block and compute its raster reference.
        B = A(firstrow:lastrow, firstcol:lastcol, :);
        RB = maprefblock(RA, [firstrow lastrow], [firstcol lastcol]);
    else
        % Rectangle defined by input limits does not overlap the raster.
        B = A([],[],:);
        RB = [];
    end
end


function mustBeMapRasterReference(R, rectilinearOnly, mapfuncname, geofuncname)
% Inputs
%    R - Raster reference object
%    rectilinearOnly - True if calling function is supported only for rectilinear map rasters
%    mapfuncname - Name function that operates on map rasters
%    geofuncname - Name function that operates on geographic rasters

    if isa(R,'map.rasterref.MapRasterReference')
        % R is a MapRasterReference object, but it might be nonscalar, or
        % it might be rectilinear.
        if ~isscalar(R)            
            error(message('map:validators:mustBeScalarRasterReference'))
        elseif rectilinearOnly && R.TransformationType ~= "rectilinear"
            error(message('map:validators:mustBeRectilinearRaster'));
        end
    else
        % R is not a MapRasterReference object.
        msg = message('map:validators:mustBeMapRasterReference');
        if isscalar(R) && isa(R,'map.rasterref.GeographicRasterReference')
            % R is a scalar GeographicRasterReference; perhaps the
            % user meant to call geocrop instead of mapcrop.
            errorID = 'map:validators:useGeographicRasterFunction';
            str = string(getString(msg)) + " " ...
                + string(getString(message(errorID, geofuncname, mapfuncname)));
            throw(MException(errorID, str));
            
            % To do: Include the following, if it becomes possible to use
            %        it within an argument validation function.
            %
            % ric = matlab.lang.correction.ReplaceIdentifierCorrection(mapfuncname,geofuncname);
        else
            error(msg)
        end
    end
end


function tf = limitsOverlap(RA, xlimits, ylimits)
% Return true if the rectangle defined by xlimits and ylimits overlaps the
% bounding rectangle of the raster referenced by RA.  If the rectangles
% touch but are merely tangent, return false.
    noOverlapInX = (xlimits(2) <= RA.XWorldLimits(1)) || (xlimits(1) >= RA.XWorldLimits(2));
    noOverlapInY = (ylimits(2) <= RA.YWorldLimits(1)) || (ylimits(1) >= RA.YWorldLimits(2));
    tf = ~(noOverlapInX || noOverlapInY);
end


function [firstrow, lastrow] = rowLimitsFromYLimits(RA, ylimi)
    % Adjust for north-to-south orientation.
    if strcmp(RA.ColumnsStartFrom,"north")
        ylimi = flip(ylimi);
    end
    
    nrows = RA.RasterSize(1);
    [firstrow, lastrow] = snapRasterLimitsForCropping( ...
        ylimi, nrows, RA.RasterInterpretation);
end


function [firstcol, lastcol] = columnLimitsFromXLimits(RA, xlimi)
    % Adjust for east-to-west orientation.
    if strcmp(RA.RowsStartFrom,"east")
        xlimi = flip(xlimi);
    end
    
    ncols = RA.RasterSize(2);
    [firstcol, lastcol] = snapRasterLimitsForCropping( ...
        xlimi, ncols, RA.RasterInterpretation);    
end
