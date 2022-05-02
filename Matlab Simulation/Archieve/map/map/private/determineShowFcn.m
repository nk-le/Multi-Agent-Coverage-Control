function showFcn = determineShowFcn(options, varargin)
%determineShowFcn Return handle to show function
%
%   Selects a display function from the options listed in OPTIONS
%   based on the number and type of data arguments, or returns a simple
%   non-display function to handle the edge case where no data arguments
%   are present. OPTIONS is a structure of show function handles.
%
%   See also GEOSHOW, MAPSHOW.

% Copyright 2006-2015 The MathWorks, Inc.

% Get the number of data arguments.
numDataArgs = internal.map.getNumberOfDataArgs(varargin{:});

switch numDataArgs
    case 0
        showFcn = @(varargin)reshape([],[0,1]);
        
    case 1
        if ~isempty(varargin{1})
            if isobject(varargin{1})
                showFcn = options.showVectorFcn;
            else
                showFcn = options.showStructFcn;
            end
        else
            showFcn = @(varargin)reshape([],[0,1]);
        end
        
    case 2
        showFcn = determineTwoArgShowFcn(options, varargin{:});
        
    otherwise
        if ~all(cellfun('isempty', varargin(1:numDataArgs)))
            showFcn = options.showRasterFcn;
        else
            showFcn = @(varargin)reshape([],[0,1]);
        end
end

%--------------------------------------------------------------------------

function showFcn = determineTwoArgShowFcn(options, varargin)

arg1 = varargin{1};
arg2 = varargin{2};

isVectorInput  = isvector(arg1) && isvector(arg2);
neitherArgIsEmpty = ~(isempty(arg1) || isempty(arg2));
allEmptyInputs = isempty(arg1) && isempty(arg2);

if isVectorInput 
   if ~firstArgIsImage(varargin{:})
      showFcn = options.showVecFcn;
   else
      showFcn = options.showRasterFcn;
   end
   
elseif neitherArgIsEmpty
   showFcn = options.showRasterFcn;
   
elseif allEmptyInputs
   showFcn = @(varargin)reshape([],[0,1]);
   
else
   showFcn = getFunctionFromDisplayType(varargin{3:end});
end

%--------------------------------------------------------------------------

function showFcn = getFunctionFromDisplayType(varargin)
default = 'line';
displayType = map.internal.findNameValuePair('DisplayType', default, varargin{:});

switch lower(displayType)
   case {'point','multipoint','line','polygon'}
      showFcn = @geovecshow;
      
   case {'image','surface','mesh','contour'}
      showFcn = @georastershow;
      
   otherwise
      showFcn = @geovecshow;
end
      
%--------------------------------------------------------------------------

function tf = firstArgIsImage(varargin)
% Check for image syntax by verifying the second argument
% as a referencing vector or referencing matrix
% and that the 'DisplayType' parameter has been set to image.
refVecSize = [1,3];
secondArgCouldBeRefVec = isequal(size(varargin{2}), refVecSize);
if secondArgCouldBeRefVec && displayTypeIsImage(varargin{:})
   tf = true;
else
   tf = false;
end

%--------------------------------------------------------------------------

function tf = displayTypeIsImage(varargin)
% Check DisplayType parameter/value pair for 'image'.
if numel(varargin) > 2
   pairs = varargin(3:end);
   default = '';
   displayType = map.internal.findNameValuePair('DisplayType', default, pairs{:});
   tf = strcmpi(displayType, 'image');     
else
   tf = false;
end
