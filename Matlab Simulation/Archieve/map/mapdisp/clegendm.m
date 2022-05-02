function hLegend = clegendm(varargin)
%CLEGENDM Add legend labels to map contour display
%
%   CLEGENDM(CS, H) adds a legend specifying the contour line heights to the
%   current map contour plot.  CS and H are the contour matrix output and
%   object handle outputs from CONTOURM, CONTOUR3M, or CONTOURFM.
%
%   CLEGENDM(CS, H, LOC) places the legend in the specified location:
%
%        0 = Automatic placement (default)
%        1 = Upper right-hand corner
%        2 = Upper left-hand corner
%        3 = Lower left-hand corner
%        4 = Lower right-hand corner
%       -1 = To the right of the plot
%
%   CLEGENDM(...,UNITSTR) appends the text UNITSTR to each entry
%   in the legend.
%
%   CLEGENDM(...,STRINGS) uses the text specified by STRINGS.
%   STRINGS must have same number of entries as the line children of H.
%
%   H = CLEGENDM(...) returns the handle to the LEGEND object created.
%
%   Example
%   -------
%   % Create a legend in the lower right-hand corner with a unit string
%   % indicating that the contour elevations are in meters.
%   load topo60c
%   worldmap world
%   [c,h] = contourm(topo60c,topo60cR,-6000:1500:6000);
%   clegendm(c,h,4,' m')
%
%   Note
%   ----
%   When the STRINGS input is omitted, contour values increase from bottom
%   to the top within the legend. But if a list of strings is provided, the
%   contour values increase from top to bottom. The elements of STRINGS
%   follow the same order. (The first element of STRINGS labels the lowest
%   level contour and they appear together at the top of the legend.) This
%   ordering convention is consistent with the order imposed by the
%   'Strings' property of MATLAB contour objects.
%
%   See also CLABELM, CONTOURCBAR, CONTOURFM, CONTOURM, CONTOUR3M, LEGEND

% Copyright 1996-2020 The MathWorks, Inc.

% Validate number of inputs.
narginchk(2, 4)

% Parse the inputs.
[varargin{:}] = convertStringsToChars(varargin{:});
[h, location, strings] = parseInputs(varargin);

% Set the DisplayName of each contour line. And, if strings is a cell
% array, orders the handles in hLine such that the lowest level contour
% comes first and the highest level contour comes last.
hLines = setDisplayNames(h, strings);

if ~isempty(hLines)
    % Construct a legend.
    hLegend0 = legend(hLines,'Location',location);
else
    hLegend0 = [];
end

% Assign output if requested.
if nargout > 0
    hLegend = hLegend0;
end

%--------------------------------------------------------------------------

function [h, loc, strings] = parseInputs(inputs)
% Parse the INPUTS cell array.

% Obtain G, LOC, and STRINGS from INPUTS. Note that the contour matrix, C,
% is not needed.
switch numel(inputs)
    case 2
        % CLEGENDM(CS, H)
        % c = varargin{1};
        g = inputs{2};
        loc = 0;
        strings = {};
    case  3
        % c = varargin{1};
        g = inputs{2};
        if ischar(inputs{3}) || iscell(inputs{3})
            % CLEGENDM(CS, H, 'UNITSTR'/STRINGS)
            loc = 0;
            strings = inputs{3};
        else
            % CLEGENDM(CS, H, LOC)
           loc = inputs{3};
           strings = {};
        end
    case 4
        % CLEGENDM(CS, H, 'UNITSTR'/STRINGS)
        % c = varargin{1};
        g = inputs{2};
        loc = inputs{3};
        strings = inputs{4};
end

% Validate that the handle input is from CONTOURM, CONTOURFM, or CONTOUR3M.
assert(~isempty(g) && ishghandle(g, 'hggroup'), ...
    'map:clegendm:notHgGroupHandle', ...
    'The parameter, H, is not an hggroup handle from %s, %s, or %s.', ...
    'CONTOURM', 'CONTOURFM', 'CONTOUR3M');

% Get the geographic contour graphics object.
h = getappdata(g, 'mapgraph');

% Validate the handle.
assert(isa(h,'internal.mapgraph.GeographicContourGroup'), ...
    'map:clegendm:notGeoContourGroupHandle', ...
    'The handle, H, is not a handle from %s, %s, or %s.', ...
    'CONTOURM', 'CONTOURFM', 'CONTOUR3M');

% Validate LOC
validateattributes(loc, {'numeric'}, ...
    {'scalar', 'integer', '<=',4, '>=',-1}, mfilename, 'LOC', 3);

% Convert LOC to string value
locTable = { ...
    'NorthEastOutside', ...
    'Best', ...
    'NorthEast', ...
    'NorthWest', ...
    'SouthWest', ...
    'SouthEast'};
loc = lower(locTable{loc+2});

% Validate UNITSTR, STRINGS
if ischar(strings)
    validateattributes(strings, {'char','string'}, ...
        {'nonempty'}, mfilename, 'UNITSTR', 4);
else
    validateattributes(strings, {'cell','string'}, ...
       {'2d'}, mfilename, 'STRINGS', 4);
end

%--------------------------------------------------------------------------

function hLines = setDisplayNames(h, strings)
% Given the handle H to a geographic contour group, set the DisplayName of
% each of its line children, and return and ordered vector containing their
% handles.  STRINGS can be: (1) empty, (2) a unit string, or (3) a cell
% array of strings.

% Find the line children of h.HGGroup -- these are the contour lines.
hLines = findobj(get(h.HGGroup,'Children'),'Type','line');

% Leading text that needs to be stripped off from the Tag value of each
% line to isolate its numeric value (expressed as a string).
skip = length('contour line: ');

% Decode second input.
if isempty(strings)
    % Empty.
    unitstr = '';
    useTag = true;
elseif ischar(strings)
    % Unit string.
    unitstr = strings;
    useTag = true;
else
    % List of strings in cell array. First string goes with lowest contour
    % which plots at the top of the legend. (Otherwise lowest contour plots
    % at the bottom of the legend.)
    useTag = false;
    hLines = hLines(end:-1:1);
end

% Set the DisplayName property on each of the contour lines.
for k = 1:numel(hLines)
    hLine = hLines(k);
    if useTag
        % Extract the contour level from the tag string
        % and append the unit string.
        tag = get(hLine,'Tag');        
        displayName = [tag(skip+1:end) unitstr];
    else
        displayName = strings{k};
    end
    set(hLine,'DisplayName',displayName)
end
