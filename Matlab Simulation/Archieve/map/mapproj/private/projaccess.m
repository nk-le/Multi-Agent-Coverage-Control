function [a, b] = projaccess(direction, proj, c1, c2)
%PROJACCESS Process coordinates using PROJ library
%
%   [X, Y] = PROJACCESS('FWD', PROJ, LAT, LON) applies the forward
%   transformation defined by the map projection in the PROJ structure,
%   converting locations given in latitude and longitude to a planar,
%   projected map coordinate system. PROJ may be either a map projection
%   MSTRUCT or a GeoTIFF INFO structure. The transformation is applied
%   using the PROJ library.
%
%   [LAT, LON] = PROJACCESS('INV', PROJ, X, Y) applies the inverse
%   transformation defined by the map projection in the PROJ structure,
%   converting locations in a planar, projected map coordinate system to
%   latitudes and longitudes.
%
%   See also PROJFWD, PROJINV, PROJLIST

% Copyright 1996-2020 The MathWorks, Inc.

% The PROJ library expects vectors of class double.
% Preserve the class type of the returned values. The inputs to this
% function are expected to be either single or double.
if ~all(strcmp('double', {class(c1), class(c2)}))
    castToSingle = true;
    c1 = double(c1);
    c2 = double(c2);
else
    castToSingle = false;
end

% Find the NaN values and convert to 0. The PROJ library does not accept
% NaN values.
c1NanIndex = find(isnan(c1));
c2NaNIndex = find(isnan(c2));
c1(c1NanIndex) = 0;
c2(c2NaNIndex) = 0;

% Convert the input GTIF structure to a string suitable for the PROJ
% library.
gtif  = proj2gtif(proj);
proj4 = gtif2proj4(gtif);

% Process the points using PROJ
try
    [a, b] = map.internal.crs.transformWithPROJ4String(proj4, direction, c1, c2);
catch
    a = zeros(size(c1));
    b = zeros(size(c2));
end

% Cast the values back to their original class type, if required.
% If any of the vectors are class single, then cast both back to single.
% (This is the same behavior as mfwdtran or minvtran).
if castToSingle
    a = single(a);
    b = single(b);
end

% Reset NaN indices.
% a: lat or x
% b: lon or y
a(c2NaNIndex) = NaN;
b(c1NanIndex) = NaN;

% Reshape output to the input and convert Inf to NaN.
a = reshape(a,size(c2));
a(a==Inf) = NaN;
b = reshape(b,size(c1));
b(b==Inf) = NaN;
