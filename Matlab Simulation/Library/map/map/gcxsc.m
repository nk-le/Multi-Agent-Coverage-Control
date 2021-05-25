function [lat, lon] = gcxsc(gclat, gclon, gcaz, sclat, sclon, scrho, angleUnit)
%GCXSC  Intersection points for great and small circle pairs
%
%   [LAT,LON] = GCXSC(GCLAT,GCLON,GCAZ,SCLAT,SCLON,SCRHO) finds the
%   intersection points, if any, between a great circle given and a small
%   circle on the sphere. The first 3 inputs are in great circle form, with
%   with each circle defined by the latitude and longitude of a point on
%   that circle and the azimuth at that point. The next 3 are in small
%   circle form: center latitude, center longitude and radius. All inputs
%   and outputs are in degrees. Outputs are column vectors, regardless of
%   the shape of the inputs. The outputs contain NaN for pairs of circles
%   that do not intersect or that coincide.
%
%   [...] = GCXSC(..., angleUnit) uses angleUnit, which matches either
%   'degrees' or 'radians', to specify the units of the latitude,
%   longitude, azimuth, and radius arguments.
%
%   MAT = GCXSC(...) returns a single output, where MAT = [LAT LON].
%
%   Note: The help for GC2SC explains the azimuth and longitude convention
%   for great cicles that start at a pole.
%
%   Example
%   -------
%   gclat = 43;
%   gclon = 0;
%   gcaz = 10;
%   sclat = 47;
%   sclon = 3;
%   scrho = 12;
%   [ilat,ilon] = gcxsc(gclat,gclon,gcaz,sclat,sclon,scrho)
%   % ilat =
%   %    35.5068   58.9143
%   % ilon =
%   %    -1.6159    5.4039
%
%  See also GC2SC, SCXSC, CROSSFIX, GCXGC, RHXRH

% Copyright 1996-2020 The MathWorks, Inc.

    inDegrees = nargin < 7 || map.geodesy.isDegree(angleUnit);

    gclat = gclat(:);
    gclon = gclon(:);
    gcaz  = gcaz(:);
    sclat = sclat(:);
    sclon = sclon(:);
    scrho = scrho(:);
    
    if ~inDegrees
        gclat = rad2deg(gclat);
        gclon = rad2deg(gclon);
        gcaz  = rad2deg(gcaz);
        sclat = rad2deg(sclat);
        sclon = rad2deg(sclon);
        scrho = rad2deg(scrho);
    end

    try
        [ilat1, ilon1, ilat2, ilon2, coincident, nonIntersecting] ...
            = gcxscElementwiseInDegrees(gclat, gclon, gcaz, sclat, sclon, scrho);
    catch me
        if strcmp(me.identifier,'MATLAB:dimagree') || ...
                strcmp(me.identifier,'MATLAB:sizeDimensionsMustMatch')
            error('map:validate:inconsistentSizes6','Inconsistent input sizes.')
        else
            rethrow(me)
        end
    end

    if any(coincident(:))
         warning('map:gcxsc:identicalCircles','Coincident circles.')
    end

    if any(nonIntersecting(:))
        warning('map:gcxsc:noIntersection','Non-intersecting circles.')
    end
    
    % Assign N-by-2 outputs.
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


