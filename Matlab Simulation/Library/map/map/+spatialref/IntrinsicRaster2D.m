classdef IntrinsicRaster2D
% Stub class that enables load for spatialref.GeoRasterReference and
% spatialref.MapRasterReference objects saved in R2012b and earlier
% releases.

% Copyright 2010-2013 The MathWorks, Inc.

    properties
        RasterSize
        RasterInterpretation
    end

    methods (Static)
        function I = loadobj(I)
        end
    end
    
    methods (Access = private)
        function self = IntrinsicRaster2D(~,~)
            % Ensure that instances of this class cannot be constructed.
        end
    end
end
