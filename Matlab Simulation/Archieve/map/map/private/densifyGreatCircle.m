function [lat, lon] = densifyGreatCircle(lat, lon, maxsep, angleUnit)
% Insert additional vertices where needed, along great circle arcs
% connecting adjacent pairs of vertices (core computation needed by
% INTERPM and MAPPROFILE).

% Copyright 2019 The MathWorks, Inc.

    % Ensure column vectors.
    lat = lat(:);
    lon = lon(:);
    
    % Compute max angular separation between each pair of adjacent vertices.
    separation = max([abs(diff(lat))'; abs(diff(lon))'])';
    
    % Find separations that exceed the specified limit.
    indx = find(separation > maxsep);
    if ~isempty(indx)
        steps = ceil(separation(indx)/maxsep);
        [lat, lon] = toDegrees(angleUnit, lat, lon);
        [lat, lon] = insertDenseVertices(lat, lon, indx, steps, @linspaceGreatCircle);
        lon = unwrapMultipart(lon,'degree');
        [lat, lon] = fromDegrees(angleUnit, lat, lon);
    end
end


function [latinsert, loninsert] = linspaceGreatCircle(lat, lon, e, step)
% Work in degrees using the great functions from map.geodesy.internal
    lat1 = lat(e);
    lon1 = lon(e);
    lat2 = lat(e+1);
    lon2 = lon(e+1);
    [S,az] = map.geodesy.internal.greatCircleDistance(lat1,lon1,lat2,lon2);
    S = (1:step-1) * S / step;
    [latinsert, loninsert] = map.geodesy.internal.greatCircleTrace(lat1,lon1,S,az);
end
