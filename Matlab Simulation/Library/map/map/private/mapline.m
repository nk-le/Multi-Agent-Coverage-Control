function varargout = mapline(xdata, ydata, varargin)
%MAPLINE Display line without projection
%
%   Construct a line object for display in map (x-y) coordinates. Return
%   empty if XDATA and YDATA are empty.
%
%   Example
%   -------
%   load coast
%   figure
%   mapline(long, lat, 'Color', 'black')

% Copyright 2006-2011 The MathWorks, Inc.

% Verify NaN locations are equal.
if ~isequal(isnan(xdata), isnan(ydata))
   error('map:mapline:inconsistentXY', ...
       'XDATA and YDATA mismatch in size or NaN locations.')
end

if ~isempty(xdata) || ~isempty(ydata)
   % Create the line object and set the default color to blue.
   h = line(xdata(:), ydata(:), 'Color', [0 0 1], varargin{:});
else
   % Either xdata or ydata are empty.
   h = reshape([],[0 1]);
end

% Suppress output if called with no return value and no semicolon.
if nargout > 0
   varargout{1} = h;
end
