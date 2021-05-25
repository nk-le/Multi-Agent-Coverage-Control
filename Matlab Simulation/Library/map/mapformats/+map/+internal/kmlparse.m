function [filename, S, options] = kmlparse(fcnName, type, varargin)
%KMLPARSE Parse input for KML functions
%
%   [filename, S, kml] = KMLPARSE(fcnName, type, varargin) parses varargin
%   input and returns validated and parsed output. See KMLWRITE for a
%   description of inputs for varargin.
%
%   Input Arguments
%   ----------------
%   fcnName          - Name of calling function for use in error messages
%
%   type             - Type of elements to parse. The type is either
%                      'polygon', 'line', 'point', or 'any'.
%
%   varargin         - Cell array of inputs to parse
%
%
%   Output Arguments
%   ----------------
%   filename         - String indicating name of KML file
%
%   S                - A geopoint or geoshape vector
% 
%   options          - Scalar structure containing parsed options
%
%   See also KMLWRITE, KMLWRITELINE, KMLWRITEPOINT, KMLWRITEPOLYGON

% Copyright 2012-2020 The MathWorks, Inc.

% Use try/catch since this is an internal function.
try
    % Verify filename.
    filename = verifyFilename(varargin{1}, fcnName);
    varargin(1) = [];
    
    % Parse input.
    [dataArgs, options, userSupplied] = parseInput(type, varargin{:});
    
    % Validate input.
    if any(strcmp(type, {'point','line','polygon'}))
        % Using (filename, lat, lon) or (filename, lat, lon, alt) syntax.
        % Validate arrays and convert to dynamic vector.
        [S, options] = arraysToDynamicVector(dataArgs, options, type);
    else
        % Validate dataArgs.
        [S, options] = validateDataArgs( ...
            dataArgs, options, userSupplied, type, fcnName, varargin{:});
    end    
catch e
    throwAsCaller(e)
end

% Spec field is not needed anymore.
options = rmfield(options, 'Spec');

%--------------------------------------------------------------------------

function [dataArgs, options, userSupplied] = parseInput(type, varargin)
% Parse the data from varargin.

% Verify the number of data arguments.
numDataArgs = verifyNumberOfDataArgs(type, varargin);
    
% Define dataArgs.
dataArgs = varargin(1:numDataArgs);

% Check numDataArgs
if numDataArgs < 2 && ~strcmp(type,'any')
    % Expect 2 or more inputs for point, line, polygon input.
    % This branch is reached by not supplying enough data parameters:
    % fcnName(filename,'A','Color','r')
    % fcnName(filename,0,'Color','r')
    % For better error messaging, validate latitude and longitude. If it
    % passes, then issue not enough inputs error.
    validateattributes(dataArgs{1}, ...
        {'single','double'}, {'nonempty'}, 'kmlparse', 'latitude coordinates');
    if ~isscalar(varargin)
        validateattributes(varargin{2}, ...
        {'single','double'}, {'nonempty'}, 'kmlparse', 'longitude coordinates');
    end
    error(message('MATLAB:narginchk:notEnoughInputs'))
end

% Remove the data arguments from varargin to obtain the pvpairs.
varargin(1:numDataArgs) = [];

% Set the number of required elements for the options structure. If a
% single character address is specified, then the number of elements is 1;
% otherwise, the number of elements is equal to the numel of the first data
% argument.
numElements = numberOfFeatures(dataArgs{1}, type);

% Construct the validator table.
validatorTable = constructValidatorTable(type, numElements);

% Get the list of parameter names based on type.
parameterNames = validatorTable{:,1};

% Get the list of function handles to validate the input.
validateFcns = validatorTable{:,2};

% Parse the parameter/value pair input. 
[options, userSupplied, unmatched] = ...
    internal.map.parsepv(parameterNames, validateFcns, varargin{:});

% Check if varargin contained unmatched parameters.
if ~isempty(unmatched)
    validatestring(unmatched{1},parameterNames,mfilename);
end

% Determine if an attribSpec is provided as a structure.
if userSupplied.Description && isstruct(options.Description{1})
    % An attribSpec is supplied in the options structure. Assign the Spec
    % field to it. Set the userSupplied.Description field to
    % false, since the Description will be created using the supplied
    % attribSpec. Modify the Description field to contain an empty space
    % for all elements.
    options.Spec = options.Description{1};
    userSupplied.Description = false;
    options.Description = {' '}; 
else
    % An attribSpec is not provided, set the Spec field to [].
    options(1).Spec = [];
end

if isa(options.Camera{1}, 'geopoint') && isa(options.LookAt{1}, 'geopoint')
    % Specifying both Camera and LookAt at the same time is not allowed.
    error(message('map:kml:expectedOneViewParameter'));
end

% Assign default values if not supplied.
options = assignDefaultValues(options, userSupplied);

%--------------------------------------------------------------------------

function options = assignDefaultValues(options, userSupplied)
% Assign default values for CutPolygons and PolygonCutMeridian if not
% supplied by the user.

% Default names and values:
% CutPolygons: true
% PolygonCutMeridian: 180
names = {'CutPolygons', 'PolygonCutMeridian'};
defaults = {true, 180};

if all(isfield(userSupplied, names))
    for k = 1:length(defaults)
        if ~userSupplied.(names{k})
            options.(names{k}) = defaults{k};
        end
    end
end
        
%--------------------------------------------------------------------------

function [S, options] = validateDataArgs( ...
    dataArgs, options, userSupplied, type, fcnName, varargin)
% Validate dataArgs. FILENAME is not supplied in VARARGIN.

dataArg1 = dataArgs{1};
if isscalar(dataArgs) && (isstruct(dataArg1) || isobject(dataArg1))
    % Using (filename, S) syntax
    % Check the coordinates and altitude values of dataArg1.
    % Create a description table if requested,
    [S, options] = checkFeatures(dataArg1, options, userSupplied);
    
elseif ~isscalar(dataArgs)
    % Using (filename, lat, lon) or (filename, lat, lon, alt) syntax
    % Validate arrays and convert to dynamic vector.
    [S, options] = arraysToDynamicVector(dataArgs, options, type);
    
