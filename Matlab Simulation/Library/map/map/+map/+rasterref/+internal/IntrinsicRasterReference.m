classdef IntrinsicRasterReference
%IntrinsicRaster Intrinsic coordinates for 2-D image or raster
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the feature
%       itself may be removed in a future release.
%
%   For two-dimensional raster grids and images, IntrinsicRasterReference
%   objects encapsulate the aspects of spatial referencing that are
%   independent of any external spatial coordinate system.
%
%   map.rasterref.internal.IntrinsicRasterReference public methods:
%     limits (Abstract)   - Limits of raster in intrinsic X and Y
%     sizesMatch          - True if object and raster/image are size-compatible
%     contains            - True if raster contains points
%     intrinsicToDiscrete - Transform intrinsic coordinates to discrete subscripts
%     setRasterSize - Update NumRows and NumColumns given a size vector
%
%   map.rasterref.internal.IntrinsicRasterReference protected methods:
%     rasterSize          - Size of specified dimension

% Copyright 2013-2018 The MathWorks, Inc.

    %------------------------- Public Properties --------------------------
    
    properties (Abstract)
        % Number of rows and columns in associated raster
        NumRows
        NumColumns
    end
    
    properties (Abstract, Constant)
        % Difference between number of elements along a given dimension
        % minus the number of intervals between samples along that
        % dimension (0 for cells, 1 for postings)
        ElementsMinusIntervals
    end
    
    %-------------------------- Abstract Methods --------------------------
    
    methods (Abstract)
        [xlimits, ylimits] = limits(I)
        offset = scaledOffset(I, scale)
        [a, b, first, last] =  cropAndSubsampleLimits1D(I,d,f,limits)
    end
    
    %-------------------------- Ordinary Methods --------------------------
    
    methods
        function tf = sizesMatch(I, A)
            %sizesMatch True if object and raster/image are size-compatible
            %
            %   TF = sizesMatch(I,A) returns true if the sizes of A
            %   is consistent with the NumRows and NumColumns properties of
            %   object I.
            
            tf = (I.NumRows    == size(A,1)) && ...
                 (I.NumColumns == size(A,2));
        end
        
        
        function tf = contains(I, xi, yi)
            %contains True if raster contains points
            %
            %   TF = I.contains(xIntrinsic,yIntrinsic) accepts a set of
            %   point locations in intrinsic raster coordinates, defined
            %   by the arrays xIntrinsic and yIntrinsic, and returns a
            %   logical array TF having the same size as xIntrinsic and
            %   yIntrinsic such that TF(k) is true if and only if the
            %   point (xIntrinsic(k), yIntrinsic(k)) falls within the
            %   limits of the raster (or image) associated with the
            %   IntrinsicRaster2D object I.
            
            if (I.NumRows > 0) && (I.NumColumns > 0)
                if ~isequal(size(xi), size(yi))
                    error(message('map:validate:inconsistentSizes','XI','YI'))
                end
                
                [xlimits, ylimits] = limits(I);
                tf =  (xlimits(1) <= xi) & (xi <= xlimits(2)) ...
                    & (ylimits(1) <= yi) & (yi <= ylimits(2));
            else
                tf = false(size(xi));
            end
        end
        
        
        function [row, col] = intrinsicToDiscrete(I, xi, yi)
            %intrinsicToDiscrete Transform intrinsic coordinates to discrete subscripts
            %
            %   [ROW, COL] = intrinsicToDiscrete(I, xIntrinsic, yIntrinsic)
            %   returns the arrays ROW and COL which are the row and
            %   column subscripts of the cells that contain a set of
            %   points (xIntrinsic, yIntrinsic) for the raster (or
            %   image) associated with the IntrinsicRaster2D object I.
            %   xIntrinsic and yIntrinsic must have the same size. ROW
            %   and COL will have the same size as xIntrinsic and
            %   yIntrinsic. For an M-by-N raster, 1 <= ROW <= M and
            %   1 <= COL <= N, except when a point (xIntrinsic(k),
            %   yIntrinsic(k)) falls outside the image. Then both ROW(k)
            %   and COL(k) are NaN.
            
            outside = ~contains(I,xi,yi);
            
            row = min(round(yi), I.NumRows);
            col = min(round(xi), I.NumColumns);
            
            row(outside) = NaN;
            col(outside) = NaN;
        end
        
        
        function [rows, cols, firstxi, firstyi] = setupCropAndSubsample(...
                I, xlimits, ylimits, xSampleFactor, ySampleFactor)
            %setupCropAndSubsample Indices and new first corner for cropping/subsampling
            %
            %   Inputs
            %   ------
            %   xlimits - Requested limits in intrinsic X
            %   ylimits - Requested limits in intrinsic Y
            %   xSampleFactor - Sample factor in intrinsic X
            %   ySampleFactor - Sample factor in intrinsic Y
            %
            %     The requested limits can be specified in any order. The
            %     sample factors must be nonzero integers. A negative sign
            %     indicates a reversal of direction in the corresponding
            %     dimension.
            %
            %   Outputs
            %   -------
            %   rows - Vector of row indices
            %   cols - Vector of column indices
            %   firstxi - Intrinsic X location of new first corner
            %   firstxy - Intrinsic Y location of new first corner
            %
            %     The vectors of row and column indices indicate which
            %     elements are to be taken from the original raster during
            %     cropping and/or subsampling. Each is either monotonically
            %     increasing, if direction is not reversed, or monotonically
            %     decreasing, if it is.
            %
            %     The new first corner location (firstxi, firstyi) is
            %     relative to the intrinsic system of the original raster.
            
            validateattributes(xlimits,{'double'},{'real','finite','size',[1 2]})
            validateattributes(ylimits,{'double'},{'real','finite','size',[1 2]})
            validateattributes(xSampleFactor,{'double'},{'real','scalar','nonzero','integer'})
            validateattributes(ySampleFactor,{'double'},{'real','scalar','nonzero','integer'})
            
            % Computations in intrinsic X (across the columns)
            dim = 2;
            f = min(I.NumColumns, abs(xSampleFactor));
            [a,b,first,last] = cropAndSubsampleLimits1D(I,dim,f,xlimits);
            
            samedir = sign(xSampleFactor) > 0;
            if samedir
                firstxi = a;
                cols = first:f:last;
                if isempty(cols)
                    cols = first;
                end
            else
                firstxi = b;
                cols = last:-f:first;
                if isempty(cols)
                    cols = last;
                end
            end
            
            % Computations in intrinsic Y (down the columns)
            dim = 1;
            f = min(I.NumRows, abs(ySampleFactor));
            [a,b,first,last] = cropAndSubsampleLimits1D(I,dim,f,ylimits);
            
            samedir = sign(ySampleFactor) > 0;
            if samedir
                firstyi = a;
                rows = first:f:last;
                if isempty(rows)
                    rows = first;
                end
            else
                firstyi = b;
                rows = last:-f:first;
                if isempty(rows)
                    rows = last;
                end
            end            
        end
        
        
        function I = setRasterSize(I, rasterSize)
            % setRasterSize Update NumRows and NumColumns given a size vector
            
            validateattributes(rasterSize, {'double'}, ...
                {'row', 'positive', 'integer', 'finite'},'','RasterSize')
            
            map.internal.assert(numel(rasterSize) >= 2, ...
                'map:spatialref:invalidRasterSize','RasterSize')
            
            I.NumRows    = rasterSize(1);
            I.NumColumns = rasterSize(2);
        end
        
        
        function [numrows, numcols, xsample, ysample, xshift, yshift] ...
                = scaleRaster(I, xscale, yscale)
            % For a raster scaled by xscale in intrinsic x and yscale in
            % intrinsic y, compute the scaled raster size, locations
            % to be sampled in the input raster, and possible shift in
            % location.
            %
            %   numrows is the number of rows in the resized raster.
            %
            %   numcols is the number of columns in the resized raster.
            %
            %   xsample is a column vector indicating the location of the
            %   new cell centers or sample postings in the intrinsic space
            %   of the original raster. xSample(j) indicates the location,
            %   relative to the input raster, of the cell centers or
            %   posting points in the j-th column of the new raster.
            %
            %   ysample is a column vector indicating the location of the
            %   new cell centers or sample postings in the intrinsic space
            %   of the original raster. ySample(i) indicates the location,
            %   relative to the input raster, of the cell centers or
            %   posting points in the i-th row of the new raster.
            %
            %   xshift is a small non-negative scalar that specifies a
            %   shift in the location of the first corner, in intrinsic
            %   x, in order to keep the scaled raster centered
            %   on the original.
            %
            %   yshift is a small non-negative scalar that specifies a
            %   shift in the location of the first corner, in intrinsic
            %   y, in order to keep the scaled raster centered
            %   on the original.
            %
            %   If the scale inputs, in combination with the original
            %   raster size, allow the raster limits to be preserved, then
            %   xshift and yshift are exactly 0.

            % Number of rows or columns relative to number of intervals
            % Equal 0 for cells, 1 for postings
            extra = I.ElementsMinusIntervals;
            
            numIntervalsScaledInX = xscale .* (I.NumColumns - extra);
            numIntervalsScaledInY = yscale .* (I.NumRows - extra);
            
            numrows = extra + floor(numIntervalsScaledInY);
            numcols = extra + floor(numIntervalsScaledInX);
            
            % xshift and yshift are zero except when:
            %   floor(numIntervalsScaledInX) ~= numIntervalsScaledInX or
            %   floor(numIntervalsScaledInY) ~= numIntervalsScaledInY
            xshift = rem(numIntervalsScaledInX, 1) / (2 * xscale);
            yshift = rem(numIntervalsScaledInY, 1) / (2 * yscale);
            
            % scaledOffset returns the location, in the intrinsic space of
            % the input raster, of first sample in the scaled raster in the
            % dimension corresponding to scale -- excluding a possible
            % shift needed to preserve the raster center.
            xsample = scaledOffset(I, xscale) + xshift + (0:(numcols-1))' / xscale;
            ysample = scaledOffset(I, yscale) + yshift + (0:(numrows-1))' / yscale;
        end
    end
    
    %-------------------------- Protected Method --------------------------
    
    methods (Access = protected)
        function n = rasterSize(I, dim)
            % Input d can be either 1 or 2.
            if dim == 1
                n = I.NumRows;
            else
                n = I.NumColumns;
            end
        end
    end
end
