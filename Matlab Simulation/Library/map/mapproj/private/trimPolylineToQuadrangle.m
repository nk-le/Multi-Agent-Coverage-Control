function [lat, lon] = ...
    trimPolylineToQuadrangle(lat, lon, latlim, lonlim)
%TRIMPOLYLINETOQUADRANGLE Trim lat-lon polyline to quadrangle
%
%   [latTrimmed, lonTrimmed] ...
%        = trimPolylineToQuadrangle(lat, lon, latlim, lonlim)
%   trims the polyline defined by vectors LAT and LON to the
%   latitude-longitude quadrangle defined by LATLIM and LONLIM. LAT and
%   LON may contain multiple parts separated by NaNs.  All inputs and
%   outputs are assumed to be in units of radians.

% Copyright 2007-2008 The MathWorks, Inc.

% Skip operation when possible.
if isempty(lat)
    return
elseif all(isnan(lat))
    lat = NaN;
    lon = NaN;
    return
end

% Work with column vectors throughout, but keep track of input shape.
rowVectorInput = (size(lat,2) > 1);
lat = lat(:);
lon = lon(:);

% Make sure lat and lon arrays are NaN-terminated.
nanTerminatedInput = isnan(lon(end));
if ~nanTerminatedInput
    lon(end+1,1) = NaN;
    lat(end+1,1) = NaN;
end

% Remove extraneous NaN separators, just in case.
[lat, lon] = removeExtraNanSeparators(lat, lon);

% Make sure the longitudes are unwrapped.
lon = unwrapMultipart(lon);

% Trim latitudes to southern limit.
[lat, lon] = trimPolylineToVerticalLine(lat, lon, latlim(1), 'lower');

% Trim latitudes to northern limit.
[lat, lon] = trimPolylineToVerticalLine(lat, lon, latlim(2), 'upper');

% Trim longitudes.
[lat, lon] = trimPolylineToLonlim(lat, lon, lonlim);

% Make NaN-termination consistent with input.
if nanTerminatedInput && (isempty(lon) || ~isnan(lon(end)))
    lon(end + 1,1) = NaN;
    lat(end + 1,1) = NaN;
end

% Make shape consistent with input.
if rowVectorInput
    lat = lat';
    lon = lon';
end
