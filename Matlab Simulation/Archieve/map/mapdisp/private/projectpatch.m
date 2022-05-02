function [x, y, z, userdata] = projectpatch(mstruct, lat, lon, z)
% Project patch vertices using newer polygon trimming.

% Copyright 2007-2012 The MathWorks, Inc.

% Save the input data in a structure that will be accepted by ismapped
userdata.clipped = [];
userdata.trimmed = [];
userdata.lat = lat;
userdata.lon = lon;
userdata.z = z;

%  Project the patch vertices, with special handling in the case of 'globe'
if ~strcmp(mstruct.mapprojection,'globe')
    [x, y] = projectpatch2D(mstruct, lat, lon);
    z = z(ones(size(x)));
    z(isnan(x)) = NaN;
else
    spheroid = map.internal.mstruct2spheroid(mstruct);
    [lat, lon] = toDegrees(mstruct.angleunits, lat, lon);
    [x, y, z] = spheroid.geodetic2ecef(lat, lon, z);
end

%-----------------------------------------------------------------------

function [x, y] = projectpatch2D(mstruct, lat, lon)

if isempty(lat)
    x = [];
    y = [];
    return
end

[first, last] = internal.map.findFirstLastNonNan(lat);
lon = fromRadians(mstruct.angleunits, ...
    unwrapMultipart(toRadians(mstruct.angleunits,lon)));

% Identify counter-clockwise rings that don't wrap a pole.
ccw = ~ispolycw(lon,lat);
D180 = fromDegrees(mstruct.angleunits,180);
wrapsPole = abs(lon(first) - lon(last)) > D180;
ccw(wrapsPole) = false;

% Reverse the vertex order in all such rings
if any(ccw(:))
    indx = find(ccw(:));
    for k = 1:numel(indx)
        j = indx(k);
        lat(first(j):last(j)) = lat(last(j):-1:first(j));
        lon(first(j):last(j)) = lon(last(j):-1:first(j));
    end
end

% Trim and project each ring individually
n = numel(first);
xcells = cell(n,1);
ycells = cell(n,1);
for k = 1:n
    latk = lat(first(k):last(k));
    lonk = lon(first(k):last(k));
    [x,y] = feval(mstruct.mapprojection, ...
        mstruct, latk, lonk, 'geopolygon','forward');
    xcells{k} = x;
    ycells{k} = y;
end

% Combine all the rings the trimmed. Ensure that the (x, y) arrays have
% single NaN-separators and a single NaN-terminator (but if there are no
% vertices left, then the arrays should be empty).
[x,y] = polyjoin(xcells,ycells);
[x,y] = removeExtraNanSeparators(x,y);
if ~isempty(x) && ~isnan(x(end))
    x(end+1,1) = NaN;
    y(end+1,1) = NaN;
end
if all(isnan(x(:)))
    x = [];
    y = [];
end
