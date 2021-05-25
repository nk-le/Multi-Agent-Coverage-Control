function [rng, az] = trimPolylineToCircle(rng, az, maxrange)
%TRIMPOLYLINETOCIRCLE Trim range-azimuth polyline to circle
%
%   [rngTrimmed, azTrimmed] ...
%        = trimPolylineToCircle(rng, az, maxrange)
%   trims the polyline defined by vectors RNG and AZ to the circle
%   defined by the range limit MAXRANGE.  RNG and AZ may contain
%   multiple parts separated by NaNs.  All inputs and outputs are
%   assumed to be in units of radians.

% Copyright 2007-2015 The MathWorks, Inc.

% Skip operation when possible.
if isempty(rng)
    return
elseif all(isnan(rng))
    rng = NaN;
    az  = NaN;
    return
end

% Work with column vectors throughout, but keep track of input shape.
rowVectorInput = (size(rng,2) > 1);
rng = rng(:);
az  = az (:);

% Make sure lat and az  arrays are NaN-terminated.
nanTerminatedInput = isnan(az (end));
if ~nanTerminatedInput
    az (end+1,1) = NaN;
    rng(end+1,1) = NaN;
end

% Remove extraneous NaN separators, just in case.
[rng, az ] = removeExtraNanSeparators(rng, az);

% Trim range-azimuth to the vertical line defined by rng == maxrange
[az, rng] = truncateCurveOnCircle(rad2deg(az), rng, maxrange);
az = deg2rad(az);

% Make sure terminating NaNs haven't been lost.
if ~isempty(rng) && ~isnan(rng(end))
    rng(end+1,1) = NaN;
    az(end+1,1) = NaN;
end

% Clean up
[rng, az ] = removeExtraNanSeparators(rng, az);

% Make NaN-termination consistent with input.
if nanTerminatedInput && (isempty(az) || ~isnan(az(end)))
    az (end+1,1) = NaN;
    rng(end+1,1) = NaN;
end

% Make shape consistent with input.
if rowVectorInput
    rng = rng';
    az  = az';
end
