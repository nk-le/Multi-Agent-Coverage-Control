function validateRasterSizeConsistency(A,RA)
% Argument validation for functions that operate on geographic or map
% raster data
%
% Error if the first numbers of rows and columns in raster A are
% inconsistent with the RasterSize property of referencing object RA.

% Copyright 2019 The MathWorks, Inc.

    if ~sizesMatch(RA,A)
        s = sprintf("[%d %d",size(A,[1 2]));
        for k = 3:ndims(A)
            s = s + sprintf(" %d",size(A,k));
        end
        s = s + "]";
        try
            error(message('map:validate:inconsistentRasterSize', ...
                s, sprintf("[%d %d]", RA.RasterSize)))
        catch e
            throwAsCaller(e)
        end
    end
end
