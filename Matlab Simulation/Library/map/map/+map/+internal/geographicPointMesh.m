function [latmesh,lonmesh] = geographicPointMesh(R)
%geographicPointMesh Geographic mesh of cell center or sample location points
%
%   [LATMESH, LONMESH] = map.internal.geographicPointMesh(R) returns a
%   geographic (latitude-longitude) mesh in which each element corresponds
%   to a row and column in the raster grid or image associated with
%   referencing object R.
%
%   If R.RasterInterpretation is 'cells', then the mesh specifies the
%   geographic coordinates of the cell center points.
%
%   If R.RasterInterpretation is 'postings', then the mesh specifies the
%   geographic coordinates of the sample point locations.
%
%   Examples
%   --------
%   % A raster of cells such that each element in the mesh is the center of
%   % a geographic cell having finite area:
%   R = georasterref('LatitudeLimits',[27 28],'LongitudeLimits',[86 87], ...
%       'RasterSize',[120 120],'RasterInterpretation','cells')
%   [latmesh,lonmesh] = map.internal.geographicPointMesh(R);
%   size(latmesh)
%   size(lonmesh)
%
%   % A raster of posting points such that each element in the mesh is the
%   % specific point location of a sample or measurement:
%   R = georasterref('LatitudeLimits',[27 28],'LongitudeLimits',[86 87], ...
%       'RasterSize',[121 121],'RasterInterpretation','postings')
%   [latmesh,lonmesh] = map.internal.geographicPointMesh(R);
%   size(latmesh)
%   size(lonmesh)
%
%   Input Argument
%   --------------
%   R -- Geographic raster reference object.
%
%   Output Arguments
%   ----------------
%   LATMESH -- M-by-N array indicating the latitude of each point in a
%     geographic mesh, such that LATMESH(I,J) corresponds to the (I,J)-th
%     element of the associated M-by-N raster grid.
%     Data type: double.
%
%   LONMESH -- M-by-N array indicating the latitude of each point in a
%     geographic mesh, such that LATMESH(I,J) corresponds to the (I,J)-th
%     element of the associated M-by-N raster grid.
%     Data type: double.
%
%   In both cases M is equal to R.RasterSize(1) and N is equal to
%   R.RasterSize(2).

% Copyright 2014-2019 The MathWorks, Inc.

[latv, lonv] = map.internal.geographicGridVectors(R);
nrows = length(latv);
ncols = length(lonv);

% Equivalent to [lonmesh,latmesh] = meshgrid(lonv,latv);
latmesh = latv(:,ones(1,ncols));
lonmesh = lonv(ones(nrows,1),:);
