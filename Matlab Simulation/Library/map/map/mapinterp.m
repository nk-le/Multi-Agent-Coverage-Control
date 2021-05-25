function Vq = mapinterp(V, R, xq, yq, method)
%MAPINTERP Map raster interpolation.
%
%   Vq = MAPINTERP(V,R,xq,yq) interpolates the spatially referenced
%   raster V, returning a value in Vq for each of the query points in
%   arrays xq and yq. R is a map raster reference object, which
%   specifies the location and extent of data in V.
%
%   Vq = MAPINTERP(...,method) specifies alternate methods.  The default
%   is linear interpolation.  Available methods are:
%
%     'nearest' - nearest neighbor interpolation
%     'linear'  - bilinear interpolation
%     'cubic'   - bicubic interpolation
%     'spline'  - spline interpolation
%
%   See also geointerp, interp2, griddedInterpolant, meshgrid

% Copyright 2016 The MathWorks, Inc.
    
    % Handle input
    validateattributes(R, ...
        {'map.rasterref.MapCellsReference', ...
        'map.rasterref.MapPostingsReference'}, ...
        {'scalar'}, 'mapinterp', 'R')
    validateattributes(V, {'numeric', 'logical'}, ...
        {'size', R.RasterSize}, 'mapinterp', 'V')
    if nargin < 5
        method = 'linear';
    else
        method = validatestring(method, ...
            {'nearest', 'linear', 'cubic', 'spline'}, ...
            'mapinterp', 'method');
    end
    
    % Convert data types if necessary
    origClassV = class(V);
    changeClassV = ~isfloat(V);
    if changeClassV
        V = double(V);
    end
    
    % Make any data outside of map limits NaN (extrapolation not supported)
    % Check for query point size mismatch in the process
    try
        idxToRemove = ~contains(R, xq, yq);
    catch ME
        if strcmp(ME.identifier, ...
                'map:spatialref:sizeMismatchInCoordinatePairs')
            error(message('map:validate:inconsistentSizes', ...
                'xq', 'yq'))
        end
        validateattributes(xq, {'double', 'single'}, {'real'}, ...
            'mapinterp', 'xq')
        validateattributes(yq, {'double', 'single'}, {'real'}, ...
            'mapinterp', 'yq')
        rethrow(ME)
    end
    xq(idxToRemove) = NaN;
    yq(idxToRemove) = NaN;
    
    % Convert projected coordinates to intrinsic (row and column indices) 
    % to perform the interpolation
    [cq, rq] = worldToIntrinsic(R, xq, yq);
    
    % Perform interpolation
    % Use same method for extrapolation to account for data points within
    % x and y limits, but beyond 'cells' data points
    F = griddedInterpolant(V, method, method);
    Vq = F(rq, cq);
    
    % Convert class back if necessary
    if strcmp(origClassV, 'logical') %#ok<ISLOG>
        Vq = (Vq >= 0.5);
    elseif changeClassV || isempty(Vq)
        Vq = cast(Vq, origClassV);
    end
end
