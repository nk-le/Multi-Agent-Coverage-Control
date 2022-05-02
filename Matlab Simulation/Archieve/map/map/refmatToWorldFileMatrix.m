function W = refmatToWorldFileMatrix(refmat)
%refmatToWorldFileMatrix Convert referencing matrix to world file matrix
%
%   W = refmatToWorldFileMatrix(REFMAT) converts the 3-by-2 referencing
%   matrix REFMAT to a 2-by-3 world file matrix W.
%
%   See also map.rasterref.GeographicRasterReference/worldFileMatrix,
%            map.rasterref.MapRasterReference/worldFileMatrix

% Copyright 2010-2020 The MathWorks, Inc.

% The following expressions are derived in map.internal.referencingMatrix.m

map.rasterref.internal.validateRasterReference(refmat, ...
    {}, 'refmatToWorldFileMatrix', 'REFMAT', 1)

Cinv = [0  1  1;...
        1  0  1;...
        0  0  1];

W = refmat' * Cinv;
