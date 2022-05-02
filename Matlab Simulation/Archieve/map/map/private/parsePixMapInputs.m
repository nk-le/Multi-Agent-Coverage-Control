function [R, height, width, hasFlag] ...
    = parsePixMapInputs(func_name, flagstr, varargin)
% Input-parsing for MAPBBOX, MAPOUTLINE, and PIXCENTERS.
%
%   Handle the following argument lists:
%
%      INFO
%      INFO, FLAG
%      R, SIZEA
%      R, SIZEA, FLAG
%      R, HEIGHT, WIDTH
%      R, HEIGHT, WIDTH, FLAG
%
%   FLAGSTR is the acceptable value of FLAG.
%   Set FLAGSTR = [] if FLAG is not to be used.

%   Copyright 1996-2017 The MathWorks, Inc.  

[varargin{:}] = convertStringsToChars(varargin{:});
if isstruct(varargin{1})
    [R, height, width, hasFlag] = parseInfo(func_name, flagstr, varargin{:});
else
    [R, height, width, hasFlag] = parseOther(func_name, flagstr, varargin{:});
end

%----------------------------------------------------------------------
function [R, height, width, hasFlag] = parseInfo(func_name, flagstr, varargin)

info = varargin{1};
if ~isfield(info,'RefMatrix') || ~isfield(info,'Height') || ~isfield(info,'Width')
    error('map:validate:missingInfoFields', ...
        'Function %s expected input number 1, %s, to contain %s, %s, and %s fields.',...
        func_name, 'INFO', 'RefMatrix', 'Height', 'Width');
else
    R = info.RefMatrix;
    try
        map.rasterref.internal.validateRasterReference(R, {}, func_name, 'R', 1)
    catch %#ok<CTCH>
        % Throw an error that make sense in this context.
        error('map:validate:infoHasInvalidR', ...
            'Function %s expected input number %d, %s, to contain a valid %s value.', ...
            func_name, 1, 'INFO', 'RefMatrix')
    end
    try
        [height, width] = checkHeightAndWidth(info.Height, info.Width, func_name);
    catch %#ok<CTCH>
        % Throw an error that make sense in this context.
        error('map:validate:infoHasInvalidHorW', ...
            'Function %s expected input number %d, %s, to contain valid %s and %s values.', ...
            func_name, 1, 'INFO', 'Height', 'Width')
    end
end

if numel(varargin) >= 2 && ~isempty(flagstr) && ischar(flagstr)
    % Inputs: INFO, FLAG
    checkFlag(func_name, flagstr, varargin{2}, 2);
    hasFlag = true;
else
    % Inputs: INFO
    hasFlag = false;
end

%-------------------------------------------------------------------------
function [R, height, width, hasFlag] = parseOther(func_name, flagstr, varargin)

R = varargin{1};
map.rasterref.internal.validateRasterReference(R,'planar',func_name,'R',1)

switch(numel(varargin))
    case 2
        % Inputs: R, SIZEA
        [height, width] = checkSizeA(varargin{2}, func_name);
        hasFlag = false;
        
    case 3
        if ~isempty(flagstr) && ischar(flagstr) && ischar(varargin{3})
            % Inputs: R, SIZEA, FLAG
            [height, width] = checkSizeA(varargin{2}, func_name);
            checkFlag(func_name, flagstr, varargin{3}, 3);
            hasFlag = true;
        else
            % Inputs: R, HEIGHT, WIDTH
            [height, width]...
                = checkHeightAndWidth(varargin{2}, varargin{3}, func_name);
            hasFlag = false;
        end
        
    case 4
        % Inputs: R, HEIGHT, WIDTH, FLAG
        [height, width]...
            = checkHeightAndWidth(varargin{2}, varargin{3}, func_name);
        checkFlag(func_name, flagstr, varargin{4}, 4);
        hasFlag = true;
end

if isobject(R)
    rasterSize = R.RasterSize;
    assert(isequal(height, rasterSize(1)) && isequal(width, rasterSize(2)), ...
        'map:validate:expectedSizesToMatch', ...
        'Function %s expected the %s property of the map raster reference object to be consistent with its raster size inputs (%s or %s and %s).', ...
        func_name, 'RasterSize', 'SIZEA', 'HEIGHT', 'WIDTH')
end

%----------------------------------------------------------------------
function [height, width] = checkSizeA(sizeA, func_name)

sizeAAttributes = {'real','positive','integer'};
validateattributes(sizeA, {'double'}, sizeAAttributes, func_name, 'SIZEA', 2)

if numel(sizeA) < 2 || ~ismatrix(sizeA) || size(sizeA,1) ~= 1
    error('map:validate:invalidSizeA', ...
        'Function %s expected input number %d, %s, to be 1-by-N.', ...
        func_name, 2, 'SIZEA')
end

height = sizeA(1);
width  = sizeA(2);

%----------------------------------------------------------------------
function [height, width] = checkHeightAndWidth(height, width, func_name)

hwAttributes = {'real','scalar','positive','integer'};
validateattributes(height, {'double'}, hwAttributes, func_name, 'HEIGHT', 2);
validateattributes(width,  {'double'}, hwAttributes, func_name, 'WIDTH',  3);

%----------------------------------------------------------------------
function checkFlag(func_name, flagstr, flag, pos)

try
    validatestring(flag, {flagstr}, func_name, '', pos);
catch exception
    error('map:validate:expectedFlag', ...
        'Function %s expected input number %d to be the string ''%s''.',...
        func_name, pos, flagstr);
end
