function [lat, lon] = densifyRhumbline(lat, lon, maxsep, angleUnit)
% Insert additional vertices where needed, along rumbline arcs
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
        % Interpolate additional vertices where needed.
        steps = ceil(separation(indx)/maxsep);
        [lat, lon] = toRadians(angleUnit, lat, lon);
        [lat, lon] = insertDenseVertices(lat, lon, indx, steps, @linspaceRhumbline);
        lon = unwrapMultipart(lon);
        [lat, lon] = fromRadians(angleUnit, lat, lon);
    end
end


function [latinsert, loninsert] = linspaceRhumbline(lat, lon, e, step)
    phi1 = lat(e);
    phi2 = lat(e+1);
    lambda1 = lon(e);
    lambda2 = lon(e+1);
    
    %  Compute distance and azimuth, then sample at intermediate distances.
    [S, az] = rhumblineinv(phi1, lambda1, phi2, lambda2, 1);
    S = (1:step-1)' * S / step;
    
    %  Pass column vectors to rhumblinefwd.
    c = ones(size(S));
    [latinsert, loninsert] = rhumblinefwd(phi1(c,1), lambda1(c,1), az(c,1), S, 1);
    loninsert = wrapToPi(loninsert);
end
