function [lat, lon] = ...
    trimPolygonToQuadrangle(lat, lon, latlim, lonlim, inc)
%TRIMPOLYGONTOQUADRANGLE Trim lat-lon polygon to quadrangle
%
%   [latTrimmed, lonTrimmed] = ...
%       trimPolygonToQuadrangle(lat, lon, latlim, lonlim, inc) trims the
%   polygon defined by vectors LAT and LON to the latitude-longitude
%   quadrangle defined by LATLIM and LONLIM. LAT and LON may contain
%   multiple rings separated by NaNs.  Outer rings should be clockwise,
%   inner rings counterclockwise.  INC is the angular distance increment to
%   be used to define the edges of trimmed polygons that intersect edge of
%   the small circle itself.  All inputs and outputs are assumed to be in
%   units of radians.

% Copyright 2005-2017 The MathWorks, Inc.

% Skip operation for empty inputs.
if isempty(lat)
    return
end

% Work with column vectors throughout, but keep track of input shape.
rowVectorInput = (size(lat,2) > 1);
lat = lat(:);
lon = lon(:);

% Make sure lat and lon arrays are NaN-terminated.
nanTerminatedInput = isnan(lon(end));
if ~nanTerminatedInput
    lon(end+1,1) = NaN;
    lat(end+1,1) = NaN;
end

% Tolerance for snapping to limits.
tolSnap = 10*eps(pi);

% Tolerance for closing nearly-closed polygons.
tolClose = 5*pi/180;

% Pre-process lat-lon polygons.
[lat, lon] = preprocessLatLonPolygons(lat, lon, tolSnap, tolClose);

% Trim to longitude limits.
[lat, lon] = trimLongitudes(lat, lon, lonlim, tolSnap);

% Trim to latitude limits.
[lat, lon] = trimLatitudes(lat, lon, latlim(1), 'lower', tolClose);
[lat, lon] = trimLatitudes(lat, lon, latlim(2), 'upper', tolClose);

% Interpolate points along the edges where the original polygon has been
% truncated to fit within the latitude-longitude limits.
[lat, lon] = snapAndInterpolate(lat, lon, latlim, lonlim, tolSnap, inc);

% Make NaN-termination consistent with input.
if nanTerminatedInput && ~isempty(lon) && ~isnan(lon(end))
    lon(end+1,1) = NaN;
    lat(end+1,1) = NaN;
end

% Make shape consistent with input.
if rowVectorInput
    lat = lat';
    lon = lon';
end

%--------------------------------------------------------------------------

function [lat, lon] = trimLongitudes(lat, lon, lonlim, tolSnap)
% Trim to longitude limits, assuming that inputs have already been
% unwrapped in longitude.

% Save a copy of the input polygon.
latT = lat;
lonT = lon;

% Treat the polygon edges (both outer and inner) as polylines. This will
% leave dangling endpoints along at the eastern and western edges of the
% quadrangle, which can be dealt with separately.
[lat, lon] = trimPolylineToLonlim(lat, lon, lonlim);

% Clean out any vertical strips left over from polyline trimming.
[lat, lon] = removeResidualsAtLimits(lat, lon, lonlim);

