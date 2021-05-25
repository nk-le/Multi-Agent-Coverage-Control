function varargout = mappointshow(xdata, ydata, varargin)
%MAPPOINTSHOW Display points without projection
%
%   Construct a line object for display in map (x-y) coordinates. Set the
%   LineStyle to 'none' so that only the coordinate points are displayed.
%   Set the Marker and MarkerEdgeColor to default values that can be reset
%   with VARARGIN.  Return empty if XDATA and YDATA are empty.
%
%   Example
%   -------
%   load coast
%   figure
%   mappointshow(long, lat)

% Copyright 2012 The MathWorks, Inc.

h = mapline(xdata, ydata, ...
   'Marker', '+', 'MarkerEdgeColor', 'red', varargin{:}, 'LineStyle', 'none');

% Suppress output if called with no return value and no semicolon.
if nargout > 0
    varargout{1} = h;
end
