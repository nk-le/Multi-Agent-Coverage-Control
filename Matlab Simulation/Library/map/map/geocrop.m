function [B, RB] = geocrop(A, RA, latlim, lonlim)
%GEOCROP Crop a geographic raster
%
%   [B,RB] = GEOCROP(A,RA,LATLIM,LONLIM) crops an input raster A to the
%   latitude-longitude limits specified by the 1-by-2 vectors LATLIM and
%   LONLIM and returns the cropped result in B. A and B are numeric or
%   logical rasters, and B is the same type as A. RA is a geographic raster
%   reference object that specifies the location and extent of data in A.
%   RB is a geographic raster reference object associated with the output
%   raster B. If the specified limits do not intersect the input raster,
%   then both B and RB are empty.
%
%   Example
%   -------
%   % Extract part of a 1-degree-by-1-degree SRTM elevation grid. The DTED
%   % data used in this example is courtesy of the U.S. Geological Survey.
%   [A,RA] = readgeoraster('n39_w106_3arc_v2.dt1','OutputType','double');
%   latlim = [  39.5   39.9];
%   lonlim = [-105.8 -105.2];
%   [B,RB] = geocrop(A,RA,latlim,lonlim);
%   figure
%   geoshow(B,RB,'DisplayType','surface')
%   demcmap(B)
%
%   See also geointerp, georefcells, georefpostings, georesize, mapcrop

% Copyright 2019-2020 The MathWorks, Inc.

    % Validate arguments
    arguments
        A {mustBeNumericOrLogical, mustBeReal, mustBeNonsparse, mustBeNonempty, mustBe2Dor3DRaster}
        RA {mustBeGeographicRasterReference(RA, "geocrop", "mapcrop")}  % Includes check for scalar
        latlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeNondecreasingLimits, ...
            mustBeGreaterThanOrEqual(latlim, -90), mustBeLessThanOrEqual(latlim,90)}
        lonlim (1,2) {mustBeNumeric, mustBeReal, mustBeFinite}
    end    
    validateRasterSizeConsistency(A,RA)
    
    % Input limits can be any numeric type; use double
    % to ensure that full precision is maintained.
    latlim = double(latlim);
    lonlim = double(lonlim);
    
    [firstrow, lastrow] = rowLimitsForCropping(RA, latlim);
    if isempty(firstrow)
        % No overlap in latitude (with edge-only intersections excluded).
        B = A([],[],:);
        RB = [];
    else
        [firstcol, lastcol] = columnLimitsForCropping(RA, lonlim);
        if isempty(firstcol)
        % No overlap in longitude (with edge-only intersections excluded).
            B = A([],[],:);
            RB = [];
        else
            % Extract a sub-block and compute its raster reference.
            [RB, rows, cols] = georefblock(RA, [firstrow lastrow], [firstcol lastcol]);
            if RB.LongitudeLimits(2) > 360
                RB.LongitudeLimits = RB.LongitudeLimits - 360;
            end
            B = A(rows, cols, :);
        end
    end
end


function mustBeGeographicRasterReference(R, geofuncname, mapfuncname)
% Inputs
%    R - Raster reference object
%    geofuncname - Name function that operates on geographic rasters
%    mapfuncname - Name function that operates on map rasters

    if isa(R,'map.rasterref.GeographicRasterReference')
        if ~isscalar(R)
            error(message('map:validators:mustBeScalarRasterReference'))
        end
    else
        % R is not a GeographicRasterReference object.
        msg = message('map:validators:mustBeGeographicRasterReference');
        if isscalar(R) && isa(R,'map.rasterref.MapRasterReference')
            % R is s scalar MapRasterReference object; perhaps the
            % user meant to call mapcrop instead of geocrop.
            errorID = 'map:validators:useMapRasterFunction';
            str = string(getString(msg)) + " " ...
                + string(getString(message(errorID, mapfuncname, geofuncname)));
            throw(MException(errorID, str));
            
            % To do: Include the following, if it becomes possible to use
            %        it within an argument validation function.
            %
            % ric = matlab.lang.correction.ReplaceIdentifierCorrection(geofuncname,mapfuncname);
        else
            error(msg)
        end
    end
end


function [firstrow, lastrow] = rowLimitsForCropping(RA, latlim)
% Intersect raster latitude limits with a latitude limits vector, returning
% empty for non-intersecting limits and for edge-only intersections.

    latlim = intersectLatitudeLimits(RA, latlim);
    if isempty(latlim)
        firstrow = [];
        lastrow  = [];
    else
        [firstrow, lastrow] = rowLimitsFromLatitudeLimits(RA, latlim);
    end
end