if ~isempty(lat)
    % The polyline trimming process can easily separate what was
    % originally a closed curve into two parts such that the first part
    % ends on the eastern or western edge and the second part starts on
    % the eastern or western edge, with the other ends dangling loose
    % the middle. Such part pairs can be identified because the last
    % vertex of the first part coincides with the first vertex of the
    % second part, and then reconnected. It's important to do this
    % reconnecting end points along the perimeter.
    [lon, lat] = mergeEndToEndPairs(lon, lat, lonlim, tolSnap);
    
    % As needed, reconnect dangling endpoints along the perimeter of
    % the quadrangle, which we treat as a rectangle with a xLimit equal
    % to lonlim and a yLimit of [-pi/2 pi/2].
    [lon, lat] = snapAndClose(lon, lat, lonlim, [-pi/2 pi/2], tolSnap);
    
    % Check for unenclosed counter-clockwise rings.
    if internal.map.ccwRingsAreUnenclosed(lon, lat)
        % All the "outermost" rings are counter-clockwise; enclose them
        % within a clockwise ring tracing the perimeter of the quadrangle.
        lat = [[-1 1 1 -1 -1]' * pi /2; NaN; lat];
        lon = [lonlim([1 1 2 2 1])';    NaN; lon];
    end
else
    % All the inputs have been trimmed away. Repeat processing with the
    % complement of the longitude limits and check for unenclosed
    % counter-clockwise rings (that fall completely outside the
    % quadrangle).
    complement = [lonlim(2) - 2*pi, lonlim(1)];
    [latT, lonT] = trimPolylineToLonlim(latT, lonT, complement);
    [latT, lonT] = removeResidualsAtLimits(latT, lonT, complement);
    [lonT, latT] = mergeEndToEndPairs(lonT, latT, complement, tolSnap);
    [lonT, latT] = snapAndClose(lonT, latT, complement, [-pi/2 pi/2], tolSnap);
    if internal.map.ccwRingsAreUnenclosed(lonT, latT)
        % Return a clockwise ring tracing the perimeter of the quadrangle.
        lat = [-1 1 1 -1 -1]' * pi / 2;
        lon = lonlim([1 1 2 2 1])';
    end
end

%-----------------------------------------------------------------------

function [x,y] = snapAndClose(x, y, xLimit, yLimit, tolSnap)
% Snap to both sets of limits, then close polygon in rectangle.

[x, y] = map.internal.clip.snapOpenEndsToLimits( ...
    x, y, xLimit, tolSnap, yLimit, tolSnap);

[x, y] = map.internal.clip.closePolygonInRectangle( ...
    x, y, xLimit, yLimit);

%--------------------------------------------------------------------------

function [lat, lon] = trimLatitudes(lat, lon, latBound, boundType, tolClose)
% Apply a lower or upper latitude limit, in between forward and backward
% 90-degree clockwise rotations.

if ~isempty(lat)
    lon = -lon;
    [lat, lon] = trimPolygonToVerticalLine( ...
        lat, lon, latBound, boundType, tolClose);
    lon = -lon;
end

%--------------------------------------------------------------------------

function [lat, lon] = snapAndInterpolate( ...
    lat, lon, latlim, lonlim, tolSnap, inc)

if ~isempty(lat)
    % Snap points that are very close to the latitude and longitude limits.
    closeOnWest = abs(lon - lonlim(1)) < tolSnap;
    closeOnEast = abs(lon - lonlim(2)) < tolSnap;
    closeOnSouth = abs(lat - latlim(1)) < tolSnap;
    closeOnNorth = abs(lat - latlim(2)) < tolSnap;

    lon(closeOnWest) = lonlim(1);
    lon(closeOnEast) = lonlim(2);
    lat(closeOnSouth) = latlim(1);
    lat(closeOnNorth) = latlim(2);

    % Interpolate points along the edges where the original polygon has been
    % truncated to fit within the x,y-limits.
    [lon, lat] = interpolateAlongVerticalEdge(lon, lat, lonlim(1), inc);  % West edge
    [lon, lat] = interpolateAlongVerticalEdge(lon, lat, lonlim(2), inc);  % East edge
    [lat, lon] = interpolateAlongVerticalEdge(lat, lon, latlim(1), inc);  % South edge
    [lat, lon] = interpolateAlongVerticalEdge(lat, lon, latlim(2), inc);  % North edge
end

%-----------------------------------------------------------------------

function [lat, lon] = removeResidualsAtLimits(lat, lon, lonlim)
% If the process of trimming polylines in longitude has left any
% vertical strips at either the western or eastern longitude limit,
% remove them.

[first, last] = internal.map.findFirstLastNonNan(lat);
iRemove = false(size(lat));
for k = 1:numel(first)
    if all(lon(first(k):last(k)) <= lonlim(1)) || ...
       all(lon(first(k):last(k)) >= lonlim(2))
        iRemove(first(k):last(k)) = true;
    end 
end
lat(iRemove) = [];
lon(iRemove) = [];

%-----------------------------------------------------------------------

function [x, y] = mergeEndToEndPairs(x, y, xlimit, tolSnap)
% Merge end-to-end all pairs of NaN-separated curves for which the last
% point in one curve is the first point in another curve.  Assert that
% such connections occur only as isolated pairs -- we do not expect to
% encounter a chain of pairs.  The operation performed here is related
% to what function POLYMERGE does, but is more specialized and has a
% more streamlined implementation.

% Indices of the first and last vertex in each curve.
[first, last] = internal.map.findFirstLastNonNan(x);

% Remove closed loops (and isolated points) from further consideration
closed = abs(x(first) - x(last)) < tolSnap ...
       & abs(y(first) - y(last)) < tolSnap;
first(closed) = [];
last(closed) = [];

if ~isempty(first)
    % Find connecting pairs by comparing square matrices (xFirst vs.
    % xLast and yFirst vs. yLast) in which the coordinates of the first
    % vertices are replicated across the columns and the coordinates of the
    % last vertices are replicated down the rows.
    O = ones(1,numel(first));
    xFirst = x(first,O);
    yFirst = y(first,O);
    xLast = x(last,O)';
    yLast = y(last,O)';
    [i2,i1] = find(abs(xFirst - xLast) < tolSnap & ...
        abs(yFirst - yLast) < tolSnap);
    
    % Column vectors first1, first2, last1, and last2 have one element per
    % pair. first1 indexes the first vertex of the first element in each of
    % the pairs, and last1 indexes the last vertex of the first element.
    % Likewise, first2 and last2 index the first and last vertices of the
    % second element of each pair.
    first1 = first(i1);
    first2 = first(i2);
    last1 = last(i1);
    last2 = last(i2);
    
    % Exclude pairs that connect at xlimit(1) or xlimit(2).  Compare using
    % the same tolerance that will be later be used to snap the end points
    % of open curves to the limits.
    onEdge = abs(x(first2) - xlimit(1)) < tolSnap ...
           | abs(x(first2) - xlimit(2)) < tolSnap;
    first1(onEdge) = [];
    first2(onEdge) = [];
    last1( onEdge) = [];
    last2( onEdge) = [];
    
    % We expect only pair-wise connections.
    pairwiseConnectionsOnly ...
        = isempty(intersect(first1,first2)) && isempty(intersect(last1,last2));
    map.internal.assert(pairwiseConnectionsOnly, 'map:topology:connectionsChain')
    
    % If there are non-unique elements in last1, that means there's at
    % least one vertex at which one or more segments end and two or more
    % segments start.
    [first1, last1, first2, last2] = removeRedundantPairs(x, y, ...
        first1, last1, first2, last2);
    
    % Grow indices for connecting and removing pairs.
    iJoin = [];
    iRemove = [];
    for k = 1:numel(first1)
        % For joining pairs; include terminating NaN from second segment
        % and avoid duplicating the shared vertex.
        iJoin = [iJoin first1(k):(last1(k)-1) first2(k):(1 + last2(k))];  %#ok<AGROW>
        
        % For removing pairs; include terminating NaNs from both segments.
        iRemove = [iRemove first1(k):(1 + last1(k)) first2(k):(1 + last2(k))];  %#ok<AGROW>
    end
    
    % Connect all the pairs.
    xJoined = x(iJoin);
    yJoined = y(iJoin);
    
    % And remove them from the original vertex arrays.
    x(iRemove) = [];
    y(iRemove) = [];
    
    % Add connected pairs back at the front of the vertex arrays.
    x = [xJoined; x];
    y = [yJoined; y];
end

%-----------------------------------------------------------------------

function [first1, last1, first2, last2] ...
    = removeRedundantPairs(x, y, first1, last1, first2, last2)
% Apply a "minimum interior angle" criterion to eliminate ambiguous
% connections and avoid pairing up the same segment more than once.
% Note that we've already removed all isolated points, if any, so each
% curve has at least 2 vertices. This means that the expressions ui-1 and
% iv+1 used in the loop below will always turn out to be valid indices.

last1Unique = unique(last1);
if numel(last1Unique) < numel(last1)
    % There are duplicates in last1. Remove them, along with the
    % corresponding elements of first1, first2, and last2.
    for k = 1:numel(last1Unique)
        % For each unique value in last1, find the "interior angle"
        % corresponding to all instances. Keep only the instance with the
        % smallest interior angle.
        index = find(last1 == last1Unique(k));
        iu = last1(index(1));
        ux = x(iu) - x(iu-1);
        uy = y(iu) - y(iu-1);
        iv = first2(index);
        vx = x(iv+1) - x(iv);
        vy = y(iv+1) - y(iv);
        theta = interiorAngle(ux, uy, vx, vy);
        remove = index(theta > min(theta));
        first1(remove) = [];
        first2(remove) = [];
        last1(remove) = [];
        last2(remove) = [];
    end
end
