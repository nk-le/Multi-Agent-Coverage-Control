function [lat, lon] = adjustPolarVertices(lat, lon, poleLat, tolSnap)
% Preprocess any polygons that touch the designated pole, inserting
% extra polar vertices and adjusting longitudes as needed.

% Copyright 2008-2012 The MathWorks, Inc.

% Identify vertices at latitude poleLat. We generally expect to find at
% most one vertex at a given pole, unless there's a ring that starts and
% ends at the pole and/or two polar vertices are adjacent but have
% different longitudes.
polarVertices = find((abs(lat - poleLat) < tolSnap));

if ~isempty(polarVertices)
    % Indices of the first and last vertex in each ring.
    [first, last] = internal.map.findFirstLastNonNan(lat);
    
    % Process the polar vertices separately for each ring. (It would be
    % very unusual, but allow for one or more rings that share just one
    % point at the pole.) Each time we call adjustPV, it's possible that
    % we'll need to update arrays first and last. (Their sizes won't
    % change, but their contents will if new polar vertices are
    % inserted.) Process the rings in reverse order, because changing a
    % given ring affects the values of first, last, and polarVertices
    % for the rings that follow it but not those that precede it.
    for k = numel(first):-1:1
        s = first(k);
        e = last(k);
        q = (s <= polarVertices) & (polarVertices <= e);
        if any(q)
            p = polarVertices(q);
            [lat, lon] = adjustPV(lat, lon, poleLat, p, s, e);
        end
    end
end

%--------------------------------------------------------------------------

function [lat, lon] = adjustPV(lat, lon, poleLat, p, s, e)
% For valid configurations with polar vertices (with indices given by P)
% within the ring starting with index S and ending with index E.
% There are two basic configurations:
%
% (1) The ring is "pre-trimmed" and makes an artificial visit to the pole,
% where it traverses straight "edge" with length exactly 2*pi.
%
% (2) The ring makes a legitimate visit to the pole, traversing less than
% 2*pi and representing a "wedge" with a single intrinsic polar vertex.
%
% In the first case, remove all polar vertices, plus any extra vertices
% used to "travel" down a meridian to the pole and back. In the second
% case, insert new vertices and adjust longitudes of polar points as
% needed to ensure that the ring both approaches and departs the pole
% along a pure meridional segments. And, if either endpoint is at the
% pole, ensure that the ring is closed. Error if an invalid
% configuration is detected.

% Determine which configuration we have.
minLonPolar = min(lon(p));
maxLonPolar = max(lon(p));
preTrimmed = (abs(maxLonPolar - minLonPolar - 2*pi) < eps(2*pi));

if preTrimmed
    [lat, lon] = adjustPretrimmed(lat, lon, p, s, e);
 else
    % The ring includes a (single) polar wedge.
    if isscalar(p)
        [lat, lon] = adjustPV1(lat, lon, poleLat, p, s, e);
    elseif numel(p) == 2
        [lat, lon] = adjustPV2(lat, lon, p, s, e);
    elseif numel(p) == 3
        [lat, lon] = adjustPV3(lat, lon, p, s, e);
    elseif numel(p) > 3
        error(message('map:topology:tooManyPolarVertices', numel(p)))
    end
end

%--------------------------------------------------------------------------

function [lat, lon] = adjustPretrimmed(lat, lon, p, s, e)
% Eliminate all polar vertices and any other redundant vertices that
% may lie along meridians leading to the pole and back.

% Perform a simple check to partially validate the input.
k = find(diff(p) > 1);
map.internal.assert(numel(k) <= 1, ...
    'map:topology:multipleVisitsToPole', numel(k))

% Construct logical vectors identifying the polar and meridional
% vertices within the ring, for indices s:e.  After excluding one or two
% of the meridional vertices, we'll remove all the polar vertices, the
% non-exluded meridional vertices, and a possible duplicate vertex to be
% introduced later during a shift operation.
%
% The duplicate vertex will occur if vertex e coincides with vertex s.
% If these vertices fall in the "coastline" segment, then they'll end up
% adjacent following the shift, and one of them will have to be deleted.
% The choice as to which is arbitrary, and the code below selects vertex
% e. If the duplication happens elsewhere (e and s are polar or
% non-coastal meridional vertices), then vertex e will be deleted
% anyway. In this case, it's not actually necessary to tag it as a
% duplicate, but neither is any harm done by doing so.

