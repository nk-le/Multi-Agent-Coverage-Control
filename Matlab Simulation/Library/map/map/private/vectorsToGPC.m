function p = vectorsToGPC(x, y, varargin)
% Convert polygon representation from a pair of NaN-separated coordinate
% vectors to a structure array that can be passed to gpcmex.
%
%   p = vectorsToGPC(x, y)
%   p = vectorsToGPC(x, y, func_name, var_name_1, var_name_2)

% Copyright 2009-2016 The MathWorks, Inc.

% Locate the vertex coordinates within the NaN-separated arrays.
[first,last] = internal.map.findFirstLastNonNan(x);

% Pre-allocate structure array.
p(1, numel(first)) = struct('x',[],'y',[],'ishole',[]);

% Loop over parts and assign fields.
ishole = ~ispolycw(x,y);
for k = 1:numel(first)
    p(k).x = x(first(k):last(k));
    p(k).y = y(first(k):last(k));
    p(k).ishole = ishole(k);
end

% If all three optional inputs have been provided, check to see if
% there's at least one clockwise ring and warn if there is not.
if numel(varargin) == 3
    warnNoClockwiseRing(p, varargin{:})
end

%-----------------------------------------------------------------------

function warnNoClockwiseRing(p, func_name, var_name_1, var_name_2)
% Warn if the GPC structure P fails to contain at least one clockwise ring

if ~isempty(p) && all([p.ishole])
   warning('map:polygon:noExternalContours', ...
       ['(%s,%s) contains no external contours. Function %s assumes that' ...
       ' that external contours have clockwise-ordered vertices,', ...
       ' and all contours in (%s,%s) have counterclockwise-ordered', ...
       ' vertices. Use %s to reverse the vertex order if necessary.'], ...
       var_name_1, var_name_2, upper(func_name), ...
       var_name_1, var_name_2, 'POLY2CW')
end
