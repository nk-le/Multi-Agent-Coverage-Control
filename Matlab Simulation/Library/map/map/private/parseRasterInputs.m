function [ax, dataArgs, displayType, HGpairs] = parseRasterInputs( ...
    mapfilename, varargin)
%PARSERASTERINPUTS Parse command line and return raster parameters
%
%   [AX, DATAARGS, DISPLAYTYPE, HGPAIRS] = PARSERASTERINPUTS(MAPFILENAME, 
%   VARARGIN) returns the parsed inputs from the command line. MAPFILENAME
%   is the name of the calling function and is used to create error
%   messages. The output arguments are defined as follows:
%
%   AX          The axes handle to display the object
%
%   DATAARGS    The input data arguments
%
%   DISPLAYTYPE A string defining the type of raster data
%               Valid types are: 'image' and 'grid'
%
%   HGPAIRS     A cell array containing the arguments to pass to the 
%               display function
%
%   See also GEORASTERSHOW, MAPRASTERSHOW, READMAPDATA.

% Copyright 2006-2012 The MathWorks, Inc.

% Obtain the data arguments and the property/value pairs in a cell
%  from the command line.
[dataArgs, paramPairs] = splitDataAndParamPairs(mapfilename,varargin{:});

% Verify that the parameter/value pairs are
%  string, value combinations.
checkParamValuePairs(mapfilename,paramPairs);

% Obtain the 'qualifiers' (non-HG prop/value pairs)
%  from the parameter pairs.
% HGpairs will be the remaining prop/value pairs that
%   are passed through to the HG object.
[ax, displayType, HGpairs] = ...
   parseQualifiers(mapfilename, numel(dataArgs), paramPairs{:});

% Obtain the axes and the rasterdata structure.
[ax, dataArgs, displayType, HGpairs] = ...
   parseRasterData(mapfilename, ax, dataArgs, displayType, HGpairs);

%----------------------------------------------------------------------
function [dataArgs, propValuePairs] = ...
   splitDataAndParamPairs(mapfilename, varargin)

% Split the data from the parameter/value pairs.
firstArgIsAxesHandle = ...
    isscalar(varargin{1}) && ishghandle(varargin{1},'axes');
if firstArgIsAxesHandle
   % Parse out (AX, ...) syntax
   if nargin > 2 
      % Designate first argument (axes handle) as Parent.
      varargin = [varargin(2:end), {'Parent'}, varargin(1)];
   else
      error(sprintf('map:%s:tooFewInputs', mapfilename), ...
          'Function %s expected at least two input arguments but was called instead with one input argument.', ...
         upper(mapfilename))
   end
end

if ischar(varargin{1})  % (FILENAME)
   dataArgs = varargin(1);
   varargin(1) = [];
else
   % numArgs is the number of arguments to the first string input
   numArgs = getNumDataArgs(varargin{1:end}); 
   if numArgs > 0
      dataArgs = varargin(1:numArgs);
      varargin(1:numArgs) = [];
   else
      dataArgs = {};    
   end
end

% Property/value pairs are the remainder of the arguments.
propValuePairs = varargin;

%----------------------------------------------------------------------
function numArgs = getNumDataArgs(varargin)
% Get the number of arguments to the first string input.

numArgs = nargin;
for i=1:nargin
   if ischar(varargin{i})
      numArgs = i-1;
      return;
   end
end

%----------------------------------------------------------------------
function checkParamValuePairs(mapfilename, varargin)
% Verify the inputs are in 'Parameter', value pairs syntax form,
%  by checking for pairs (even) and a string first pair.

pairs = varargin{:};
if ~isempty(pairs)
   if rem(length(pairs),2)
      error(sprintf('map:%s:invalidPairs', mapfilename), ...
          'The property/value inputs must always occur as pairs.')
   end
   params = pairs(1:2:end);
   for i=1:length(params)
      if ~ischar(params{i})
         error(sprintf('map:%s:invalidPropString', mapfilename),...
             'The parameter/value pairs must be a string followed by value.')
      end
   end
end

%---------------------------------------------------------------------
function [ax, displayType, pairs] = ...
   parseQualifiers(mapfilename, numArgs,varargin)
% Obtain the optional qualifiers from the input.
%  numArgs is the number of initial inputs preceding varargin.

% Assign empty if not found in varargin.
ax = [];
displayType = [];
deleteIndex = false(size(varargin));

validPropertyNames = ...
   {'DisplayType', 'Parent'};
for k = 1:2:numel(varargin)
   try
      propName = validatestring(lower(varargin{k}), validPropertyNames, ...
         mapfilename, 'PARAM', k);
   catch e
      if ~isempty(strfind(e.identifier,mapfilename))
         propName = '';
      else
         rethrow(e)
      end
   end
   switch propName
      case 'DisplayType'
         displayNames = {'surface','contour', 'mesh','texturemap', 'image'};
         displayType = validatestring(lower(varargin{k+1}),displayNames,...
            mapfilename,'DISPLAYTYPE',numArgs+k+1);
         deleteIndex(k:k+1) = true;

      case 'Parent'
         ax = varargin{k+1};
         checkAxes(ax, mapfilename, varargin{k}, numArgs+k+1);
         deleteIndex(k:k+1) = true;

      otherwise
   end
end
varargin(deleteIndex) = [];
pairs = varargin;

%----------------------------------------------------------------------
function checkAxes(ax, function_name, variable_name, argument_position)
% Check for a valid axes object.

if argument_position == 1
    arg_name = variable_name;
else
    arg_name = 'PARENT';
end

if  ~all(ishghandle(ax))
    error(sprintf('map:%s:invalidHandle', function_name), ...
        'Function %s expected its %s input argument, %s, to be a valid axes handle. The parameter is not a handle.', ...
        upper(function_name), num2ordinal(argument_position), arg_name)
end

if ~isscalar(ax)
    error(sprintf('map:%s:tooManyHandles', function_name), ...
        'Function %s expected its %s input argument, %s, to be a valid axes handle. The parameter is a handle array.', ...
        upper(function_name), num2ordinal(argument_position), arg_name)
end

if ~ishghandle(ax,'axes')
    error(sprintf('map:%s:handleNotAxes', function_name), ...
        'Function %s expected its %s input argument, %s, to be a valid axes handle. The handle type is ''%s'' rather than ''%s''.', ...
        upper(function_name), num2ordinal(argument_position), arg_name, get(ax,'Type'), 'axes')
end

%----------------------------------------------------------------------
function [ax, dataArgs, displayType, HGpairs] = ...
   parseRasterData(mapfilename, ax, dataArgs, displayType, HGpairs)
% Parse the dataArgs cell array and return the map data in rasterdata
%  and the axes handle in ax.

% Get the axes object.
if isempty(ax)
   ax = newplot;
end

if ischar(dataArgs{1})
   % Obtain the dataArgs from the file
   [dataArgs, fileDisplayType] ...
       = map.graphics.internal.readMapData(mapfilename, dataArgs{1});

   displayTypeNotSpecifiedByUser = isempty(displayType);
   if displayTypeNotSpecifiedByUser
      displayType = fileDisplayType;
   end
end

displayTypeNotSpecifiedByUserOrFile = isempty(displayType);
if displayTypeNotSpecifiedByUserOrFile
   displayType = 'image';
end
