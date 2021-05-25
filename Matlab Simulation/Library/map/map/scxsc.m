function [lat, lon] = scxsc(lat1, lon1, rho1, lat2, lon2, rho2, angleUnit)
%SCXSC  Intersection points for pairs of small circles
%
%   [LAT,LON] = SCXSC(LAT1,LON1,RHO1,LAT2,LON2,RHO2) finds the intersection
%   points between pairs of small circles on the sphere. The circles are
%   defined by their center points (LAT1,LON1) and (LAT2,LON2) and radii
%   (RHO1 and RHO2), with each radius expressed as a spherical (angular)
%   distance. In the case of tangent circles, the tangent point is included
%   twice. All inputs and outputs are in degrees. Given scalar inputs, LAT
%   and LON are 1-by-2 row vectors. Otherwise they are N-by-2 matrices. The
%   outputs contain NaN for pairs of circles that do not intersect or that
%   coincide (including circles of zero radius that coincide).
%
%   [...] = SCXSC(..., angleUnit) uses angleUnit, which matches either
%   'degrees' or 'radians', to specify the units of the latitude,
%   longitude, and radius arguments.
%
%   MAT = SCXSC(...) returns a single N-by-4 output, MAT = [LAT LON].
%
%   Example
%   -------
%   lat1 = -10;
%   lon1 = -170;
%   rho1 = 20;
%   lat2 = 3;
%   lon2 = 179;
%   rho2 = 15;
%   [ilat,ilon] = scxsc(lat1,lon1,rho1,lat2,lon2,rho2)
%   % ilat =
%   %    -8.8368    9.8526
%   % ilon =
%   %    169.7578 -167.5637
%
%   See also GCXGC, GCXSC, RHXRH, POLYXPOLY

% Copyright 1996-2020 The MathWorks, Inc.

    inDegrees = (nargin < 7 || map.geodesy.isDegree(angleUnit));

    lat1 = lat1(:);
    lon1 = lon1(:);
    rho1 = rho1(:);
    lat2 = lat2(:);
    lon2 = lon2(:);
    rho2 = rho2(:);
    
    if ~inDegrees
        lat1 = rad2deg(lat1);
        lon1 = rad2deg(lon1);
        rho1 = rad2deg(rho1);
        lat2 = rad2deg(lat2);
        lon2 = rad2deg(lon2);
        rho2 = rad2deg(rho2);
    end
    
    try
        [ilat1, ilon1, ilat2, ilon2, coincident, nonIntersecting] ...
            = scxscElementwiseInDegrees(lat1, lon1, rho1, lat2, lon2, rho2);
    catch me
        if strcmp(me.identifier,'MATLAB:dimagree') || ...
                strcmp(me.identifier,'MATLAB:sizeDimensionsMustMatch')
            error('map:validate:inconsistentSizes6','Inconsistent input sizes.')
        else
            rethrow(me)
        end
    end
    
    if any(coincident(:))
         warning('map:scxsc:identicalCircles','Coincident circles.')
    end

    if any(nonIntersecting(:))
        warning('map:scxsc:noIntersection','Non-intersecting circles.')
    end
    
    % Assign N-by-2 outputs.
    lat = [ilat1(:) ilat2(:)];
    lon = [ilon1(:) ilon2(:)];
    
    if ~inDegrees
        lat = deg2rad(lat);
        lon = deg2rad(lon);
    end
    
    if nargout < 2
        % Combine results into single N-by-4 output.
        lat = [lat lon];
    end
end


