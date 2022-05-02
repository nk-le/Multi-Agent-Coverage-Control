function [lat, lon] = gcxgc(lat1, lon1, az1, lat2, lon2, az2, angleUnit)
%GCXGC  Intersection points for pairs of great circles
%
%   [LAT,LON] = GCXGC(LAT1,LON1,AZ1,LAT2,LON2,AZ2) finds both intersection
%   points for pairs of great circles on the sphere.  Inputs are in great
%   circle form, with each circle defined by the latitude and longitude of
%   a point on that circle and the azimuth at that point.  When two circles
%   are identical (which may not be obvious from the inputs), NaNs are
%   returned.  All inputs and outputs are in degrees. Outputs are column
%   vectors, regardless of the shape of the inputs.
%
%   [...] = GCXGC(..., angleUnit) uses angleUnit, which matches either
%   'degrees' or 'radians', to specify the units of the latitude,
%   longitude, and azimuth arguments.
%
%   MAT = GCXGC(...) returns a single output, where MAT = [LAT LON].
%
%   Note: The help for GC2SC explains the azimuth and longitude convention
%   for great circles that start at a pole.
%
%   Example
%   -------
%   lat1 = 10;
%   lon1 = 13;
%   az1 = 12;
%   lat2 = 0;
%   lon2 = 20;
%   az2 = -23;
%   [ilat,ilon] = gcxgc(lat1,lon1,az1,lat2,lon2,az2)
%   % ilat =
%   %    14.0725  -14.0725
%   % ilon =
%   %    13.8919 -166.1081
%
%   See also GC2SC, GCXSC, SCXSC, CROSSFIX, RHXRH, POLYXPOLY

% Copyright 1996-2020 The MathWorks, Inc.

    inDegrees = nargin < 7 || map.geodesy.isDegree(angleUnit);

    lat1 = lat1(:);
    lon1 = lon1(:);
    az1  = az1(:);
    lat2 = lat2(:);
    lon2 = lon2(:);
    az2  = az2(:);
    
    if ~inDegrees
        lat1 = rad2deg(lat1);
        lon1 = rad2deg(lon1);
        az1  = rad2deg(az1);
        lat2 = rad2deg(lat2);
        lon2 = rad2deg(lon2);
        az2  = rad2deg(az2);
    end

    try
        [ilat1, ilon1, ilat2, ilon2] ...
            = gcxgcElementwiseInDegrees(lat1, lon1, az1, lat2, lon2, az2);
    catch me
        if strcmp(me.identifier,'MATLAB:dimagree') || ...
                strcmp(me.identifier,'MATLAB:sizeDimensionsMustMatch')
            error('map:validate:inconsistentSizes6','Inconsistent input sizes.')
        else
            rethrow(me)
        end
    end

    % Combine and reshape output.
    lat = [ilat1(:) ilat2(:)];
    lon = [ilon1(:) ilon2(:)];

    if ~inDegrees
        lat = deg2rad(lat);
        lon = deg2rad(lon);
    end

    if nargout < 2
        % Combine results into single output.
        lat = [lat lon];
    end
end


function [ilat1, ilon1, ilat2, ilon2] ...
    = gcxgcElementwiseInDegrees(lat1, lon1 ,az1, lat2, lon2, az2)
% Return the latitude and longitude of one of the two intersection points
% for pair of great circle inputs, with NaN designating coincident circles.
% All input and output angles are in degrees.

    % Locate one pole of each circle on the unit sphere in a
    % sphere-centered Cartesian system.
    [nx1, ny1, nz1] = greatCircleNormal(lat1, lon1, az1);
    [nx2, ny2, nz2] = greatCircleNormal(lat2, lon2, az2);

    % Find a point 90 degrees from the center of both circles.
    [xi, yi, zi] = crossProduct(nx1, ny1, nz1, nx2, ny2, nz2);

    % Find the length the projection of the cross product in the X-Y plane.
    lengthOfProjectionInXY = hypot(xi, yi);

    % Find the length of the overall cross product. The result is a number
    % in the closed interval [0 1], and will equal very when for any pair
    % of great circles with identical or antipodal poles, indicating
    % coincident circles. Otherwise (when the length of the cross product
    % is non-zero) the circles are distinct.
    lengthOfCrossProduct = hypot(lengthOfProjectionInXY, zi);
    distinctCircles = (lengthOfCrossProduct > 0);

    % Initialize all output elements to NaN, then assign values to the ones
    % corresponding to distinct circles.
    ilat1 = nan(size(lengthOfCrossProduct));
    ilon1 = nan(size(lengthOfCrossProduct));
    q = distinctCircles(:);
    ilat1(q) = atan2d(zi(q), lengthOfProjectionInXY(q));
    ilon1(q) = atan2d(yi(q), xi(q));
    
    % There's another intersection at the antipode of the first.
    [ilat2, ilon2] = antipode(ilat1, ilon1);
end


function [wx, wy, wz] = crossProduct(ux, uy, uz, vx, vy, vz)
% Elementwise cross product of 3-vectors

    wx = uy .* vz - uz .* vy;
    wy = uz .* vx - ux .* vz;
    wz = ux .* vy - uy .* vx;
end
