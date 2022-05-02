function [B, RB] = mapresize(A, RA, scale, varargin)
% MAPRESIZE Resize a projected raster
%
%   [B, RB] = MAPRESIZE(A,RA,SCALE) returns the raster B that is SCALE
%   times the size of A. Both A and B are numeric or logical rasters. RA is
%   a map raster reference object that specifies the location and extent of
%   data in A. mapresize returns RB which is a map raster reference object
%   associated with the output raster B. If A has more than two dimensions,
%   mapresize only resizes the first two dimensions. If scale is in the
%   range [0 1], B is smaller than A. If scale is greater than 1, B is
%   larger than A. By default, mapresize uses cubic interpolation.
%
%   [B, RB] = MAPRESIZE(A,RA,SCALE,METHOD) specifies the interpolation
%   method. Available methods are:
%
%     'nearest' - nearest neighbor interpolation
%     'bilinear'  - bilinear interpolation
%     'cubic'   - cubic interpolation (default)
%
%   [B, RB] = MAPRESIZE(____, 'Antialiasing', value) specifies whether to
%   perform antialiasing when shrinking a raster. The default value depends
%   on the interpolation method you choose.  For the 'nearest' method, the
%   default is false; for all other methods, the default is true.
%
%   Example
%   -------
%   [boston, R] = readgeoraster('boston.tif');
%   mapshow(boston,R)
%   [resizedBoston, resizedR] = mapresize(boston,R,1/16);
%   figure
%   mapshow(resizedBoston, resizedR)
%
% See also mapcrop, mapinterp, maprefcells, maprefpostings, georesize

% Copyright 2018-2019 The MathWorks, Inc.
    
    narginchk(3,Inf)
    
    validateattributes(RA, ...
        {'map.rasterref.MapCellsReference', ...
        'map.rasterref.MapPostingsReference'}, ...
        {'scalar'}, mfilename, 'RA')
    validateattributes(A, {'numeric', 'logical'}, ...
        {'real','nonsparse','nonempty','size',[RA.RasterSize NaN]}, mfilename, 'A')
    validateattributes(scale, {'numeric'}, ...
        {'scalar','positive','finite'}, mfilename, 'scale')
    
    isPostings = double(isa(RA, 'map.rasterref.MapPostingsReference'));
    tooFewRows = (isPostings + floor(scale * (size(A,1)-isPostings))) < 2;
    tooFewColumns = (isPostings + floor(scale * (size(A,2)-isPostings))) < 2;
    if tooFewRows || tooFewColumns
        error(message('map:validate:scaledOutputSizeTooSmall'))
    end
    
    p = inputParser;
    addOptional(p,'method','cubic',@(x) ~isempty(...
        validatestring(x, ["nearest", "bilinear", "cubic"],mfilename,'method')));
    addParameter(p,'Antialiasing','',@(x) islogical(x) || isnumeric(x) ...
        || isStringScalar(validatestring(x,["on","off"],mfilename)));
    parse(p,varargin{:})
    
    method = validatestring(p.Results.method, ["nearest", "bilinear", "cubic"], mfilename, 'method');
    
    if any(strcmp(p.UsingDefaults, 'Antialiasing'))
        if scale < 1 && method ~= "nearest"
            antialiasing = true;
        else
            antialiasing = false;
        end
    else
        antialiasing = matlab.lang.OnOffSwitchState(p.Results.Antialiasing);
        if ~isscalar(antialiasing)
            error(message('MATLAB:images:imresize:badAntialiasing'));
        end
    end
    
    [RB, xSample, ySample] = scaleSizeAndDensity(RA, double(scale));
    
    B = resizeRaster(A, xSample, ySample, method, antialiasing);
    
    % If input was binary, convert output back to binary.
    if islogical(A)
        B = B > 128;
    end
end
