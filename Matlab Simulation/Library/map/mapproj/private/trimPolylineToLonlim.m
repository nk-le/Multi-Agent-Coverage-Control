function [lat, lon] = trimPolylineToLonlim(lat, lon, lonlim)
% Trim the polyline defined by column vectors LAT and LON to the longitude
% limits defined by LONLIM. LAT and LON may contain multiple parts
% separated by NaNs.  All inputs and outputs are assumed to be in units of
% radians.

% Copyright 2008 The MathWorks, Inc.

% Determine pairs of limits to use for trimming in longitude.
[w, e] = expandLonlim(lonlim, min(lon), max(lon));

latcells = cell(1,numel(w));
loncells = cell(1,numel(w));
for k = 1:numel(w)
    % Trim unwrapped longitudes to the western limit of the k-th pair.
    [lonk, latk] = trimPolylineToVerticalLine(lon, lat, w(k), 'lower');
        
    % Now trim to the eastern limit of the k-th pair.
    [lonk, latk] = trimPolylineToVerticalLine(lonk, latk, e(k), 'upper');
    
    % Shift to the interval:  lonlim(1) + [0 2*pi];
    lonk = lonk + (lonlim(1) - w(k));
    
    latcells{k} = latk;
    loncells{k} = lonk;
end

% Combine the results.
[lat, lon] = polyjoin(latcells, loncells);

% Clean up
[lat, lon] = removeExtraNanSeparators(lat,lon);

%-----------------------------------------------------------------------

function [w, e] = expandLonlim(lonlim, minlon, maxlon)
% Compute western and eastern limits (w and e) consistent with the
% limits (minlon, maxlon) of the unwrapped longitudes.  Most often the
% limits will be scalars, but in certain cases (such as a long curve
% that spirals around the Earth) there can be two or even more
% intervals to work with.  In such cases it will be necessary to trim in
% longitude to [w(1) e(1)], then [w(2) e(2)], etc., then take the union
% of the results.

twopi = 2*pi;

% Width of the quadrangle, accounting for possible wrapping.
quadwidth = wrapTo2Pi(lonlim(2) - lonlim(1));

% Longitude difference between the minimum of the unwrapped data
% longitudes and the western limit wrapped to the largest possible
% value that is still less than or equal to the minimum unwrapped data
% longitude.
delta = mod(minlon - lonlim(1), twopi);

% Western-most western limit.
if quadwidth > delta
    ww = minlon - delta;
else
    ww = minlon - delta + twopi;
end

% Eastern-most western limit.
ew = maxlon - mod(maxlon - lonlim(1), twopi);

% Vectors of western and eastern limits.
numberOfIntervals = 1 + round((ew - ww) / twopi);
w = ww + (0:(numberOfIntervals-1)) * twopi;
e = w + quadwidth;

% Adjust limits for rounding to make them coincide with the corresponding
% elements of lonlim if they turn out to be nearly equal.
w = lonlim(1) + twopi * round((w - lonlim(1))/twopi);
e = lonlim(2) + twopi * round((e - lonlim(2))/twopi);

%-----------------------------------------------------------------------

function [lat,lon] = polyjoin(latcells,loncells)
% Private copy of polyjoin that skips argument checking.

M = numel(latcells);
N = 0;
for k = 1:M
    N = N + numel(latcells{k});
end

lat = zeros(N + M - 1, 1);
lon = zeros(N + M - 1, 1);
p = 1;
for k = 1:(M-1)
    q = p + numel(latcells{k});
    lat(p:(q-1)) = latcells{k};
    lon(p:(q-1)) = loncells{k};
    lat(q) = NaN;
    lon(q) = NaN;
    p = q + 1;
end
if M > 0
    lat(p:end) = latcells{M};
    lon(p:end) = loncells{M};
end
