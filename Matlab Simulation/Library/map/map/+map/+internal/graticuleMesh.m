function [latmesh, lonmesh] = graticuleMesh(latlim, lonlim, sz)
% Return a latitude-longitude graticule mesh spanning the specified limits,
% with the specified size. All three inputs are 1x2. The latlim and lonlim
% inputs should be strictly increasing.

% Copyright 2020 The MathWorks, Inc.

    lat = linspace(latlim(1), latlim(2), sz(1));
    lon = linspace(lonlim(1), lonlim(2), sz(2));
    [latmesh, lonmesh] = ndgrid(lat, lon);
end
