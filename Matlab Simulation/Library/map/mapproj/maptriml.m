function [latc, lonc] = maptriml(lat, lon, latlim, lonlim)
%MAPTRIML  Trim lines to latitude-longitude quadrangle
%
%   [LATC, LONC] = MAPTRIML(LAT, LON, LATLIM, LONLIM) trims a line with
%   vertices specified by vectors LAT and LON to the quadrangle specified
%   by LATLIM and LONLIM.  LATLIM is a vector of the form [southern-limit
%   northern-limit] and LONLIM is a vector of the form [western-limit
%   eastern-limit].  All angles are in units of degrees.  Outputs
%   LATC and LONC are column vectors regardless of the shape of
%   inputs LAT and LON.
%
%   Example
%   -------
%   load coastlines
%   [latc, lonc] = maptriml(coastlat, coastlon, [-30 80], [20 230]);
%
%   See also GEOCROP, MAPTRIMP

% Copyright 1996-2019 The MathWorks, Inc.

checklatlon(lat, lon, mfilename, 'LAT', 'LON', 1, 2)
checkgeoquad(latlim, lonlim, mfilename, 'LATLIM', 'LONLIM', 3, 4)
if isempty(lat)
    emptyColumnVector = reshape([],[0 1]);
    latc = emptyColumnVector;
    lonc = emptyColumnVector;
elseif all(isnan(lat))
    latc = NaN;
    lonc = NaN;
else
    [latc, lonc] = map.internal.clip.clipLineToQuadrangle( ...
        lat, lon, latlim(1), latlim(2), lonlim(1), lonlim(2));
    if ~isempty(latc) && ~isnan(latc(end))
        latc(end+1) = NaN;
        lonc(end+1) = NaN;
    end
end
