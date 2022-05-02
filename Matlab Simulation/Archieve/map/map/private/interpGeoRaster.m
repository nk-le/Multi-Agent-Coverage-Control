function val = interpGeoRaster(Z, R, lat, lon, method)
%interpGeoRaster Interpolate data grid referenced to geographic coordinates
%
%   VAL = interpGeoRaster(Z, R, LAT, LON, METHOD) interpolates a regular
%   data grid Z with referencing object R at the points specified by
%   vectors of latitude and longitude, LAT and LON. Nearest-neighbor
%   interpolation is used by default.  NaN is returned for points outside
%   the grid limits or for which LAT or LON contain NaN.  All angles are in
%   units of degrees. The string METHOD indicates the method of
%   interpolation: 'linear' for bilinear interpolation, 'cubic' for bicubic
%   interpolation, or 'nearest' for nearest neighbor interpolation.

% Copyright 2010 The MathWorks, Inc.

% Return NaN for points outside the data limits
% and avoid passing such points to interp2.
val = NaN(size(lat));
q = R.contains(lat,lon);

% Work with column vectors.
q = q(:);

% Convert points within the data limits to intrinsic X and Y.
xi = R.longitudeToIntrinsicX(lon(q));
yi = R.latitudeToIntrinsicY(lat(q));

% Raster size.
[M,N] = size(Z);

% Interpolate in intrinsic coordinates.
if strcmp(method,'nearest')
    row = min(round(yi), M);
    col = min(round(xi), N);
    val(q) = Z(row + M*(col - 1));
else
    % Snap in all points that fall within distance 0.5 of an edge, so that
    % we get a non-NaN value for them from interp2.
    xi(0.5 <= xi & xi < 1) = 1;
    yi(0.5 <= yi & yi < 1) = 1;
    xi(N < xi & xi <= N + 0.5) = N;
    yi(M < yi & yi <= M + 0.5) = M;
    
    % Use interp2 for 'linear' and 'cubic', with * to bypass input checks.
    val(q) = interp2(Z, xi, yi, ['*' method]);
end
