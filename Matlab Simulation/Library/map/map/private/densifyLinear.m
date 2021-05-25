function [lat, lon] = densifyLinear(lat, lon, maxsep)
% Insert additional vertices where needed, between adjacent pairs of
% vertices, with independent linear spacing in latitude and longitude.
% (core computation needed by BUFFERM, INTERPM, and VEC2MTX).

% Copyright 2019 The MathWorks, Inc.

    % Ensure column vectors.
    lat = lat(:);
    lon = lon(:);
    
    % Compute max angular separation between each pair of adjacent vertices.
    separation = max([abs(diff(lat))'; abs(diff(lon))'])';
    
    % Find separations that exceed the specified limit.
    indx = find(separation > maxsep);
    
    if ~isempty(indx)
        % Interpolate additional vertices where needed.
        steps = ceil(separation(indx)/maxsep);
        [lat, lon] = insertDenseVertices(lat, lon, indx, steps, @linspaceLatitudeLongitude);
    end
end


function [latinsert, loninsert] = linspaceLatitudeLongitude(lat, lon, e, step)
% Independent linear spacing in laitude and longitude
    factors = (1:step-1)';
    latinsert = ((lat(e+1)-lat(e))/step)*factors + lat(e);
    loninsert = ((lon(e+1)-lon(e))/step)*factors + lon(e);
end