else
    % Using (filename, address) syntax
    S = validateAddress(dataArg1, fcnName);
end

%--------------------------------------------------------------------------

function t = constructValidatorTable(type, numElements)
% Construct a table containing the parameter names as the first column and
% the validation functions as the second column.

% Construct table with common names and validators.
t = constructCommonTable(numElements);

switch type
    case 'point'
        t = constructPointTable(t, numElements);
        t = constructColorAlphaTable(t, numElements);
        
    case 'line'
        t = constructLineTable(t, numElements);
        t = constructColorAlphaTable(t, numElements);
        t = constructLineWidthTable(t, numElements);
        
    case 'polygon'
        t  = constructPolygonTable(t, numElements);
        t = constructLineWidthTable(t, numElements);
        
    case 'any'
        t = constructPointTable(t, numElements);
        t = constructLineTable(t, numElements);
        t = constructPolygonTable(t, numElements);
        t = constructColorAlphaTable(t, numElements);
        t = constructLineWidthTable(t, numElements);
end

%--------------------------------------------------------------------------

function t = constructCommonTable(numElements)
% Construct table common to all geometry types.

names = {'Description', 'Name', 'Camera', 'LookAt', 'AltitudeMode'};
n = length(names);
t = table(cell(n,1),cell(n,1));

row = 1;
name = 'Description';
fcn = @(x)validateCellWrapper(x, @validateDescription, name, numElements);
t{row,:} = {name, fcn};

row = row + 1;
name = 'Name';
fcn = @(x)validateCellWrapper(x, @validateStringCell, name, numElements);
t{row,:} = {name,fcn};

row = row + 1;
name = 'Camera';
fcn = @(x)validateViewPointWrapper(x, @validateViewParameters, name, numElements);
t{row,:} = {name,fcn};

row = row + 1;
name = 'LookAt';
fcn = @(x)validateViewPointWrapper(x, @validateViewParameters, name, numElements);
t{row,:} = {name,fcn};

row = row + 1;
name = 'AltitudeMode';
defaultAltitudeMode = 'clampToGround';
modeFcn = @(x, y) validateAltitudeMode(x, y, defaultAltitudeMode);
fcn = @(x)validateCellWrapper(x, modeFcn, name, numElements);
t{row,:} = {name,fcn};

%--------------------------------------------------------------------------

function t = constructPointTable(t, numElements)
% Add point specific name and validation functions.

name = 'Icon';
fcn = @(x)validateCellWrapper(x, @validateFilenameCell, name, numElements);
t{end+1,:} = {name,fcn};

name = 'IconScale';
fcn = @(x)validateNumericWrapper(x, @validatePositiveNumericArray, name, numElements);
t{end+1,:} = {name,fcn};

%--------------------------------------------------------------------------

function t = constructLineTable(t, numElements)
% Add line specific name and validation functions.

name = 'Width';
fcn = @(x)validateNumericWrapper(x, @validatePositiveNumericArray, name, numElements);
t{end+1,:} = {name,fcn};

%--------------------------------------------------------------------------

function t = constructPolygonTable(t, numElements)
% Add polygon specific name and validation functions.

name = 'FaceColor';
fcn = @(x)validateColorWrapper(x, @validateColor, name, numElements);
t{end+1,:} = {name,fcn};  

name = 'EdgeColor';
fcn = @(x)validateColorWrapper(x, @validateColor, name, numElements);
t{end+1,:} = {name,fcn};

name = 'FaceAlpha';
fcn = @(x)validateNumericWrapper(x, @validateAlpha, name, numElements);
t{end+1,:} = {name,fcn};

name = 'EdgeAlpha';
fcn = @(x)validateNumericWrapper(x, @validateAlpha, name, numElements);
t{end+1,:} = {name,fcn};

name = 'Extrude';
fcn = @(x)validateNumericWrapper(x, @validateLogicalArray, name, numElements);
t{end+1,:} = {name,fcn};   

name = 'CutPolygons';
numElements = 1;
fcn = @(x)validateScalarWrapper(x, @validateLogicalArray, name, numElements);
t{end+1,:} = {name,fcn};       

name = 'PolygonCutMeridian';
numElements = 1;
fcn = @(x)validateScalarWrapper(x, @validateNumericArray, name, numElements);
t{end+1,:} = {name,fcn};    

%--------------------------------------------------------------------------

function t = constructColorAlphaTable(t, numElements)
% Construct table for Color and Alpha.

name = 'Color';
fcn = @(x)validateColorWrapper(x, @validateColor, name, numElements);
t{end+1,:} = {name,fcn};

name = 'Alpha';
fcn = @(x)validateNumericWrapper(x, @validateAlpha, name, numElements);
t{end+1,:} = {name,fcn};

%--------------------------------------------------------------------------

function t = constructLineWidthTable(t, numElements)
% Construct table for Color and Alpha.

name = 'LineWidth';
fcn = @(x)validateNumericWrapper(x, @validatePositiveNumericArray, name, numElements);
t{end+1,:} = {name,fcn};

%--------------------------------------------------------------------------

function numFeatures = numberOfFeatures(arg1, type)
% Determine number of features:
%    1 for address input
%    1 for 'line' or 'polygon' type
%    length(arg1) for geopoint or geoshape input
%    numel(arg1) for all others

if any(strcmp(class(arg1),{'geopoint','geoshape'}))
    numFeatures = length(arg1);
elseif any(strcmp(type,{'line','polygon'})) || ischar(arg1)
    % numFeatures is 1 for address input or 'line' or 'polygon' coordinate
    % array input. A line or polygon feature may be mult-part (separated by
    % NaNs) but it is considered a single feature.
    numFeatures = 1;
else
    numFeatures = numel(arg1);
end

%--------------------------------------------------------------------------

function filename = verifyFilename(filename, fcnName)
% Verify and validate the filename input.

filenamePos = 1;
filename = convertStringsToChars(filename);
validateattributes(filename, {'char', 'string'}, {'scalartext','nonempty'}, ...
    'kmlparse', 'FILENAME', filenamePos);

