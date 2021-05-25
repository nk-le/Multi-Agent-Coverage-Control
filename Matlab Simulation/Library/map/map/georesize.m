function [B, RB] = georesize(A, RA, latscale, lonscale, varargin)
% GEORESIZE Resize a geographic raster
%
%   [B, RB] = GEORESIZE(A,RA,SCALE) returns the raster B that is SCALE
%   times the size of A. Both A and B are numeric or logical rasters. RA is
%   a geographic raster reference object that specifies the location and
%   extent of data in A. georesize returns RB which is a geographic raster
%   reference object associated with output raster B. If A has more than
%   two dimensions, georesize only resizes the first two dimensions. If
%   scale is in the range [0 1], B is smaller than A. If scale is greater
%   than 1, B is larger than A. By default, georesize uses cubic
%   interpolation.
%
%   [B, RB] = GEORESIZE(A,RA,LATSCALE,LONSCALE) returns the raster B and
%   that is LATSCALE times the size of A in latitude and LONSCALE times the
%   size of A in longitude.
%
%   [B, RB] = GEORESIZE(____,METHOD) specifies the interpolation method.
%   Available methods are:
%
%     'nearest' - nearest neighbor interpolation
%     'bilinear'  - bilinear interpolation
%     'cubic'   - cubic interpolation (default)
%
%   [B, RB] = GEORESIZE(____, 'Antialiasing', value) specifies whether to
%   perform antialiasing when shrinking a raster. The default value depends
%   on the interpolation method you choose.  For the 'nearest' method, the
%   default is false; for all other methods, the default is true.
%
%   Example
%   -------
%   load korea5c
%   geoshow(korea5c,korea5cR,'DisplayType','texturemap')
%   [resizedKorea, resizedKoreaR] = georesize(korea5c, korea5cR, 0.25);
%   figure
%   geoshow(resizedKorea,resizedKoreaR,'DisplayType','texturemap')
%
% See also geointerp, georefcells, georefpostings, mapresize

% Copyright 2018 The MathWorks, Inc.

    narginchk(3,Inf)
    
    validateattributes(RA, ...
        {'map.rasterref.GeographicCellsReference', ...
        'map.rasterref.GeographicPostingsReference'}, ...
        {'scalar'}, mfilename, 'RA')
    validateattributes(A, {'numeric', 'logical'}, ...
        {'real','nonsparse','nonempty','size',[RA.RasterSize NaN]}, mfilename, 'A')
    
    if nargin > 3
        if isnumeric(lonscale)
            validateattributes(latscale, {'numeric'}, ...
                {'scalar','positive','finite'}, mfilename, 'latscale')
            validateattributes(lonscale, {'numeric'}, ...
                {'scalar','positive','finite'}, mfilename, 'lonscale')
        else
            varargin = [{lonscale}, varargin];
            validateattributes(latscale, {'numeric'}, ...
                {'scalar','positive','finite'}, mfilename, 'scale')
            lonscale = latscale;
        end
    else
        validateattributes(latscale, {'numeric'}, ...
            {'scalar','positive','finite'}, mfilename, 'scale')
        lonscale = latscale;
    end
    
    isPostings = double(isa(RA, 'map.rasterref.GeographicPostingsReference'));
    tooFewRows = (isPostings + floor(lonscale * (size(A,1)-isPostings))) < 2;
    tooFewColumns = (isPostings + floor(latscale * (size(A,2)-isPostings))) < 2;
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
        if latscale < 1 && lonscale < 1 && method ~= "nearest"
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
    
    [RB, xSample, ySample] = scaleSizeAndDensity(RA, double(latscale), double(lonscale));
    
    B = resizeRaster(A, xSample, ySample, method, antialiasing);
    
    % If input was binary, convert output back to binary.
    if islogical(A)
        B = B > 128;
    end
end
