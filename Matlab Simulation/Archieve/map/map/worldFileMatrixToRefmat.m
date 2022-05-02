function refmat = worldFileMatrixToRefmat(W)
%worldFileMatrixToRefmat Convert world file matrix to referencing matrix
%
%      worldFileMatrixToRefmat will be removed in a future release.
%      Construct a raster reference object using GEORASTERREF or
%      MAPRASTERREF instead.
%
%   REFMAT = worldFileMatrixToRefmat(W) converts the 2-by-3 world file
%   matrix W to a 3-by-2 referencing matrix REFMAT.
%
%   For the world file matrix definitions, see the help for the
%   worldFileMatrix methods of the map raster reference and geographic
%   raster reference classes.
%
%   See also refmatToWorldFileMatrix,
%      map.rasterref.GeographicRasterReference/worldFileMatrix,
%      map.rasterref.MapRasterReference/worldFileMatrix

% Copyright 2010-2020 The MathWorks, Inc.

W = validateWorldFileMatrix(W, 'worldFileMatrixToRefmat', 'W', 1);
refmat = map.internal.referencingMatrix(W);