function latlim = intersectLatitudeLimits(RA, latlim)
% Intersect raster latitude limits with a latitude limit vector, returning
% empty for non-intersecting limits and for edge-only intersections.

    lim1 = RA.LatitudeLimits;
    lim2 = latlim;
    if ((lim2(2) < lim1(1)) || (lim1(2) < lim2(1)))
        latlim = [];
    else
        latlim(1) = max(lim1(1), lim2(1));
        latlim(2) = min(lim1(2), lim2(2));
        if latlim(1) == latlim(2)
            if ~(RA.LatitudeLimits(1) < latlim(1) && latlim(1) < RA.LatitudeLimits(2))
                % Filter edge-only intersection.
                latlim = [];
            end
        end
    end
end


function [firstrow, lastrow] = rowLimitsFromLatitudeLimits(RA, latlim)
% RA is the referencing object for the input raster. ylimi specifies the
% requested limits after conversion to intrinsic coordinates. The outputs
% indicate the first and last rows to be copied from the input raster.

    ylimi = latitudeToIntrinsicY(RA,latlim);
    
    % Adjust for north-to-south orientation.
    if strcmp(RA.ColumnsStartFrom,"north")
        ylimi = flip(ylimi);
    end
    
    nrows = RA.RasterSize(1);
    [firstrow, lastrow] = snapRasterLimitsForCropping( ...
        ylimi, nrows, RA.RasterInterpretation);
end


function [firstcol, lastcol] = columnLimitsForCropping(RA, lonlim)
% Intersect raster longitude limits with a longitude limits vector,
% returning empty for non-intersecting limits and for edge-only
% intersections.
    
    lonlim = intersectLongitudeLimits(RA, lonlim);
    if isempty(lonlim)
        firstcol = [];
        lastcol  = [];
    elseif isequal(size(lonlim), [1 2])
        [firstcol, lastcol] = columnLimitsFromLongitudeLimits(RA, lonlim);
    else
        % Limits overlap in two separate, disjoint regions. There's no
        % way to define reasonable expectations for output in this case.
        error(message('map:spatialref:twoRegionsOfOverlap','geocrop'))
    end
end


function lonlim = intersectLongitudeLimits(RA, lonlim)
% Find all intersection(s) between the quadrangle defined by the raster's
% geographic limits and quadrangle defined by the input limits (using
% latitude limits of [-90 90] for both, because this function is only
% concerned with longitude limits). There could be 0, 1, or 2 intersections.
% On output, the number of intersections is given by n = size(lonlim,1).
    
    if RA.RasterExtentInLongitude < 360
        [~, lonlimI] = intersectgeoquad([-90 90], lonlim, [-90 90], RA.LongitudeLimits);
        
        % lonlimI can contain:
        %
        %    No rows (no overlap)
        %    One row (one zone of overlap)
        %    Two rows (two zones of overlap)
        %
        % In the second and third cases, the intersections may be zero-area
        % quadrangles with identical eastern and western limits. If they
        % fall on the edge of the raster, they need to be filtered out.
        
        lonlim = [];
        n = size(lonlimI,1);
        for k = 1:n
            intersectsOnlyOnEdge = false;
            if lonlimI(k,1) == lonlimI(k,2)
                xi = longitudeToIntrinsicX(RA, lonlimI(k,1));
                if ~(RA.XIntrinsicLimits(1) < xi && xi < RA.XIntrinsicLimits(2))
                    intersectsOnlyOnEdge = true;
                end
            end
            if ~intersectsOnlyOnEdge
                lonlim(end+1,:) = lonlimI(k,:); %#ok<AGROW>
            end
        end
    end
end


function [firstcol, lastcol] = columnLimitsFromLongitudeLimits(RA, lonlim)
% RA is the referencing object for the input raster. xlimi specifies the
% requested limits after conversion to intrinsic coordinates. The outputs
% indicate the range of columns to be copied from the input raster.

    ncols = RA.RasterSize(2);
    inputSpans360 = (RA.RasterExtentInLongitude == 360);
    
    % Compute intrinsic limits. They may be increasing or decreasing.
    xlimi = longitudeToIntrinsicX(RA, lonlim);
    
    % Adjust for east-to-west orientation.
    if strcmp(RA.RowsStartFrom,"east")
        xlimi = flip(xlimi);
    end
    
    if strcmp(RA.RasterInterpretation,"cells")
        % Resolve 0.5 / ncols + 0.5 ambiguity in 360-degree input case.
        if inputSpans360
            if xlimi(1) >= ncols + 0.5
                xlimi(1) = 0.5;
            end
            if xlimi(2) <= 0.5
                xlimi(2) = ncols + 0.5;
            end
        end
    end
    
    % It's possible that xlimi(1) == xlimi(2). This could happen because
    % (a) a single point or meridian segment was requested or (b) a full
    % 360 degrees were requested. It's important to know which is the case.
    full360Requested = abs(lonlim(2) - lonlim(1)) == 360;
    
    full360InLongitude = inputSpans360 && full360Requested;
    
    [firstcol, lastcol] = snapRasterLimitsForCropping(xlimi, ...
        ncols, RA.RasterInterpretation, full360InLongitude);
end
