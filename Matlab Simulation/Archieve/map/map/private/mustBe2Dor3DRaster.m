function mustBe2Dor3DRaster(A)
% Argument validation for functions that operate on geographic or map
% raster data

% Copyright 2019 The MathWorks, Inc.

    if ndims(A) > 3
        error(message('map:validators:mustBe2Dor3DRaster', ndims(A)))
    end
end