% Add .kml extension to filename if necessary.
kmlExt = '.kml';
[pathname, basename, ext] = fileparts(filename);
map.internal.assert(isequal(lower(ext), kmlExt) || isempty(ext), ...
    'map:fileio:invalidExtension', upper(fcnName), filename, kmlExt);
filename = fullfile(pathname,[basename,kmlExt]);

%--------------------------------------------------------------------------

function numDataArgs = verifyNumberOfDataArgs(type, inputs)
% Verify the number of required data arguments.
%
% The command line is composed of two sets of parameters:
%    the required arguments, followed by parameter-value pairs.
%
% For the case of KMLWRITE, the number of required arguments is either one,
% for S or ADDRESS input, or two for LAT and LON input, or three for LAT,
% LON, ALTITUDE input. A single required argument may be of the following
% type:
%   struct: geostruct input
%   dynamic vector
%   char  : address data 
%   cell  : address data
%   
% For the case of two or more required arguments (lat and lon input), the
% type of argument is numeric.
%
% verifyNumberOfDataArgs calculates the number of required data arguments
% and verifies the command line syntax. INPUTS is expected to contain at
% least one element. The FILENAME argument from the command line is
% expected to be removed prior to calling.

% Assign a logical row vector that has one more element than INPUTS,
% which contains true when the corresponding element of INPUTS is a
% string, false otherwise, and which ends in true which will help in the
% case where INPUTS contains no strings.
stringPattern = [cellfun(@ischar, inputs) true];

% Determine the number of data arguments:
%
% Define a working row vector that looks like this: [1 1 2 3 ...
% numel(inputs)], and call it numDataArgKey.  Then index into it with the
% stringPattern row vector (both have length 1 + numel(inputs)) and keep
% the first element that results (because there may be more than one
% string) to define numDataArgs.  The following three cases cover all the
% possibilities:
%
% (1) inputs{1} is a string, which means it must contain an address,
% which is the one and only data argument.  The first element of
% stringPattern is true, and the first element returned by the logical
% indexing step is the first element of numDataArgKey, which is 1.
%
% (2) inputs contains at least one string, but it is not inputs{1}. In
% this case, the number of data arguments is one less than the position of
% the first string in INPUTS. Due to the offset in the definition of
% numDataArgKey (the 2nd value is 1, the 3rd value is 2, etc.) the first
% element of the array returned by the indexing step will be the required
% value.
%
% (3) inputs contains no strings, so only the last element in
% stringPattern is true, which indexes the last element of numDataArgKey,
% which is numel(inputs). All the arguments are data arguments in this
% case.
numDataArgKey = [1, 1:numel(inputs)];
numDataArgs = numDataArgKey(stringPattern);
numDataArgs = numDataArgs(1);

% Set logicals for the conditions of one, two, or three data arguments. For
% one data argument, the char case is previously defined. 
% For the error condition: kmlwrite(filename, object / struct, number) 
% if you also include the check below in haveOneDataArg:
%  || isstruct(inputs{1}) || isobject(inputs{1});
% the code will issue an error from validatestring (below), which is not 
% very helpful. By not including the check, the code issues an error when
% validating latitude and longitude inputs.
haveOneDataArg = numDataArgs == 1 || iscell(inputs{1});
haveThreeDataArgs = ~haveOneDataArg && numDataArgs == 3;
haveTwoDataArgs = ~haveOneDataArg && ~haveThreeDataArgs;

% The paramPos is the expected position of the first parameter-value pair.
% The function expects one, two, or thee data arguments, so the paramPos is
% one plus the expected values.
paramPos = [2,3,4];
paramPos = paramPos([haveOneDataArg haveTwoDataArgs haveThreeDataArgs]);

% If the paramPos variable is not a string, then error for the following
% cases: 
% 1. If client is KMLWRITE since it is the only client that supports
%    ADDRESS as input (denoted with type='any')
% 2. For all other clients when numDataArgs > 3 
%    (clients only support, lat, lon, altitude numeric inputs)
if ~stringPattern(paramPos) && (strcmp(type,'any') || numDataArgs > 3)
    % argPos is the position in the command line arguments for the paramPos
    % variable. Since FILENAME is removed from INPUTS, it is one plus
    % paramPos. 
     argPos = paramPos+1;
     validateattributes(inputs{paramPos},{'char', 'string'},{'nonempty'},mfilename,'NAME',argPos);
end
    
%--------------------------------------------------------------------------

function c = validateCellWrapper(c, validateFcn, parameter, numElements)
% Validate cell wrapper function provides a common interface to validate
% inputs that are required to be cell array.

% c needs to be a cell array.
if ~iscell(c)
    c = {c};
end

% c needs to be a row vector.
c = {c{:}}; %#ok<CCAT1>

% Validate the number of elements in c.
validateNumberOfCellElements(c, parameter, numElements);

% Execute the validation function.
c = validateFcn(c, parameter);

% Map any empty characters to space characters.
c = mapEmptyToSpaceChar(c);

%--------------------------------------------------------------------------

function c = validateNumericWrapper(c, validateFcn, parameter, numElements)
% Validate numeric wrapper function provides a common interface to validate
% inputs that are required to be numeric array.

if iscell(c)
    c = cell2mat(c);
end

% Execute the validation function.
c = validateFcn(c, parameter);