function [ilat1, ilon1, ilat2, ilon2, coincident, nonIntersecting] ...
    = scxscElementwiseInDegrees(lat1, lon1, rho1, lat2, lon2, rho2)

    rho1 = reflectAt180(rho1);
    rho2 = reflectAt180(rho2);

    [lat1, lon1, rho1, lat2, lon2, rho2] ...
        = largerCircleFirst(lat1, lon1, rho1, lat2, lon2, rho2);
    
    % Compute unit vectors. Each element of [nx1 ny1 nz1] is a unit normal
    % to the plane containing one of the first set of circles. Each element
    % of [nx2 ny2 nz2] is a unit normal to the plane containing one of the
    % second set of circles.
    
    cosPhi1 = cosd(lat1);
    sinPhi1 = sind(lat1);
    lambda1 = lon1;
    
    nx1 = cosd(lambda1) .* cosPhi1;
    ny1 = sind(lambda1) .* cosPhi1;
    nz1 = sinPhi1;

    cosPhi2 = cosd(lat2);
    sinPhi2 = sind(lat2);
    lambda2 = lon2;
    
    nx2 = cosd(lambda2) .* cosPhi2;
    ny2 = sind(lambda2) .* cosPhi2;
    nz2 = sinPhi2;
    
    % Cosine and sine of distance between circle centers. Guard against
    % round off in the dot product used to compute the cosine.
    cosDelta = min(max(nx1 .* nx2 + ny1 .* ny2 + nz1 .* nz2, -1), 1);
    sinDelta = sqrt(1 - cosDelta .^ 2);
    
    % Apply the spherical law of cosines. The denominator will be non-zero
    % except for pairs of circles that are concentric or that both have
    % zero radius.
    cosRelativeAzimuth ...
        = (cosd(rho2) - cosDelta .* cosd(rho1)) ./ (sinDelta .* sind(rho1));
    
    % Initialize outputs to NaN and determine which elements correspond to
    % intersecting, non-coincident circles.
    sz = size(cosDelta);
    
    ilat1 = nan(sz);
    ilon1 = nan(sz);
    ilat2 = nan(sz);
    ilon2 = nan(sz);
    
    identicalCenters = ((nx1 ==  nx2) & (ny1 ==  ny2) & (nz1 ==  nz2));
    antipodalCenters = ((nx1 == -nx2) & (ny1 == -ny2) & (nz1 == -nz2));
    
    coincident = (identicalCenters & (rho1 == rho2)) ...
        | (antipodalCenters & (rho1 + rho2 == 180));
    
    nonIntersecting = ~coincident ...
        & (identicalCenters | antipodalCenters | abs(cosRelativeAzimuth) > 1);
    
    % Use the logical column vector q to select only the elements for
    % which the circles intersect and are non-coincident.
    q = ~coincident(:) & ~nonIntersecting(:);
    
    % Compute the intersections only for elements known to have two unique
    % points of intersection (or a single tangent point).
    [ilat1(q), ilon1(q), ilat2(q), ilon2(q)] ...
        = computeIntersections(cosPhi1(q), sinPhi1(q), cosPhi2(q), ...
            sinPhi2(q), lambda1(q), lambda2(q), cosRelativeAzimuth(q), rho1(q));
end


function rho = reflectAt180(rho)
% Map rho to the range [0 180]. The graph of this function has a
% sawtooth shape, with a minimum of zero when rho is a multiple of 360
% and maximum of 180 when rho = 180 + N*360, for integer N.
    rho = mod(rho, 360);
    rho(rho > 180) = 360 - rho(rho > 180);
end


function [lat1, lon1, rho1, lat2, lon2, rho2] ...
    = largerCircleFirst(lat1, lon1, rho1, lat2, lon2, rho2)
    
    q = (rho1(:) < rho2(:));
    [lat1(q), lat2(q)] = swap(lat1(q), lat2(q));
    [lon1(q), lon2(q)] = swap(lon1(q), lon2(q));
    [rho1(q), rho2(q)] = swap(rho1(q), rho2(q));
end


function [x,y] = swap(x,y)
    t = x;
    x = y;
    y = t;
end


function [ilat1, ilon1, ilat2, ilon2] = computeIntersections(cosPhi1, ...
    sinPhi1, cosPhi2, sinPhi2, lambda1, lambda2, cosRelativeAzimuth, rho1)
% Assuming that intersections exist, compute them. This is a general
% elementwise function even though in practice all its inputs are column
% vectors.
    
    % Relative azimuth from point 1 (center of great circle) to the
    % intersection point(s).
    azi = acosd(cosRelativeAzimuth);
    
    % Azimuth from point 1 (center of greate circle) to point 2 (center of
    % small circle).
    az12 = greatCircleAzimuth(cosPhi1, sinPhi1, cosPhi2, sinPhi2, lambda2 - lambda1);
    
    % Compute the two intersection points by following great circles for
    % (spherical) distance rho1 starting from the center of the first
    % circle. They are unique unless azi is zero, in which case both
    % (ilat1, ilon1) and (ilat2, ilon2) will contain the coordinates of the
    % same point.
    [ilat1, ilon1] = greatCircleForward(cosPhi1, sinPhi1, lambda1, az12 - azi, rho1);
    [ilat2, ilon2] = greatCircleForward(cosPhi1, sinPhi1, lambda1, az12 + azi, rho1);
end


function az = greatCircleAzimuth(cosPhi1, sinPhi1, cosPhi2, sinPhi2, deltaLambda)
% Input deltaLambda and output AZ are in degrees. This is a elementwise function.

    az = atan2d(cosPhi2 .* sind(deltaLambda),...
        cosPhi1 .* sinPhi2 - sinPhi1 .* cosPhi2 .* cosd(deltaLambda));
end


function [phi, lambda] = greatCircleForward(cosPhi0, sinPhi0, lambda0, az, arclen)
% Great circle forward computation with angles in degrees. This is an
% elementwise function.

    cosDelta = cosd(arclen);
    sinDelta = sind(arclen);

    cosAz = cosd(az);
    sinAz = sind(az);

    phi = asind(sinPhi0.*cosDelta + cosPhi0.*sinDelta.*cosAz);
    dlambda = atan2d(sinDelta.*sinAz, cosPhi0.*cosDelta - sinPhi0.*sinDelta.*cosAz);
    lambda = wrapTo180(lambda0 + dlambda);
end
