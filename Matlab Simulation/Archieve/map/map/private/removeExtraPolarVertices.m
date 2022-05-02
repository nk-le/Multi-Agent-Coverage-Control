function [lat, lon] = removeExtraPolarVertices(lat, lon, tolSnap)
% Clean up polar vertices found in the latitude-longitude column vectors
% LAT and LON: Snap nearly-polar vertices to the poles, remove the
% middle vertices from runs of three or more vertices at either pole,
% remove adjacent, coincident polar vertices, and remove any part that
% contains in which all the vertices are at the north pole, or all
% the vertices are at the south pole. LAT and LON may include
% NaN-separators.

% Copyright 2010 The MathWorks, Inc.

% Snap nearly-polar (and "beyond-polar") vertices to the poles.
lat(90 - lat < tolSnap) =  90;
lat(90 + lat < tolSnap) = -90;

polarVertices = ~isempty(lat) && ((max(lat) == 90) || (min(lat) == -90));
if polarVertices
    % Remove middle vertices from runs of 3 or more north polar vertices.
    f = find(lat == 90);
    t = [-1; diff(f)];
    extraVertices = f([diff(t); 1] == 0);
    lat(extraVertices) = [];
    lon(extraVertices) = [];
    
    % Remove middle vertices from runs of 3 or more south polar vertices.
    f = find(lat == -90);
    t = [-1; diff(f)];
    extraVertices = f([diff(t); 1] == 0);
    lat(extraVertices) = [];
    lon(extraVertices) = [];
    
    % Detect pairs of adjacent polar vertices with the same longitude
    % values, and remove one element from each pair.
    duplicatesNorth = (lat == 90) ...
        & [diff(lat) == 0; false] & [diff(lon) == 0; false];
    duplicatesSouth = (lat == -90) ...
        & [diff(lat) == 0; false] & [diff(lon) == 0; false];
    duplicates = duplicatesNorth | duplicatesSouth;
    lat(duplicates) = [];
    lon(duplicates) = [];
    
    % Remove any part that contains only north polar vertices or only south
    % polar vertices (and keep parts with vertices at both poles).
    [first, last] = internal.map.findFirstLastNonNan(lat);
    for k = 1:numel(first)
        s = first(k);
        e = last(k);
        if all(lat(s:e) == 90) || all(lat(s:e) == -90)
            lat(s:e) = NaN;
            lon(s:e) = NaN;
        end
    end
    [lat, lon] = removeExtraNanSeparators(lat, lon);
end
