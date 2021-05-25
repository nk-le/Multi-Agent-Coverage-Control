classdef (Sealed, Hidden) RasterInfo
% RasterInfo Display geospatial raster metadata

% Copyright 2019-2020 The MathWorks, Inc.
    
    properties (SetAccess = private)
        Filename
        FileModifiedDate
        FileSize
        FileFormat
        RasterSize
        NumBands
        NativeFormat
        MissingDataIndicator
        Categories
        ColorType
        Colormap
        RasterReference
        CoordinateReferenceSystem
        Metadata
    end
    
    methods
        function infoObj = RasterInfo(infostruct)
            if nargin > 0 && isstruct(infostruct)
                fields = convertCharsToStrings(fieldnames(infostruct))';
                for name = fields
                    if isprop(infoObj, name)
                        infoObj.(name) = infostruct.(name);
                    end
                end
            end
        end
    end
end