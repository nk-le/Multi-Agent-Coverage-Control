classdef IntrinsicPostingsReference < map.rasterref.internal.IntrinsicRasterReference
%IntrinsicRaster Intrinsic coordinates for raster of postings
%
%       FOR INTERNAL USE ONLY -- This class is intentionally
%       undocumented and is intended for use only within other toolbox
%       classes and functions. Its behavior may change, or the feature
%       itself may be removed in a future release.
%
%   For two-dimensional postings-type raster grids, IntrinsicCellsReference
%   objects implement and encapsulate the aspects of spatial referencing
%   that are independent of any external spatial coordinate system.
%
%   map.rasterref.internal.IntrinsicPostingsReference properties:
%     NumRows    - Number of rows
%     NumColumns - Number of columns
%
%   map.rasterref.internal.IntrinsicPostingsReference methods:
%     limits              - Limits of raster in intrinsic X and Y
%     sizesMatch          - True if object and raster/image are size-compatible
%     contains            - True if raster contains points
%     intrinsicToDiscrete - Transform intrinsic coordinates to discrete subscripts
%     setRasterSize - Update NumRows and NumColumns given a size vector
%
%     For an M-by-N raster of postings, contains(I,x,y) is true only when
%     both of the following are true:
%
%              1 <= x <= M
%              1 <= y <= N

% Copyright 2013-2018 The MathWorks, Inc.

    properties
        % Number of rows and columns in associated raster
        NumRows    = 2;
        NumColumns = 2;
    end
    
    properties (Constant)
        ElementsMinusIntervals = 1
    end
    
    
    methods
        function I = set.NumRows(I, numRows)
            validateattributes(numRows, {'double'}, ...
                {'row', 'positive', 'integer', 'finite'},'','NumRows')
            
            if numRows < 2
                msg = message('map:spatialref:oneColumnOrRowOfPostings', ...
                    'RasterInterpretation','postings','RasterSize');
                throwAsCaller(MException(msg.Identifier,'%s',msg.getString()))
            end
            
            I.NumRows = numRows;
        end
        
        
        function I = set.NumColumns(I, numColumns)
            validateattributes(numColumns, {'double'}, ...
                {'row', 'positive', 'integer', 'finite'},'','NumColumns')
            
            if numColumns < 2
                msg = message('map:spatialref:oneColumnOrRowOfPostings', ...
                    'RasterInterpretation','postings','RasterSize');
                throwAsCaller(MException(msg.Identifier,'%s',msg.getString()))
            end
            
            I.NumColumns = numColumns;
        end
        
        
        function [xlimits, ylimits] = limits(I)
            xlimits = [1 I.NumColumns];
            ylimits = [1 I.NumRows];
        end
        
        
        function  offset = scaledOffset(~,~)
            % Location of first scaled sample computed by scaleRaster(), in
            % the dimension corresponding to scale, excluding a possible
            % shift needed to preserve the raster center
            offset = 1;
        end
        
        
        function [a, b, first, last] = cropAndSubsampleLimits1D(~,~,~,~,~)
            assert(false,'map:setupCropAndSubsample:postingsNotSupported', ...
                'Postings are not supported by the setupCropAndSubsample method')
        end
    end
end
