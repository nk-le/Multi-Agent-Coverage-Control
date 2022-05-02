function Vq = geointerp(V, R, latq, lonq, method)
%GEOINTERP Geographic raster interpolation.
%
%   Vq = GEOINTERP(V,R,latq,lonq) interpolates the geographically
%   referenced raster V, returning a value in Vq for each of the query
%   points in arrays latq and lonq. R is a geographic raster reference
%   object, which specifies the location and extent of data in V.
%
%   Vq = GEOINTERP(...,method) specifies alternate methods.  The default
%   is linear interpolation.  Available methods are:
%
%     'nearest' - nearest neighbor interpolation
%     'linear'  - bilinear interpolation
%     'cubic'   - bicubic interpolation
%     'spline'  - spline interpolation
%
%   See also mapinterp, interp2, griddedInterpolant, meshgrid

% Copyright 2016 The MathWorks, Inc.
    
    % Handle input
    validateattributes(R, ...
        {'map.rasterref.GeographicCellsReference', ...
        'map.rasterref.GeographicPostingsReference'}, ...
        {'scalar'}, 'geointerp', 'R')
    validateattributes(V, {'numeric', 'logical'}, ...
        {'size', R.RasterSize}, 'geointerp', 'V')
    if nargin < 5
        method = 'linear';
    else
        method = validatestring(method, ...
            {'nearest', 'linear', 'cubic', 'spline'}, ...
            'geointerp', 'method');
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
        idxToRemove = ~contains(R, latq, lonq);
    catch ME
        if strcmp(ME.identifier, ...
                'map:spatialref:sizeMismatchInCoordinatePairs')
            error(message('map:validate:inconsistentSizes', ...
                'latq', 'lonq'))
        else
            validateattributes(latq, {'double', 'single'}, {'real'}, ...
                'geointerp', 'latq')
            validateattributes(lonq, {'double', 'single'}, {'real'}, ...
                'geointerp', 'lonq')
            rethrow(ME)
        end
    end
    latq(idxToRemove) = NaN;
    lonq(idxToRemove) = NaN;
    
    % Convert geographic coordinates to intrinsic (row and column indices) 
    % to perform the interpolation
    [cq, rq] = geographicToIntrinsic(R, latq, lonq);
    
    % Perform interpolation
    % Use same method for extrapolation to account for data points within
    % latitude and longitude limits, but beyond 'cells' data points
    F = griddedInterpolant(V, method, method);
    Vq = F(rq, cq);
    
    % Convert class back if necessary
    if strcmp(origClassV, 'logical') %#ok<ISLOG>
        Vq = (Vq >= 0.5);
    elseif changeClassV || isempty(Vq)
        Vq = cast(Vq, origClassV);
    end
end
