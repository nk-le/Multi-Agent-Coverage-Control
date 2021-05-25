function refvec = refmat2vec(refmat,rasterSize)
%REFMAT2VEC Convert referencing matrix to referencing vector
%
%        REFMAT2VEC will be removed in a future release.
%        Construct a geographic raster reference object instead using
%        refmatToGeoRasterReference.
%
%   REFVEC = REFMAT2VEC(REFMAT,rasterSize) converts a referencing matrix,
%   REFMAT, to the referencing vector REFVEC.  REFMAT is a 3-by-2
%   referencing matrix defining a 2-dimensional affine transformation from
%   pixel coordinates to geographic coordinates.  rasterSize is the size of
%   the data grid that is being referenced. REFVEC is a 1-by-3 referencing
%   vector with elements:
%
%         [cells/angleunit north-latitude west-longitude].  
%
%   Example 
%   -------
%   % Convert referencing matrix for a 180-by-360 raster of cells with
%   % 1-degree resolution
%   % referencing matrix.
%   refmat = [0 1; 1 0; -0.5 -90.5]
%   rasterSize = [180 360];
%   refvec = refmat2vec(refmat,rasterSize)
%
%   See also refmatToGeoRasterReference

% Copyright 1996-2020 The MathWorks, Inc.

refvec = map.internal.referencingMatrixToVector(refmat, rasterSize);