function [ilat1, ilon1, ilat2, ilon2, coincident, nonIntersecting] ...
    = gcxscElementwiseInDegrees(gclat, gclon, gcaz, sclat, sclon, scrad)

    % Compute unit vectors, cosine of latitude, and sine of latitude for
    % circle centers, points 1 and 2, and longitude of point 1. Point 1 is
    % the great circle center and point 2 is the small circle center. Each
    % element of [nx1 ny1 nz1] is a unit normal to the plane containing a
    % great circle. Each element of [nx2 ny2 nz2] is a unit normal to the
    % plane containing a small circle.
    %
    % All input and output angles are in degrees.

    [nx1, ny1, nz1] = greatCircleNormal(gclat, gclon, gcaz);
    
    cosPhi1 = hypot(nx1,ny1);
    sinPhi1 = nz1;
    lambda1 = atan2d(ny1,nx1);
    
    cosPhi2 = cosd(sclat);
    sinPhi2 = sind(sclat);
    lambda2 = sclon;
    
    nx2 = cosd(lambda2) .* cosPhi2;
    ny2 = sind(lambda2) .* cosPhi2;
    nz2 = sinPhi2;

    % Cosine and sine of distance between circle centers. Guard against
    % round off in the dot product used to compute the cosine.
    cosDelta = min(max(nx1 .* nx2 + ny1 .* ny2 + nz1 .* nz2, -1), 1);
    sinDelta = sqrt(1 - cosDelta .^ 2);
    
    % Simplify the spherical law of cosines for the special case in which
    % circle1 is a great circle.
    cosRelativeAzimuth = cosd(scrad) ./ sinDelta;
    
    % Initialize outputs to NaN and determine which elements correspond to
    % intersecting, non-coincident circles.
    sz = size(cosDelta);
    
    ilat1 = nan(sz);
    ilon1 = nan(sz);
    ilat2 = nan(sz);
    ilon2 = nan(sz);
    
    identicalCenters = ((nx1 ==  nx2) & (ny1 ==  ny2) & (nz1 ==  nz2));
    antipodalCenters = ((nx1 == -nx2) & (ny1 == -ny2) & (nz1 == -nz2));
    
    % The circle can coincide only when the small circle is also a great
    % circle and thus has a radius of 90 degrees.
    coincident = (identicalCenters | antipodalCenters) & (scrad == 90);
    
    nonIntersecting = ~coincident ...
        & (identicalCenters | antipodalCenters | abs(cosRelativeAzimuth) > 1);
    
    % Use the logical column vector q to select only the elements for
    % which the circles intersect and are non-coincident.
    q = ~coincident(:) & ~nonIntersecting(:);
    
    % Compute the intersections only for elements known to have two unique
    % points of intersection (or a single tangent point).
    [ilat1(q), ilon1(q), ilat2(q), ilon2(q)] ...
        = computeIntersections(cosPhi1(q), sinPhi1(q), cosPhi2(q), ...
            sinPhi2(q), lambda1(q), lambda2(q), cosRelativeAzimuth(q));
end


function [ilat1, ilon1, ilat2, ilon2] = computeIntersections( ...
        cosPhi1, sinPhi1, cosPhi2, sinPhi2, lambda1, lambda2, cosRelativeAzimuth)
% Assuming that intersections exist, compute them. This is a general
% elementwise function even though in practice all its inputs are column
% vectors.
    
    % Relative azimuth from point 1 (center of great circle) to the
    % intersection point(s).
    azi = acosd(cosRelativeAzimuth);
    
    % Azimuth from point 1 (center of greate circle) to point 2 (center of
    % small circle).
    az12 = greatCircleAzimuth(cosPhi1, sinPhi1, cosPhi2, sinPhi2, lambda2 - lambda1);
    
    % Compute the two intersection points by following great circles for 90
    % degrees starting from the center of the great circle. They are unique
    % unless azi is zero. When azi is zero, (ilat1,ilon1) and (ilat2,ilon2)
    % contain the coordinates of the same point.
    [ilat1, ilon1] = greatCircleForward90(cosPhi1, sinPhi1, lambda1, az12 - azi);
    [ilat2, ilon2] = greatCircleForward90(cosPhi1, sinPhi1, lambda1, az12 + azi);
end


function az = greatCircleAzimuth(cosPhi1, sinPhi1, cosPhi2, sinPhi2, deltaLambda)
% Input deltaLambda and output AZ are in degrees. This is a elementwise function.

    az = atan2d(cosPhi2 .* sind(deltaLambda),...
        cosPhi1 .* sinPhi2 - sinPhi1 .* cosPhi2 .* cosd(deltaLambda));
end


function [phi, lambda] = greatCircleForward90(cosPhi0, sinPhi0, lambda0, az)
% Follow great circle for 90 degrees starting at specified azimuth. This is
% an elementwise function.

    cosAz = cosd(az);
    sinAz = sind(az);
    
    phi = asind(cosPhi0 .* cosAz);
    lambda = wrapTo180(lambda0 + atan2d(sinAz, -sinPhi0 .* cosAz));
end
