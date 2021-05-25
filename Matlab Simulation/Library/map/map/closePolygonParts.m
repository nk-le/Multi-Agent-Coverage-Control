function [xdata, ydata] = closePolygonParts(xdata, ydata, angleunits)
%closePolygonParts  Close all rings in multipart polygon
%
%   [XDATA, YDATA] = closePolygonParts(XDATA, YDATA) ensures that each
%   ring in a multipart (NaN-separated) polygon is "closed" by repeating
%   the first vertex at the end of the ring, unless the beginning and end
%   are already identical.  Coordinate vectors XDATA and YDATA must
%   match in size and have identical NaN locations.
%
%   [LAT, LON] = closePolygonParts(LAT, LON, ANGLEUNITS) works with
%   latitude-longitude data and accounts for longitude wrapping with a
%   period of 360 if ANGLEUNITS is 'degrees' and 2*pi if ANGLEUNITS is
%   'radians'.  For a ring to be considered closed, the latitudes of its
%   first and last vertices must match exactly, but their longitudes
%   need only match modulo the appropriate period.  Such rings are
%   returned unaltered.
%
%   X-Y Example
%   -----------
%   xOpen = [1 0 2 NaN 0.5 0.5 1 1];
%   yOpen = [0 1 2 NaN 0.8 1 1 0.8];
%   [xClosed, yClosed] = closePolygonParts(xOpen, yOpen)
%
%   Lat-Lon Example
%   ---------------
%   % Construct a two-part polygon based on coast.mat.  The first ring
%   % is Antarctica.  The longitude of its first vertex is -180 and the
%   % longitude of its last vertex is 180.  The second ring is a small
%   % island from which the last vertex, a replica of the first vertex,
%   % is removed.
%   c = load('coast.mat');
%   [latparts, lonparts] = polysplit(c.lat, c.long);
%   latparts{2}(end) = [];
%   lonparts{2}(end) = [];
%   latparts(3:end) = [];
%   lonparts(3:end) = [];
%   [lat, lon] = polyjoin(latparts, lonparts);
%
%   % Examine how closePolygonParts treats the two rings.  In both
%   % cases, the first and last vertices differ.  However, Antarctica
%   % remains unchanged while the small island is closed back up.
%   [latClosed, lonClosed] = closePolygonParts(lat, lon, 'degrees');
%   [latpartsClosed, lonpartsClosed] = polysplit(latClosed, lonClosed);
%   lonpartsClosed{1}(end) - lonpartsClosed{1}(1)  % Result is 360
%   lonpartsClosed{2}(end) - lonpartsClosed{2}(1)  % Result is 0

% Copyright 2005-2010 The MathWorks, Inc.

% Assign a predicate that checks if a part is open or closed.
if nargin == 3
    % Work in latitude-longitude.  Interpret the first argument (xdata)
    % as latitude and the second argument (ydata) as longitude.  It is
    % essential for the function interface defined in the help above and
    % the partsIsClosed function defined below to be consistent about
    % this.
    period = fromDegrees(angleunits,360);
    partIsClosed = @(latStart, lonStart, latEnd, lonEnd) ...
        (latStart == latEnd) && (mod(lonStart,period) == mod(lonEnd,period));
else
    % Work in X-Y.
    partIsClosed = @(xStart, yStart, xEnd, yEnd) ...
        (xStart == xEnd) && (yStart == yEnd);
end

% Clean up the data.
[xdata, ydata] = removeExtraNanSeparators(xdata, ydata);

% Find NaN locations.
nanInd = find(isnan(xdata));

% Simulate the trailing NaN if it's missing.
simulateTrailingNaN = ~isempty(xdata) && ~isnan(xdata(end));
if simulateTrailingNaN
    nanInd(end+1) = numel(xdata) + 1;
end

% Build an index to help replicate the start point for each open part in
% xdata and ydata.
numParts = numel(nanInd);
newInd = [];
nanInd = [0; nanInd(:)];
for k = 1:numParts
    iStart = nanInd(k)   + 1;
    iEnd   = nanInd(k+1) - 1;
    if partIsClosed(xdata(iStart), ydata(iStart), xdata(iEnd), ydata(iEnd))
        newInd = [newInd, iStart:iEnd, (iEnd + 1)]; %#ok<AGROW>
    else
        newInd = [newInd, iStart:iEnd, iStart, (iEnd + 1)]; %#ok<AGROW>
    end
end

% Make sure not to run off the end of the xdata, ydata arrays if they don't
% each really have a terminating NaN.
if simulateTrailingNaN
    newInd(end) = [];
end

% Replicate start points as needed.
xdata = xdata(newInd);
ydata = ydata(newInd);
