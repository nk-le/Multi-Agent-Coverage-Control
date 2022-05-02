function refmat = referencingVectorToMatrix(refvec, rasterSize)
%referencingVectorToMatrix Convert referencing vector to referencing matrix
%
%     This function is intentionally undocumented and is intended for
%     use only by other Mapping Toolbox functions.  Its behavior may
%     change, or the function itself may be removed, in a future release.
%
%   REFMAT = referencingVectorToMatrix(REFVEC, rasterSize) converts a
%   referencing refvec, REFVEC, to the referencing matrix REFMAT. REFMAT
%   is a 3-by-2 referencing matrix defining a 2-dimensional affine
%   transformation from intrinsic coordinates to geographic coordinates.
%   rasterSize is the size of the raster that is being referenced. REFVEC
%   is a 1-by-3 referencing vector with elements:
%
%             [cells/degree north-latitude west-longitude].

% Copyright 2020 The MathWorks, Inc.

    arguments
        refvec           {mustBeNumeric, mustBeReal, mustBeFinite}
        rasterSize (1,:) {mustBeNumeric, mustBeReal, mustBeFinite}
    end
    
    if numel(refvec) == 6
        % refvec is already a referencing matrix.
        refmat = reshape(refvec, [3 2]);
    else
        refvec = validateReferencingVector(refvec);
        nrows  = double(rasterSize(1));
        cellsize = 1/refvec(1);
        lat11 = refvec(2) + cellsize * (0.5 - nrows);
        lon11 = refvec(3) + cellsize * 0.5;
        W = [cellsize     0     lon11; ...
                0     cellsize  lat11];
        refmat = map.internal.referencingMatrix(W);
    end
end


function refvec = validateReferencingVector(refvec)
    arguments
        refvec (1,3) {mustBeNumeric, mustBeReal, mustBeFinite}
    end
    
    if refvec(1) <= 0
        error(message('map:refmat2vec:refvecCellDensityMustBePositive'))
    end
    
    refvec = double(refvec);
end