% All parameter values must be converted to a cell array.
c = num2cell(c(:)');

% Validate the number of elements in c.
validateNumberOfCellElements(c, parameter, numElements);

% Map any empty characters to space characters.
c = mapEmptyToSpaceChar(c);

%--------------------------------------------------------------------------

function c = validateScalarWrapper(c, validateFcn, parameter, numElements)
% Validate numeric wrapper function provides a common interface to validate
% inputs that are required to be numeric array.

% Execute the validation function.
c = validateFcn(c, parameter);

% Validate the number of elements in c.
validateNumberOfCellElements(c, parameter, numElements);

%--------------------------------------------------------------------------

function c = validateViewPointWrapper(c, validateFcn, parameter, numElements)
% validateViewPointWrapper provides a common interface to validate inputs
% for view point parameters (Camera and LookAt) that are required to be
% geopoint vectors.

% Validate input as a geopoint vector.
validateattributes(c, {'geopoint'}, {}, mfilename, parameter)

% Make sure required field names are present and setup Camera and LookAt
% specific data.
names = fieldnames(c);

if strcmp(parameter, 'Camera')
    % Camera
    required = 'Altitude'; 
    
    attributeNames = {'Altitude', 'Heading', 'Tilt', 'Roll',  'AltitudeMode'};
    viewParameters = {'Heading', 'Tilt', 'Roll'};
    viewRanges = { ...
        {'>=', 0, '<=', 360}, ...
        {'>=', 0, '<=', 180}, ...
        {'>=', -180, '<=', 180}};
else
    % LookAt
    
    % Check required parameter, Range.
    required = 'Range';
    
    % Check Altitude since it is required for Camera but not for LookAt.
    if ~any(strcmp('Altitude', names))
        c.Altitude = 0;
    end
    
    attributeNames = {'Altitude', 'Heading', 'Tilt', 'Range', 'AltitudeMode'};
    viewParameters = {'Heading', 'Tilt', 'Range'};
    viewRanges = { ...
        {'>=', 0, '<=', 360}, ...
        {'>=', 0, '<=', 90}, ...
        {'>=', 0}};
end

% Make sure required fields are present.
if isempty(names) || ~any(strcmp(required, names))
    error(message('map:kml:expectedField', parameter, required))
end

% Validate Altitude.
validateattributes(c.Altitude, {'numeric'}, {'real','finite'}, ...
    'kmlparse', [parameter '.Altitude']);

% Validate coordinates.
% NaN locations must be identical and values cannot be infinite.
% Clients need to validate that NaN locations coincide with feature 
% coordinates.
lat = c.Latitude;
lon = c.Longitude;
nanLat = isnan(lat);
nanLon = isnan(lon);
latStr = [parameter '.Latitude'];
lonStr = [parameter '.Longitude'];
if ~isequal(nanLat, nanLon) || all(nanLat) || any(isinf(lat)) || any(isinf(lon))
    validateattributes(lat, {'numeric'}, {'finite'}, mfilename, latStr);
    validateattributes(lon, {'numeric'}, {'finite'}, mfilename, lonStr);
else
    validateCoordinates(lat, lon, latStr, lonStr);
end
c.Longitude = wrapTo180(lon);

% Warn and remove unnecessary names.
nonAttributeNames = setdiff(names, attributeNames);
if ~isempty(nonAttributeNames)
    removedNames = sprintf('''%s'', ', nonAttributeNames{:});
    warning(message('map:kml:ignoringFieldnames', removedNames, parameter))
    for k = 1:numel(nonAttributeNames)
        c.(nonAttributeNames{k}) = [];
    end
end

% Execute the validation function.
c = validateFcn(c, parameter, viewParameters, viewRanges);

% Validate the number of elements in c.
validateNumberOfCellElements(c, parameter, numElements);
    
% Return in a cell array.
c = {c};

%--------------------------------------------------------------------------

function c = validateViewParameters(c, parameter, viewParameters, viewRanges)

names = fieldnames(c);
n = length(c);

commonAttributes = {'real', 'finite'};
for k = 1:numel(viewParameters)
    name = viewParameters{k};
    attributes = [commonAttributes, viewRanges{k}];
    if any(strcmp(name, names))
        validateattributes(c.(name), {'numeric'}, attributes, ...
            'kmlparse', [parameter '.' name]);
    else
        c.(name) = zeros(1, n);
    end
end

default = 'relativeToGround';
if any(strcmp('AltitudeMode', names))
    name = [parameter '.AltitudeMode'];
    c.AltitudeMode = validateAltitudeMode(c.AltitudeMode, name, default);
else
    c(1:length(c)).AltitudeMode = default;
end

%--------------------------------------------------------------------------

function mode = validateAltitudeMode(mode, parameterName, default)
% Validate AltitudeMode to be a valid string or cell array of strings.

if ~iscell(mode)
    mode = {mode};
end

% Change any '' values (used by geopoint to expand vector) to default.
index = cellfun(@isempty, mode);
mode(index) = {default};

% Validate mode as a cell array of strings.
mode = validateStringCell(mode, parameterName);

% Validate values
validModes = {'relativeToGround', 'relativeToSeaLevel', 'clampToGround'};
for k = 1:numel(mode)
    mode{k} = validatestring(mode{k}, validModes, 'kmlparse', parameterName);
end

% The KML format expects 'absolute' rather than 'relativeToSeaLevel'.
mode = strrep(mode, 'relativeToSeaLevel', 'absolute');

%--------------------------------------------------------------------------

function c = validateDescription(c, parameter)
% Validate description input. c is a cell array that is validated to
% contain strings or struct input.

% Permit char, or struct or numeric empty.
validInput = @(x)(ischar(x) || isstruct(x) || (isnumeric(x) && isempty(x)));
cIsCellArrayOfStringsOrStruct = cellfun(validInput, c);
if ~all(cIsCellArrayOfStringsOrStruct)
    value = c(~cIsCellArrayOfStringsOrStruct);
    value = value{1};
    validateattributes(value, {'char','string','struct'},{},'kmlparse', parameter)
end

%--------------------------------------------------------------------------

function c = validateColorWrapper(c, validateFcn, parameter, numElements)
% validateColorWrapper validates a 'Color' value.

% Execute the validation function.
c = validateFcn(c, parameter, numElements);

% Validate the number of elements in c.
validateNumberOfCellElements(c, parameter, numElements);
    
%--------------------------------------------------------------------------

function c = validateColor(c, parameter, numElements)
% Validate color input. The input c may be either a numeric array (1-by-3
% or numElements-by-3) containing RGB color values, a color string, or a
% cell array of color strings of length 1 or numElements. The output c is a
% cell array that contains KML color strings. A KML color string is valued:
% [alpha blue green red] in lower case hex. Color and opacity (alpha)
% values are expressed in hexadecimal notation. The range of values for any
% one color is 0 to 255 (00 to ff). Use the default ff for opacity.
% numElements is the number of features.

if ischar(c)
    c = {c};
end

if iscell(c)
    % c is a cell array, validate that it is a cell array of strings.
    index = cellfun(@(x) (ischar(x) && isvector(x)), c);
    if ~all(index)
        % The values in c are not all strings. Find the first non-string
        % value and issue an error using validateattributes.
        value = c{find(~index,1)};
        validateattributes(value, {'char','string'}, {'vector'}, 'kmlparse', parameter)
    end
    
    % c is a cell array of strings.
    % Allow 'none' as a color value.
    % If 'none', set to black and save index to reset to 'none'.
    noneIndex = strcmp('none',c);
    usingNone = any(noneIndex);
    if usingNone
        c{noneIndex} = 'black';
    end

    % Convert colorSpec strings to RGB values.
    rgb = zeros(numel(c), 3);
    for k = 1:numel(c)
        rgb(k,:) = map.internal.colorSpecToRGB(c{k});
    end
    c = rgb;    
else
    % A cell array is not being used. 'none' is not allowed.
    usingNone = false;
    
    % c is expected to be a numeric color array with size 1-by-3 or
    % numElements-by-3 and with values between 0 and 1.
    if size(c, 1) == 1
        % Allow the number of colors to be 1. If c contains a single color
        % (1-by-3) the numeric color value is converted to a single color
        % string and it will be propagated to all features (in the same
        % manner as a single string specification).
        numberOfRows = 1;
    else
        % Otherwise require one color for each element.
        numberOfRows = numElements;
    end
    validateattributes(c, {'double'}, ...
        {'nonempty', '>=', 0, '<=', 1, 'size', [numberOfRows 3]}, ...
        'kmlparse', parameter)
end

% Convert valid RGB values to KML color string: ffHexBlueHexGreenHexRed
numColors = size(c, 1);
kmlColors = cell(1, numColors);
for k = 1:numColors
    kmlColors{k} = sprintf('%02x', round(255 * [1 c(k,[3 2 1])]));
end

% Reset none if specified.
if usingNone
    kmlColors{noneIndex} = 'none';
end

% Return c as a cell array of KML color strings.
c = kmlColors;

%--------------------------------------------------------------------------

function  c = validateStringCell(c, parameter)
% Validate c to be a cell array of strings. The strings must be row
% vectors.

if ~iscell(c)
    c = {c};
end

index = cellfun(@(x) (isempty(x) || (isvector(x) && ischar(x))), c);
if ~all(index)
    value = c(~index);
    value = value{1};
    validateattributes(value, {'char','string'}, {'vector'}, 'kmlparse', parameter)
end

%--------------------------------------------------------------------------

function  c = validatePositiveNumericArray(c, parameter)
% Validate c to be an array containing positive numeric values. 

cIsPositiveNumericArray = ...
    isnumeric(c) && all(~isinf(c(:))) && all(c(:) > 0);
if ~cIsPositiveNumericArray
    validateattributes(c, {'numeric'}, {'finite', 'positive'}, ...
        'kmlparse', parameter);
end

%--------------------------------------------------------------------------

function  c = validateNumericArray(c, parameter)
% Validate c as an array containing non-empty, real, finite values. 

validateattributes(c, {'numeric'}, {'real','finite','nonempty'}, 'kmlparse', parameter);

%--------------------------------------------------------------------------

function  c = validateAlpha(c, parameter)
% Validate c to be an array containing positive numeric values from 0 to 1.

validateattributes(c, {'numeric'}, ...
    {'nonempty', 'finite', 'nonnegative', '<=',1, '>=',0}, 'kmlparse', parameter);

%--------------------------------------------------------------------------

function  c = validateLogicalArray(c, parameter)
% Validate c to be an array containing logical values. Treat 0 as false and
% 1 as true if numeric.

if isnumeric(c)
    ctrue = (c == 1);
    cfalse = (c == 0);
    if all(ctrue | cfalse)
        c = logical(c);
        cIsLogicalArray = true;
    else
        cIsLogicalArray = false;
    end
else
    cIsLogicalArray = islogical(c);
end

if ~cIsLogicalArray
    validateattributes(c, {'logical'}, {}, 'kmlparse', parameter);
end

% KML requires double
c = double(c);

%--------------------------------------------------------------------------

function  c = validateFilenameCell(c, parameter)
% Validate c to be a cell array containing filenames. The filenames are
% validated to be strings and to exist. A filename may contain a URL
% string containing ftp:// http:// or file://.

% Validate the input as all string.
c = validateStringCell(c, parameter);

% urlEntries is a logical array that is true for entries that contain a
% URL string.
urlEntries = isURL(c);

% Verify that all files exist. Some files may be a URL string, in which
% case filesExist is set to false.
filesExist = logical(cellfun(@(x)exist(x,'file'), c));
filesExist(urlEntries) = false;

% filesAreValid is a logical array set to true for all entries that are
% valid.
filesAreValid = urlEntries | filesExist;

if ~all(filesAreValid)
    % invalidEntries is a cell array of entries that are invalid.
    invalidEntries = c(~filesAreValid);
    fileNotFound = invalidEntries{1};
    error(message('map:fileio:fileNotFound', fileNotFound));
end

% The files may be partial pathnames. Set all filenames to absolute path.
c = getAbsolutePath(c, filesExist);

%--------------------------------------------------------------------------

function filenames = getAbsolutePath(filenames, filesExist)
% Return the absolute path of each element in filenames. filesExist is a
% cell array that is true for each file that exists.

for k=1:numel(filenames)
    if filesExist(k)
        
        try 
           fid = fopen(filenames{k},'r');
           fullfilename = fopen(fid);
           fclose(fid);
        catch e
            error(message('map:fileio:unableToOpenFile', filenames{k}));
        end
                
        if exist(fullfile(pwd,fullfilename),'file')
           fullfilename = fullfile(pwd, fullfilename);
        end
        filenames{k} = fullfilename;
    end
end
    
%--------------------------------------------------------------------------

function tf = isURL(filenames)
% Determine if a cell array of filenames contain a URL string matching
% *://. Return a logical array that is true for each element in filenames
% that contains a URL string.

tf = contains(filenames, '://');

%--------------------------------------------------------------------------

function validateNumberOfCellElements(c, parameter, maxNumElements)
% Validate the number of elements in the c cell array.

validNumberOfCellElements = length(c) == [0, 1, maxNumElements];
if ~any(validNumberOfCellElements)
    if maxNumElements == 1
        % Use an error message from validateattributes to indicate that the
        % value needs to be a scalar.
        validateattributes(c, {class(c)}, {'scalar'}, mfilename, parameter);
    else
        error(message('map:validate:mismatchNumberOfElements', ...
            parameter, maxNumElements));
    end
end

%--------------------------------------------------------------------------

function c = mapEmptyToSpaceChar(c)
% Map empty values to a single space character. c is a cell array. empty
% values in the cell array are changed to ' '.
%
% XMLWRITE will not output empty tags correctly. For example, a value of ''
% for a tag name of 'description' will output as:
% <description/> 
% rather than:
% <description></description>

spaceChar = ' ';
c(isempty(c)) = {spaceChar};
emptyIndex = cellfun(@isempty, c);
c(emptyIndex) = {spaceChar};

%--------------------------------------------------------------------------

function [S, options] = checkFeatures(S, options, userSupplied)
% Validate the coordinate and altitude arrays in S. Add a description table
% to options.Description if userSupplied.Description is false.

% Validate the input S.
S = validateS(S);

% A table needs to be created if the user did not supply a description or
% an attribute spec is supplied in the Spec field of options.  If an
% attribute spec is supplied, then userSupplied.Description is previously
% set to false.
if ~userSupplied.Description
    options = makeDefaultTable(S, options);
end

% Determine altitude field.
[S, altitudeName, altitudeIsSpecified] = determineAltitudeName(S);

% Set AltitudeMode, if not supplied, and if altitude values have been
% specified in S. The default value used by KML functions is
% 'relativeToSeaLevel' but KML uses 'absolute'.
if all(strcmp(' ', options.AltitudeMode)) && altitudeIsSpecified
    options.AltitudeMode = {'absolute'};
end

% Validate altitude.
issueWarning = true;
warningName = ['altitude (''' altitudeName ''')'];
needTable = false;
if isa(S, 'geopoint')
    % S is a geopoint vector.
    % Validate altitude and verify NaN locations.
    lat = S.Latitude;
    alt = S.(altitudeName);
    alt = validateAltitude(alt, lat);
    [S.(altitudeName), needTable] = checkAltitudeNans( ...
        alt, lat, warningName, issueWarning);
else
    % S is a geoshape vector, validate that the NaN locations in the
    % altitude values are consistent with the NaN locations in latitude
    % and ensure that the altitude values do not contain inf values.
    alt = S.(altitudeName);
    lat = S.Latitude;
    if ~isequal(isnan(lat),isnan(alt)) || any(isinf(alt)) || any(~isreal(alt))
        % The altitude values are not consistent with latitude or contain
        % inf or non-real values. Loop through each element, check the
        % altitude values and issue a warning once. Set the altitude values
        % to have consistent NaN locations with latitude.
        altCell = cell(1, length(S));
        for k = 1:length(S)
            lat = S(k).Latitude;
            alt = S(k).(altitudeName);
            alt = validateAltitude(alt, lat);
            [altCell{k}, warningIssued] = ...
                checkAltitudeNans(alt, lat, warningName, issueWarning);
            if warningIssued
                issueWarning = false;
                needTable = true;
            end
        end
        S.(altitudeName) = altCell;
    end
end

% A table needs to be re-created if a warning has been issued since the
% values of S have changed from NaN to 0.
if ~userSupplied.Description && needTable
    options = makeDefaultTable(S, options);
end
    
%--------------------------------------------------------------------------

function [S, options] = arraysToDynamicVector(dataArgs, options, type)
% Validate the latitude and longitude coordinate arrays in dataArgs 
% and the altitude (if present).  If type is 'point' return S as a geopoint
% vector. If type is 'line', return S as a geoshape vector with 'line'
% Geometry. If type is 'polygon' return S as a geoshape vector with
% 'polygon' geometry; otherwise return S as a geopoint vector.

% Validate coordinates.
lat = dataArgs{1};
lon = dataArgs{2};
[lat, lon] = validateCoordinates(lat, lon);

if length(dataArgs) == 3
    % Using (filename, lat, lon, alt) syntax
    % Validate altitude.
    alt = dataArgs{3};
    alt = validateAltitude(alt, lat);
    
    % Set AltitudeMode, if not supplied.
    % The default value used by
    % KMLWRITE is 'relativeToSeaLevel' but KML uses 'absolute'
    if all(strcmp(' ', options.AltitudeMode))
        options.AltitudeMode = {'absolute'};
    end
    
    % Check NaN locations of altitude.
    issueWarning = true;
    alt = checkAltitudeNans(alt, lat, 'altitude', issueWarning);
else
    % Assign alt values of 0.
    alt = zeros(1, numel(lat));
end

% Create dynamic vector based on type.
if any(strcmp(type,{'line','polygon'}))
    S = geoshape(lat, lon, 'Altitude', {alt}, 'Geometry', type);
else
    S = geopoint(lat, lon, 'Altitude', alt);
end

%--------------------------------------------------------------------------

function address = validateAddress(address, fcnName)
% Validate address as a string or a cell array of strings.

validTypes = {'cell', 'char', 'string'};
validateattributes(address, validTypes, {'nonempty'}, fcnName, 'ADDRESS', 2);

% address must be a cell array.
if ~iscell(address)
    address = {address};
end

% Verify that address is a cell array of strings.
index = cellfun(@(x)(isempty(x) || (isvector(x) && ischar(x))), address);
if ~all(index)
    value = address{find(~index, 1)};
    validateattributes(value, {'char', 'string'}, {'vector'}, fcnName, 'ADDRESS')
end
    
%--------------------------------------------------------------------------

function S = validateS(S)
% Validate input S.

if isstruct(S)
    % Validate structure input and convert to a dynamic vector.
    S = validateGeostruct(S);
else
    % Validate input as geopoint or geoshape.
    validateattributes(S, {'geopoint','geoshape'}, {'nonempty'}, mfilename, 'S', 2);
end

% Validate coordinates.
validateCoordinates(S.Latitude, S.Longitude);

%--------------------------------------------------------------------------

function options = makeDefaultTable(S, options)
% Create a default HTML table based on S and the attribSpec. The attribSpec
% is supplied in options.Spec and may be empty. The options Description
% field contains the output HTML table.

attribSpec = options.Spec;

% Create an attribSpec if it is empty.
if isempty(attribSpec)
    attribSpec = makeattribspec(S);
else
    % Validate the attribute spec.
    attribSpec = validateAttributeSpec(attribSpec, S);
end

% Convert the attribute fields of the dynamic vector to a cell array
% containing HTML. The table is the description field of a KML
% Placemark element which is located at the specified coordinates.
options.Description = attributeFieldsToHTML(S, attribSpec);

%--------------------------------------------------------------------------

function v = validateGeostruct(S)
% Validate S is a geostruct and convert to a geopoint or geoshape.

% Verify the input is a non-empty structure.
validateattributes(S, {'struct'}, {'vector','nonempty'}, ...
     mfilename, 'S', 2);

 % Support version1 geostruct.
if isfield(S,'lat') && isfield(S,'long')
   S = updategeostruct(S);
end

% Convert to dynamic vector and validate.
v = map.internal.struct2DynamicVector(S);

% Ensure v is a geopoint or geoshape (not a mappoint or mapshape).
% This occurs if S is a mapstruct.
c = class(v);
map.internal.assert(any(strcmp(c,{'geopoint','geoshape'})), ...
    'map:geostruct:expectedGeostruct');

%--------------------------------------------------------------------------

function html = attributeFieldsToHTML(S, attribSpec)
% Convert attribute fields to HTML. Create an HTML table as a string value
% in the cell array HTML for each element in the dynamic vector S by
% applying the attribute specification, attribSpec. HTML is the same length
% as S.

% Obtain the field names of the attribute structure to be used in the
% table.
rowHeaderNames = getAttributeLabelsFromSpec(attribSpec);

% Convert the fields to a string cell array.
c = attributeFieldsToStringCell(S, attribSpec);

% Convert each element of S to an HTML table. 
html = cell(1,length(S));
for k=1:length(S)
    % Convert the cell array to an HTML table.
    html{k} = makeTable(rowHeaderNames, c(:,k));
end

%--------------------------------------------------------------------------

function attributeLabels = getAttributeLabelsFromSpec(attribSpec)
% Obtain the table names from the attribute spec.  attributeLabels is a
% cell array containing the string names for each attribute.

% Assign the field names of the desired attributes.
specFieldNames = fieldnames(attribSpec);

% Assign the number of desired attributes.
numSpecFields = numel(specFieldNames);

% Allocate space for the attribute labels.
attributeLabels = cell(1,numSpecFields);

% Obtain the names from the spec.
for m=1:numSpecFields
    specFieldName = specFieldNames{m};
    attributeLabels{m} = attribSpec.(specFieldName).AttributeLabel;   
end

%--------------------------------------------------------------------------

function c = attributeFieldsToStringCell(S, attribSpec)
% Convert the dynamic vector S to a string cell array by applying the 
% format in the structure attribSpec.

% Get the field names of the attribute structure and initialize a cell
% array.
attributeNames = fieldnames(attribSpec);
c = cell(length(attributeNames), length(S));

% Apply the specification to S.
% Loop through each of the attributeNames and convert each value  of the
% dynamic vector to a string. Apply the attribute specification to the
% numeric values. A cell array in a geopoint or geoshape vector is always
% a cellstr.
for k=1:numel(attributeNames)
    fieldName = attributeNames{k};
    value = S.(fieldName);
    if ischar(value)
        c(k,:) = {value};
    elseif iscell(value)
        c(k,:) = value;
    else
        for n = 1:length(value)
            v = value(n);
            c{k, n} = num2str(v, attribSpec.(fieldName).Format);
        end
    end
end

%--------------------------------------------------------------------------

function attribSpec = validateAttributeSpec(attribSpec, S)
% Validate attribute specification.

% If attribSpec is empty, make sure it's an empty struct.
if isempty(attribSpec)
    % No need to check anything else, including the attribute fields of S.
    attribSpec = struct([]);
else
    % Make sure that attribSpec is a scalar structure.
    validateattributes(attribSpec, {'struct'}, {'scalar'}, ...
        'kmlwrite', 'Description')
    
    % Validates attribute values in S and make sure attribSpec and S are
    % mutually consistent.
    defaultspec = makeattribspec(S);  
    attributeNamesInS = fields(defaultspec);
    attributeNamesInattribSpec = fields(attribSpec);
    
    % Check 1:  Every attribute in attribSpec must be present in S.
    missingAttributes = setdiff(attributeNamesInattribSpec,attributeNamesInS);
    map.internal.assert(isempty(missingAttributes), ...
        'map:geostruct:missingAttributes');
    
    % Check 2:  Field types in attribSpec must be consistent with S. While
    % in this loop, use the default to fill in any fields missing from
    % attribSpec.
    for k = 1:numel(attributeNamesInattribSpec)
        attributeName = attributeNamesInattribSpec{k};
        fSpec = attribSpec.(attributeName);
        fDefault = defaultspec.(attributeName);
        
        if ~isfield(fSpec,'AttributeLabel')
            attribSpec.(attributeName).AttributeLabel = fDefault.AttributeLabel;
        end
        
        if ~isfield(fSpec,'Format')
            attribSpec.(attributeName).Format = fDefault.Format;
        end
    end
end

%--------------------------------------------------------------------------

function  html = makeTable(names, values)
% Create a cell array containing HTML embedded tags representing a table.
% The table is two-column with name, value pairs. 

% NAMES is a string cell array containing the names for the first column in
% the table. VALUES is a string cell array containing the values for the
% second column in the table.  HTML is a char array containing embedded
% HTML tags defining a table. 

if ~isempty(names)
    numRows = numel(names);
    html = cell(numRows+2,1);

    html{1} = sprintf('<html><table border="1">\n');
    rowFmt = '<tr><td>%s</td><td>%s</td></tr>\n';
    for k = 1:numRows
        html{k+1} = sprintf(rowFmt, names{k}, values{k});
    end
    html{numRows+2} = sprintf('</table><br></br></html>\n');
    html = char([html{:}]);
else
    html = ' ';
end

%--------------------------------------------------------------------------

function [lat, lon] = validateCoordinates(lat, lon, latStr, lonStr)
% Validate the latitude, longitude coordinates.

if nargin < 3
    latStr = 'latitude coordinates';
end

if nargin < 4
    lonStr = 'longitude coordinates';
end

% Ensure row vectors. Input shape does not matter.
lat = lat(:)';
lon = lon(:)';

% Ensure lat and lon arrays are class single or double and equal in size.
validateattributes(lat, {'single','double'}, {'real','nonempty'}, mfilename, latStr);
validateattributes(lon, {'single','double'}, {'real','nonempty','size',size(lat)}, mfilename, lonStr);
     
% Validate values in coordinate arrays.
validateCoordinateValues(lat, lon, latStr, lonStr)

%--------------------------------------------------------------------------

function validateCoordinateValues(lat, lon, latStr, lonStr)
% Validate values in coordinate arrays.

% Ensure arrays are finite.
% Ensure lat and lon contain at least one non-NaN value.
% NaN values cause validateattributes to throw an error in the 'finite'
% case, but are permitted. 
latNaNIndices = isnan(lat);
lonNaNIndices = isnan(lon);
classes = {'single','double'};
if any(isinf(lon)) || any(isinf(lat)) || all(latNaNIndices) || all(lonNaNIndices)
    attributes = {'real', 'nonempty', 'finite'};
    validateattributes(lat, classes, attributes, mfilename, latStr);
    validateattributes(lon, classes, attributes, mfilename, lonStr);
end

% Validate consistent location of NaN values.
if ~isequal(latNaNIndices, lonNaNIndices)
    error(message('map:kml:mismatchedNaNsInCoordinatePairs'))
end

% Validate latitudes are in range.
if any(lat > 90) || any(lat < -90)
    validateattributes(lat(~latNaNIndices), classes, {'>=',-90,'<=',90}, mfilename, latStr);
end

%--------------------------------------------------------------------------

function alt = validateAltitude(alt, lat)
% Validate altitude.

% Ensure row vector for consistency with lat and lon.
% validateCoordinates ensures that lat and lon are row vectors.
alt = alt(:)';

% Ensure length matches if alt is a scalar.
name = 'altitude';
if isscalar(alt) && isnumeric(alt) && isreal(alt)
    alt = alt * ones(1, numel(lat));
else
    % Validate altitude. Ensure size matches coordinates.
    attributes = {'real', 'nonempty', 'size', size(lat)};
    validateattributes(alt, {'numeric'}, attributes, mfilename, name);
end

% Allow NaN values but altitude cannot be infinite.
if any(isinf(alt))
    validateattributes(alt, {'numeric'}, {'finite'}, mfilename, name);
end

%--------------------------------------------------------------------------

function [alt, warningIssued] = checkAltitudeNans( ...
    alt, lat, warningName, issueWarning)
% If ALT and LAT have matching lengths, then check that the NaN locations
% of ALT match the NaN locations of LAT. If not, then set those ALT values
% to 0 and warn if issueWarning is true.

warningIssued = false;
% If lengths are not equal, there is no need to issue an error here because
% validation of altitude values will fail elsewhere.
if length(alt) == length(lat)
    altNans = isnan(alt);
    latNans = isnan(lat);
    altOrLatNans = latNans | altNans;
    if ~isequal(latNans, altOrLatNans)
        if issueWarning
            warning('map:kml:settingAltitudeToZero', ...
                'Setting %s NaN values to 0.', warningName)
            warningIssued = true;
        end
        alt(altNans) = 0;
    end
end

%--------------------------------------------------------------------------

function [S, altitudeName, altitudeIsSpecified] = determineAltitudeName(S)
% Determine the altitude name from the input dynamic vector, S.

% Assign default values.
defaultName = 'Altitude';
isVertexProperty = isa(S, 'geoshape');

% Find altitude names in S.
altitudeNames = {'Altitude', 'Elevation', 'Height'};
names = fieldnames(S);
index = ismember(altitudeNames, names);

% Validate altitude.
if any(index)
    if length(find(index)) > 1
        warning(message('map:kml:tooManyAltitudeFields'))
        altitudeName = defaultName;
        S = rmfield(S, altitudeNames(index));
        S = assignAltitude(S, isVertexProperty, altitudeName);
        altitudeIsSpecified = false;
    else
        altitudeName = altitudeNames{index};
        altitudeIsSpecified = true;
    end
else
    altitudeName = defaultName;
    S = assignAltitude(S, isVertexProperty, altitudeName);
    altitudeIsSpecified = false;
end

%--------------------------------------------------------------------------

function S = assignAltitude(S, isVertexProperty, altitudeName)
% Assign altitudeName property to S. S is a geopoint or geoshape vector.

if ~isVertexProperty
    S.(altitudeName) = 0;
else
    % For optimization, use a cell array to add new a altitude property
    % (altitudeName) to S. The value is 0 and expanded to the same length
    % as each vertex element of S and has consistent NaN locations with
    % Latitude.
    cvalue = cell(1,length(S));
    for k = 1:length(S)
        % Use Latitude as the array to match. Both Latitude and Longitude
        % have consistent length and NaN locations.
        lat = S(k).Latitude;
        
        % Expand value to match length of lat.
        n = length(lat);
        defaultValue = zeros(1, n);
        
        % Set non-NaN locations to value.
        index = isnan(lat);
        defaultValue(index) = NaN;
        cvalue{k} = defaultValue;
    end
    % Set altitudeName.
    S.(altitudeName) = cvalue;
end
