function tileNames = globedems(latlim,lonlim)
%GLOBEDEMS GLOBE data filenames for latitude-longitude quadrangle
%
%  tileNames = GLOBEDEMS(LATLIM, LONLIM) returns a cell array of the tile
%  names covering the geographic region for GLOBEDEM digital elevation
%  maps. The region is specified by two-element vectors of latitude and
%  longitude limits in units of degrees.
%
%  tileNames = GLOBEDEMS(LAT, LON) returns a cell array of the tile names
%  covering the geographic region for GLOBEDEM digital elevation maps. The
%  region is specified by scalar latitude and longitude points, in units of
%  degrees.
%
%  See also GEORASTERINFO, READGEORASTER

% Copyright 1996-2019 The MathWorks, Inc.

% Define names and bounding rectangle limits.
[tileNames, latlimS, latlimN, lonlimW, lonlimE] = globetiles();

% Ensure row vectors.
latlim = latlim(:)';
lonlim = lonlim(:)';

% Validate inputs.
if isscalar(latlim) && isnumeric(latlim)
    latlim = latlim(1, [1 1]);
else
    validateattributes(latlim, {'numeric'}, {'size',[1,2]}, ...
        mfilename, 'LATLIM', 1);
end

if isscalar(lonlim) && isnumeric(lonlim)
    lonlim = lonlim(1, [1 1]);
else
    validateattributes(lonlim, {'numeric'}, {'size',[1,2]}, ...
        mfilename, 'LONLIM', 2);
end

% Determine intersecting quads and return those tileNames.
tileNames = intersectTilesWithGeoQuad( ...
    latlim, lonlim, tileNames, lonlimW, lonlimE, latlimS, latlimN);
