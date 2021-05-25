classdef (Sealed = true) IntrinsicCellsReference ...
        < map.rasterref.internal.IntrinsicRasterReference
%IntrinsicRaster Intrinsic coordinates for raster of cells
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the feature
%       itself may be removed in a future release.
%
%   For two-dimensional cell-type raster grids and images,
%   IntrinsicCellsReference objects implement and encapsulate the aspects
%   of spatial referencing that are independent of any external spatial
%   coordinate system.
%
%   map.rasterref.internal.IntrinsicCellReference properties:
%     NumRows    - Number of rows
%     NumColumns - Number of columns
%
%   map.rasterref.internal.IntrinsicCellsReference methods:
%     limits              - Limits of raster in intrinsic X and Y
%     sizesMatch          - True if object and raster/image are size-compatible
%     contains            - True if raster contains points
%     intrinsicToDiscrete - Transform intrinsic coordinates to discrete subscripts
%     setRasterSize - Update NumRows and NumColumns given a size vector
%     cropAndSubsampleLimits1D - Limits for cropping/subsampling in a single dimension
%
%     For an M-by-N raster of cells, contains(I,x,y) is true only when
%     both of the following are true:
%
%          0.5 <= x <= M + 0.5
%          0.5 <= y <= N + 0.5

% Copyright 2013-2018 The MathWorks, Inc.

    properties
        % Number of rows and columns in associated raster
        NumRows    = 2;
        NumColumns = 2;
    end
    
    properties (Constant)
        ElementsMinusIntervals = 0
    end
    
    
    methods
        function I = set.NumRows(I, numRows)
            validateattributes(numRows, {'double'}, ...
                {'row', 'positive', 'integer', 'finite'},'','NumRows')
            I.NumRows = numRows;
        end


        function I = set.NumColumns(I, numColumns)
            validateattributes(numColumns, {'double'}, ...
                {'row', 'positive', 'integer', 'finite'},'','NumColumns')
            I.NumColumns = numColumns;
        end
        
        
        function [xlimits, ylimits] = limits(I)
            %limits Limits of raster in intrinsic X and Y
            xlimits = 0.5 + [0 I.NumColumns];
            ylimits = 0.5 + [0 I.NumRows];
        end
        
        
        function  offset = scaledOffset(~, scale)
            % Location of first scaled sample computed by scaleRaster(), in
            % the dimension corresponding to scale, excluding a possible
            % shift needed to preserve the raster center
            offset = (1 + 1/scale) / 2;
        end
        
        
        function [a,b,first,last] = cropAndSubsampleLimits1D(I,d,f,limits)
            %cropAndSubsampleLimits1D Limits for cropping/subsampling in a single dimension
            %
            %   [a, b, first, last] = cropAndSubsampleLimits1D(I,d,f,limits)
            %   Working in one dimension at a time, select the first and
            %   last row or column indices to use when subsampling a
            %   cell-oriented raster grid, given user-specified limits, and
            %   revise the limits to match a set of output cells with cell
            %   extent exactly equal to f * (input cell extent).
            %
            %     d - Dimension (1 for intrinsic Y, 2 for intrinsic X)
            %     f - Subsampling factor (positive integer; 1 <= f <= n)
            %     limits - Limits in intrinsic coordinates
            %
            %   Intrinsic coordinates are defined such that center of the
            %   k-th cell falls at the value x = k on the real line. The
            %   limits of the input raster are thus 0.5 and 0.5 + n.
            %
            %   a and b are real numbers such that 0.5 <= a, a < b, and b <
            %   0.5 + n, that result from snapping the input limits to the
            %   grid while respecting other constraints as well.
            
            % Preliminaries
            n = rasterSize(I,d);
            a = max(0.5, min(limits));
            b = min(n + 0.5, max(limits));
            
            % Step 1 -- Determine the number of output cells
            
            % Candidate for number of output cells
            m = ceil((b - a) / f);
            
            while f*m > n
                % We don't have enough input cells available to create m
                % output cells, so decrease the number of output cells.
                m = m - 1;
            end
            
            % Step 2 -- Estimate the indices of the first and last input
            % cells to be covered by the output cells, by starting from an
            % integer close to the average of a and b, and going
            % (approximately, in the case of even f*m) an equal distance to
            % either side. Note that this definition of first and last
            % differs from the specification given in the help above.
            % That's OK, we'll use these intermediate values, then adjust
            % them at the end.
            if mod(f*m,2) == 0
                % f*m is even; we need to cover 2*h input cells. f*m/2
                % should be an integer, but just in case floating point
                % round off causes it to depart (very slight) from an
                % integer value, snap it back with round().
                h = round(f*m/2);
                c = round((a + b - 1)/2);
                first = c - (h - 1);
                last  = c + h;
            else
                % f*m is odd; we need to cover 2*h + 1 input cells. As
                % above, apply round() just in case (f*m - 1)/2 takes on a
                % slightly non-integer floating point value.
                h = round((f*m - 1)/2);
                c = round((a + b)/2);
                first = c - h;
                last  = c + h;
            end
            
            % Step 3 -- If our estimated range of input indices falls too
            % far to the left, move it to the right. Likewise, if it falls
            % too far to the right, move it to the left. Because we've
            % already ensure that f * m <= n, only one of these conditions
            % can hold at a time.
            if first < 1
                % Shift to the right by (1 - first), which is a positive value.
                last = last + (1 - first);
                first = 1;
            elseif last > n
                % Shift to the left by (last - n), which is a positive value.
                first = first - (last - n);
                last = n;
            end
            
            % Step 4 -- Re-assign the limits (in intrinsic coordinates) to
            % match the extent spanned by the selected input cells.
            a = first - 0.5;
            b = last  + 0.5;
            
            % Step 5 -- Now adjust first and last to correspond to the
            % indices of the first and last samples to be taken from the
            % input grid, thus matching their definition in the help.
            if mod(f,2) == 0
                h = round(f/2);
                first = first + h - 1;
                last  = last - h;
            else
                % Note: when f == 1, we end up here and h == 0.
                h = round((f - 1)/2);
                first = first + h;
                last  = last - h;
            end
        end
    end
end
