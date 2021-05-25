function refvec = referencingMatrixToVector(refmat, rasterSize)
%referencingMatrixToVector Convert referencing matrix to referencing vector
%
%     This function is intentionally undocumented and is intended for
%     use only by other Mapping Toolbox functions.  Its behavior may
%     change, or the function itself may be removed, in a future release.
%
%   REFVEC = referencingMatrixToVector(REFMAT, rasterSize) converts a
%   referencing matrix, REFMAT, to the referencing vector REFVEC.  REFMAT
%   is a 3-by-2 referencing matrix defining a 2-dimensional affine
%   transformation from intrinsic coordinates to geographic coordinates.
%   rasterSize is the size of the raster that is being referenced. REFVEC
%   is a 1-by-3 referencing vector with elements:
%
%            [cells/degree north-latitude west-longitude].

% Copyright 2020 The MathWorks, Inc.

    arguments
        refmat           {mustBeNumeric, mustBeReal, mustBeFinite}
        rasterSize (1,:) {mustBeNumeric, mustBeReal, mustBeFinite}
    end
    
    if numel(refmat) == 3
        % refmat is already a referencing vector.
        refvec = reshape(refmat, [1 3]);
        if refvec(1) <= 0
            error(message('map:refmat2vec:refvecCellDensityMustBePositive'))
        end
    else
        refmat = validateReferencingMatrix(refmat);
        nrows = double(rasterSize(1));
        xi = 0.5;
        yi = 0.5 + nrows;
        west  = xi * refmat(2,1) + refmat(3,1);
        north = yi * refmat(1,2) + refmat(3,2);
        refvec = [1/refmat(1,2) north west];
    end
end


function refmat = validateReferencingMatrix(refmat)
    arguments
        refmat (3,2) {mustBeNumeric, mustBeReal, mustBeFinite}
    end
    
    if (refmat(1,1) ~= 0) || (refmat(2,2) ~= 0)
        error(message('map:refmat2vec:mustBeIrrotational'));
    end
    
    if refmat(1,2) <= 0
        error(message('map:refmat2vec:rowsMustBeIncreasing'))
    end
    
    if refmat(2,1) <= 0
        error(message('map:refmat2vec:columnsMustBeIncreasing'))
    end
    
    if refmat(1,2) ~= refmat(2,1)
        error(message('map:refmat2vec:cellsMustBeSquare'))
    end
    
    refmat = double(refmat);
end