sz = size(lat);

atPole          = false(sz);
onMeridian      = false(sz);
duplicateVertex = false(sz);

atPole(p) = true;
onMeridian(s:e) = (lon(s:e) ==  min(lon(p))) | (lon(s:e) == max(lon(p)));
duplicateVertex(e) = (lat(e) == lat(s)) && (lon(e) == lon(s));

% Exclude one or two of the meridional vertices that might also be
% coastline vertices. Ensure that these are kept by setting the
% corresponding elements of onMeridian to false.

index = find(atPole | onMeridian);
k = find(diff(index) ~= 1);
if isempty(k) && ~isempty(index)
    % Only one sequence of polar and/or meridional vertices.
    if index(1) == s
        % Sequence starts at the start point; keep the last vertex.
        onMeridian(index(end)) = false;
    elseif index(end) == e
        % Sequence ends at the end point; keep the first vertex.
        onMeridian(index(1)) = false;
    else
        % Sequence falls in the middle; keep first and last vertices.
        onMeridian(index([1 end])) = false;
    end
elseif isscalar(k)
    % Two sequences of polar and/or meridional vertices.
    onMeridian(index([k k+1])) = false;
end

% If the ring starts and ends somewhere within the sequence of vertices
% that forms the "coastline" (the actual external boundary of the
% ring, that is) then:
%
% * The vertex order of the ring will have to be permuted via a circular
%   shift to ensure continuity after the polar and meridional vertices
%   are removed.
%
% * There is likely to be a pair of adjacent duplicate vertices. This
%   would result from the shift moving identical first and last vertices
%   to adjacent positions in the coordinate arrays.

breakInCoastline ...
    = ~atPole(s) && ~onMeridian(s) && ~atPole(e) && ~onMeridian(e);

% Get ready to remove the polar vertices, meridional vertices that are not
% also coastline vertices, and a possible duplicate vertex.
removeVertex = atPole | onMeridian | duplicateVertex;

if breakInCoastline
    % Permute the vertices to ensure that the coastline is contiguous.
    k = find(atPole | onMeridian);
    shift = (k(1) - s + 1);
    permutation = circshift(s:e, [0 shift]);
    lat(s:e) = lat(permutation);
    lon(s:e) = lon(permutation);
    
    % Permute the removeVertex vector to ensure consistency.  There's no
    % need to permute atPole, onMeridian, or duplicateVertex because
    % they are not used after this point.
    removeVertex(s:e) = removeVertex(permutation);
end

% Remove vertices with a single operation on each coordinate array.
lat(removeVertex) = [];
lon(removeVertex) = [];

%--------------------------------------------------------------------------

function [lat, lon] = adjustPV1(lat, lon, poleLat, p, s, e)
% Insert polar vertices when numel(p) == 1.

if p == s
    % Ring starts at pole.
    
    % Ensure that the first segment follows the meridian.
    lon(s) = lon(s+1);
    
    % Insert a new polar vertex after the current end point,
    % replicating its longitude.
    [lat, lon] = insertVertex(lat, lon, poleLat, lon(e), e+1);
elseif p == e
    % Ring ends at pole.
    
    % Ensure that the last segment follows the meridian.
    lon(e) = lon(e-1);
    
    % Insert a new polar vertex before the current start point,
    % replicating its longitude.
    [lat, lon] = insertVertex(lat, lon, poleLat, lon(s), s);
else
    % The polar point falls somewhere in the middle of the ring.
    
    ringIsClosed = (lon(s) == lon(e)) && (lat(s) == lat(e));
    if ringIsClosed
        % Shift to start and end at the pole.  Omit the start point
        % (an arbitrary choice; omitting the end point could work as
        % well) and add a new polar vertex (thus conserving vertices).
        lon(s:e) = [lon(p+1); lon(p+1:e); lon(s+1:p-1); lon(p-1)];
        lat(s:e) = [poleLat;  lat(p+1:e); lat(s+1:p-1); poleLat];
    else
        % Shift to start at the pole, preserving the both original start
        % and end points, then insert a new polar vertex (increasing
        % the vertex count by 1).
        lon(s:e) = [lon(p+1); lon(p+1:e); lon(s:p-1)];
        lat(s:e) = [poleLat;  lat(p+1:e); lat(s:p-1)];
        [lat, lon] = insertVertex(lat, lon, poleLat, lon(e), e+1);
    end
