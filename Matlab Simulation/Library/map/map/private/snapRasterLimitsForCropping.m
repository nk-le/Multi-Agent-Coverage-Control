function [first, last] = snapRasterLimitsForCropping(intrinsicLimits, ...
    numRowsOrColumns, rasterInterpretation, full360InLongitude)

% Snap limits in intrinsic X or Y to column or row limits
%
%   Inputs
%   ------
%   intrinsicLimits -- Raster limits in intrinsic X or Y
%   numberOfRowsOrColumns -- Columns for X, rows for Y
%   rasterInterpretation -- "cells" or "postings"
%
%   full360InLongitude -- True for a geographic raster that spans 360
%      degrees + requested longitude limits that also span 360 degrees
%      Needed only when cropping in longitude.
%
%   Outputs
%   -------
%   first -- Index of first column or row to be copied from input raster
%   last  -- Index of last column or row to be copied from input raster

% Copyright 2019-2020 The MathWorks, Inc.

    if nargin < 4
        full360InLongitude = false;
    end
    
    if strcmp(rasterInterpretation,"cells")
        % Snap cell limits.
        first = floor(intrinsicLimits(1) + 0.5);
        last  = ceil( intrinsicLimits(2) - 0.5);
    else
        % Snap postings limits.
        first = floor(intrinsicLimits(1));
        last  = ceil( intrinsicLimits(2));
    end
    
    % Constrain limits to fall within the input raster.
    first = max(1, min(numRowsOrColumns, first));
    last  = max(1, min(numRowsOrColumns, last));
    
    % Adjust limits to ensure at least two columns or rows.
    if full360InLongitude
        if last == first
            % Avoid overlapping columns given a geographic raster that
            % spans 360 degrees + requested longitude limits that span 360.
            if last > 1
                last = last - 1;
            else % first == last == 1
                ncols = numRowsOrColumns;  % Longitude ==> columns
                last = ncols;
            end
        end
    else
        if last == first
            % Add an extra row or column: Input limits are very close or
            % identical. Decrease first or increase last to ensure
            % that first < last, so that we return 2 rows or columns
            % (the minimum number allowed).
            if first > 1
                first = first - 1;
            else % first == last == 1
                last = last + 1;
                % This code is reached only for cells. With postings, both
                % elements of intrinsicLimits would have to fall on the
                % first horizontal or vertical edge, but then there would
                % be no overlap.
            end
        elseif last + 1 == first
            % Limits specify two rows or columns, but are reversed.
            % This happens in the case of cells if, for some integer M,
            % intrinsicLimits(1) == intrinsicLimits(2) == M + 0.5 on input.
            % Then, after snapping, intrinsicLimits(2) == M and
            % intrinsicLimits(1) == M + 1. Correct by swapping the limits.
            t = first;
            first = last;
            last = t;
        end
    end
end