end

%--------------------------------------------------------------------------

function [lat, lon] = adjustPV2(lat, lon, p, s, e)
% Adjust polar vertices when numel(p) == 2.

p1 = p(1);
p2 = p(2);
if (p1 == s) && (p2 == e)
    % Ring starts and ends at pole.
    
    % Ensure that the first segment follows the meridian.
    lon(s) = lon(s+1);
    
    % Ensure that the last segment follows the meridian.
    lon(e) = lon(e-1);
elseif (p2 - p1) == 1
    % Ring includes two adjacent polar vertices.
    
    if p1 == s
        % Ring starts at pole.
        
        % Ensure that ring leaves pole along meridian.
        lon(s+1) = lon(s+2);
        
        % Ensure that ring returns to pole along meridian.
        lon(s) = lon(e);
        
        % Permute vertices to start and end at pole.
        indx = [(s+1:e) s];
        lat(s:e) = lat(indx);
        lon(s:e) = lon(indx);
    elseif p2 == e
        % Ring ends at pole.
        
        % Ensure that ring leaves pole along meridian.
        lon(e) = lon(s);
        
        % Ensure that ring returns to pole along meridian.
        lon(e-1) = lon(e-2);
        
        % Permute vertices to start and end at pole.
        indx = [e (s:e-1)];
        lat(s:e) = lat(indx);
        lon(s:e) = lon(indx);
    else
        % Ring touches pole somewhere in the middle.
        
        % Ensure that ring approaches pole along meridian.
        lon(p1) = lon(p1-1);
        
        % Ensure that ring leaves pole along meridian.
        lon(p2) = lon(p2+1);
        
        % Permute vertices to start and end at pole.
        ringIsClosed = (lon(s) == lon(e)) && (lat(s) == lat(e));
        if ringIsClosed
            % We should end up with one fewer vertices than we started
            % within order to avoid two adjacent copies of the original
            % start/end vertex.
            lat(s:e-1) = [lat(p2:e); lat(s+1:p1)];
            lon(s:e-1) = [lon(p2:e); lon(s+1:p1)];
            lat(e) = [];
            lon(e) = [];
        else
            % Ring is open, let it stay open (and conserve vertices).
            lat(s:e) = [lat(p2:e); lat(s:p1)];
            lon(s:e) = [lon(p2:e); lon(s:p1)];
        end
    end
else
    error(message('map:topology:invalidPairOfPolarVertices'))
end

%--------------------------------------------------------------------------

function [lat, lon] = adjustPV3(lat, lon, p, s, e)
% Insert polar vertices when numel(p) == 3.

if isequal(p, [s s+1 e]')
    % Ensure that ring approaches pole along meridian.
    lon(e) = lon(e-1);
    
    % Remove redundant vertex, ensuring that ring is open at pole.
    lon(s) = [];
    lat(s) = [];
    
    % Ensure that ring leaves pole along meridian.
    lon(s) = lon(s+1);
    
elseif isequal(p, [s e-1 e]')
    % Ensure that ring leaves pole along meridian.
    lon(s) = lon(s+1);
    
    % Ensure that ring approaches pole along meridian.
    lon(e-1) = lon(e-2);
    
    % Remove redundant vertex, ensuring that ring is open at pole.
    lon(e) = [];
    lat(e) = [];
else
    error(message('map:topology:invalidTripletOfPolarVertices'))
end

%--------------------------------------------------------------------------

function [x, y] = insertVertex(x, y, xs, ys, k)
% Insert a new scalar vertex (xs, ys) into the coordinate arrays (x, y),
% replacing the k-th vertex and shifting all subsequent vertices
% forward by one element.

x = [x(1:k-1); xs; x(k:end)];
y = [y(1:k-1); ys; y(k:end)];
